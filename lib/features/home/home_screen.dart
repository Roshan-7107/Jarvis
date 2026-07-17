/// JARVIS — Home Screen
/// Dashboard with feature cards for all JARVIS capabilities.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../sign_recognition/camera_screen.dart';
import '../avatar/avatar_screen.dart';
import '../emergency/emergency_screen.dart';
import '../translation/translation_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _backendConnected = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final connected = await ApiService().checkHealth();
    if (mounted) {
      setState(() => _backendConnected = connected);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Logo
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryCyan.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('🤖', style: TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'JARVIS',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 3,
                                  ),
                                ),
                                Text(
                                  'AI Communication Assistant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMuted.withOpacity(0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Settings
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                              icon: const Icon(
                                Icons.settings_rounded,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Status indicator
                        _StatusBadge(connected: _backendConnected),
                        const SizedBox(height: 24),
                        // Tagline
                        Text(
                          'Breaking Communication\nBarriers with AI',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary.withOpacity(0.95),
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Translate sign language to speech, text, and beyond.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Feature Grid ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _FeatureCard(
                        id: 'sign_recognition',
                        icon: Icons.sign_language_rounded,
                        emoji: '🤟',
                        title: 'Sign Recognition',
                        subtitle: 'Real-time gesture detection',
                        gradient: AppTheme.primaryGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        id: 'reverse_comm',
                        icon: Icons.record_voice_over_rounded,
                        emoji: '🗣️',
                        title: 'Reverse Comm',
                        subtitle: 'Speech/text to signs',
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentPurple, Color(0xFF6200EA)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AvatarScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        id: 'emergency',
                        icon: Icons.emergency_rounded,
                        emoji: '🚨',
                        title: 'Emergency',
                        subtitle: 'SOS & urgent alerts',
                        gradient: AppTheme.emergencyGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmergencyScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        id: 'translation',
                        icon: Icons.translate_rounded,
                        emoji: '🌍',
                        title: 'Translation',
                        subtitle: 'Multilingual output',
                        gradient: const LinearGradient(
                          colors: [AppTheme.successGreen, Color(0xFF00B0FF)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TranslationScreen(),
                          ),
                        ),
                      ),
                    ]),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                  ),
                ),

                // ── Quick Demo Section ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      'QUICK DEMO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted.withOpacity(0.6),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                // Quick gesture buttons
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _QuickGestureButton(
                          label: '👋 HELLO',
                          onTap: () => _navigateToRecognition(['HELLO']),
                        ),
                        _QuickGestureButton(
                          label: '🆘 HELP + HOSPITAL',
                          onTap: () =>
                              _navigateToRecognition(['HELP', 'HOSPITAL', 'PAIN']),
                        ),
                        _QuickGestureButton(
                          label: '💧 WATER',
                          onTap: () =>
                              _navigateToRecognition(['WATER', 'PLEASE']),
                        ),
                        _QuickGestureButton(
                          label: '🔥 HELP + FIRE',
                          onTap: () =>
                              _navigateToRecognition(['HELP', 'FIRE']),
                          isEmergency: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRecognition(List<String> gestures) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(demoGestures: gestures),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool connected;

  const _StatusBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (connected ? AppTheme.successGreen : AppTheme.emergencyRed)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (connected ? AppTheme.successGreen : AppTheme.emergencyRed)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? AppTheme.successGreen : AppTheme.emergencyRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'Backend Connected' : 'Backend Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: connected ? AppTheme.successGreen : AppTheme.emergencyRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String id;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.id,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.surfaceOverlay,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }
}

class _QuickGestureButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isEmergency;

  const _QuickGestureButton({
    required this.label,
    required this.onTap,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isEmergency
            ? AppTheme.emergencyRed.withOpacity(0.1)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEmergency
                    ? AppTheme.emergencyRed.withOpacity(0.3)
                    : AppTheme.surfaceOverlay,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isEmergency
                    ? AppTheme.emergencyRed
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
