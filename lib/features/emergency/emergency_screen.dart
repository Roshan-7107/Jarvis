/// JARVIS — Emergency Screen
/// Emergency alert display and simulated SOS workflow.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyService _emergencyService = EmergencyService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sosTriggered = false;
  Map<String, dynamic>? _sosResult;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    // Create a demo emergency
    _emergencyService.checkForEmergency(['HELP', 'FIRE']);

    setState(() => _sosTriggered = true);

    // Simulate SOS workflow
    final result = await _emergencyService.simulateSOS();
    if (mounted) {
      setState(() => _sosResult = result);
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const Expanded(
                      child: Text(
                        'EMERGENCY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.emergencyRed,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── SOS Button ──
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _sosTriggered ? 1.0 : _pulseAnimation.value,
                            child: GestureDetector(
                              onTap: _sosTriggered ? null : _triggerSOS,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _sosTriggered
                                      ? null
                                      : AppTheme.emergencyGradient,
                                  color: _sosTriggered
                                      ? AppTheme.emergencyRed.withOpacity(0.3)
                                      : null,
                                  boxShadow: _sosTriggered
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppTheme.emergencyRed
                                                .withOpacity(
                                                    0.4 * _pulseAnimation.value),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: Text(
                                    _sosTriggered ? '✅' : 'SOS',
                                    style: TextStyle(
                                      fontSize: _sosTriggered ? 48 : 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Text(
                        _sosTriggered
                            ? 'SOS Alert Sent'
                            : 'Tap to Simulate SOS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _sosTriggered
                              ? AppTheme.successGreen
                              : AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Emergency gestures (HELP + FIRE, HELP + POLICE, etc.)\nautomatically trigger this screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── SOS Result ──
                      if (_sosResult != null) ...[
                        _ResultCard(
                          icon: Icons.location_on_rounded,
                          label: 'Location Captured',
                          value:
                              '${_sosResult!['latitude']}, ${_sosResult!['longitude']}',
                          color: AppTheme.successGreen,
                        ),
                        _ResultCard(
                          icon: Icons.people_rounded,
                          label: 'Contacts Notified',
                          value:
                              '${_sosResult!['contacts_notified']} contacts alerted',
                          color: AppTheme.primaryCyan,
                        ),
                        _ResultCard(
                          icon: Icons.message_rounded,
                          label: 'Emergency Message',
                          value: _sosResult!['emergency_message'] as String,
                          color: AppTheme.warningAmber,
                        ),
                        _ResultCard(
                          icon: Icons.access_time_rounded,
                          label: 'Timestamp',
                          value: _sosResult!['timestamp'] as String,
                          color: AppTheme.textSecondary,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Emergency Gesture Reference ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.surfaceOverlay),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY GESTURES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textMuted,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _EmergencyRow(
                                gestures: 'HELP + FIRE',
                                label: '🔥 Fire Emergency'),
                            _EmergencyRow(
                                gestures: 'HELP + POLICE',
                                label: '🛡️ Safety Emergency'),
                            _EmergencyRow(
                                gestures: 'HELP + HOSPITAL',
                                label: '🏥 Medical Emergency'),
                            _EmergencyRow(
                                gestures: 'HELP + PAIN',
                                label: '😣 Medical Assistance'),
                            _EmergencyRow(
                                gestures: 'EMERGENCY',
                                label: '🚨 General Emergency'),
                          ],
                        ),
                      ),

                      if (_sosTriggered) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _sosTriggered = false;
                              _sosResult = null;
                            });
                            _emergencyService.dismissAlert();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceElevated,
                            foregroundColor: AppTheme.textPrimary,
                          ),
                          child: const Text('Reset Demo'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  final String gestures;
  final String label;

  const _EmergencyRow({required this.gestures, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              gestures,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.emergencyRed,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
