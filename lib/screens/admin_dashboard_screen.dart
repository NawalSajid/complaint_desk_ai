import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminId;
  const AdminDashboardScreen({super.key, required this.adminId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF9C27B0);
  static const Color _deepPurple = Color(0xFF7B1FA2);
  static const Color _cyan = Color(0xFF00BCD4);
  static const Color _bg = Color(0xFFF4F0FB);
  static const Color _cardBg = Colors.white;

  // ── Bottom-nav index ────────────────────────────────────────────────────────
  int _navIndex = 0;

  // ── Animation ───────────────────────────────────────────────────────────────
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // ── Priority bar animation controllers ──────────────────────────────────────
  late AnimationController _barController;
  late Animation<double> _highAnim;
  late Animation<double> _medAnim;
  late Animation<double> _lowAnim;

  // ── Stat data ────────────────────────────────────────────────────────────────
  final int _total = 128;
  final int _pending = 34;
  final int _inProgress = 52;
  final int _resolved = 42;

  // Priority counts
  final int _high = 77;
  final int _medium = 38;
  final int _low = 13;

  // ── Recent complaints (dummy) ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _recent = [
    {
      'id': '#C-1041',
      'title': 'Hostel water supply issue',
      'dept': 'Facilities',
      'status': 'Pending',
      'priority': 'High',
      'time': '2h ago',
    },
    {
      'id': '#C-1040',
      'title': 'Library AC not working',
      'dept': 'Maintenance',
      'status': 'In Progress',
      'priority': 'Medium',
      'time': '4h ago',
    },
    {
      'id': '#C-1039',
      'title': 'Parking area lights broken',
      'dept': 'Security',
      'status': 'Pending',
      'priority': 'Low',
      'time': '6h ago',
    },
    {
      'id': '#C-1038',
      'title': 'IT lab projector fault',
      'dept': 'IT Dept',
      'status': 'Resolved',
      'priority': 'High',
      'time': '1d ago',
    },
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final maxVal = _high.toDouble();
    _highAnim = Tween<double>(begin: 0, end: _high / maxVal).animate(
      CurvedAnimation(
          parent: _barController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _medAnim = Tween<double>(begin: 0, end: _medium / maxVal).animate(
      CurvedAnimation(
          parent: _barController,
          curve: const Interval(0.1, 0.8, curve: Curves.easeOut)),
    );
    _lowAnim = Tween<double>(begin: 0, end: _low / maxVal).animate(
      CurvedAnimation(
          parent: _barController,
          curve: const Interval(0.2, 0.9, curve: Curves.easeOut)),
    );

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _barController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'In Progress':
        return _cyan;
      case 'Resolved':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _buildBottomNav(),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
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
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130,
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
              colors: [Color(0xFF6A0080), _deepPurple],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _purple.withAlpha(220),
                                  _cyan.withAlpha(220)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: Colors.white, size: 17),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Complaint',
                                  style: TextStyle(
                                    color: Color(0xFF80DEEA),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Desk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: '.AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Notification bell
                      Stack(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 20),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Welcome, Admin',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Collapsed title
    );
  }

  // ── 2×2 Stat Grid ─────────────────────────────────────────────────────────────
  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'Total Complaints',
          value: _total,
          icon: Icons.description_outlined,
          gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
          iconBg: Colors.white.withAlpha(45),
        ),
        _StatCard(
          label: 'Pending',
          value: _pending,
          icon: Icons.schedule_rounded,
          gradientColors: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          iconBg: Colors.white.withAlpha(45),
        ),
        _StatCard(
          label: 'In Progress',
          value: _inProgress,
          icon: Icons.sync_rounded,
          gradientColors: const [Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          iconBg: _cyan.withAlpha(28),
          darkText: true,
        ),
        _StatCard(
          label: 'Resolved',
          value: _resolved,
          icon: Icons.check_circle_outline_rounded,
          gradientColors: const [Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          iconBg: _purple.withAlpha(22),
          darkText: true,
        ),
      ],
    );
  }

  // ── Priority breakdown card ────────────────────────────────────────────────────
  Widget _buildPriorityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withAlpha(14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Priority Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _barController,
            builder: (_, __) => Column(
              children: [
                _PriorityBar(
                  label: 'High',
                  count: _high,
                  progress: _highAnim.value,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 13),
                _PriorityBar(
                  label: 'Medium',
                  count: _medium,
                  progress: _medAnim.value,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 13),
                _PriorityBar(
                  label: 'Low',
                  count: _low,
                  progress: _lowAnim.value,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Complaints ─────────────────────────────────────────────────────────
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
          _recent.length,
          (i) => _ComplaintTile(
            data: _recent[i],
            statusColor: _statusColor(_recent[i]['status']),
            priorityColor: _priorityColor(_recent[i]['priority']),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Home'},
      {'icon': Icons.list_alt_rounded, 'label': 'Complaints'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _purple.withAlpha(18),
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
              final selected = _navIndex == i;
              final icon = items[i]['icon'] as IconData;
              final label = items[i]['label'] as String;
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _purple.withAlpha(18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: selected ? _purple : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected ? _purple : Colors.grey.shade400,
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

// ── Reusable Stat Card ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconBg;
  final bool darkText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.iconBg,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? const Color(0xFF1A1A2E) : Colors.white;
    final subColor = darkText ? Colors.grey.shade500 : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(darkText ? 14 : 60),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: textColor),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Priority Bar Row ───────────────────────────────────────────────────────────
class _PriorityBar extends StatelessWidget {
  final String label;
  final int count;
  final double progress; // 0.0 – 1.0
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

// ── Complaint List Tile ────────────────────────────────────────────────────────
class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;
  final Color priorityColor;

  const _ComplaintTile({
    required this.data,
    required this.statusColor,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Priority dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: priorityColor.withAlpha(100), blurRadius: 6)
              ],
            ),
          ),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['id'],
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['status'],
                        style: TextStyle(
                          fontSize: 9.5,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${data['dept']}  ·  ${data['time']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}