import 'package:flutter/material.dart';
import 'login_screen.dart';

const Color _primary = Color(0xFF9C27B0);
const Color _accent  = Color(0xFF00BCD4);
const Color _violet  = Color(0xFF5C35CC);
const Color _surface = Color(0xFFF6F6FA);
const Color _card    = Colors.white;
const Color _inkDark = Color(0xFF11112A);
const Color _inkMid  = Color(0xFF72728A);
const Color _inkLight= Color(0xFFB4B4C8);
const Color _border  = Color(0xFFEAEAF2);
const Color _green   = Color(0xFF0BAB64);

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(String role) => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder:        (_, __, ___) => LoginScreen(role: role),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: h * 0.04),

                  // ── Brand row (original preserved exactly) ───────────
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primary.withAlpha(200),
                              _accent.withAlpha(200),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Complaint',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'Desk',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: '.AI',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.055),

                  // ── Welcome block ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circle
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'UNIVERSITY PORTAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Choose your role\nto get started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Access your personalised dashboard securely.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.04),

                  // ── Section label ────────────────────────────────────
                  const Text(
                    'SELECT ROLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _inkLight,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Admin card ───────────────────────────────────────
                  _RoleCard(
                    title:    'Administrator',
                    subtitle: 'Manage complaints, assign tasks and oversee operations',
                    icon:     Icons.shield_rounded,
                    gradient: [_primary, _violet],
                    tag:      'Full Access',
                    tagIcon:  Icons.verified_rounded,
                    onTap:    () => _go('admin'),
                  ),

                  const SizedBox(height: 14),

                  // ── User card ────────────────────────────────────────
                  _RoleCard(
                    title:    'Student',
                    subtitle: 'Submit, track and follow up on complaints easily',
                    icon:     Icons.person_rounded,
                    gradient: [_accent, const Color(0xFF0097A7)],
                    tag:      'Standard',
                    tagIcon:  Icons.person_outline_rounded,
                    onTap:    () => _go('user'),
                  ),

                  SizedBox(height: h * 0.045),

                  // ── Stats row ────────────────────────────────────────
                  Row(
                    children: [
                      _StatBox(
                        value: '24h',
                        label: 'Response',
                        color: _primary,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        value: '100%',
                        label: 'Secure',
                        color: _green,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        value: 'Live',
                        label: 'Tracking',
                        color: _accent,
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.04),

                  // ── Footer ───────────────────────────────────────────
                  Center(
                    child: Text(
                      'v1.0.0  ·  University Complaint Cell',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _inkLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final String       title;
  final String       subtitle;
  final IconData     icon;
  final List<Color>  gradient;
  final String       tag;
  final IconData     tagIcon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tag,
    required this.tagIcon,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.gradient.first;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed ? base.withValues(alpha: 0.35) : _border,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: _pressed ? 0.12 : 0.06),
                blurRadius: _pressed ? 22 : 14,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [

              // Gradient icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: base.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _inkDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: base.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.tagIcon,
                                  size: 9, color: base),
                              const SizedBox(width: 3),
                              Text(
                                widget.tag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: base,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _inkMid,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: base.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    color: base, size: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: _inkMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}