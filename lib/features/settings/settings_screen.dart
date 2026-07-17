/// JARVIS — Settings Screen
/// Configuration for language, backend, and confidence threshold.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backendConnected = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _checking = true);
    final connected = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _backendConnected = connected;
        _checking = false;
      });
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
                        'SETTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Backend Status ──
                    _SettingsSection(
                      title: 'BACKEND CONNECTION',
                      children: [
                        _SettingsTile(
                          icon: Icons.cloud_rounded,
                          title: 'Backend Status',
                          subtitle: _checking
                              ? 'Checking...'
                              : _backendConnected
                                  ? 'Connected to ${AppConstants.defaultBaseUrl}'
                                  : 'Not connected',
                          trailing: _checking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryCyan,
                                  ),
                                )
                              : Icon(
                                  _backendConnected
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  color: _backendConnected
                                      ? AppTheme.successGreen
                                      : AppTheme.emergencyRed,
                                ),
                          onTap: _checkBackend,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Recognition ──
                    _SettingsSection(
                      title: 'RECOGNITION',
                      children: [
                        _SettingsTile(
                          icon: Icons.speed_rounded,
                          title: 'Confidence Threshold',
                          subtitle:
                              '${(AppConstants.confidenceThreshold * 100).toInt()}% minimum',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                        _SettingsTile(
                          icon: Icons.timer_rounded,
                          title: 'Sequence Timeout',
                          subtitle:
                              '${AppConstants.gestureSequenceTimeoutMs / 1000}s idle timeout',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                        _SettingsTile(
                          icon: Icons.format_list_numbered_rounded,
                          title: 'Max Sequence Length',
                          subtitle:
                              '${AppConstants.maxSequenceLength} gestures max',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── About ──
                    _SettingsSection(
                      title: 'ABOUT',
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'JARVIS',
                          subtitle: 'Version ${AppConstants.appVersion}',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'Gesture Vocabulary',
                          subtitle:
                              '${AppConstants.gestureLabels.length} supported gestures',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          title: 'Supported Languages',
                          subtitle:
                              '${AppConstants.supportedLanguages.length} languages',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Version footer
                    Center(
                      child: Text(
                        '${AppConstants.appName} v${AppConstants.appVersion}\n${AppConstants.appTagline}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted.withOpacity(0.6),
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceOverlay),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primaryCyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
