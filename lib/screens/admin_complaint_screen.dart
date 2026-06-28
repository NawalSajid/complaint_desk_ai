import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/analytics_screen.dart';
import 'package:complaint_desk_ai/screens/admin_setting_screen.dart';
import 'package:complaint_desk_ai/screens/admin_dashboard_screen.dart'; // ← your separate file
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS  (single source of truth for both screens)
// ══════════════════════════════════════════════════════════════════════════════
const Color kViolet = Color(0xFF9C27B0);
const Color kDeepViolet = Color(0xFF7B1FA2);
const Color kDarkViolet = Color(0xFF6A0080);
const Color kCyan = Color(0xFF00BCD4);
const Color kSurface = Color(0xFFF4F0FB);
const Color kWhite = Colors.white;
const Color kInkDark = Color(0xFF1A1A2E);
const Color kInkMid = Color(0xFF4A4A6A);
const Color kInkLight = Color(0xFF8888A0);
const Color kBorder = Color(0xFFEEEEF5);
const Color kVioletLight = Color(0xFFEDE8FF);

// ══════════════════════════════════════════════════════════════════════════════
// SHARED DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════
enum Priority { high, medium, low }

enum ComplaintStatus { pending, inProgress, resolved }

extension PriorityExt on Priority {
  String get label => const ['High', 'Medium', 'Low'][index];
  Color get fg =>
      const [Color(0xFFA32D2D), Color(0xFF854F0B), Color(0xFF3B6D11)][index];
  Color get bg =>
      const [Color(0xFFFCEBEB), Color(0xFFFFF5EC), Color(0xFFEAF3DE)][index];
  Color get dot =>
      const [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF22C55E)][index];
}

extension StatusExt on ComplaintStatus {
  String get label => const ['Pending', 'In Progress', 'Resolved'][index];
  Color get fg =>
      const [Color(0xFF854F0B), Color(0xFF185FA5), Color(0xFF3B6D11)][index];
  Color get bg =>
      const [Color(0xFFFFF5EC), Color(0xFFEEF4FF), Color(0xFFEAF3DE)][index];
  Color get dot =>
      const [Color(0xFFF59E0B), Color(0xFF00BCD4), Color(0xFF22C55E)][index];
}

class ComplaintItem {
  final String id;
  final String title;
  final String category;
  final Priority priority;
  final ComplaintStatus status;
  final String timeAgo;
  final String studentName;
  final String rollNo;
  final String description;
  final String date;
  final String sortKey;

  const ComplaintItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.timeAgo,
    required this.studentName,
    required this.rollNo,
    required this.description,
    required this.date,
    required this.sortKey,
  });

  // ── Format ISO datetime to "dd/mm/yyyy  HH:mm" ───────────────────────────
  static String _formatDateTime(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt    = DateTime.parse(raw).toLocal();
      final day   = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year  = dt.year.toString();
      final hour  = dt.hour.toString().padLeft(2, '0');
      final min   = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year  $hour:$min';
    } catch (_) {
      return raw;
    }
  }

  factory ComplaintItem.fromApi(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? 'Pending').toString();
    final priorityRaw = (json['priority'] ?? 'Medium').toString();

    ComplaintStatus mapStatus(String s) {
      final v = s.toLowerCase();
      if (v == 'resolved') return ComplaintStatus.resolved;
      if (v == 'in progress' || v == 'in_progress') {
        return ComplaintStatus.inProgress;
      }
      return ComplaintStatus.pending;
    }

    Priority mapPriority(String p) {
      final v = p.toLowerCase();
      if (v == 'high') return Priority.high;
      if (v == 'low') return Priority.low;
      return Priority.medium;
    }

    final createdAt = (json['created_at'] ?? '').toString();

    return ComplaintItem(
      id: '#C-${json['id']}',
      title: (json['description'] ?? 'Complaint').toString(),
      category: (json['category'] ?? 'General').toString(),
      priority: mapPriority(priorityRaw),
      status: mapStatus(statusRaw),
      timeAgo: _formatDateTime(createdAt),
      studentName: (json['user_name'] ?? 'Unknown User').toString(),
      rollNo: (json['user_email'] ?? 'N/A').toString(),
      description: (json['description'] ?? '').toString(),
      date: createdAt.split(' ').first,
      sortKey: createdAt,
    );
  }
}

