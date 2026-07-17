/// JARVIS — Hand Landmark Service
/// Extracts 21 hand landmarks from camera frames using MediaPipe's
/// palm detection + hand landmark TFLite models via tflite_flutter.
///
/// Two-stage pipeline:
///   1. Palm Detection: Detects hand presence in the full frame
///   2. Hand Landmark: Extracts 21 3D keypoints from the detected hand region
///
/// For the hackathon MVP, we use a simplified single-pass approach where
/// the hand landmark model processes the full frame directly (assuming
/// the hand is roughly centered, which works well with a front-facing camera).

import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/utils/logger.dart';

/// Result of hand landmark detection.
class HandLandmarkResult {
  /// 21 landmarks, each with (x, y, z) in normalized coordinates.
  final List<List<double>> landmarks;

  /// Detection confidence score [0, 1].
  final double confidence;

  /// Whether a hand was detected.
  final bool handDetected;

  const HandLandmarkResult({
    required this.landmarks,
    required this.confidence,
    required this.handDetected,
  });

  /// Get a specific landmark by index (0-20).
  List<double> operator [](int index) => landmarks[index];

  /// Flatten landmarks to a 63-element list for the gesture classifier.
  List<double> flatten() {
    final result = <double>[];
    for (final lm in landmarks) {
      result.addAll(lm);
    }
    return result;
  }

  /// Normalize landmarks: translate wrist to origin, scale by max distance.
  /// This matches the normalization used during training.
  HandLandmarkResult normalized() {
    if (!handDetected || landmarks.isEmpty) return this;

    final wrist = landmarks[0];
    final centered = landmarks.map((lm) {
      return [lm[0] - wrist[0], lm[1] - wrist[1], lm[2] - wrist[2]];
    }).toList();

    // Find max distance from wrist
    double maxDist = 0;
    for (final lm in centered) {
      final dist = sqrt(lm[0] * lm[0] + lm[1] * lm[1] + lm[2] * lm[2]);
      if (dist > maxDist) maxDist = dist;
    }

    if (maxDist < 1e-6) return this;

    final scaled = centered.map((lm) {
      return [lm[0] / maxDist, lm[1] / maxDist, lm[2] / maxDist];
    }).toList();

    return HandLandmarkResult(
      landmarks: scaled,
      confidence: confidence,
      handDetected: handDetected,
    );
  }

  static const HandLandmarkResult empty = HandLandmarkResult(
    landmarks: [],
    confidence: 0.0,
    handDetected: false,
  );
}

/// Service for extracting hand landmarks from camera frames.
///
/// Uses MediaPipe's hand landmark lite TFLite model.
/// Input: 224x224 RGB image normalized to [0, 1]
/// Output: 21 landmarks (x, y, z) + handedness score
class HandLandmarkService extends ChangeNotifier {
  Interpreter? _landmarkInterpreter;
  bool _isLoaded = false;
  bool _isProcessing = false;

  // Model input dimensions (hand_landmark_lite expects 224x224)
  static const int _inputSize = 224;
  static const int _numLandmarks = 21;
  static const int _coordsPerLandmark = 3;

  bool get isLoaded => _isLoaded;
  bool get isProcessing => _isProcessing;

  /// Initialize the hand landmark model.
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      AppLogger.info('HandLandmark', 'Loading hand landmark model...');

