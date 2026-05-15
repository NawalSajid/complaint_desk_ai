import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;

  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _inkLight = Color(0xFFB0B0C0);
  static const Color _surface = Color(0xFFF7F7FB);
  static const Color _white = Colors.white;

  // Signature accent: deep indigo-violet
  static const Color _violet = Color(0xFF5C35CC);
  static const Color _violetLight = Color(0xFFEDE8FF);

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToComplaints() {
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintsScreen(userId: widget.userId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // ── Header card ────────────────────────────────────────────
              _buildHeader(size),

              // ── Scrollable content ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _violet,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CATEGORIES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _violet,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── 2×2 Category grid ──────────────────────────────
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.18,
                        children: [
                          _CategoryCard(
                            title: 'Academic',
                            subtitle: 'Faculty & course issues',
                            icon: Icons.school_outlined,
                            accentColor: const Color(0xFF2979FF),
                            bgColor: const Color(0xFFEEF4FF),
                            onTap: _goToComplaints,
                          ),
                          _CategoryCard(
                            title: 'Hostel',
                            subtitle: 'Accommodation concerns',
                            icon: Icons.apartment_outlined,
                            accentColor: const Color(0xFFE67E22),
                            bgColor: const Color(0xFFFFF5EC),
                            onTap: _goToComplaints,
                          ),
                          _CategoryCard(
                            title: 'Transport',
                            subtitle: 'Bus & route issues',
                            icon: Icons.directions_bus_outlined,
                            accentColor: const Color(0xFF7B35CC),
                            bgColor: const Color(0xFFF2EBFF),
                            onTap: _goToComplaints,
                          ),
                          _CategoryCard(
                            title: 'Harassment',
                            subtitle: 'Report misconduct',
                            icon: Icons.shield_outlined,
                            accentColor: const Color(0xFF0BAB64),
                            bgColor: const Color(0xFFEAF9F2),
                            onTap: _goToComplaints,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── General + New Complaint row ────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _CategoryCard(
                              title: 'General',
                              subtitle: 'Other complaints',
                              icon: Icons.chat_bubble_outline_rounded,
                              accentColor: const Color(0xFFE84393),
                              bgColor: const Color(0xFFFFF0F7),
                              onTap: _goToComplaints,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NewComplaintCard(onTap: _goToComplaints),
                          ),
                        ],
                      ),

                      SizedBox(height: size.height * 0.035),

                      // ── Feature badges ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _Badge(
                              icon: Icons.lock_outline_rounded,
                              label: 'Secure'),
                          SizedBox(width: 10),
                          _Badge(
                              icon: Icons.bar_chart_rounded,
                              label: 'Live Tracking'),
                          SizedBox(width: 10),
                          _Badge(
                              icon: Icons.bolt_rounded,
                              label: 'Fast Resolution'),
                        ],
                      ),

                      SizedBox(height: size.height * 0.03),

                      // ── Footer ─────────────────────────────────────────
                      Center(
                        child: Text(
                          'v1.0.0  ·  University Complaint Cell',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _inkLight,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom navigation bar ──────────────────────────────────────────────
      bottomNavigationBar: _BottomBar(
        userId: widget.userId,
        activeIndex: 0,
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      decoration: const BoxDecoration(
        color: _white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Logo mark
                  Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color.fromRGBO(156, 39, 176, 1).withAlpha(200),
                                        const Color.fromRGBO(0, 188, 212, 1).withAlpha(200),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(156, 39, 176, 1).withAlpha(60),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Complaint',
                                        style: TextStyle(
                                          color: Color.fromRGBO(0, 188, 212, 1),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: 'Desk',
                          style: TextStyle(
                            color: Color.fromRGBO(156, 39, 176, 1),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: '.AI',
                          style: TextStyle(
                            color: Color.fromRGBO(156, 39, 176, 1),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _violetLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'NA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _violet,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Hero banner ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(156, 39, 176, 1),
                      Color.fromRGBO(123, 82, 232, 24),
                      Color.fromRGBO(44, 167, 246, 24),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(156, 39, 176, 1).withAlpha(28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GOOD MORNING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'What can we\nhelp you with?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _white,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4DFFC3),
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                '3 active complaints',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: _pressed ? 0.25 : 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor
                    .withValues(alpha: _pressed ? 0.12 : 0.05),
                blurRadius: _pressed ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF8888A0),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New Complaint Card ────────────────────────────────────────────────────────

class _NewComplaintCard extends StatefulWidget {
  final VoidCallback? onTap;
  const _NewComplaintCard({this.onTap});

  @override
  State<_NewComplaintCard> createState() => _NewComplaintCardState();
}

class _NewComplaintCardState extends State<_NewComplaintCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF5C35CC).withValues(alpha: 0.2),
              width: 1.5,
              // Dashed via custom approach: use solid with lower opacity instead
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C35CC).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color.fromRGBO(156, 39, 176, 1),
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'New complaint',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(156, 39, 176, 1),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tap to submit',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF8888A0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF5C35CC)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C35CC),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final String? userId;
  final int activeIndex;

  const _BottomBar({required this.userId, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const violet = Color.fromRGBO(156, 39, 176, 1);

    final items = [
      _BottomBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _BottomBarItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Complaints'),
      _BottomBarItem(icon: Icons.track_changes_outlined, activeIcon: Icons.track_changes_rounded, label: 'Track'),
      _BottomBarItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEF5), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == activeIndex;
            return GestureDetector(
              onTap: () {
                if (userId == null) return;
                if (i == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: userId!)),
                  );
                } else if (i == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ComplaintsScreen(userId: userId!)),
                  );
                } else if (i == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TrackComplaintsScreen(userId: userId!)),
                  );
                } else if (i == 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: userId!)),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? violet.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 22,
                      color: isActive ? violet : const Color(0xFFAAAAAC),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? violet : const Color(0xFFAAAAAC),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _BottomBarItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}