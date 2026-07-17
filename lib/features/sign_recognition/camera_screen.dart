/// JARVIS — Camera Screen
/// Real-time sign language recognition with camera feed.
/// Wires the ML pipeline: Camera → Hand Landmarks → Gesture Classification → Sequence → LLM

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/camera_service.dart';
import '../../services/gesture_service.dart';
import '../../services/gesture_sequence_service.dart';
import '../../services/api_service.dart';
import '../../services/emergency_service.dart';
import '../../services/speech_service.dart';
import '../../models/gesture_model.dart';
import '../../models/intent_model.dart';
import '../../widgets/gesture_card.dart';
import '../../widgets/intent_card.dart';
import '../../widgets/emergency_banner.dart';
import '../emergency/emergency_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<String>? demoGestures;

  const CameraScreen({super.key, this.demoGestures});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final GestureService _gestureService = GestureService();
  final GestureSequenceService _sequenceService = GestureSequenceService();
  final ApiService _apiService = ApiService();
  final EmergencyService _emergencyService = EmergencyService();
  final SpeechService _speechService = SpeechService();

  IntentResult? _intentResult;
  bool _isInterpreting = false;
  bool _isStreamingFrames = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize ML models and camera in parallel
    await Future.wait([
      _gestureService.initialize(),
      _cameraService.initialize(),
      _speechService.initialize(),
    ]);

    // If demo gestures provided, simulate them
    if (widget.demoGestures != null && widget.demoGestures!.isNotEmpty) {
      _simulateDemoGestures(widget.demoGestures!);
    } else if (_cameraService.isInitialized && _gestureService.isModelLoaded) {
      // Start real-time processing if models are ready
      _startFrameStream();
    }

    if (mounted) setState(() {});
  }

  /// Start streaming camera frames to the gesture recognition pipeline.
  void _startFrameStream() {
    if (_isStreamingFrames) return;

    _cameraService.startImageStream((CameraImage image) async {
      final result = await _gestureService.processFrame(image);
      if (result != null && mounted) {
        _sequenceService.addGesture(result);
        setState(() {});
      }
    });

    _isStreamingFrames = true;
  }

  /// Stop the frame stream.
  Future<void> _stopFrameStream() async {
    if (!_isStreamingFrames) return;
    await _cameraService.stopImageStream();
    _isStreamingFrames = false;
  }

  Future<void> _simulateDemoGestures(List<String> gestures) async {
    // Simulate gestures one by one with delay
    for (final gesture in gestures) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = _gestureService.simulateGesture(gesture);
      _sequenceService.addGesture(result);
      if (mounted) setState(() {});
    }

    // Auto-complete and interpret
    await Future.delayed(const Duration(milliseconds: 300));
    _sequenceService.completeSequence();
    if (mounted) setState(() {});
    await _interpretSequence();
  }

  Future<void> _interpretSequence() async {
    if (_sequenceService.isEmpty) return;

    // Pause frame stream during interpretation to avoid conflicts
    await _stopFrameStream();

    setState(() {
      _isInterpreting = true;
      _error = null;
    });

    try {
      // Check for emergency first (deterministic rules)
      final alert = _emergencyService.checkForEmergency(
        _sequenceService.gestureLabels,
      );

      // Call backend for LLM interpretation
      final result = await _apiService.interpretGestures(
        gestures: _sequenceService.gestureLabels,
        confidenceScores: _sequenceService.confidenceScores,
      );

      if (mounted) {
        setState(() {
          _intentResult = result;
          _isInterpreting = false;
        });

        // If emergency, navigate to emergency screen
        if (alert != null) {
          _navigateToEmergency();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Interpretation failed: $e';
          _isInterpreting = false;
        });
      }
    }
  }

  void _navigateToEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyScreen()),
    );
  }

  void _resetAll() {
    _sequenceService.reset();
    _intentResult = null;
    _error = null;
    _gestureService.clearGesture();
    setState(() {});

    // Resume frame stream after reset
    if (_cameraService.isInitialized && _gestureService.isModelLoaded) {
      _startFrameStream();
    }
  }

  @override
  void dispose() {
    _stopFrameStream();
    _cameraService.dispose();
    _gestureService.dispose();
    _sequenceService.dispose();
    _speechService.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              _buildAppBar(),

              // ── Model Status Banner ──
              if (_gestureService.isInitializing) _buildModelLoadingBanner(),
              if (!_gestureService.isInitializing && !_gestureService.isModelLoaded)
                _buildSimulationModeBanner(),

              // ── Camera Preview ──
              Expanded(
                flex: 3,
                child: _buildCameraPreview(),
              ),

              // ── Emergency Banner ──
              if (_emergencyService.hasActiveAlert)
                EmergencyBanner(
                  alert: _emergencyService.activeAlert!,
                  onTap: _navigateToEmergency,
                  onDismiss: () {
                    _emergencyService.dismissAlert();
                    setState(() {});
                  },
                ),

              // ── Gesture Sequence ──
              _buildSequenceBar(),

              // ── Intent Result or Loading ──
              Expanded(
                flex: 2,
                child: _buildResultArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelLoadingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryCyan.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryCyan,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading ML models...',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryCyan,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationModeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simulation mode — ML models not loaded. Check logs for TFLite crash.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'SIGN RECOGNITION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                if (_gestureService.isModelLoaded)
                  const Text(
                    '● LIVE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.greenAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetAll,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCyan),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraService.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryCyan),
            const SizedBox(height: 16),
            Text(
              _cameraService.error ?? 'Initializing camera...',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            // Demo gesture buttons as fallback
            const SizedBox(height: 24),
            _buildDemoButtons(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera feed
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CameraPreview(_cameraService.controller!),
            ),
          ),
        ),
        // Gesture overlay (shows current detected gesture)
        if (_gestureService.currentGesture != null)
          Positioned(
            bottom: 16,
            left: 32,
            right: 32,
            child: GestureCard(
              gesture: _gestureService.currentGesture!,
              isActive: true,
            ),
          ),
        // Controls overlay
        Positioned(
          top: 16,
          right: 32,
          child: Column(
            children: [
              // Camera switch button
              _MiniActionButton(
                icon: Icons.flip_camera_android_rounded,
                onTap: () async {
                  await _stopFrameStream();
                  await _cameraService.switchCamera();
                  if (_gestureService.isModelLoaded) {
                    _startFrameStream();
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              // Quick demo button (fallback)
              if (!_gestureService.isModelLoaded)
                _MiniDemoButton(
                  label: '🤟',
                  onTap: () {
                    final g = _gestureService.simulateGesture('HELLO');
                    _sequenceService.addGesture(g);
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: AppConstants.gestureLabels.take(12).map((label) {
        return _DemoGestureButton(
          label: label,
          onTap: () {
            final g = _gestureService.simulateGesture(label);
            _sequenceService.addGesture(g);
            setState(() {});
          },
        );
      }).toList(),
    );
  }

  Widget _buildSequenceBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceOverlay),
      ),
      child: Row(
        children: [
          const Icon(Icons.gesture_rounded, size: 20, color: AppTheme.primaryCyan),
          const SizedBox(width: 8),
          Expanded(
            child: _sequenceService.isEmpty
                ? Text(
                    _gestureService.isModelLoaded
                        ? 'Show gestures to the camera...'
                        : 'Perform gestures to build a sequence...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sequenceService.sequence.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureChip(
                            label: g.label,
                            isEmergency: AppConstants.emergencyGestures.contains(g.label),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Interpret button
          if (!_sequenceService.isEmpty)
            Material(
              color: AppTheme.primaryCyan,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isInterpreting
                    ? null
                    : () {
                        _sequenceService.completeSequence();
                        _interpretSequence();
                      },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: _isInterpreting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surfaceDark,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: AppTheme.surfaceDark,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isInterpreting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryCyan),
            SizedBox(height: 16),
            Text(
              'JARVIS is interpreting...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.emergencyRed),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _interpretSequence,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_intentResult != null) {
      return SingleChildScrollView(
        child: IntentCard(
          intent: _intentResult!,
          onSpeak: () => _speechService.speak(_intentResult!.message),
          onTranslate: () {
            // Navigate to translation with the message
          },
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sign_language_rounded,
            size: 48,
            color: AppTheme.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _gestureService.isModelLoaded
                ? 'Show gestures to the camera\nJARVIS will recognize them in real-time'
                : 'Build a gesture sequence\nthen tap interpret',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _MiniDemoButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MiniDemoButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

class _DemoGestureButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DemoGestureButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceOverlay),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
