// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

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
const Color _accent = Color.fromRGBO(0, 188, 212, 1);
const Color _surface = Color(0xFFF7F7FB);
const Color _cardBg = Colors.white;

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
  String _sortOption = 'Recent';

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  int _priorityRank(String p) {
    switch (p.toLowerCase()) {
      case 'high':   return 0;
      case 'medium': return 1;
      case 'low':    return 2;
      default:       return 3;
    }
  }

  List<dynamic> get sortedComplaints {
    final list = List<dynamic>.from(complaints);
    switch (_sortOption) {
      case 'Recent':
        list.sort((a, b) => (b['created_at'] ?? '').toString()
            .compareTo((a['created_at'] ?? '').toString()));
        break;
      case 'Oldest':
        list.sort((a, b) => (a['created_at'] ?? '').toString()
            .compareTo((b['created_at'] ?? '').toString()));
        break;
      case 'Priority: High to Low':
        list.sort((a, b) => _priorityRank(a['priority'] ?? 'Normal')
            .compareTo(_priorityRank(b['priority'] ?? 'Normal')));
        break;
      case 'Priority: Low to High':
        list.sort((a, b) => _priorityRank(b['priority'] ?? 'Normal')
            .compareTo(_priorityRank(a['priority'] ?? 'Normal')));
        break;
    }
    return list;
  }

  // ── Category icon + color ─────────────────────────────────────────────────

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic':   return Icons.school_rounded;
      case 'hostel':     return Icons.apartment_rounded;
      case 'transport':  return Icons.directions_bus_rounded;
      case 'harassment': return Icons.shield_rounded;
      case 'general':    return Icons.chat_bubble_outline_rounded;
      default:           return Icons.description_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':   return const Color(0xFF5C6BC0);
      case 'hostel':     return const Color(0xFFE67E22);
      case 'transport':  return const Color(0xFF7B52E8);
      case 'harassment': return const Color(0xFF0BAB64);
      case 'general':    return const Color(0xFFE84393);
      default:           return _accent;
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

                      // ── Section label (own line) ─────────────────────
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
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Sort + refresh (own line, right-aligned) ─────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortOption,
                                  icon: const Icon(Icons.swap_vert_rounded,
                                      size: 14, color: _primary),
                                  isDense: true,
                                  isExpanded: true,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primary),
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _sortOption = v);
                                  },
                                  // Short label when the dropdown is closed —
                                  // this is what actually stops the overflow.
                                  selectedItemBuilder: (context) => const [
                                    Text('Recent', overflow: TextOverflow.ellipsis),
                                    Text('Oldest', overflow: TextOverflow.ellipsis),
                                    Text('Priority ↓', overflow: TextOverflow.ellipsis),
                                    Text('Priority ↑', overflow: TextOverflow.ellipsis),
                                  ],
                                  items: const [
                                    DropdownMenuItem(value: 'Recent', child: Text('Recent')),
                                    DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                                    DropdownMenuItem(
                                        value: 'Priority: High to Low',
                                        child: Text('Priority: High to Low')),
                                    DropdownMenuItem(
                                        value: 'Priority: Low to High',
                                        child: Text('Priority: Low to High')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: fetchComplaints,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.refresh_rounded, size: 16, color: _primary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      isLoading
                          ? _buildLoadingState()
                          : complaints.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: sortedComplaints
                                      .map((c) => _buildComplaintCard(c))
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
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen(userId: widget.userId)),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.4),
                      ),
                    ),
                    const Text('Manage your submissions',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Color(0xFF9090A0))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
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
          MaterialPageRoute(builder: (context) => NewComplaintScreen(userId: widget.userId)),
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
            BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
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
            const Text('Submit New Complaint',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }

  // ── Complaint Card ────────────────────────────────────────────────────────

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final title = c['category'] ?? 'General';
    final description = c['description'] ?? '';
    final priority = c['priority'] ?? 'Normal';
    final status = c['status'] ?? 'Pending';
    final time = formatDate(c['created_at'] ?? '');

    // ── User confirmation flag (mirrors detail screen's parsing logic) ──────
    final userConfirmed = c['user_confirmed'] == true ||
        c['user_confirmed'] == 1 ||
        c['user_confirmed'].toString() == 'true' ||
        c['user_confirmed'].toString() == '1';

    // NOTE: statusColor/statusDisplay now depend on userConfirmed too,
    // so a resolved-but-unconfirmed complaint doesn't show as "done" (green).
    final statusColor = _statusColor(status, userConfirmed);
    final priorityColor = _priorityColor(priority);
    final iconData = _categoryIcon(title);
    final iconBgColor = _categoryColor(title);

    String statusDisplay(String s, bool confirmed) {
      final v = s.toLowerCase();
      // Resolved by admin but student hasn't confirmed yet — don't call it "Resolved".
      if ((v == 'resolved' || v == 'confirmed') && !confirmed) {
        return 'Awaiting Confirmation';
      }
      switch (v) {
        case 'new':        return 'Pending';
        case 'inprogress': return 'In Progress';
        case 'confirmed':  return 'Resolved';
        default:
          return s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
      }
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserComplaintDetailScreen(
              complaint: c,
              userId: widget.userId,
              onConfirmed: fetchComplaints,
            ),
          ),
        );
        // Refresh list when returning so card status stays in sync
        fetchComplaints();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEEF5), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card top
            // ── FIXED: status pill pushed fully to the right edge ────────
            // Right-side padding trimmed to almost nothing (16 → 2) and the
            // status pill + checkmark are wrapped in their own Row so they
            // hug the edge as a single group, regardless of title length.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 2, 12),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: _primary.withValues(alpha: 0.06), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBgColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(iconData, color: iconBgColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), letterSpacing: -0.2)),
                  ),
                  const SizedBox(width: 6),
                  // Status pill (+ confirmed checkmark) grouped into one
                  // Row so they move together and sit flush at the edge.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(statusDisplay(status, userConfirmed),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                          ],
                        ),
                      ),
                      if (userConfirmed) ...[
                        const SizedBox(width: 6),
                        _buildConfirmedBadge(),
                      ],
                    ],
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
                  Text(description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B80), height: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag(priority, priorityColor),
                      const Spacer(),
                      Row(
                        children: const [
                          Text('View details', style: TextStyle(fontSize: 10, color: Color(0xFFB0B0C0))),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFB0B0C0)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: const Color(0xFFF0F0F5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFB0B0C0)),
                      const SizedBox(width: 5),
                      Text(time, style: const TextStyle(fontSize: 10.5, color: Color(0xFFB0B0C0))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmed badge (shown next to status pill once user confirmed) ───────

  Widget _buildConfirmedBadge() {
    return Tooltip(
      message: 'You confirmed this resolution',
      child: Icon(
        Icons.verified_rounded,
        size: 18,
        color: const Color(0xFF0BAB64),
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
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEEF5)),
        ),
        child: const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2)),
      )),
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
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.07), shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined, size: 30, color: _primary),
            ),
            const SizedBox(height: 14),
            const Text('No complaints yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            const Text('Tap the button above to submit one',
                style: TextStyle(fontSize: 12, color: Color(0xFF9090A0))),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const tabs = [
      _NavData('Home', Icons.home_outlined, Icons.home_rounded),
      _NavData('Complaints', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
      _NavData('Track', Icons.track_changes_outlined, Icons.track_changes_rounded),
      _NavData('Profile', Icons.person_outline_rounded, Icons.person_rounded),
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => routes[i]()));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final isActive = i == activeIndex;
            final tab = tabs[i];
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _primary.withValues(alpha: 0.10),
                          _accent.withValues(alpha: 0.07),
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withValues(alpha: 0.18), width: 1),
                      )
                    : const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(14))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isActive
                        ? Icon(tab.activeIcon, size: 22, color: _primary)
                        : Icon(tab.icon, size: 22, color: const Color(0xFFABABCC)),
                    const SizedBox(height: 3),
                    isActive
                        ? Text(tab.label.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _primary, letterSpacing: 0.5))
                        : Text(tab.label.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFFABABCC), letterSpacing: 0.5)),
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

  // `confirmed` = whether the student has confirmed a resolved complaint.
  // A resolved-but-unconfirmed complaint gets its own color (purple, matches
  // app brand) instead of the "done" green, so it doesn't look finished yet.
  Color _statusColor(String status, bool confirmed) {
    final v = status.toLowerCase();
    if ((v == 'resolved' || v == 'confirmed') && !confirmed) {
      return _primary;
    }
    switch (v) {
      case 'pending':
      case 'new':        return const Color(0xFFE67E22);
      case 'resolved':
      case 'confirmed':  return const Color(0xFF0BAB64);
      case 'rejected':   return const Color(0xFFE84393);
      case 'in progress':
      case 'inprogress': return const Color(0xFF2979FF);
      default:           return _primary;
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
}

// ══════════════════════════════════════════════════════════════════════════════
// USER COMPLAINT DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class UserComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final String userId;
  final VoidCallback onConfirmed;

  const UserComplaintDetailScreen({
    super.key,
    required this.complaint,
    required this.userId,
    required this.onConfirmed,
  });

  @override
  State<UserComplaintDetailScreen> createState() =>
      _UserComplaintDetailScreenState();
}

