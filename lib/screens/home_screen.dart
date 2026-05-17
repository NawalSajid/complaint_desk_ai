import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';

import '../constants.dart';

// ── Gradient helpers (matches profile_screen) ─────────────────────────────────

const Color _gradA   = Color(0xFF9C27B0);
const Color _gradB   = Color(0xFF00BCD4);
const Color _gradMid = Color(0xFF5C6BC0);

const LinearGradient _grad = LinearGradient(
  colors: [_gradA, _gradMid, _gradB],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

Widget _gradMask({required Widget child}) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => _grad.createShader(b),
      child: child,
    );

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
  static const Color _surface  = Color(0xFFF7F7FB);
  static const Color _white    = Colors.white;

  static const Color _violet      = Color(0xFF5C35CC);
  static const Color _violetLight = Color(0xFFEDE8FF);

  late AnimationController _controller;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  int    _activeComplaints = 0;
  bool   _isLoadingStats   = true;
  String _userName         = '';       // ← actual user name

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
    _fetchUserName();
    fetchActiveComplaintCount();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Fetch user name ────────────────────────────────────────────────────────

  Future<void> _fetchUserName() async {
    if (widget.userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/${widget.userId}'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() => _userName = data['name'] ?? '');
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  // ── Derive initials from name ──────────────────────────────────────────────

  String get _initials {
    final n = _userName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Fetch complaint count ──────────────────────────────────────────────────

  Future<void> fetchActiveComplaintCount() async {
    if (widget.userId == null) {
      setState(() {
        _activeComplaints = 0;
        _isLoadingStats   = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List complaints = jsonDecode(response.body);
        final int inProgressCount = complaints.where((c) {
          final status = (c['status'] as String).toLowerCase();
          return status == 'in-progress' ||
              status == 'in progress' ||
              status == 'in_progress';
        }).length;

        if (mounted) {
          setState(() => _activeComplaints = inProgressCount);
        }
      }
    } catch (e) {
      debugPrint('Error fetching active complaints: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
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
    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(),
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

                      // ── Unified 2×3 grid (all 6 cards same size) ───────
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
                          ),
                          _CategoryCard(
                            title: 'Hostel',
                            subtitle: 'Accommodation concerns',
                            icon: Icons.apartment_outlined,
                            accentColor: const Color(0xFFE67E22),
                            bgColor: const Color(0xFFFFF5EC),
                          ),
                          _CategoryCard(
                            title: 'Transport',
                            subtitle: 'Bus & route issues',
                            icon: Icons.directions_bus_outlined,
                            accentColor: const Color(0xFF7B35CC),
                            bgColor: const Color(0xFFF2EBFF),
                          ),
                          _CategoryCard(
                            title: 'Harassment',
                            subtitle: 'Report misconduct',
                            icon: Icons.shield_outlined,
                            accentColor: const Color(0xFF0BAB64),
                            bgColor: const Color(0xFFEAF9F2),
                          ),
                          _CategoryCard(
                            title: 'General',
                            subtitle: 'Other complaints',
                            icon: Icons.chat_bubble_outline_rounded,
                            accentColor: const Color(0xFFE84393),
                            bgColor: const Color(0xFFFFF0F7),
                          ),
                          _NewComplaintCard(onTap: _goToComplaints),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Feature badges ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _Badge(icon: Icons.lock_outline_rounded,  label: 'Secure'),
                          SizedBox(width: 10),
                          _Badge(icon: Icons.bar_chart_rounded,     label: 'Live Tracking'),
                          SizedBox(width: 10),
                          _Badge(icon: Icons.bolt_rounded,          label: 'Fast Resolution'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomBar(userId: widget.userId, activeIndex: 0),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
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

                  // ── Avatar with real initials ──────────────────────────
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      // Gradient border ring to match profile screen style
                      gradient: const LinearGradient(
                        colors: [_gradA, _gradB],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _violetLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _violet,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hero banner
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                              Text(
                                _isLoadingStats
                                    ? 'Loading active complaints'
                                    : '$_activeComplaints active complaints',
                                style: const TextStyle(
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
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    accentColor;
  final Color    bgColor;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    // ignore: unused_element_parameter
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
                color: widget.accentColor.withValues(alpha: _pressed ? 0.12 : 0.05),
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
                child: Icon(widget.icon, color: widget.accentColor, size: 20),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE8FF),
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
                style: TextStyle(fontSize: 10.5, color: Color(0xFF8888A0)),
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
  final String   label;

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

// ── Bottom Navigation Bar (matches profile_screen gradient style) ──────────────

class _NavTab {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  const _NavTab(this.label, this.icon, this.activeIcon);
}

class _BottomBar extends StatelessWidget {
  final String? userId;
  final int     activeIndex;

  const _BottomBar({required this.userId, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _NavTab('Home',       Icons.home_outlined,              Icons.home_rounded),
      _NavTab('Complaints', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
      _NavTab('Track',      Icons.track_changes_outlined,      Icons.track_changes_rounded),
      _NavTab('Profile',    Icons.person_outline_rounded,      Icons.person_rounded),
    ];

    void onTabTap(int i) {
      if (i == activeIndex || userId == null) return;
      final routes = <Widget Function()>[
        () => HomeScreen(userId: userId),
        () => ComplaintsScreen(userId: userId!),
        () => TrackComplaintsScreen(userId: userId!),
        () => ProfileScreen(userId: userId!),
      ];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => routes[i]()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final isActive = i == activeIndex;
            final tab      = tabs[i];

            return GestureDetector(
              onTap: () => onTabTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _gradA.withValues(alpha: 0.10),
                            _gradB.withValues(alpha: 0.07),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _gradA.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      )
                    : const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isActive
                        ? _gradMask(child: Icon(tab.activeIcon, size: 22, color: Colors.white))
                        : Icon(tab.icon, size: 22, color: const Color(0xFFABABCC)),
                    const SizedBox(height: 3),
                    isActive
                        ? _gradMask(
                            child: Text(
                              tab.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : Text(
                            tab.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFABABCC),
                              letterSpacing: 0.5,
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