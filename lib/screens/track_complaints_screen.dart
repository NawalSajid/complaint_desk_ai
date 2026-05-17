// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// ── Theme constants ───────────────────────────────────────────────────────────
const Color _primary  = Color.fromRGBO(156, 39, 176, 1);
const Color _accent   = Color.fromRGBO(0, 188, 212, 1);
const Color _gradMid  = Color(0xFF5C6BC0);
const Color _surface  = Color(0xFFF7F7FB);
const Color _cardBg   = Colors.white;

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

class TrackComplaintsScreen extends StatefulWidget {
  final String userId;

  const TrackComplaintsScreen({super.key, required this.userId});

  @override
  State<TrackComplaintsScreen> createState() => _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen>
    with SingleTickerProviderStateMixin {
  int total      = 0;
  int pending    = 0;
  int inProgress = 0;
  int resolved   = 0;
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double>   _fadeAnim;

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
          total      = complaints.length;
          pending    = complaints.where((c) =>
              c['status'] == 'New' || c['status'] == 'Pending').length;
          inProgress = complaints.where((c) =>
              c['status'] == 'In-Progress' ||
              c['status'] == 'In Progress'  ||
              c['status'] == 'in_progress').length;
          resolved   = complaints.where((c) => c['status'] == 'Resolved').length;
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
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1)),
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
                      'Track Complaints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const Text(
                    'Monitor your complaint status',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9090A0)),
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
                  child: const Icon(Icons.refresh_rounded, size: 18, color: _primary),
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

  // ── Banner (purple → cyan gradient) ───────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _gradMid, _accent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bar_chart_rounded, color: Colors.white, size: 13),
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
              // Icon badge
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
    required int    count,
    required double percentage,
    required Color  color,
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
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    required String  count,
    required String  title,
    required String  subtitle,
    required Color   color,
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
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9090A0)),
          ),
          const SizedBox(height: 12),
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
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Resolved',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Successfully closed complaints',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9090A0)),
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
          const CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
          const SizedBox(height: 14),
          const Text(
            'Loading statistics…',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9090A0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    const activeIndex = 2;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        borderRadius: BorderRadius.all(Radius.circular(14))),
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
}

// ── Nav Data ──────────────────────────────────────────────────────────────────

class _NavData {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  const _NavData(this.label, this.icon, this.activeIcon);
}