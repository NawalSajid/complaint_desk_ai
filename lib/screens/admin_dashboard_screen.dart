// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'admin_complaint_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminId;
  final void Function(int) onNavTap;
  final ValueNotifier<int> refreshNotifier;
  final void Function() onRefreshAll;
  const AdminDashboardScreen({
    super.key,
    required this.adminId,
    required this.onNavTap,
    required this.refreshNotifier,
    required this.onRefreshAll,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  static const Color _purple     = Color(0xFF9C27B0);
  static const Color _deepPurple = Color(0xFF7B1FA2);
  static const Color _darkPurple = Color(0xFF6A0080);
  static const Color _cyan       = Color(0xFF00BCD4);

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  bool _loading = true;
  int  _total = 0, _pending = 0, _inProgress = 0, _resolved = 0;
  int  _high = 0, _medium = 0, _low = 0;
  List<ComplaintItem> _recentItems = [];

  // ── Invisible auto-refresh ─────────────────────────────────────────────────
  // Silently polls the server in the background so the dashboard stays in
  // sync with new/updated complaints without showing any loading spinner
  // or interrupting whatever the admin is doing.
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_onRefresh); 

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
    _fetchData();

    // Start silent background polling. Uses _fetchComplaints() directly
    // (not _fetchData) so _loading is never toggled and no spinner appears.
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted) _fetchComplaints();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    widget.refreshNotifier.removeListener(_onRefresh);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  void _onRefresh() {          // ← ADD this method
    _fetchData();
  }
  // ── Fetch everything ───────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    await _fetchComplaints();
    if (mounted) setState(() => _loading = false);
  }

  // ── Complaints — same model/parsing as AdminComplaintsScreen ──────────────
  Future<void> _fetchComplaints() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/api/admin/complaints'));
      if (res.statusCode != 200) return;

      final list = (jsonDecode(res.body) as List)
          .map((e) => ComplaintItem.fromApi(e as Map<String, dynamic>))
          .toList();

      // Sort newest first so "recent" picks the actual latest items
      list.sort((a, b) => b.sortKey.compareTo(a.sortKey));

      int total = list.length;
      int pending = 0, inProgress = 0, resolved = 0;
      int high = 0, medium = 0, low = 0;

      for (final c in list) {
        if (c.status == ComplaintStatus.pending) {
          pending++;
        } else if (c.status == ComplaintStatus.inProgress) {
          inProgress++;
        } else if (c.status == ComplaintStatus.resolved) {
          resolved++;
        }

        if (c.priority == Priority.high) {
          high++;
        } else if (c.priority == Priority.medium) {
          medium++;
        } else if (c.priority == Priority.low) {
          low++;
        }
      }

      if (!mounted) return;
      setState(() {
        _total       = total;
        _pending     = pending;
        _inProgress  = inProgress;
        _resolved    = resolved;
        _high        = high;
        _medium      = medium;
        _low         = low;
        _recentItems = list.take(4).toList();
      });
    } catch (_) {}
  }

  // ── Build — no Scaffold, no bottom nav (owned by AdminRoot) ───────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _purple))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        _buildStatGrid(),
                        const SizedBox(height: 24),
                        _buildPriorityCard(),
                        const SizedBox(height: 24),
                        _buildRecentSection(),
                        const SizedBox(height: 30),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _deepPurple,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darkPurple, _deepPurple],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(10),
                  ),
                ),
              ),
              Positioned(
                left: -20, bottom: -20,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withAlpha(18),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                _purple.withAlpha(220),
                                _cyan.withAlpha(220),
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: Colors.white, size: 17),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                text: 'Complaint',
                                style: TextStyle(
                                  color: Color(0xFF80DEEA), fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: 'Desk',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: '.AI',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold, letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Welcome, Admin',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12.5),
                      ),
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

  // ── Stat grid ──────────────────────────────────────────────────────────────
  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'Total', sublabel: 'Complaints', value: _total,
          icon: Icons.description_outlined,
          accentColor: _cyan,
          gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
          darkText: false,
        ),
        _StatCard(
          label: 'Pending', sublabel: 'Awaiting review', value: _pending,
          icon: Icons.schedule_rounded,
          accentColor: const Color(0xFFF59E0B),
          gradientColors: const [Color(0xFF9C27B0), Color(0xFF6A0080)],
          darkText: false,
        ),
        _StatCard(
          label: 'In Progress', sublabel: 'Being handled', value: _inProgress,
          icon: Icons.sync_rounded,
          accentColor: _cyan,
          gradientColors: const [Colors.white, Color(0xFFEAF8FB)],
          darkText: true,
        ),
        _StatCard(
          label: 'Resolved', sublabel: 'Completed', value: _resolved,
          icon: Icons.check_circle_outline_rounded,
          accentColor: const Color(0xFF22C55E),
          gradientColors: const [Colors.white, Color(0xFFEAFBEE)],
          darkText: true,
        ),
      ],
    );
  }

  // ── Priority breakdown card ─────────────────────────────────────────────────
  Widget _buildPriorityCard() {
    final total = _high + _medium + _low;
    final safeTotal = total > 0 ? total.toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEF5)),
        boxShadow: [
          BoxShadow(
            color: _purple.withAlpha(12),
            blurRadius: 16, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Breakdown',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E), letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _PriorityRow(
            label: 'High', count: _high,
            fraction: _high / safeTotal,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _PriorityRow(
            label: 'Medium', count: _medium,
            fraction: _medium / safeTotal,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _PriorityRow(
            label: 'Low', count: _low,
            fraction: _low / safeTotal,
            color: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  // ── Recent complaints ──────────────────────────────────────────────────────
  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Complaints',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E), letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavTap(1), // 1 = Complaints tab
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 12.5, color: _purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_recentItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No complaints yet',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          )
        else
          ..._recentItems.map((c) => _ComplaintTile(
                item: c,
                onUpdated: _fetchComplaints,
              )),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAT CARD — no top strip, decorative circle only
// ══════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String label, sublabel;
  final int value;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool darkText;

  const _StatCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.darkText,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? const Color(0xFF1A1A2E) : Colors.white;
    final subColor  = darkText ? const Color(0xFF8888A0) : Colors.white70;
    final iconColor = darkText ? accentColor : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: darkText
            ? Border.all(color: const Color(0xFFEEEEF5))
            : null,
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(darkText ? 20 : 80),
            blurRadius: 14, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14, bottom: -14,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withAlpha(darkText ? 20 : 35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(darkText ? 22 : 50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 15, color: iconColor),
                    ),
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: textColor, letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: textColor, letterSpacing: -0.2,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 10.5, color: subColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRIORITY ROW
// ══════════════════════════════════════════════════════════════════════════════
class _PriorityRow extends StatelessWidget {
  final String label;
  final int count;
  final double fraction;
  final Color color;

  const _PriorityRow({
    required this.label,
    required this.count,
    required this.fraction,
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
              fontSize: 12.5, fontWeight: FontWeight.w600,
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(80),
                        blurRadius: 6, offset: const Offset(0, 2),
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
              fontSize: 12.5, fontWeight: FontWeight.bold, color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPLAINT TILE — uses the same ComplaintItem model as the Complaints screen
// ══════════════════════════════════════════════════════════════════════════════
class _ComplaintTile extends StatelessWidget {
  final ComplaintItem item;
  final VoidCallback? onUpdated;
  const _ComplaintTile({required this.item, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminComplaintDetailScreen(complaint: item),
        ),
      ).then((_) => onUpdated?.call()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: item.priority.dot,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: item.priority.dot.withAlpha(100), blurRadius: 6),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.id,
                        style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.status.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status.label,
                          style: TextStyle(
                            fontSize: 9.5, color: item.status.fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E), letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category}  ·  ${item.timeAgo}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}