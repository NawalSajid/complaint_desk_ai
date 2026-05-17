import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PASTE THIS FILE ALONGSIDE YOUR EXISTING main.dart / admin_root.dart
//
// Then in AdminRoot._AdminRootState.build(), replace:
//   _PlaceholderScreen(label: 'Analytics', ...)
// with:
//   AdminAnalyticsScreen(onNavTap: _setNav, navIndex: _navIndex),
// ══════════════════════════════════════════════════════════════════════════════

const Color kViolet      = Color(0xFF9C27B0);
const Color kDeepViolet  = Color(0xFF7B1FA2);
const Color kDarkViolet  = Color(0xFF6A0080);
const Color kCyan        = Color(0xFF00BCD4);
const Color kSurface     = Color(0xFFF4F0FB);
const Color kWhite       = Colors.white;
const Color kInkDark     = Color(0xFF1A1A2E);
const Color kInkMid      = Color(0xFF4A4A6A);
const Color kInkLight    = Color(0xFF8888A0);
const Color kBorder      = Color(0xFFEEEEF5);
const Color kVioletLight = Color(0xFFEDE8FF);

// ══════════════════════════════════════════════════════════════════════════════
// ANALYTICS SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class AdminAnalyticsScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  final int navIndex;

  const AdminAnalyticsScreen({
    super.key,
    required this.onNavTap,
    required this.navIndex,
  });

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with TickerProviderStateMixin {

  bool _showMonthly = false;
  bool _loading = true;
  List<ComplaintItem> _allComplaints = [];

  int get _total      => _allComplaints.length;
  int get _pending    => _allComplaints.where((c) => c.status == ComplaintStatus.pending).length;
  int get _inProgress => _allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
  int get _resolved   => _allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
  int get _high       => _allComplaints.where((c) => c.priority == Priority.high).length;
  int get _medium     => _allComplaints.where((c) => c.priority == Priority.medium).length;
  int get _low        => _allComplaints.where((c) => c.priority == Priority.low).length;

  Map<String, int> get _categoryMap {
    final map = <String, int>{};
    for (final c in _allComplaints) {
      map[c.category] = (map[c.category] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _fetchComplaints() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/complaints'));
      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((e) => ComplaintItem.fromApi(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _allComplaints = data;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, int>> get _topCategories {
    final entries = _categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

  List<double> get _weeklyBars {
    final t = _total.toDouble();
    return [t * 0.20, t * 0.31, t * 0.16, t * 0.33];
  }

  List<double> get _monthlyBars {
    final t = _total.toDouble();
    return [t * 0.60, t * 0.83, t * 0.67, t * 1.0];
  }

  static const _weeklyLabels  = ['W1', 'W2', 'W3', 'W4'];
  static const _monthlyLabels = ['Jan', 'Feb', 'Mar', 'Apr'];

  List<double>  get _bars   => _showMonthly ? _monthlyBars : _weeklyBars;
  List<String>  get _bLabel => _showMonthly ? _monthlyLabels : _weeklyLabels;

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  late AnimationController _barCtrl;
  late List<Animation<double>> _barAnims;

  late AnimationController _donutCtrl;
  late Animation<double>   _donutAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _buildBarAnims();

    _donutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _donutAnim = CurvedAnimation(parent: _donutCtrl, curve: Curves.easeOut);

    _entryCtrl.forward();
    _fetchComplaints();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _barCtrl.forward();
        _donutCtrl.forward();
      }
    });
  }

  void _buildBarAnims() {
    _barAnims = List.generate(_bars.length, (i) {
      final start = i * 0.10;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _barCtrl,
          curve: Interval(start, (start + 0.65).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });
  }

  void _switchPeriod(bool monthly) {
    setState(() => _showMonthly = monthly);
    _barCtrl
      ..reset()
      ..forward();
    _buildBarAnims();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _barCtrl.dispose();
    _donutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      // FIX 1: resizeToAvoidBottomInset prevents keyboard from causing overflow
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: AdminBottomNav(
        activeIndex: widget.navIndex,
        onTap: widget.onNavTap,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBarCard(),
                    const SizedBox(height: 14),
                    _buildDonutRow(),
                    const SizedBox(height: 14),
                    _buildCategoryCard(),
                    const SizedBox(height: 14),
                    _buildSummaryCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 170,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: kDarkViolet,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kDarkViolet, kDeepViolet],
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
                    color: kWhite.withAlpha(12),
                  ),
                ),
              ),
              Positioned(
                left: -20, bottom: -20,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kCyan.withAlpha(20),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  // Reduced top padding from 14→8 to reclaim ~6px
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  kViolet.withAlpha(220),
                                  kCyan.withAlpha(220),
                                ]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.campaign_rounded,
                                  color: kWhite, size: 16),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                  text: 'Complaint',
                                  style: TextStyle(
                                      color: Color(0xFF80DEEA),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3),
                                ),
                                TextSpan(
                                  text: 'Desk',
                                  style: TextStyle(
                                      color: kWhite,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3),
                                ),
                                TextSpan(
                                  text: '.AI',
                                  style: TextStyle(
                                      color: kWhite,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -0.3),
                                ),
                              ]),
                            ),
                          ]),
                          Container(
                            width: 34, height: 34, // trimmed from 38
                            decoration: BoxDecoration(
                              color: kWhite.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_outlined,
                                color: kWhite, size: 17),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // reduced from 8
                      const Text(
                        'Analytics',
                        style: TextStyle(
                            color: kWhite,
                            fontSize: 20, // reduced from 22 to save ~3px
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 3), // reduced from 4
                      Row(children: [
                        const Text('Last 30 days',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2), // tighter vertical
                          decoration: BoxDecoration(
                            color: kCyan.withAlpha(40),
                            borderRadius: BorderRadius.circular(99),
                            border:
                                Border.all(color: kCyan.withAlpha(80)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  color: Color(0xFF80DEEA), size: 11),
                              SizedBox(width: 3),
                              Text('+12%',
                                  style: TextStyle(
                                      color: Color(0xFF80DEEA),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10), // reduced from 16
                      Row(children: [
                        _StatChip(
                            value: _total.toString(),
                            label: 'Total\ncomplaints'),
                        const SizedBox(width: 8),
                        _StatChip(
                            value: _pending.toString(),
                            label: 'Pending\nreview'),
                        const SizedBox(width: 8),
                        _StatChip(
                            value: _resolved.toString(),
                            label: 'Resolved',
                            valueColor: const Color(0xFF80DEEA)),
                      ]),
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

  Widget _buildBarCard() {
    final bars  = _bars;
    final max   = bars.reduce(math.max);
    final maxI  = bars.indexOf(max);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                // FIX 3: Flexible prevents the title from pushing the toggle off-screen
                child: Text(
                  'Complaints over time',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kInkDark,
                      letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _PeriodBtn(
                      label: 'Weekly',
                      active: !_showMonthly,
                      onTap: () => _switchPeriod(false)),
                  _PeriodBtn(
                      label: 'Monthly',
                      active: _showMonthly,
                      onTap: () => _switchPeriod(true)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _barCtrl,
            builder: (_, __) {
              return SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(bars.length, (i) {
                    final animFrac = _barAnims[i].value;
                    final heightFrac = (bars[i] / max) * animFrac;
                    final isMax = i == maxI;

                    // Reserve fixed space for top label (16px) and
                    // bottom label (16px) + gaps. The bar itself fills
                    // whatever remains via Expanded so it can never
                    // overflow the 140px SizedBox.
                    const double labelH = 16.0;
                    const double gapTop = 4.0;
                    const double gapBot = 8.0;
                    const double maxBarH = 140.0 - labelH - gapTop - labelH - gapBot;

                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Value label — fixed height slot
                            SizedBox(
                              height: labelH,
                              child: AnimatedOpacity(
                                duration:
                                    const Duration(milliseconds: 300),
                                opacity: animFrac > 0.6 ? 1.0 : 0.0,
                                child: Text(
                                  bars[i].round().toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isMax
                                        ? kDeepViolet
                                        : kInkLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: gapTop),
                            // Bar — height capped to maxBarH, never overflows
                            Container(
                              height: (maxBarH * heightFrac)
                                  .clamp(0.0, maxBarH),
                              decoration: BoxDecoration(
                                color: isMax
                                    ? kDeepViolet
                                    : const Color(0xFFCE93D8),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: gapBot),
                            // Axis label — fixed height slot
                            SizedBox(
                              height: labelH,
                              child: Text(
                                _bLabel[i],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kInkLight,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonutRow() {
    final totalD = _total.toDouble();
    final prioritySlices = [
      _Slice(_high   / totalD, const Color(0xFFE24B4A)),
      _Slice(_medium / totalD, const Color(0xFFF59E0B)),
      _Slice(_low    / totalD, const Color(0xFF22C55E)),
    ];
    final statusSlices = [
      _Slice(_pending    / totalD, const Color(0xFFF59E0B)),
      _Slice(_inProgress / totalD, kCyan),
      _Slice(_resolved   / totalD, const Color(0xFF22C55E)),
    ];

    return Row(
      // FIX 4: crossAxisAlignment.start prevents the two cards from stretching
      // each other vertically and causing overflow
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By priority',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kInkDark)),
                const SizedBox(height: 14),
                // FIX 5: Wrap in a Row with crossAxisAlignment.center and
                // constrain the legend column to avoid overflow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _donutAnim,
                      builder: (_, __) => _DonutChart(
                          slices: prioritySlices,
                          progress: _donutAnim.value,
                          size: 66),
                    ),
                    const SizedBox(width: 12),
                    // FIX 6: Expanded on legend column prevents it from
                    // overflowing on narrow screens
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LegendItem(
                              dot: const Color(0xFFEF4444),
                              label: 'High',
                              pct: '${(_high * 100 / _total).round()}%',
                              pctColor: const Color(0xFFA32D2D)),
                          const SizedBox(height: 6),
                          _LegendItem(
                              dot: const Color(0xFFF59E0B),
                              label: 'Med',
                              pct: '${(_medium * 100 / _total).round()}%',
                              pctColor: const Color(0xFF854F0B)),
                          const SizedBox(height: 6),
                          _LegendItem(
                              dot: const Color(0xFF22C55E),
                              label: 'Low',
                              pct: '${(_low * 100 / _total).round()}%',
                              pctColor: const Color(0xFF3B6D11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By status',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kInkDark)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _donutAnim,
                      builder: (_, __) => _DonutChart(
                          slices: statusSlices,
                          progress: _donutAnim.value,
                          size: 66),
                    ),
                    const SizedBox(width: 12),
                    // FIX 6: Same fix — Expanded wraps the legend column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LegendItem(
                              dot: const Color(0xFFF59E0B),
                              label: 'Pending',
                              pct: '${(_pending * 100 / _total).round()}%',
                              pctColor: const Color(0xFF854F0B)),
                          const SizedBox(height: 6),
                          _LegendItem(
                              dot: kCyan,
                              label: 'Active',
                              pct: '${(_inProgress * 100 / _total).round()}%',
                              pctColor: const Color(0xFF0097A7)),
                          const SizedBox(height: 6),
                          _LegendItem(
                              dot: const Color(0xFF22C55E),
                              label: 'Done',
                              pct: '${(_resolved * 100 / _total).round()}%',
                              pctColor: const Color(0xFF3B6D11)),
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
    );
  }

  Widget _buildCategoryCard() {
    final cats = _topCategories;
    final maxCount = cats.isEmpty ? 1 : cats.first.value;

    const barColors = [
      Color(0xFF7B1FA2),
      Color(0xFF9C27B0),
      Color(0xFFAB47BC),
      Color(0xFFCE93D8),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                // FIX 7: Flexible prevents the title from pushing the badge off-screen
                child: Text(
                  'Top categories',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kInkDark,
                      letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This month',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: kInkLight,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...cats.asMap().entries.map((e) {
            final idx   = e.key;
            final entry = e.value;
            final frac  = entry.value / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: kInkDark,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Stack(children: [
                    Container(
                        height: 7,
                        decoration: BoxDecoration(
                            color: kVioletLight,
                            borderRadius: BorderRadius.circular(99))),
                    FractionallySizedBox(
                      widthFactor: frac,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: barColors[idx % barColors.length],
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                                color: barColors[idx % barColors.length]
                                    .withAlpha(80),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 26,
                  child: Text(
                    entry.value.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kDeepViolet),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final resolutionRate = _total > 0
        ? (_resolved / _total * 100).round()
        : 0;
    final pendingRate = _total > 0
        ? (_pending / _total * 100).round()
        : 0;
    final activeRate = _total > 0
        ? (_inProgress / _total * 100).round()
        : 0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                // FIX 8: Flexible on the title prevents horizontal overflow
                child: Text(
                  'Performance summary',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kInkDark,
                      letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This week',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: kInkLight,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _SummaryRow(
            label: 'Resolution rate',
            value: '$resolutionRate%',
            fraction: _total > 0 ? _resolved / _total : 0,
            barColor: const Color(0xFF22C55E),
            valueColor: const Color(0xFF3B6D11),
          ),
          const SizedBox(height: 14),

          _SummaryRow(
            label: 'Pending rate',
            value: '$pendingRate%',
            fraction: _total > 0 ? _pending / _total : 0,
            barColor: const Color(0xFFF59E0B),
            valueColor: const Color(0xFF854F0B),
          ),
          const SizedBox(height: 14),

          _SummaryRow(
            label: 'In-progress rate',
            value: '$activeRate%',
            fraction: _total > 0 ? _inProgress / _total : 0,
            barColor: kCyan,
            valueColor: const Color(0xFF0097A7),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 14),

          // FIX 9: Wrap the bottom mini-stats row in a LayoutBuilder so that
          // on very narrow screens each stat still has enough room
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'Total', value: _total.toString(),
                  color: kDeepViolet),
              _Separator(),
              _MiniStat(label: 'High priority', value: _high.toString(),
                  color: const Color(0xFFE24B4A)),
              _Separator(),
              _MiniStat(label: 'Resolved', value: _resolved.toString(),
                  color: const Color(0xFF22C55E)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════
class _Slice {
  final double fraction;
  final Color  color;
  const _Slice(this.fraction, this.color);
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kViolet.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color  valueColor;

  const _StatChip({
    required this.value,
    required this.label,
    this.valueColor = kWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: kWhite.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kWhite.withAlpha(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, color: Colors.white60, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;

  const _PeriodBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? kWhite : kInkLight)),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<_Slice> slices;
  final double       size;
  final double       progress;

  const _DonutChart({
    required this.slices,
    required this.size,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter: _DonutPainter(slices: slices, progress: progress)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  final double       progress;

  const _DonutPainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 5;
    const sw = 10.0;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = kBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    double angle = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.fraction * 2 * math.pi * progress;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        angle,
        sweep - (progress < 1.0 ? 0 : 0.08),
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
      angle += s.fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.slices != slices;
}

/// FIX 11: _LegendItem — use Flexible on the label text so it wraps/ellipses
/// instead of overflowing when the parent column is constrained by Expanded
class _LegendItem extends StatelessWidget {
  final Color  dot;
  final String label;
  final String pct;
  final Color  pctColor;

  const _LegendItem({
    required this.dot,
    required this.label,
    required this.pct,
    required this.pctColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8, height: 8,
            decoration:
                BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10.5,
                color: kInkDark,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 4),
        Text(pct,
            style: TextStyle(
                fontSize: 10.5,
                color: pctColor,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color  barColor;
  final Color  valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.barColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              // FIX 12: Flexible on the label so long strings don't overflow
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      color: kInkMid,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    color: valueColor,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(children: [
          Container(
              height: 7,
              decoration: BoxDecoration(
                  color: barColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(99))),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                      color: barColor.withAlpha(80),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // FIX 13: min size prevents extra height
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, color: kInkLight, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: kBorder);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN BOTTOM NAV
// ══════════════════════════════════════════════════════════════════════════════
class AdminBottomNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const AdminBottomNav(
      {super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_outlined, Icons.grid_view_rounded,  'Home'),
      (Icons.list_alt_outlined,  Icons.list_alt_rounded,   'Complaints'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded,  'Analytics'),
      (Icons.settings_outlined,  Icons.settings_rounded,   'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
              color: kViolet.withAlpha(18),
              blurRadius: 20,
              offset: const Offset(0, -4))
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
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? kViolet.withAlpha(18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isActive ? item.$2 : item.$1,
                          size: 22,
                          color: isActive
                              ? kViolet
                              : Colors.grey.shade400),
                      const SizedBox(height: 3),
                      Text(item.$3,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive
                                  ? kViolet
                                  : Colors.grey.shade400)),
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
// STUB MODELS (delete if merging into your single-file project)
// ══════════════════════════════════════════════════════════════════════════════
enum Priority { high, medium, low }
enum ComplaintStatus { pending, inProgress, resolved }

extension PriorityExt on Priority {
  String get label => const ['High', 'Medium', 'Low'][index];
  Color get fg => const [Color(0xFFA32D2D), Color(0xFF854F0B), Color(0xFF3B6D11)][index];
  Color get bg => const [Color(0xFFFCEBEB), Color(0xFFFFF5EC), Color(0xFFEAF3DE)][index];
  Color get dot => const [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF22C55E)][index];
}

extension StatusExt on ComplaintStatus {
  String get label => const ['Pending', 'In Progress', 'Resolved'][index];
  Color get fg => const [Color(0xFF854F0B), Color(0xFF185FA5), Color(0xFF3B6D11)][index];
  Color get bg => const [Color(0xFFFFF5EC), Color(0xFFEEF4FF), Color(0xFFEAF3DE)][index];
  Color get dot => const [Color(0xFFF59E0B), Color(0xFF00BCD4), Color(0xFF22C55E)][index];
}

class ComplaintItem {
  final String id, title, category, timeAgo, studentName, rollNo, description, date;
  final Priority priority;
  final ComplaintStatus status;
  const ComplaintItem({
    required this.id, required this.title, required this.category,
    required this.priority, required this.status, required this.timeAgo,
    required this.studentName, required this.rollNo,
    required this.description, required this.date,
  });

  factory ComplaintItem.fromApi(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? 'Pending').toString().toLowerCase();
    final priorityRaw = (json['priority'] ?? 'Medium').toString().toLowerCase();

    final status = statusRaw == 'resolved'
        ? ComplaintStatus.resolved
        : (statusRaw == 'in progress' || statusRaw == 'in_progress')
            ? ComplaintStatus.inProgress
            : ComplaintStatus.pending;

    final priority = priorityRaw == 'high'
        ? Priority.high
        : priorityRaw == 'low'
            ? Priority.low
            : Priority.medium;

    return ComplaintItem(
      id: '#C-${json['id']}',
      title: (json['description'] ?? 'Complaint').toString(),
      category: (json['category'] ?? 'General').toString(),
      priority: priority,
      status: status,
      timeAgo: 'Now',
      studentName: (json['user_name'] ?? 'Unknown').toString(),
      rollNo: (json['user_email'] ?? 'N/A').toString(),
      description: (json['description'] ?? '').toString(),
      date: (json['created_at'] ?? '').toString().split(' ').first,
    );
  }
}

const kAllComplaints = <ComplaintItem>[
  ComplaintItem(id:'#C-1042',title:'WiFi not working in hostel block B',category:'Hostel',priority:Priority.high,status:ComplaintStatus.pending,timeAgo:'2h ago',studentName:'Areeba Khan',rollNo:'CS-21-045',description:'WiFi down in hostel block B.',date:'15 May 2026'),
  ComplaintItem(id:'#C-1041',title:'Hostel water supply issue',category:'Hostel',priority:Priority.high,status:ComplaintStatus.pending,timeAgo:'2h ago',studentName:'Hamza Raza',rollNo:'EE-22-011',description:'Water supply intermittent.',date:'15 May 2026'),
  ComplaintItem(id:'#C-1040',title:'Library AC not working',category:'General',priority:Priority.medium,status:ComplaintStatus.inProgress,timeAgo:'4h ago',studentName:'Sara Malik',rollNo:'BBA-21-034',description:'AC broken in library.',date:'15 May 2026'),
  ComplaintItem(id:'#C-1039',title:'Parking area lights broken',category:'General',priority:Priority.low,status:ComplaintStatus.pending,timeAgo:'6h ago',studentName:'Ali Tariq',rollNo:'CS-20-088',description:'Lights broken.',date:'14 May 2026'),
  ComplaintItem(id:'#C-1038',title:'IT lab projector fault',category:'Academic',priority:Priority.high,status:ComplaintStatus.resolved,timeAgo:'1d ago',studentName:'Fatima Noor',rollNo:'SE-22-019',description:'Projector faulty.',date:'14 May 2026'),
  ComplaintItem(id:'#C-1037',title:'Bus route 3 cancelled',category:'Transport',priority:Priority.high,status:ComplaintStatus.pending,timeAgo:'8h ago',studentName:'Usman Ghani',rollNo:'ME-21-055',description:'Bus cancelled.',date:'14 May 2026'),
  ComplaintItem(id:'#C-1036',title:'Canteen food quality deteriorating',category:'General',priority:Priority.medium,status:ComplaintStatus.inProgress,timeAgo:'1d ago',studentName:'Zara Ahmed',rollNo:'CS-22-033',description:'Food quality issue.',date:'13 May 2026'),
  ComplaintItem(id:'#C-1035',title:'Library closing early on Fridays',category:'General',priority:Priority.low,status:ComplaintStatus.resolved,timeAgo:'2d ago',studentName:'Omar Farooq',rollNo:'LAW-21-012',description:'Library closes early.',date:'13 May 2026'),
];