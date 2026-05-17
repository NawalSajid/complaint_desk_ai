import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/new_complaint_screen.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../constants.dart';

// ── Theme constants ───────────────────────────────────────────────────────────
const Color _primary = Color.fromRGBO(156, 39, 176, 1);
const Color _accent  = Color.fromRGBO(0, 188, 212, 1);
const Color _gradMid = Color(0xFF5C6BC0);
const Color _surface = Color(0xFFF7F7FB);
const Color _cardBg  = Colors.white;

const LinearGradient _grad = LinearGradient(
  colors: [_primary, _gradMid, _accent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Gradient helpers ──────────────────────────────────────────────────────────

Widget _gradMask({required Widget child}) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => _grad.createShader(b),
      child: child,
    );

class ComplaintsScreen extends StatefulWidget {
  final String userId;

  const ComplaintsScreen({super.key, required this.userId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> complaints = [];
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    fetchComplaints();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── BACKEND LOGIC — UNTOUCHED ─────────────────────────────────────────────

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => complaints = data);
      } else {
        debugPrint('Failed to fetch complaints: ${response.statusCode}');
        showMessage('Failed to load complaints');
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
      showMessage('Error connecting to server');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: _primary,
                onRefresh: fetchComplaints,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddButton(),
                      const SizedBox(height: 28),

                      // ── Section header ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [_primary, _accent],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'RECENT COMPLAINTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: fetchComplaints,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.refresh_rounded,
                                      size: 13, color: _primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Refresh',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Complaint list ────────────────────────────────
                      isLoading
                          ? _buildLoadingState()
                          : complaints.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: complaints
                                      .map((c) => _buildComplaintCard(
                                            c['category'] ?? 'General',
                                            c['description'] ?? '',
                                            c['priority'] ?? 'Normal',
                                            c['status'] ?? 'Pending',
                                            c['category'] ?? 'General',
                                            formatDate(c['created_at'] ?? ''),
                                            '0 updates',
                                          ))
                                      .toList(),
                                ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(userId: widget.userId),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Gradient title ─────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_primary, _accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'My Complaints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white, // masked by shader
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const Text(
                    'Manage your submissions',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9090A0),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Complaint count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${complaints.length} total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add Button ────────────────────────────────────────────────────────────

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () async {
        bool? added = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewComplaintScreen(userId: widget.userId),
          ),
        );
        if (added == true) fetchComplaints();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary, Color.fromRGBO(123, 82, 232, 1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Submit New Complaint',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Complaint Card ────────────────────────────────────────────────────────

  Widget _buildComplaintCard(
    String title,
    String description,
    String priority,
    String status,
    String category,
    String time,
    String updates,
  ) {
    final statusColor   = _statusColor(status);
    final priorityColor = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card top
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.03),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(
                    color: _primary.withValues(alpha: 0.06), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_categoryIcon(category),
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B6B80),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag(priority, priorityColor),
                    const SizedBox(width: 8),
                    _buildTag(category, _accent),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 12, color: Color(0xFFB0B0C0)),
                        const SizedBox(width: 4),
                        Text(updates,
                            style: const TextStyle(
                                fontSize: 10.5, color: Color(0xFFB0B0C0))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFF0F0F5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFFB0B0C0)),
                    const SizedBox(width: 5),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFFB0B0C0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tag ───────────────────────────────────────────────────────────────────

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEEEF5)),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 30, color: _primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'No complaints yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the button above to submit one',
              style: TextStyle(fontSize: 12, color: Color(0xFF9090A0)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav (matches profile_screen gradient style) ────────────────────

  Widget _buildBottomNav() {
    const tabs = [
      _NavData('Home',       Icons.home_outlined,              Icons.home_rounded),
      _NavData('Complaints', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
      _NavData('Track',      Icons.track_changes_outlined,      Icons.track_changes_rounded),
      _NavData('Profile',    Icons.person_outline_rounded,      Icons.person_rounded),
    ];
    const activeIndex = 1;

    void onTap(int i) {
      if (i == activeIndex) return;
      final routes = <Widget Function()>[
        () => HomeScreen(userId: widget.userId),
        () => ComplaintsScreen(userId: widget.userId),
        () => TrackComplaintsScreen(userId: widget.userId),
        () => ProfileScreen(userId: widget.userId),
      ];
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => routes[i]()));
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
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primary.withValues(alpha: 0.10),
                            _accent.withValues(alpha: 0.07),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _primary.withValues(alpha: 0.18), width: 1),
                      )
                    : const BoxDecoration(
                        borderRadius:
                            BorderRadius.all(Radius.circular(14))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isActive
                        ? _gradMask(
                            child: Icon(tab.activeIcon,
                                size: 22, color: Colors.white))
                        : Icon(tab.icon,
                            size: 22, color: const Color(0xFFABABCC)),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':     return const Color(0xFFE67E22);
      case 'resolved':    return const Color(0xFF0BAB64);
      case 'rejected':    return const Color(0xFFE84393);
      case 'in progress':
      case 'inprogress':  return const Color(0xFF2979FF);
      default:            return _primary;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return const Color(0xFFE84393);
      case 'medium': return const Color(0xFFE67E22);
      case 'low':    return const Color(0xFF0BAB64);
      default:       return _accent;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic':   return Icons.school_outlined;
      case 'hostel':     return Icons.apartment_outlined;
      case 'transport':  return Icons.directions_bus_outlined;
      case 'harassment': return Icons.shield_outlined;
      default:           return Icons.chat_bubble_outline_rounded;
    }
  }
}

class _NavData {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  const _NavData(this.label, this.icon, this.activeIcon);
}