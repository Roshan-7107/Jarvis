/// JARVIS — Camera Service
/// Manages camera lifecycle, frame capture, and permissions.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _error;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Initialize the camera system.
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _error = 'No cameras available';
        AppLogger.error('Camera', _error!);
        notifyListeners();
        return;
      }

      // Prefer front camera for sign language recognition
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _initController(frontCamera);
    } catch (e) {
      _error = 'Camera initialization failed: $e';
      AppLogger.error('Camera', _error!, e);
      notifyListeners();
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
      _error = null;
      AppLogger.info('Camera', 'Initialized: ${camera.lensDirection}');
      notifyListeners();
    } catch (e) {
      _error = 'Camera controller error: $e';
      AppLogger.error('Camera', _error!, e);
      notifyListeners();
    }
  }

  /// Switch between front and back cameras.
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    final currentDirection = _controller?.description.lensDirection;
    final nextCamera = _cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );

    await _controller?.dispose();
    _isInitialized = false;
    notifyListeners();

    await _initController(nextCamera);
  }

  /// Start streaming camera frames for gesture processing.
  Future<void> startImageStream(Function(CameraImage) onFrame) async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.startImageStream(onFrame);
      AppLogger.info('Camera', 'Image stream started');
    } catch (e) {
      AppLogger.error('Camera', 'Failed to start stream', e);
    }
  }

  /// Stop the camera image stream.
  Future<void> stopImageStream() async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.stopImageStream();
      AppLogger.info('Camera', 'Image stream stopped');
    } catch (e) {
      AppLogger.error('Camera', 'Failed to stop stream', e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
