// ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

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

  // Bar colors — distinct palette, one per bar
  static const _barColors = [
    Color(0xFF7C3AED), // violet
    Color(0xFF2563EB), // blue
    Color(0xFF059669), // green
    Color(0xFFD97706), // amber
  ];

  // ── Weekly: last 4 weeks ──────────────────────────────────────────────────
  List<double> get _weeklyBars {
    final now = DateTime.now();
    final buckets = List<double>.filled(4, 0);
    bool anyParsed = false;
    for (final c in _allComplaints) {
      final parsed = _parseDate(c.date);
      if (parsed == null) continue;
      anyParsed = true;
      final diffDays = now.difference(parsed).inDays.abs();
      if (diffDays < 7) {
        buckets[3]++;
      // ignore: curly_braces_in_flow_control_structures
      } else if (diffDays < 14) buckets[2]++;
      else if (diffDays < 21) buckets[1]++;
      else if (diffDays < 28) buckets[0]++;
    }
    if (!anyParsed) {
      // Fallback demo data for weekly
      return [3.0, 5.0, 4.0, 6.0];
    }
    return buckets;
  }

  // ── Monthly: May, Jun, Jul, Aug ──────────────────────────────────────────
  // Fixed to always show May–Aug regardless of current date
  static const _fixedMonthlyTargets = [
    (2026, 5),  // May
    (2026, 6),  // Jun
    (2026, 7),  // Jul
    (2026, 8),  // Aug
  ];

  List<double> get _monthlyBars {
    final buckets = List<double>.filled(4, 0);
    bool anyParsed = false;
    for (final c in _allComplaints) {
      final parsed = _parseDate(c.date);
      if (parsed == null) continue;
      anyParsed = true;
      for (int i = 0; i < 4; i++) {
        if (parsed.year == _fixedMonthlyTargets[i].$1 &&
            parsed.month == _fixedMonthlyTargets[i].$2) {
          buckets[i]++;
          break;
        }
      }
    }
    if (!anyParsed) {
      // Fallback demo data for May–Aug
      return [12.0, 18.0, 15.0, 22.0];
    }
    // If parsed but all zeros, use sensible demo fallback
    final hasData = buckets.any((b) => b > 0);
    if (!hasData) return [12.0, 18.0, 15.0, 22.0];
    return buckets;
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw.trim());
    if (iso != null) return iso;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final parts = raw.trim().split(RegExp(r'[\s]+'));
    if (parts.length == 3) {
      final monthStr = parts[1].toLowerCase();
      if (monthStr.length < 3) return null;
      final m    = months[monthStr.substring(0, 3)];
      final day  = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);
      if (m != null && day != null && year != null) return DateTime(year, m, day);
    }
    return null;
  }

  List<String> get _weeklyLabels => ['W1', 'W2', 'W3', 'W4'];
  List<String> get _monthlyLabels => ['May', 'Jun', 'Jul', 'Aug'];

  List<double>  get _bars   => _showMonthly ? _monthlyBars : _weeklyBars;
  List<String>  get _bLabel => _showMonthly ? _monthlyLabels : _weeklyLabels;

  // Category colors
  static const _catColors = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  late AnimationController _barCtrl;
  late List<Animation<double>> _barAnims;

  late AnimationController _pieCtrl;
  late Animation<double>   _pieAnim;

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

    _pieCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _pieAnim = CurvedAnimation(parent: _pieCtrl, curve: Curves.easeInOut);

    _entryCtrl.forward();
    _fetchComplaints();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _barCtrl.forward();
        _pieCtrl.forward();
      }
    });
  }

  void _buildBarAnims() {
    _barAnims = List.generate(4, (i) {
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

  Future<void> _fetchComplaints() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/complaints'));
      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((e) => ComplaintItem.fromApi(e as Map<String, dynamic>))
            .toList();
        setState(() { _allComplaints = data; _loading = false; });
      } else if (mounted) {
        setState(() { _allComplaints = kAllComplaints; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _allComplaints = kAllComplaints; _loading = false; });
    }
  }

  List<MapEntry<String, int>> get _topCategories {
    final entries = _categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(6).toList();
  }

  void _switchPeriod(bool monthly) {
    setState(() => _showMonthly = monthly);
    _barCtrl..reset()..forward();
    _buildBarAnims();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _barCtrl.dispose();
    _pieCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kViolet))
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
                          _buildPieRow(),
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

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    // months list removed because it's unused
    const rangeLabel = 'May – Aug 2026';
    final resRate = _total > 0 ? (_resolved / _total * 100).round() : 0;

    return SliverAppBar(
      expandedHeight: 160,
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
              Positioned(right: -30, top: -30,
                child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: kWhite.withAlpha(12)))),
              Positioned(left: -20, bottom: -20,
                child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: kCyan.withAlpha(20)))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Analytics',
                              style: TextStyle(color: kWhite, fontSize: 22,
                                  fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kCyan.withAlpha(40),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: kCyan.withAlpha(80)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: Color(0xFF80DEEA), size: 12),
                              const SizedBox(width: 4),
                              Text('$resRate% resolved',
                                  style: const TextStyle(color: Color(0xFF80DEEA),
                                      fontSize: 11, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(rangeLabel,
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _StatChip(value: _total.toString(), label: 'Total\ncomplaints'),
                        const SizedBox(width: 8),
                        _StatChip(value: _inProgress.toString(), label: 'In\nProgress',
                            valueColor: const Color(0xFF80DEEA)),
                        const SizedBox(width: 8),
                        _StatChip(value: _resolved.toString(), label: 'Resolved',
                            valueColor: const Color(0xFF86EFAC)),
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

  // ── Bar chart — multi-color, proper grouped bars ──────────────────────────
  Widget _buildBarCard() {
    final bars   = _bars;
    final labels = _bLabel;
    final maxVal = bars.reduce(math.max);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    // Y-axis grid lines: 0, 25%, 50%, 75%, 100% of max
    const gridCount = 4;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Complaints over time',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: kInkDark, letterSpacing: -0.2),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _PeriodBtn(label: 'Weekly',  active: !_showMonthly, onTap: () => _switchPeriod(false)),
                  _PeriodBtn(label: 'Monthly', active: _showMonthly,  onTap: () => _switchPeriod(true)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _barCtrl,
            builder: (_, __) {
              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Y-axis labels
                    SizedBox(
                      width: 28,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(gridCount + 1, (i) {
                          final val = (safeMax * (gridCount - i) / gridCount).round();
                          return Text('$val',
                              style: const TextStyle(fontSize: 9, color: kInkLight));
                        }),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Chart area
                    Expanded(
                      child: CustomPaint(
                        painter: _GridPainter(gridCount: gridCount),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(bars.length, (i) {
                              final animFrac   = _barAnims[i].value;
                              final heightFrac = (bars[i] / safeMax) * animFrac;
                              final barColor   = _barColors[i % _barColors.length];

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Value label on top of bar
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 300),
                                        opacity: animFrac > 0.6 ? 1.0 : 0.0,
                                        child: Text(
                                          bars[i].round().toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: barColor),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Bar body
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft:  Radius.circular(7),
                                          topRight: Radius.circular(7),
                                        ),
                                        child: Container(
                                          height: (130 * heightFrac).clamp(4.0, 130.0),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                barColor.withAlpha(170),
                                                barColor,
                                              ],
                                            ),
                                          ),
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
                    ),
                  ],
                ),
              );
            },
          ),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: List.generate(bars.length, (i) {
                final barColor = _barColors[i % _barColors.length];
                return Expanded(
                  child: Center(
                    child: Text(labels[i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: barColor)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: List.generate(labels.length, (i) {
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _barColors[i % _barColors.length],
                      borderRadius: BorderRadius.circular(3),
                    )),
                const SizedBox(width: 5),
                Text(labels[i],
                    style: const TextStyle(fontSize: 10.5, color: kInkMid,
                        fontWeight: FontWeight.w500)),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  // ── Pie chart row — SOLID filled, no donut hole ────────────────────────────
  Widget _buildPieRow() {
    final totalD = _total > 0 ? _total.toDouble() : 1.0;

    // Priority slices
    final prioritySlices = [
      _PieSlice(_high   / totalD, const Color(0xFFEF4444), 'High',   _high),
      _PieSlice(_medium / totalD, const Color(0xFFF59E0B), 'Medium', _medium),
      _PieSlice(_low    / totalD, const Color(0xFF22C55E), 'Low',    _low),
    ];

    // Status slices
    final statusSlices = [
      _PieSlice(_pending    / totalD, const Color(0xFFF59E0B), 'Pending',     _pending),
      _PieSlice(_inProgress / totalD, const Color(0xFF2563EB), 'In Progress', _inProgress),
      _PieSlice(_resolved   / totalD, const Color(0xFF22C55E), 'Resolved',    _resolved),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By priority',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: kInkDark)),
                const SizedBox(height: 2),
                Text('$_total total',
                    style: const TextStyle(fontSize: 10, color: kInkLight)),
                const SizedBox(height: 14),
                Center(
                  child: AnimatedBuilder(
                    animation: _pieAnim,
                    builder: (_, __) => _SolidPieChart(
                      slices: prioritySlices,
                      progress: _pieAnim.value,
                      size: 110,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...prioritySlices.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PieLegendRow(slice: s, total: _total),
                )),
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: kInkDark)),
                const SizedBox(height: 2),
                Text('$_total total',
                    style: const TextStyle(fontSize: 10, color: kInkLight)),
                const SizedBox(height: 14),
                Center(
                  child: AnimatedBuilder(
                    animation: _pieAnim,
                    builder: (_, __) => _SolidPieChart(
                      slices: statusSlices,
                      progress: _pieAnim.value,
                      size: 110,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...statusSlices.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PieLegendRow(slice: s, total: _total),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Category card ──────────────────────────────────────────────────────────
  Widget _buildCategoryCard() {
    final cats     = _topCategories;
    final maxCount = cats.isEmpty ? 1 : cats.first.value;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Top categories',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: kInkDark, letterSpacing: -0.2),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kSurface,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${cats.length} categories',
                    style: const TextStyle(fontSize: 10.5, color: kInkLight,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (cats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No data yet',
                    style: TextStyle(color: kInkLight, fontSize: 12)),
              ),
            )
          else
            ...cats.asMap().entries.map((e) {
              final idx   = e.key;
              final entry = e.value;
              final frac  = entry.value / maxCount;
              final pct   = _total > 0 ? (entry.value * 100 / _total).round() : 0;
              final color = _catColors[idx % _catColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(children: [
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 78,
                    child: Text(entry.key,
                        style: const TextStyle(fontSize: 12.5, color: kInkDark,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Stack(children: [
                      Container(height: 7,
                          decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(99))),
                      FractionallySizedBox(
                        widthFactor: frac.clamp(0.0, 1.0),
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(color: color.withAlpha(80),
                                  blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text('${entry.value} ($pct%)',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.bold, color: color)),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }

  // ── Performance summary ────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final resolutionRate = _total > 0 ? _resolved    / _total : 0.0;
    final pendingRate    = _total > 0 ? _pending     / _total : 0.0;
    final activeRate     = _total > 0 ? _inProgress  / _total : 0.0;

    final resPct  = (resolutionRate * 100).round();
    final pendPct = (pendingRate    * 100).round();
    final actPct  = (activeRate     * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Performance summary',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: kInkDark, letterSpacing: -0.2),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kSurface,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('All time',
                    style: TextStyle(fontSize: 10.5, color: kInkLight,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Resolution rate', value: '$resPct%',
              fraction: resolutionRate.clamp(0.0, 1.0),
              barColor: const Color(0xFF22C55E), valueColor: const Color(0xFF3B6D11)),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Pending rate', value: '$pendPct%',
              fraction: pendingRate.clamp(0.0, 1.0),
              barColor: const Color(0xFFF59E0B), valueColor: const Color(0xFF854F0B)),
          const SizedBox(height: 14),
          _SummaryRow(label: 'In-progress rate', value: '$actPct%',
              fraction: activeRate.clamp(0.0, 1.0),
              barColor: const Color(0xFF2563EB), valueColor: const Color(0xFF1D4ED8)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GRID PAINTER — horizontal lines behind bar chart
// ══════════════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final int gridCount;
  const _GridPainter({required this.gridCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBorder
      ..strokeWidth = 0.8;

    final chartH = size.height - 24; // subtract x-label area
    for (int i = 0; i <= gridCount; i++) {
      final y = chartH * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// SOLID PIE CHART — filled slices, no donut hole, with gap between slices
// ══════════════════════════════════════════════════════════════════════════════
class _PieSlice {
  final double fraction;
  final Color  color;
  final String label;
  final int    count;
  const _PieSlice(this.fraction, this.color, this.label, this.count);
}

class _SolidPieChart extends StatelessWidget {
  final List<_PieSlice> slices;
  final double          progress;
  final double          size;

  const _SolidPieChart({
    required this.slices,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SolidPiePainter(slices: slices, progress: progress),
      ),
    );
  }
}

class _SolidPiePainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double          progress;

  const _SolidPiePainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 2;

    final total = slices.fold(0.0, (s, e) => s + e.fraction);
    if (total <= 0) {
      // Draw empty grey circle
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = kBorder..style = PaintingStyle.fill);
      return;
    }

    // Draw a thin white background circle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = kBorder..style = PaintingStyle.fill);

    double angle = -math.pi / 2; // start at top
    const gapAngle = 0.035; // small gap in radians between slices

    for (final s in slices) {
      if (s.fraction <= 0) continue;
      final sweep = (s.fraction / total) * 2 * math.pi * progress - gapAngle;
      if (sweep <= 0) {
        angle += (s.fraction / total) * 2 * math.pi * progress;
        continue;
      }

      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          angle,
          sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Thin white border for crispness
      final borderPaint = Paint()
        ..color = kWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      angle += (s.fraction / total) * 2 * math.pi * progress;
    }
  }

  @override
  bool shouldRepaint(_SolidPiePainter old) =>
      old.progress != progress || old.slices != slices;
}

class _PieLegendRow extends StatelessWidget {
  final _PieSlice slice;
  final int       total;

  const _PieLegendRow({required this.slice, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (slice.count * 100 / total).round() : 0;
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(slice.label,
          style: const TextStyle(fontSize: 11.5, color: kInkMid,
              fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis)),
      Text('${slice.count}',
          style: const TextStyle(fontSize: 11.5, color: kInkDark,
              fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: slice.color.withAlpha(22),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$pct%',
            style: TextStyle(fontSize: 9.5, color: slice.color,
                fontWeight: FontWeight.w700)),
      ),
    ]);
  }
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
        boxShadow: [BoxShadow(color: kViolet.withAlpha(12),
            blurRadius: 16, offset: const Offset(0, 5))],
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
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: kWhite.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kWhite.withAlpha(30)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                  color: valueColor, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.white60, height: 1.2)),
        ]),
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;

  const _PeriodBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? kWhite : kInkLight)),
      ),
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
    required this.label, required this.value,
    required this.fraction, required this.barColor, required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: kInkMid,
                fontWeight: FontWeight.w500))),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor,
            fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(height: 7,
            decoration: BoxDecoration(color: barColor.withAlpha(28),
                borderRadius: BorderRadius.circular(99))),
        FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [BoxShadow(color: barColor.withAlpha(80),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN BOTTOM NAV
// ══════════════════════════════════════════════════════════════════════════════
class AdminBottomNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const AdminBottomNav({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_outlined, Icons.grid_view_rounded,  'Home'),
      (Icons.list_alt_outlined,  Icons.list_alt_rounded,   'Complaints'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded,  'Analytics'),
      (Icons.settings_outlined,  Icons.settings_rounded,   'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(color: kWhite,
        boxShadow: [BoxShadow(color: kViolet.withAlpha(18),
            blurRadius: 20, offset: const Offset(0, -4))]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? kViolet.withAlpha(18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isActive ? item.$2 : item.$1, size: 22,
                        color: isActive ? kViolet : Colors.grey.shade400),
                    const SizedBox(height: 3),
                    Text(item.$3,
                        style: TextStyle(fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive ? kViolet : Colors.grey.shade400)),
                  ]),
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
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════
enum Priority { high, medium, low }
enum ComplaintStatus { pending, inProgress, resolved }

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
    final statusRaw   = (json['status']   ?? 'Pending').toString().toLowerCase();
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
      id:          '#C-${json['id']}',
      title:       (json['description'] ?? 'Complaint').toString(),
      category:    (json['category']    ?? 'General').toString(),
      priority:    priority,
      status:      status,
      timeAgo:     'Now',
      studentName: (json['user_name']   ?? 'Unknown').toString(),
      rollNo:      (json['user_email']  ?? 'N/A').toString(),
      description: (json['description'] ?? '').toString(),
      date:        (json['created_at']  ?? '').toString().split(' ').first,
    );
  }
}

const kAllComplaints = <ComplaintItem>[
];