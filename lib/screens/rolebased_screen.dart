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

/// Simple responsive helper. Scales a base value against a reference
/// width (390 = a common phone width) and clamps it so text/spacing
/// never gets too small (tiny phones) or too large (tablets/desktop).
double _rs(double base, double width, {double min = 0.85, double max = 1.35}) {
  final scale = (width / 390).clamp(min, max);
  return base * scale;
}

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
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Cap content width on large screens (tablet/desktop/web)
            // so the layout doesn't stretch uncomfortably wide.
            final contentWidth = w > 640 ? 560.0 : w;
            final hPad = w > 640 ? 0.0 : _rs(24, w);

            return FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: h),
                      child: Container(
                        width: contentWidth,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            SizedBox(height: (h * 0.04).clamp(16, 48)),

                            // ── Brand row ─────────────────────────────
                            Row(
                              children: [
                                Container(
                                  width: _rs(44, w),
                                  height: _rs(44, w),
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
                                  child: Icon(
                                    Icons.campaign_rounded,
                                    color: Colors.white,
                                    size: _rs(22, w),
                                  ),
                                ),
                                SizedBox(width: _rs(10, w)),
                                Flexible(
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Complaint',
                                          style: TextStyle(
                                            color: _accent,
                                            fontSize: _rs(22, w),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Desk',
                                          style: TextStyle(
                                            color: _primary,
                                            fontSize: _rs(22, w),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '.AI',
                                          style: TextStyle(
                                            color: _primary,
                                            fontSize: _rs(22, w),
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: (h * 0.055).clamp(20, 56)),

                            // ── Welcome block ─────────────────────────
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(_rs(22, w)),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
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
                                        padding: EdgeInsets.symmetric(
                                            horizontal: _rs(10, w), vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'UNIVERSITY PORTAL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _rs(9, w),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.6,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: _rs(12, w)),
                                      Text(
                                        'Choose your role\nto get started',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: _rs(22, w),
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: _rs(10, w)),
                                      Text(
                                        'Access your personalised dashboard securely.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: _rs(12.5, w),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: (h * 0.04).clamp(16, 40)),

                            // ── Section label ─────────────────────────
                            Text(
                              'SELECT ROLE',
                              style: TextStyle(
                                fontSize: _rs(10, w),
                                fontWeight: FontWeight.w700,
                                color: _inkLight,
                                letterSpacing: 1.8,
                              ),
                            ),

                            SizedBox(height: _rs(14, w)),

                            // ── Role cards ─────────────────────────────
                            // Side-by-side on wide screens, stacked on phones.
                            w > 640
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _RoleCard(
                                          title: 'Administrator',
                                          subtitle:
                                              'Manage complaints, assign tasks and oversee operations',
                                          icon: Icons.shield_rounded,
                                          gradient: const [_primary, _violet],
                                          tag: 'Full Access',
                                          tagIcon: Icons.verified_rounded,
                                          onTap: () => _go('admin'),
                                          width: w,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _RoleCard(
                                          title: 'Student',
                                          subtitle:
                                              'Submit, track and follow up on complaints easily',
                                          icon: Icons.person_rounded,
                                          gradient: const [_accent, Color(0xFF0097A7)],
                                          tag: 'Standard',
                                          tagIcon: Icons.person_outline_rounded,
                                          onTap: () => _go('user'),
                                          width: w,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _RoleCard(
                                        title: 'Administrator',
                                        subtitle:
                                            'Manage complaints, assign tasks and oversee operations',
                                        icon: Icons.shield_rounded,
                                        gradient: const [_primary, _violet],
                                        tag: 'Full Access',
                                        tagIcon: Icons.verified_rounded,
                                        onTap: () => _go('admin'),
                                        width: w,
                                      ),
                                      SizedBox(height: _rs(12, w)),
                                      _RoleCard(
                                        title: 'Student',
                                        subtitle:
                                            'Submit, track and follow up on complaints easily',
                                        icon: Icons.person_rounded,
                                        gradient: const [_accent, Color(0xFF0097A7)],
                                        tag: 'Standard',
                                        tagIcon: Icons.person_outline_rounded,
                                        onTap: () => _go('user'),
                                        width: w,
                                      ),
                                    ],
                                  ),

                            SizedBox(height: (h * 0.045).clamp(18, 44)),

                            // ── Stats row ──────────────────────────────
                            Row(
                              children: [
                                _StatBox(value: '24h', label: 'Response', color: _primary, width: w),
                                SizedBox(width: _rs(12, w)),
                                _StatBox(value: '100%', label: 'Secure', color: _green, width: w),
                                SizedBox(width: _rs(12, w)),
                                _StatBox(value: 'Live', label: 'Tracking', color: _accent, width: w),
                              ],
                            ),

                            SizedBox(height: (h * 0.04).clamp(16, 40)),

                            // ── Footer ─────────────────────────────────
                            Center(
                              child: Text(
                                'v1.0.0  ·  University Complaint Cell',
                                style: TextStyle(
                                  fontSize: _rs(10.5, w),
                                  color: _inkLight,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),

                            SizedBox(height: (h * 0.03).clamp(12, 32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
  final double       width;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tag,
    required this.tagIcon,
    required this.onTap,
    required this.width,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.gradient.first;
    final w = widget.width;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(_rs(18, w)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Gradient icon
              Container(
                width: _rs(52, w),
                height: _rs(52, w),
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
                child: Icon(widget.icon, color: Colors.white, size: _rs(24, w)),
              ),

              SizedBox(width: _rs(16, w)),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: _rs(15, w),
          fontWeight: FontWeight.w700,
          color: _inkDark,
          letterSpacing: -0.3,
        ),
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
          Icon(widget.tagIcon, size: 9, color: base),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              widget.tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _rs(9, w, min: 0.85, max: 1.15),
                fontWeight: FontWeight.w700,
                color: base,
                letterSpacing: 0.2,
              ),
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
                      style: TextStyle(
                        fontSize: _rs(12, w, min: 0.9, max: 1.2),
                        color: _inkMid,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: _rs(12, w)),

              // Arrow
              Container(
                width: _rs(32, w),
                height: _rs(32, w),
                decoration: BoxDecoration(
                  color: base.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.arrow_forward_rounded, color: base, size: _rs(15, w)),
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
  final double width;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: _rs(14, w)),
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
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: _rs(18, w),
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: _rs(10.5, w, min: 0.85, max: 1.2),
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