class _UserComplaintDetailScreenState extends State<UserComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _confirming = false;
bool _loadingFresh = false;
bool _userConfirmed = false;

  // ── Always use _complaint (fresh data), not widget.complaint ──────────────
  late Map<String, dynamic> _complaint;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
_currentStatus = (widget.complaint['status'] ?? 'Pending').toString();
_userConfirmed = widget.complaint['user_confirmed'] == true;

    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Fetch latest status from server immediately on open
    _fetchFreshData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch fresh complaint data from server ────────────────────────────────

  Future<void> _fetchFreshData() async {
    setState(() => _loadingFresh = true);
    try {
      final complaintId = widget.complaint['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}&_t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {'Cache-Control': 'no-cache'},
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final fresh = data.firstWhere(
          (c) => c['id'] == complaintId,
          orElse: () => null,
        );
        if (fresh != null && mounted) {
          setState(() {
            _complaint = Map<String, dynamic>.from(fresh);
            _currentStatus = (fresh['status'] ?? 'Pending').toString();
            _userConfirmed = fresh['user_confirmed'] == true ||
                fresh['user_confirmed'] == 1 ||
                fresh['user_confirmed'].toString() == 'true' ||
                fresh['user_confirmed'].toString() == '1';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching fresh complaint data: $e');
    } finally {
      if (mounted) setState(() => _loadingFresh = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // `confirmed` = whether the student has confirmed a resolved complaint.
  Color _statusColor(String s, bool confirmed) {
    final v = s.toLowerCase();
    if ((v == 'resolved' || v == 'confirmed') && !confirmed) {
      return _primary;
    }
    switch (v) {
      case 'pending':
      case 'new':        return const Color(0xFFE67E22);
      case 'resolved':
      case 'confirmed':  return const Color(0xFF0BAB64);
      case 'rejected':   return const Color(0xFFE84393);
      case 'in progress':
      case 'inprogress': return const Color(0xFF2979FF);
      default:           return _primary;
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':   return const Color(0xFFE84393);
      case 'medium': return const Color(0xFFE67E22);
      case 'low':    return const Color(0xFF0BAB64);
      default:       return _accent;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic':   return Icons.school_rounded;
      case 'hostel':     return Icons.apartment_rounded;
      case 'transport':  return Icons.directions_bus_rounded;
      case 'harassment': return Icons.shield_rounded;
      case 'general':    return Icons.chat_bubble_outline_rounded;
      default:           return Icons.description_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':   return const Color(0xFF5C6BC0);
      case 'hostel':     return const Color(0xFFE67E22);
      case 'transport':  return const Color(0xFF7B52E8);
      case 'harassment': return const Color(0xFF0BAB64);
      case 'general':    return const Color(0xFFE84393);
      default:           return _accent;
    }
  }

  // `confirmed` = whether the student has confirmed a resolved complaint.
  String _statusDisplay(String s, bool confirmed) {
    final v = s.toLowerCase();
    // Resolved by admin but student hasn't confirmed yet — don't call it "Resolved".
    if ((v == 'resolved' || v == 'confirmed') && !confirmed) {
      return 'Awaiting Confirmation';
    }
    switch (v) {
      case 'new':        return 'Pending';
      case 'inprogress': return 'In Progress';
      case 'confirmed':  return 'Resolved';
      default:
        return s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ── Confirm resolution API call ───────────────────────────────────────────

  Future<void> _confirmResolution() async {
    setState(() => _confirming = true);
    try {
      final complaintId = _complaint['id'];
      final response = await http.put(
        Uri.parse('$baseUrl/api/complaints/$complaintId/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_confirmed': true}),
      );
      if (response.statusCode == 200 && mounted) {
  setState(() => _userConfirmed = true);
  widget.onConfirmed();
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF6A1B9A), // Purple
    elevation: 8,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    duration: const Duration(seconds: 3),
    content: Row(
      children: const [
        Icon(
          Icons.verified_rounded,
          color: Colors.white,
          size: 22,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Thank you! Resolution confirmed.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  ),
);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server.')),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Always read from _complaint (fresh), not widget.complaint
    final c = _complaint;
    final category = (c['category'] ?? 'General').toString();
    final description = (c['description'] ?? '').toString();
    final priority = (c['priority'] ?? 'Normal').toString();
    final createdAt = (c['created_at'] ?? '').toString();
    final adminRemark = (c['admin_remark'] ?? '').toString();
    final isResolved = _currentStatus.toLowerCase() == 'resolved';
    final isConfirmed = _userConfirmed;
    final statusColor = _statusColor(_currentStatus, _userConfirmed);
    final catColor = _categoryColor(category);

    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // ── Hero header ───────────────────────────────────────────
              _buildHeroHeader(category, priority, catColor),

              // ── Scrollable body ───────────────────────────────────────
              Expanded(
                child: _loadingFresh
                    ? const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Info card ─────────────────────────────
                            _SectionCard(
                              child: Column(
                                children: [
                                  _InfoRow(
                                    icon: Icons.category_outlined,
                                    label: 'Category',
                                    value: category,
                                    valueColor: catColor,
                                    valueBg: catColor.withValues(alpha: 0.1),
                                    isBadge: true,
                                  ),
                                  _Divider(),
                                  _InfoRow(
                                    icon: Icons.flag_outlined,
                                    label: 'Priority',
                                    value: priority,
                                    valueColor: _priorityColor(priority),
                                    valueBg: _priorityColor(priority).withValues(alpha: 0.1),
                                    isBadge: true,
                                  ),
                                  _Divider(),
                                  _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Submitted',
                                    value: _formatDate(createdAt),
                                  ),
                                  _Divider(),
                                  _InfoRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'Current Status',
                                    value: _statusDisplay(_currentStatus, _userConfirmed),
                                    valueColor: statusColor,
                                    valueBg: statusColor.withValues(alpha: 0.1),
                                    isBadge: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Description card ───────────────────────
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(text: 'YOUR COMPLAINT'),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFEEEEF5)),
                                    ),
                                    child: Text(
                                      description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4A4A6A),
                                        height: 1.65,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Status flow ────────────────────────────
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(text: 'STATUS FLOW'),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      _StatusStep(
                                        label: 'Pending',
                                        icon: Icons.hourglass_empty_rounded,
                                        state: _stepState('pending'),
                                      ),
                                      _StepConnector(filled: _isAfter('pending')),
                                      _StatusStep(
                                        label: 'In Progress',
                                        icon: Icons.refresh_rounded,
                                        state: _stepState('in progress'),
                                      ),
                                      _StepConnector(filled: _isAfter('in progress')),
                                      _StatusStep(
                                        label: 'Resolved',
                                        icon: Icons.check_circle_outline_rounded,
                                        state: _stepState('resolved'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ── Admin remark (only if present) ─────────
                            if (adminRemark.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(text: 'ADMIN REMARK'),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F4FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFD0DAFF)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.support_agent_rounded,
                                              size: 16, color: Color(0xFF2979FF)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              adminRemark,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF1A1A2E),
                                                height: 1.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ── Resolution confirmation card ────────────
                            if (isResolved) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(text: 'RESOLUTION CONFIRMATION'),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF7F0),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF0BAB64).withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.verified_outlined, size: 15, color: Color(0xFF0BAB64)),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Admin has marked this complaint as resolved. Please confirm if your issue has been genuinely resolved.',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF2D6A4F),
                                                height: 1.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ── Already confirmed banner ────────────────
                            if (isConfirmed) ...[
                              const SizedBox(height: 12),
                              _SectionCard(
                                child: Row(
                                  children: const [
                                    Icon(Icons.verified_rounded, color: Color(0xFF0BAB64), size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'You have confirmed this resolution. Thank you!',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF2D6A4F),
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // ── Action button ──────────────────────────
                            _buildActionButton(isResolved, isConfirmed),
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

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHeroHeader(String category, String priority, Color catColor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C27B0), Color(0xFF7B52E8), Color(0xFF2CA7F6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -24, top: -24,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text('Back to complaints',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon(category), color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: Colors.white, letterSpacing: -0.4)),
                            Text('Complaint Details',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.65))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroBadge(
                        icon: Icons.warning_amber_rounded,
                        label: '$priority Priority',
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _HeroBadge(
                        icon: Icons.info_outline_rounded,
                        label: _statusDisplay(_currentStatus, _userConfirmed),
                        color: _statusColor(_currentStatus, _userConfirmed).withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────

  Widget _buildActionButton(bool isResolved, bool isConfirmed) {
    // Already confirmed — show nothing (banner above handles it)
    if (isConfirmed) return const SizedBox.shrink();

    // Resolved — show green confirm button
    if (isResolved) {
      return GestureDetector(
        onTap: _confirming ? null : _confirmResolution,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0BAB64), Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0BAB64).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_confirming)
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else ...[
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Yes, My Issue is Resolved',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.2)),
              ],
            ],
          ),
        ),
      );
    }

    // Not resolved yet — greyed out placeholder
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFFABABCC)),
          SizedBox(width: 8),
          Text('Awaiting resolution from admin',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFABABCC))),
        ],
      ),
    );
  }

  // ── Status flow helpers ───────────────────────────────────────────────────

  int _statusRank(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'new':        return 0;
      case 'in progress':
      case 'inprogress': return 1;
      case 'resolved':
      case 'confirmed':  return 2;
      default:           return 0;
    }
  }

  // The "Resolved" step (rank 2) only becomes fully "done" once the student
  // has confirmed. Until then, it shows as the current/active step — signaling
  // "reached, but waiting on you" instead of "finished".
  _StepState _stepState(String step) {
    final cur = _statusRank(_currentStatus);
    final stp = _statusRank(step);

    if (stp == 2) {
      if (cur < 2) return _StepState.upcoming;
      return _userConfirmed ? _StepState.done : _StepState.active;
    }

    if (cur == stp) return _StepState.active;
    if (cur > stp)  return _StepState.done;
    return _StepState.upcoming;
  }

  bool _isAfter(String step) => _statusRank(_currentStatus) > _statusRank(step);
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 1.4)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBg;
  final bool isBadge;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBg,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8888A0)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0), fontWeight: FontWeight.w500)),
          const Spacer(),
          isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: valueBg, borderRadius: BorderRadius.circular(99)),
                  child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor)),
                )
              : Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFEEEEF5));
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _StatusStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final _StepState state;
  const _StatusStep({required this.label, required this.icon, required this.state});

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    List<BoxShadow> shadow = [];
    switch (state) {
      case _StepState.done:
        bg = _accent.withValues(alpha: 0.12);
        fg = const Color(0xFF007B8A);
        border = _accent.withValues(alpha: 0.25);
        break;
      case _StepState.active:
        bg = _primary;
        fg = Colors.white;
        border = _primary;
        shadow = [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))];
        break;
      case _StepState.upcoming:
        bg = _surface;
        fg = const Color(0xFFABABCC);
        border = const Color(0xFFEEEEF5);
        break;
    }
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
          boxShadow: shadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool filled;
  const _StepConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 16, height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: filled ? _accent.withValues(alpha: 0.5) : const Color(0xFFEEEEF5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Nav data ──────────────────────────────────────────────────────────────────

class _NavData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavData(this.label, this.icon, this.activeIcon);
}