// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// ── Theme constants (matches ComplaintsScreen / HomeScreen) ───────────────────
const Color _primary = Color.fromRGBO(156, 39, 176, 1);  // purple
const Color _accent  = Color.fromRGBO(0, 188, 212, 1);   // cyan
const Color _surface = Color(0xFFF7F7FB);
const Color _cardBg  = Colors.white;

class TrackComplaintsScreen extends StatefulWidget {
  final String userId;

  const TrackComplaintsScreen({super.key, required this.userId});

  @override
  State<TrackComplaintsScreen> createState() => _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen>
    with SingleTickerProviderStateMixin {
  int total = 0;
  int pending = 0;
  int inProgress = 0;
  int resolved = 0;
  bool isLoading = true;

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
    fetchComplaintStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── BACKEND LOGIC — UNTOUCHED ─────────────────────────────────────────────

  Future<void> fetchComplaintStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List complaints = jsonDecode(response.body);

        setState(() {
          total = complaints.length;
          pending = complaints.where((c) =>
              c['status'] == 'New' || c['status'] == 'Pending').length;
          inProgress =
              complaints.where((c) => c['status'] == 'In-Progress').length;
          resolved =
              complaints.where((c) => c['status'] == 'Resolved').length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        _controller.forward(from: 0.0);
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                      color: _primary,
                      onRefresh: () async {
                        setState(() => isLoading = true);
                        await fetchComplaintStats();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBanner(),
                            const SizedBox(height: 28),
                            _buildSectionLabel('STATISTICS'),
                            const SizedBox(height: 14),
                            _buildProgressCard(),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    count: pending.toString(),
                                    title: 'Pending',
                                    subtitle: 'Awaiting action',
                                    color: const Color(0xFFE67E22),
                                    icon: Icons.hourglass_top_rounded,
                                    value: total == 0 ? 0 : pending / total,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildStatCard(
                                    count: inProgress.toString(),
                                    title: 'In Progress',
                                    subtitle: 'Under review',
                                    color: const Color(0xFF2979FF),
                                    icon: Icons.sync_rounded,
                                    value: total == 0 ? 0 : inProgress / total,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildResolvedBanner(),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                    ),
            ),
          ],
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
                    builder: (_) => ComplaintsScreen(userId: widget.userId),
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
              // Title
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Complaints',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Monitor your complaint status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9090A0),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Refresh button
              GestureDetector(
                onTap: () async {
                  setState(() => isLoading = true);
                  await fetchComplaintStats();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _primary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color.fromRGBO(123, 82, 232, 1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bar_chart_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'OVERVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Complaints',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Decorative circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    final double pendingPct  = total == 0 ? 0 : pending / total;
    final double progressPct = total == 0 ? 0 : inProgress / total;
    final double resolvedPct = total == 0 ? 0 : resolved / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
          const Text(
            'Complaint Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow(
            label: 'Pending',
            count: pending,
            percentage: pendingPct,
            color: const Color(0xFFE67E22),
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            label: 'In Progress',
            count: inProgress,
            percentage: progressPct,
            color: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            label: 'Resolved',
            count: resolved,
            percentage: resolvedPct,
            color: const Color(0xFF0BAB64),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int count,
    required double percentage,
    required Color color,
  }) {
    final pct = (percentage * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A5A),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($pct%)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFB0B0C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String count,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    double value = 0,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          // Count
          Text(
            count,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9090A0),
            ),
          ),
          const SizedBox(height: 12),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resolved Banner ───────────────────────────────────────────────────────

  Widget _buildResolvedBanner() {
    final resolvedPct = total == 0 ? 0 : ((resolved / total) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0BAB64), Color(0xFF3DCC91)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resolved',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Successfully closed complaints',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF9090A0),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resolved.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0BAB64),
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              Text(
                '$resolvedPct% of total',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFB0B0C0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Loading State ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 14),
          Text(
            'Loading statistics…',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF9090A0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      _NavData('Home', Icons.home_outlined, Icons.home_rounded),
      _NavData('Complaints', Icons.chat_bubble_outline_rounded,
          Icons.chat_bubble_rounded),
      _NavData('Track', Icons.track_changes_outlined,
          Icons.track_changes_rounded),
      _NavData('Profile', Icons.person_outline_rounded,
          Icons.person_rounded),
    ];

    const activeIndex = 2;

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
            final isActive = i == activeIndex;
            final item = items[i];

            void onTap() {
              if (i == 0) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: widget.userId)));
              } else if (i == 1) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ComplaintsScreen(userId: widget.userId)));
              } else if (i == 2) {
                // already here
              } else if (i == 3) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(userId: widget.userId)));
              }
            }

            return GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? _primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 22,
                      color: isActive ? _primary : const Color(0xFFAAAAAC),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? _primary
                            : const Color(0xFFAAAAAC),
                        letterSpacing: 0.3,
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

// ── Nav Data ──────────────────────────────────────────────────────────────────

class _NavData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavData(this.label, this.icon, this.activeIcon);
}