const kAllComplaints = [
  ComplaintItem(
    id: '#C-1042',
    title: 'WiFi not working in hostel block B',
    category: 'Hostel',
    priority: Priority.high,
    status: ComplaintStatus.pending,
    timeAgo: '15/05/2026  12:00',
    studentName: 'Areeba Khan',
    rollNo: 'CS-21-045',
    description:
        'The WiFi in hostel block B has been down since yesterday evening. Multiple students are affected and cannot submit assignments online. This is seriously affecting coursework deadlines.',
    date: '15 May 2026',
    sortKey: '2026-05-15 12:00:00',
  ),
  ComplaintItem(
    id: '#C-1041',
    title: 'Hostel water supply issue',
    category: 'Hostel',
    priority: Priority.high,
    status: ComplaintStatus.pending,
    timeAgo: '15/05/2026  11:00',
    studentName: 'Hamza Raza',
    rollNo: 'EE-22-011',
    description:
        'The water supply in hostel block A has been intermittent for the past three days. Students are facing serious hygiene and sanitation issues as a result.',
    date: '15 May 2026',
    sortKey: '2026-05-15 11:00:00',
  ),
  ComplaintItem(
    id: '#C-1040',
    title: 'Library AC not working',
    category: 'General',
    priority: Priority.medium,
    status: ComplaintStatus.inProgress,
    timeAgo: '15/05/2026  10:00',
    studentName: 'Sara Malik',
    rollNo: 'BBA-21-034',
    description:
        'The air conditioning in the main library reading hall has stopped working. The heat is making it very difficult to study, especially during afternoon hours.',
    date: '15 May 2026',
    sortKey: '2026-05-15 10:00:00',
  ),
  ComplaintItem(
    id: '#C-1039',
    title: 'Parking area lights broken',
    category: 'General',
    priority: Priority.low,
    status: ComplaintStatus.pending,
    timeAgo: '14/05/2026  12:00',
    studentName: 'Ali Tariq',
    rollNo: 'CS-20-088',
    description:
        'The lights in the main parking area have been broken for over a week. The area is completely dark at night, creating a serious safety concern for students and staff.',
    date: '14 May 2026',
    sortKey: '2026-05-14 12:00:00',
  ),
  ComplaintItem(
    id: '#C-1038',
    title: 'IT lab projector fault',
    category: 'Academic',
    priority: Priority.high,
    status: ComplaintStatus.resolved,
    timeAgo: '14/05/2026  11:00',
    studentName: 'Fatima Noor',
    rollNo: 'SE-22-019',
    description:
        'The projector in IT lab 2 has been faulty for three days. Multiple practical sessions have been impacted and students are falling behind on lab work.',
    date: '14 May 2026',
    sortKey: '2026-05-14 11:00:00',
  ),
  ComplaintItem(
    id: '#C-1037',
    title: 'Bus route 3 cancelled without notice',
    category: 'Transport',
    priority: Priority.high,
    status: ComplaintStatus.pending,
    timeAgo: '14/05/2026  10:00',
    studentName: 'Usman Ghani',
    rollNo: 'ME-21-055',
    description:
        'Bus route 3 has been cancelled for three consecutive days without any prior notification. Students from the eastern residential area cannot reach campus on time.',
    date: '14 May 2026',
    sortKey: '2026-05-14 10:00:00',
  ),
  ComplaintItem(
    id: '#C-1036',
    title: 'Canteen food quality deteriorating',
    category: 'General',
    priority: Priority.medium,
    status: ComplaintStatus.inProgress,
    timeAgo: '13/05/2026  12:00',
    studentName: 'Zara Ahmed',
    rollNo: 'CS-22-033',
    description:
        'The food quality in the main canteen has deteriorated significantly over the past two weeks. Several students have reported stomach issues after eating from canteen stalls.',
    date: '13 May 2026',
    sortKey: '2026-05-13 12:00:00',
  ),
  ComplaintItem(
    id: '#C-1035',
    title: 'Library closing early on Fridays',
    category: 'Academic',
    priority: Priority.low,
    status: ComplaintStatus.resolved,
    timeAgo: '13/05/2026  11:00',
    studentName: 'Omar Farooq',
    rollNo: 'LAW-21-012',
    description:
        'The library has been closing at 4pm on Fridays instead of the usual 8pm. Many students rely on the library for evening study and research sessions.',
    date: '13 May 2026',
    sortKey: '2026-05-13 11:00:00',
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN ROOT
// ══════════════════════════════════════════════════════════════════════════════
class AdminRoot extends StatefulWidget {
  final String adminId;
  const AdminRoot({super.key, required this.adminId});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  int _navIndex = 0;
  void _setNav(int i) => setState(() => _navIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          // ← Now uses the SEPARATE admin_dashboard_screen.dart, not a local class
          AdminDashboardScreen(
            adminId: widget.adminId,
            onNavTap: _setNav,
          ),
          AdminComplaintsScreen(onNavTap: _setNav, navIndex: _navIndex),
          AdminAnalyticsScreen(onNavTap: _setNav, navIndex: _navIndex),
          AdminSettingsScreen(onNavTap: _setNav, navIndex: _navIndex),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        activeIndex: _navIndex,
        onTap: _setNav,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — COMPLAINTS LIST
// ══════════════════════════════════════════════════════════════════════════════
class AdminComplaintsScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  final int navIndex;

  const AdminComplaintsScreen({
    super.key,
    required this.onNavTap,
    required this.navIndex,
  });

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

enum SortOption { recent, oldest, priorityHighLow, priorityLowHigh }

extension SortOptionExt on SortOption {
  String get label => const [
    'Recent',
    'Oldest',
    'Priority: High to Low',
    'Priority: Low to High',
  ][index];
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen>
    with SingleTickerProviderStateMixin {
  ComplaintStatus? _activeFilter;
  String _searchQuery = '';
  bool _showSearch = false;
  SortOption _sortOption = SortOption.recent;
  final _searchCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  List<ComplaintItem> _liveComplaints = [];

  List<ComplaintItem> get _complaints =>
      _liveComplaints.isNotEmpty ? _liveComplaints : kAllComplaints;

  Future<void> _fetchComplaints() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/complaints'));
      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((e) => ComplaintItem.fromApi(e as Map<String, dynamic>))
            .toList();
        setState(() => _liveComplaints = data);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ComplaintItem> get _filtered {
    var list = _complaints.toList();
    if (_activeFilter != null) {
      list = list.where((c) => c.status == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.title.toLowerCase().contains(q) ||
                c.category.toLowerCase().contains(q) ||
                c.studentName.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_sortOption) {
      case SortOption.recent:
        list.sort((a, b) => b.sortKey.compareTo(a.sortKey));
        break;
      case SortOption.oldest:
        list.sort((a, b) => a.sortKey.compareTo(b.sortKey));
        break;
      case SortOption.priorityHighLow:
        list.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case SortOption.priorityLowHigh:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildAppBar(),
              if (_showSearch) _buildSearchBar(),
              _buildFilterRow(),
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ComplaintCard(
                          complaint: _filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminComplaintDetailScreen(
                                complaint: _filtered[i],
                              ),
                            ),
                          ).then((_) => _fetchComplaints()),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: kWhite,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: kWhite,
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kViolet.withValues(alpha: 0.85),
                      kCyan.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: kViolet.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: kWhite,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Complaint',
                      style: TextStyle(
                        color: kCyan,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'Desk',
                      style: TextStyle(
                        color: kViolet,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: '.AI',
                      style: TextStyle(
                        color: kViolet,
                        fontSize: 17,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _IconBtn(
                icon: _showSearch
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                onTap: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }
                }),
              ),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.tune_rounded, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          autofocus: true,
          style: const TextStyle(
            fontSize: 13,
            color: kInkDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search complaints, students...',
            hintStyle: const TextStyle(fontSize: 13, color: kInkLight),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: kInkLight,
              size: 18,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: kInkLight,
                      size: 18,
                    ),
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchCtrl.clear();
                    }),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = <String, ComplaintStatus?>{
      'All': null,
      'Pending': ComplaintStatus.pending,
      'In Progress': ComplaintStatus.inProgress,
      'Resolved': ComplaintStatus.resolved,
    };
    return Container(
      color: kWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: kViolet,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ALL COMPLAINTS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: kViolet,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filtered.length} results',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kInkLight,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SortOption>(
                      value: _sortOption,
                      icon: const Icon(
                        Icons.swap_vert_rounded,
                        size: 16,
                        color: kInkLight,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kInkMid,
                      ),
                      isDense: true,
                      onChanged: (v) {
                        if (v != null) setState(() => _sortOption = v);
                      },
                      items: SortOption.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              children: filters.entries.map((e) {
                final isActive = _activeFilter == e.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = e.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? kViolet : kWhite,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: isActive ? kViolet : kBorder),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: kViolet.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? kWhite : kInkLight,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: kBorder),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kVioletLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_rounded, color: kViolet, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kInkDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 12, color: kInkLight),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 3 — COMPLAINT DETAIL & STATUS UPDATE
// ══════════════════════════════════════════════════════════════════════════════
class AdminComplaintDetailScreen extends StatefulWidget {
  final ComplaintItem complaint;
  const AdminComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<AdminComplaintDetailScreen> createState() =>
      _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState extends State<AdminComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  late ComplaintStatus _currentStatus;
  final _remarksCtrl = TextEditingController();
  bool _remarksError = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint.status;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  ComplaintStatus? get _nextStatus {
    if (_currentStatus == ComplaintStatus.pending) {
      return ComplaintStatus.inProgress;
    }
    if (_currentStatus == ComplaintStatus.inProgress) {
      return ComplaintStatus.resolved;
    }
    return null;
  }

  String get _actionLabel {
    if (_currentStatus == ComplaintStatus.pending) return 'Mark as In Progress';
    if (_currentStatus == ComplaintStatus.inProgress) return 'Mark as Resolved';
    return 'Complaint Resolved';
  }

  IconData get _actionIcon {
    if (_currentStatus == ComplaintStatus.pending) {
      return Icons.play_arrow_rounded;
    }
    if (_currentStatus == ComplaintStatus.inProgress) {
      return Icons.check_circle_outline_rounded;
    }
    return Icons.verified_rounded;
  }

  void _handleAction() {
    if (_currentStatus == ComplaintStatus.inProgress &&
        _remarksCtrl.text.trim().isEmpty) {
      setState(() => _remarksError = true);
      return;
    }
    if (_nextStatus != null) _updateStatusOnServer(_nextStatus!);
  }

  Future<void> _updateStatusOnServer(ComplaintStatus next) async {
    final status = next == ComplaintStatus.inProgress
        ? 'In Progress'
        : next == ComplaintStatus.resolved
        ? 'Resolved'
        : 'Pending';

    final complaintId = int.tryParse(
      widget.complaint.id.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (complaintId == null) return;

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/admin/complaints/$complaintId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'admin_remark': _remarksCtrl.text.trim(),
        }),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _currentStatus = next;
          _remarksError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to ${_currentStatus.label}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: kViolet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeroHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(),
                      const SizedBox(height: 12),
                      _buildStatusFlow(),
                      const SizedBox(height: 12),
                      if (_currentStatus != ComplaintStatus.resolved) ...[
                        _buildRemarksField(),
                        const SizedBox(height: 14),
                      ],
                      _buildActionButton(),
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

  Widget _buildHeroHeader() {
    final c = widget.complaint;
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
              right: -24,
              top: -24,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kWhite.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kWhite.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back to list',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kWhite.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${c.id}  ·  ${c.date}',
                    style: TextStyle(
                      fontSize: 10,
                      color: kWhite.withValues(alpha: 0.55),
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    c.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                      letterSpacing: -0.4,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroBadge(
                        icon: Icons.category_outlined,
                        label: c.category,
                        color: kCyan.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 8),
                      _HeroBadge(
                        icon: Icons.warning_amber_rounded,
                        label: '${c.priority.label} Priority',
                        color: kWhite.withValues(alpha: 0.18),
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

  Widget _buildInfoCard() {
    final c = widget.complaint;
    return _SectionCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Student',
            value: c.studentName,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Roll No.',
            value: c.rollNo,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Submitted',
            value: c.date,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Current Status',
            value: _currentStatus.label,
            valueColor: _currentStatus.fg,
            valueBg: _currentStatus.bg,
            isBadge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'COMPLAINT DESCRIPTION'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              '"${widget.complaint.description}"',
              style: const TextStyle(
                fontSize: 12.5,
                color: kInkMid,
                height: 1.65,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFlow() {
    return _SectionCard(
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
                state: _stepState(ComplaintStatus.pending),
              ),
              _StepConnector(filled: _currentStatus != ComplaintStatus.pending),
              _StatusStep(
                label: 'In Progress',
                icon: Icons.refresh_rounded,
                state: _stepState(ComplaintStatus.inProgress),
              ),
              _StepConnector(
                filled: _currentStatus == ComplaintStatus.resolved,
              ),
              _StatusStep(
                label: 'Resolved',
                icon: Icons.check_circle_outline_rounded,
                state: _stepState(ComplaintStatus.resolved),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StepState _stepState(ComplaintStatus step) {
    if (_currentStatus == step) return _StepState.active;
    if (_currentStatus.index > step.index) return _StepState.done;
    return _StepState.upcoming;
  }

  Widget _buildRemarksField() {
    final isResolving = _currentStatus == ComplaintStatus.inProgress;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(
                text: isResolving
                    ? 'RESOLUTION REMARKS'
                    : 'ADMIN REMARKS (OPTIONAL)',
              ),
              if (isResolving) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFE84393),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (isResolving) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF9F27).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFF854F0B),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Remarks are required before marking as Resolved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF854F0B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _remarksCtrl,
            onChanged: (_) {
              if (_remarksError) setState(() => _remarksError = false);
            },
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: kInkDark),
            decoration: InputDecoration(
              hintText: isResolving
                  ? 'Describe what action was taken to resolve this complaint...'
                  : 'Add a note or update (optional)...',
              hintStyle: const TextStyle(fontSize: 12.5, color: kInkLight),
              filled: true,
              fillColor: _remarksError ? const Color(0xFFFFF0F0) : kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _remarksError ? const Color(0xFFE24B4A) : kBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _remarksError ? const Color(0xFFE24B4A) : kBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _remarksError ? const Color(0xFFE24B4A) : kViolet,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_remarksError) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: Color(0xFFE24B4A),
                ),
                SizedBox(width: 4),
                Text(
                  'Remarks are required to mark as Resolved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE24B4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final isDone = _currentStatus == ComplaintStatus.resolved;
    return GestureDetector(
      onTap: isDone ? null : _handleAction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: isDone
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9C27B0),
                    Color(0xFF7B52E8),
                    Color(0xFF00BCD4),
                  ],
                ),
          color: isDone ? const Color(0xFFEAF3DE) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDone
              ? []
              : [
                  BoxShadow(
                    color: kViolet.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _actionIcon,
              size: 18,
              color: isDone ? const Color(0xFF3B6D11) : kWhite,
            ),
            const SizedBox(width: 8),
            Text(
              _actionLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDone ? const Color(0xFF3B6D11) : kWhite,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED BOTTOM NAV
// ══════════════════════════════════════════════════════════════════════════════
class AdminBottomNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const AdminBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
      (Icons.list_alt_outlined, Icons.list_alt_rounded, 'Complaints'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics'),
      (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kViolet.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == activeIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? kViolet.withAlpha(18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.$2 : item.$1,
                        size: 22,
                        color: isActive ? kViolet : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? kViolet : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _ComplaintCard extends StatefulWidget {
  final ComplaintItem complaint;
  final VoidCallback onTap;
  const _ComplaintCard({required this.complaint, required this.onTap});

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.06 : 0.03),
                blurRadius: _pressed ? 14 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: c.priority.dot,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c.id,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kInkLight,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            _SmallBadge(
                              label: c.priority.label,
                              fg: c.priority.fg,
                              bg: c.priority.bg,
                            ),
                            const SizedBox(width: 5),
                            _SmallBadge(
                              label: c.status.label,
                              fg: c.status.fg,
                              bg: c.status.bg,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kInkDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 11,
                              color: kInkLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              c.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: kInkLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: kInkLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              c.timeAgo,
                              style: const TextStyle(
                                fontSize: 10,
                                color: kInkLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFFCCCCDD),
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
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _SmallBadge({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kWhite.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kWhite),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: kWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: kViolet,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kViolet,
            letterSpacing: 1.4,
          ),
        ),
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
          Icon(icon, size: 15, color: kInkLight),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kInkLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: valueBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kInkDark,
                  ),
                ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: kBorder);
}

enum _StepState { done, active, upcoming }

class _StatusStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final _StepState state;
  const _StatusStep({
    required this.label,
    required this.icon,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    List<BoxShadow> shadow = [];
    switch (state) {
      case _StepState.done:
        bg = kCyan.withValues(alpha: 0.12);
        fg = const Color(0xFF007B8A);
        border = kCyan.withValues(alpha: 0.25);
        break;
      case _StepState.active:
        bg = kViolet;
        fg = kWhite;
        border = kViolet;
        shadow = [
          BoxShadow(
            color: kViolet.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
        break;
      case _StepState.upcoming:
        bg = kSurface;
        fg = kInkLight;
        border = kBorder;
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
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              textAlign: TextAlign.center,
            ),
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
      width: 16,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: filled ? kCyan.withValues(alpha: 0.5) : kBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Icon(icon, size: 18, color: kViolet),
      ),
    );
  }
}

// ignore: unused_element
class _PriorityBar extends StatelessWidget {
  final String label;
  final int count;
  final double progress;
  final Color color;
  const _PriorityBar({
    required this.label,
    required this.count,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}