      // Load the hand landmark lite model
      _landmarkInterpreter = await Interpreter.fromAsset(
        'models/hand_landmark_lite.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      _isLoaded = true;

      // Log model input/output tensor info for debugging
      final inputTensors = _landmarkInterpreter!.getInputTensors();
      final outputTensors = _landmarkInterpreter!.getOutputTensors();
      AppLogger.info('HandLandmark',
          'Model loaded — inputs: ${inputTensors.length}, outputs: ${outputTensors.length}');
      for (int i = 0; i < inputTensors.length; i++) {
        AppLogger.info('HandLandmark',
            '  Input[$i]: shape=${inputTensors[i].shape}, type=${inputTensors[i].type}');
      }
      for (int i = 0; i < outputTensors.length; i++) {
        AppLogger.info('HandLandmark',
            '  Output[$i]: shape=${outputTensors[i].shape}, type=${outputTensors[i].type}');
      }

      // Warm up
      _landmarkInterpreter?.allocateTensors();

      _isLoaded = true;
      AppLogger.info('HandLandmarks', 'Model loaded successfully.');
      notifyListeners();
    } catch (e) {
      _isLoaded = false;
      mlErrorMsg = 'Landmark Error: $e';
      AppLogger.error('HandLandmarks', 'Failed to load model: $e');
    }
  }
  
  String? mlErrorMsg;

  /// Process a camera frame and extract hand landmarks.
  Future<HandLandmarkResult> processFrame(CameraImage cameraImage) async {
    if (!_isLoaded || _landmarkInterpreter == null || _isProcessing) {
      return HandLandmarkResult.empty;
    }

    _isProcessing = true;

    try {
      // Convert CameraImage to RGB
      final rgbImage = _convertCameraImage(cameraImage);
      if (rgbImage == null) {
        return HandLandmarkResult.empty;
      }

      // Resize to model input size
      final resized = img.copyResize(
        rgbImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Prepare input tensor: [1, 224, 224, 3] normalized to [0, 1]
      final input = _imageToFloat32List(resized);

      // Run the landmark model
      // The hand_landmark_lite model has multiple outputs:
      // - Output 0: landmarks [1, 63] (21 landmarks × 3 coords)
      // - Output 1: hand presence confidence [1, 1]
      // - Output 2: handedness [1, 1]
      // Note: actual output shapes may vary — we adapt dynamically
      final outputTensors = _landmarkInterpreter!.getOutputTensors();
      final outputs = <int, Object>{};

      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        outputs[i] = _allocateOutput(shape);
      }

      _landmarkInterpreter!.runForMultipleInputs([input], outputs);

      // Parse results (adapt to model output format)
      return _parseModelOutput(outputs, outputTensors);
    } catch (e) {
      AppLogger.error('HandLandmark', 'Frame processing error', e);
      return HandLandmarkResult.empty;
    } finally {
      _isProcessing = false;
    }
  }

  /// Parse the model output into HandLandmarkResult.
  /// Adapts dynamically to the model's output tensor shapes.
  HandLandmarkResult _parseModelOutput(
    Map<int, Object> outputs,
    List<Tensor> outputTensors,
  ) {
    try {
      double confidence = 0.5; // Default confidence
      List<List<double>> landmarks = [];

      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        final totalElements = shape.reduce((a, b) => a * b);

        if (totalElements == 63 || totalElements == 63 * 1) {
          // This is the landmarks output (21 × 3 = 63)
          final flat = _flattenOutput(outputs[i]!);
          for (int j = 0; j < 21; j++) {
            landmarks.add([
              flat[j * 3],
              flat[j * 3 + 1],
              flat[j * 3 + 2],
            ]);
          }
        } else if (totalElements == 1) {
          // This could be confidence or handedness
          final flat = _flattenOutput(outputs[i]!);
          final value = flat[0];
          // Use sigmoid if the value is a logit
          final prob = value > 10 ? 1.0 : (value < -10 ? 0.0 : 1.0 / (1.0 + exp(-value)));
          if (i <= 1) {
            // First small output is typically confidence
            confidence = prob;
          }
        }
      }

      // If we couldn't parse landmarks from the expected output format,
      // try to find the largest output and interpret as landmarks
      if (landmarks.isEmpty) {
        for (int i = 0; i < outputTensors.length; i++) {
          final flat = _flattenOutput(outputs[i]!);
          if (flat.length >= 63) {
            for (int j = 0; j < 21; j++) {
              landmarks.add([
                flat[j * 3],
                flat[j * 3 + 1],
                flat[j * 3 + 2],
              ]);
            }
            break;
          }
        }
      }

      final handDetected = confidence > 0.5 && landmarks.isNotEmpty;

      return HandLandmarkResult(
        landmarks: landmarks,
        confidence: confidence,
        handDetected: handDetected,
      );
    } catch (e) {
      AppLogger.error('HandLandmark', 'Output parsing error', e);
      return HandLandmarkResult.empty;
    }
  }

  /// Flatten nested output list to a flat List<double>.
  List<double> _flattenOutput(Object output) {
    final result = <double>[];
    _flattenRecursive(output, result);
    return result;
  }

  void _flattenRecursive(Object obj, List<double> result) {
    if (obj is double) {
      result.add(obj);
    } else if (obj is num) {
      result.add(obj.toDouble());
    } else if (obj is List) {
      for (final item in obj) {
        _flattenRecursive(item, result);
      }
    }
  }

  /// Allocate output buffer matching the tensor shape.
  Object _allocateOutput(List<int> shape) {
    if (shape.length == 1) {
      return List.filled(shape[0], 0.0);
    } else if (shape.length == 2) {
      return List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
    } else if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)),
      );
    } else if (shape.length == 4) {
      return List.generate(
        shape[0],
        (_) => List.generate(
          shape[1],
          (_) => List.generate(shape[2], (_) => List.filled(shape[3], 0.0)),
        ),
      );
    }
    return List.filled(shape.reduce((a, b) => a * b), 0.0);
  }

  /// Convert CameraImage to RGB Image.
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.nv21) {
        return _convertNV21(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA(cameraImage);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  img.Image _convertNV21(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0].bytes;
    final uvPlane = cameraImage.planes[1].bytes;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * width + (x & ~1);

        if (yIndex >= yPlane.length || uvIndex + 1 >= uvPlane.length) continue;

        final yVal = yPlane[yIndex];
        final vVal = uvPlane[uvIndex];
        final uVal = uvPlane[uvIndex + 1];

        final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  img.Image _convertYUV420(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;
    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIdx = y * yRowStride + x;
        final uIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        final vIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        if (yIdx >= yPlane.length || uIdx >= uPlane.length || vIdx >= vPlane.length) continue;

        final yVal = yPlane[yIdx];
        final uVal = uPlane[uIdx];
        final vVal = vPlane[vIdx];

        final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  img.Image _convertBGRA(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final bytes = cameraImage.planes[0].bytes;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if (i + 2 >= bytes.length) continue;
        image.setPixelRgb(x, y, bytes[i + 2], bytes[i + 1], bytes[i]);
      }
    }
    return image;
  }

  /// Convert Image to model input as [1, 224, 224, 3] Float32 tensor.
  List<List<List<List<double>>>> _imageToFloat32List(img.Image image) {
    return List.generate(1, (_) {
      return List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        });
      });
    });
  }

  @override
  void dispose() {
    _landmarkInterpreter?.close();
    super.dispose();
  }
}
