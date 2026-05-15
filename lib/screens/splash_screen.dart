import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/rolebased_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF9C27B0);
  static const Color _accent = Color(0xFF00BCD4);

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _navigateToRoleSelection();
  }

  Future<void> _navigateToRoleSelection() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Background gradient ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF5FF),
                  Color(0xFFF0FAFE),
                  Color(0xFFFAF5FF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ─── Decorative background circles ──────────────────────────────
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withAlpha(28),
                    _primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.06,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.48,
              height: size.width * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accent.withAlpha(28),
                    _accent.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // ─── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // ── App Icon ───────────────────────────────────
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primary.withAlpha(200),
                                  _accent.withAlpha(200),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withAlpha(70),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: 46,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── App Name ───────────────────────────────────
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Complaint',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Desk',
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '.AI',
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Tagline ────────────────────────────────────
                          const Text(
                            'Smart University Complaint Management',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF888888),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // ── Feature pills ──────────────────────────────
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _Pill(
                                icon: Icons.bolt_rounded,
                                label: 'AI Powered',
                                color: _primary,
                              ),
                              _Pill(
                                icon: Icons.track_changes_rounded,
                                label: 'Live Tracking',
                                color: _accent,
                              ),
                              _Pill(
                                icon: Icons.shield_rounded,
                                label: 'Secure',
                                color: _primary,
                              ),
                            ],
                          ),

                          const Spacer(flex: 3),

                          // ── Loading indicator ──────────────────────────
                          Column(
                            children: [
                              SizedBox(
                                width: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    backgroundColor:
                                        _primary.withAlpha(28),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            _primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Loading…',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFAAAAAA),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // ── Version tag ────────────────────────────────
                          Text(
                            'v1.0.0  •  University Complaint Cell',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill Chip ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withAlpha(55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
