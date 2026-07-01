import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';

import '../constants.dart';

// ── Gradient helpers ──────────────────────────────────────────────────────────

const Color _gradA   = Color(0xFF9C27B0);
const Color _gradB   = Color(0xFF00BCD4);
const Color _gradMid = Color(0xFF5C6BC0);

const LinearGradient _grad = LinearGradient(
  colors: [_gradA, _gradMid, _gradB],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const Color _navActivePurple = Color(0xFF5C35CC);

// ignore: unused_element
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
  static const Color _surface     = Color(0xFFF7F7FB);
  static const Color _white       = Colors.white;
  static const Color _violet      = Color(0xFF5C35CC);
  static const Color _violetLight = Color(0xFFEDE8FF);

  late AnimationController _controller;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  int    _activeComplaints = 0;
  bool   _isLoadingStats   = true;
  String _userName         = '';

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

  String get _initials {
    final n = _userName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

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
        if (mounted) setState(() => _activeComplaints = inProgressCount);
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
    // ── Responsive breakpoints ─────────────────────────────────────────────
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    // Column count: 2 for small/medium, 3 for tablets/large
    final crossAxisCount  = sw >= 600 ? 3 : 2;
    // Aspect ratio: taller cards on small screens
    final childAspectRatio = sw >= 600
        ? 1.25
        : sw >= 380
            ? 1.18
            : 1.05;
    // Horizontal padding: grows slightly on wider screens
    final hPad = sw >= 600 ? sw * 0.05 : 20.0;
    // Font scaling
    final scale = (sw / 390).clamp(0.85, 1.3);

    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(sw, sh, scale, hPad),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 15,
                            decoration: BoxDecoration(
                              color: _violet,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CATEGORIES',
                            style: TextStyle(
                              fontSize: (11 * scale).clamp(9.0, 14.0),
                              fontWeight: FontWeight.w700,
                              color: _violet,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sh * 0.018),

                      // ── Category grid ──────────────────────────────────
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _CategoryCard(
                            title: 'Academic',
                            subtitle: 'Faculty & course issues',
                            icon: Icons.school_outlined,
                            accentColor: const Color(0xFF2979FF),
                            bgColor: const Color(0xFFEEF4FF),
                            scale: scale,
                          ),
                          _CategoryCard(
                            title: 'Hostel',
                            subtitle: 'Accommodation concerns',
                            icon: Icons.apartment_outlined,
                            accentColor: const Color(0xFFE67E22),
                            bgColor: const Color(0xFFFFF5EC),
                            scale: scale,
                          ),
                          _CategoryCard(
                            title: 'Transport',
                            subtitle: 'Bus & route issues',
                            icon: Icons.directions_bus_outlined,
                            accentColor: const Color(0xFF7B35CC),
                            bgColor: const Color(0xFFF2EBFF),
                            scale: scale,
                          ),
                          _CategoryCard(
                            title: 'Harassment',
                            subtitle: 'Report misconduct',
                            icon: Icons.shield_outlined,
                            accentColor: const Color(0xFF0BAB64),
                            bgColor: const Color(0xFFEAF9F2),
                            scale: scale,
                          ),
                          _CategoryCard(
                            title: 'General',
                            subtitle: 'Other complaints',
                            icon: Icons.chat_bubble_outline_rounded,
                            accentColor: const Color(0xFFE84393),
                            bgColor: const Color(0xFFFFF0F7),
                            scale: scale,
                          ),
                          _NewComplaintCard(
                            onTap: _goToComplaints,
                            scale: scale,
                          ),
                        ],
                      ),

                      SizedBox(height: sh * 0.025),

                      // ── Feature badges ─────────────────────────────────
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            icon: Icons.lock_outline_rounded,
                            label: 'Secure',
                            scale: scale,
                          ),
                          _Badge(
                            icon: Icons.bar_chart_rounded,
                            label: 'Live Tracking',
                            scale: scale,
                          ),
                          _Badge(
                            icon: Icons.bolt_rounded,
                            label: 'Fast Resolution',
                            scale: scale,
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
      ),
      bottomNavigationBar: _BottomBar(userId: widget.userId, activeIndex: 0),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(double sw, double sh, double scale, double hPad) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: (36 * scale).clamp(30.0, 44.0),
                    height: (36 * scale).clamp(30.0, 44.0),
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
                    child: Icon(Icons.campaign_rounded,
                        color: Colors.white,
                        size: (18 * scale).clamp(14.0, 22.0)),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Complaint',
                          style: TextStyle(
                            color: const Color.fromRGBO(0, 188, 212, 1),
                            fontSize: (18 * scale).clamp(14.0, 22.0),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: 'Desk',
                          style: TextStyle(
                            color: const Color.fromRGBO(156, 39, 176, 1),
                            fontSize: (18 * scale).clamp(14.0, 22.0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: '.AI',
                          style: TextStyle(
                            color: const Color.fromRGBO(156, 39, 176, 1),
                            fontSize: (18 * scale).clamp(14.0, 22.0),
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
                    width: (36 * scale).clamp(30.0, 44.0),
                    height: (36 * scale).clamp(30.0, 44.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_gradA, _gradB],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _violetLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: TextStyle(
                              fontSize: (12 * scale).clamp(10.0, 15.0),
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
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(sw >= 600 ? 26 : 20),
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
                            fontSize: (10 * scale).clamp(9.0, 13.0),
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.8,
                          ),
                        ),
                        SizedBox(height: sh * 0.006),
                        Text(
                          'What can we\nhelp you with?',
                          style: TextStyle(
                            fontSize: (22 * scale).clamp(18.0, 28.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: sh * 0.016),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sw >= 600 ? 14 : 12,
                            vertical: 7,
                          ),
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
                                style: TextStyle(
                                  fontSize: (11.5 * scale).clamp(10.0, 14.0),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
  final double   scale;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.scale,
    this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
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
          padding: EdgeInsets.all((16 * s).clamp(10.0, 20.0)),
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
                width: (38 * s).clamp(28.0, 46.0),
                height: (38 * s).clamp(28.0, 46.0),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon,
                    color: widget.accentColor,
                    size: (20 * s).clamp(14.0, 24.0)),
              ),
              SizedBox(height: (12 * s).clamp(6.0, 14.0)),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: (14 * s).clamp(11.0, 17.0),
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: (3 * s).clamp(2.0, 5.0)),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: (10.5 * s).clamp(9.0, 13.0),
                  color: const Color(0xFF8888A0),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
  final double scale;
  const _NewComplaintCard({this.onTap, required this.scale});

  @override
  State<_NewComplaintCard> createState() => _NewComplaintCardState();
}

class _NewComplaintCardState extends State<_NewComplaintCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
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
          padding: EdgeInsets.all((16 * s).clamp(10.0, 20.0)),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
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
                width: (38 * s).clamp(28.0, 46.0),
                height: (38 * s).clamp(28.0, 46.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE8FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: const Color.fromRGBO(156, 39, 176, 1),
                  size: (22 * s).clamp(16.0, 26.0),
                ),
              ),
              SizedBox(height: (12 * s).clamp(6.0, 14.0)),
              Text(
                'New complaint',
                style: TextStyle(
                  fontSize: (13 * s).clamp(11.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: const Color.fromRGBO(156, 39, 176, 1),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: (3 * s).clamp(2.0, 5.0)),
              Text(
                'Tap to submit',
                style: TextStyle(
                    fontSize: (10.5 * s).clamp(9.0, 13.0),
                    color: const Color(0xFF8888A0)),
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
  final double   scale;

  const _Badge({required this.icon, required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale).clamp(8.0, 14.0),
        vertical: (6 * scale).clamp(5.0, 9.0),
      ),
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
          Icon(icon,
              size: (12 * scale).clamp(10.0, 15.0),
              color: const Color(0xFF5C35CC)),
          SizedBox(width: (5 * scale).clamp(3.0, 7.0)),
          Text(
            label,
            style: TextStyle(
              fontSize: (11 * scale).clamp(9.0, 13.0),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5C35CC),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

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
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw >= 600 ? 24.0 : 8.0;

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
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: hPad),
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
                padding: EdgeInsets.symmetric(
                  horizontal: sw >= 600 ? 24 : 16,
                  vertical: 8,
                ),
                decoration: isActive
                    ? BoxDecoration(
                        color: _navActivePurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _navActivePurple.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      )
                    : const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      size: sw >= 600 ? 24 : 22,
                      color: isActive
                          ? const Color(0xFF9C27B0)
                          : const Color(0xFFABABCC),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: sw >= 600 ? 10 : 9,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive
                            ? _navActivePurple
                            : const Color(0xFFABABCC),
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