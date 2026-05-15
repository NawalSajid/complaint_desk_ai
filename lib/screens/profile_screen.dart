// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:complaint_desk_ai/screens/login_screen.dart';
import 'package:complaint_desk_ai/screens/rolebased_screen.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../constants.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────

const Color _gradA   = Color(0xFF9C27B0);
const Color _gradB   = Color(0xFF00BCD4);
const Color _gradMid = Color(0xFF5C6BC0);

const Color _bg      = Color(0xFFF5F4FA);
const Color _card    = Colors.white;
const Color _surface = Color(0xFFF0EEF9);

const Color _inkDark  = Color(0xFF110E24);
const Color _inkMid   = Color(0xFF5A5878);
const Color _inkLight = Color(0xFFABABCC);
const Color _border   = Color(0xFFEAE8F5);

const Color _green  = Color(0xFF00C47D);
const Color _red    = Color(0xFFE53935);

const LinearGradient _grad = LinearGradient(
  colors: [_gradA, _gradMid, _gradB],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Nav Tab ───────────────────────────────────────────────────────────────────

class _NavTab {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  const _NavTab(this.label, this.icon, this.activeIcon);
}

// ── Gradient mask helper ──────────────────────────────────────────────────────

Widget _gradMask({required Widget child}) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => _grad.createShader(b),
      child: child,
    );

Widget _gradLine({double width = double.infinity, double height = 2}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(height),
      ),
    );

// ── Styled TextField ──────────────────────────────────────────────────────────

Widget _styledTextField({
  required TextEditingController controller,
  required String hint,
  required Color focusColor,
  int maxLines = 1,
  IconData? prefixIcon,
}) {
  final br = BorderRadius.circular(14);
  return TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 15, color: _inkDark, fontWeight: FontWeight.w500),
    cursorColor: _gradA,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _inkLight, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _gradA, size: 19) : null,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      border: OutlineInputBorder(borderRadius: br, borderSide: const BorderSide(color: _border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: br, borderSide: const BorderSide(color: _border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: focusColor, width: 2)),
    ),
  );
}

// ── Gradient Button ───────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ac.forward(),
      onTapUp: (_) { _ac.reverse(); widget.onTap(); },
      onTapCancel: () => _ac.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _gradA.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      ),
    );
  }
}

// ── Dialog Shell ──────────────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final IconData headerIcon;
  final Color    headerColor;
  final String   title;
  final String?  subtitle;
  final Widget   body;
  final Widget   actions;

  const _DialogShell({
    required this.headerIcon,
    required this.headerColor,
    required this.title,
    this.subtitle,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: _card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, decoration: BoxDecoration(gradient: _grad, borderRadius: const BorderRadius.vertical(top: Radius.circular(22)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: headerColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(13)),
                    child: Icon(headerIcon, color: headerColor, size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _inkDark, letterSpacing: -0.3)),
                    if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: const TextStyle(fontSize: 12, color: _inkMid))],
                  ])),
                ]),
                const SizedBox(height: 18),
                const Divider(color: _border, height: 1),
                const SizedBox(height: 18),
                body,
                const SizedBox(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [actions]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int    total     = 0;
  int    resolved  = 0;
  bool   isLoading = true;
  String name      = '';

  late AnimationController _controller;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fadeIn  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    fetchProfile();
    fetchComplaints();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  // ── BACKEND — UNTOUCHED ───────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users/${widget.userId}'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() => name = data['name'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'));
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> complaints = jsonDecode(response.body);
        setState(() {
          total    = complaints.length;
          resolved = complaints.where((c) => c['status'] == 'Resolved').length;
          isLoading = false;
        });
        _controller.forward(from: 0.0);
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
        _controller.forward(from: 0.0);
      }
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(success ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 15)),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
      ]),
      backgroundColor: success ? _green : _red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _editProfile() {
    final ctrl = TextEditingController(text: name);
    showDialog(context: context, builder: (_) => _DialogShell(
      headerIcon: Icons.person_outline_rounded, headerColor: _gradA,
      title: 'Edit Profile', subtitle: 'Update your display name',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FULL NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _inkLight, letterSpacing: 1.8)),
        const SizedBox(height: 10),
        _styledTextField(controller: ctrl, hint: 'Enter your full name', focusColor: _gradA, prefixIcon: Icons.person_outline_rounded),
      ]),
      actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: _inkMid),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        _GradientButton(label: 'Save Changes', onTap: () async {
          final newName = ctrl.text.trim();
          if (newName.isEmpty) return;
          setState(() => name = newName);
          try {
            final response = await http.put(Uri.parse('$baseUrl/api/users/${widget.userId}'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': newName}));
            _showSnackBar(response.statusCode == 200 ? 'Name updated successfully' : 'Failed to update name', success: response.statusCode == 200);
          } catch (_) { _showSnackBar('Error connecting to server', success: false); }
          if (mounted) Navigator.pop(context);
        }),
      ]),
    ));
  }

  void _feedbackDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => _DialogShell(
      headerIcon: Icons.rate_review_outlined, headerColor: _gradB,
      title: 'Send Feedback', subtitle: 'We read every message — thank you',
      body: _styledTextField(controller: ctrl, hint: 'Share your thoughts or suggestions…', focusColor: _gradB, maxLines: 5),
      actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: _inkMid),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        _GradientButton(label: 'Submit', onTap: () { Navigator.pop(context); _showSnackBar('Thank you for your feedback!'); }),
      ]),
    ));
  }

  void _helpAndSupport() {
    final faqs = <(String, String)>[
      ('How do I submit a complaint?', 'Go to Complaints, choose a category, describe your issue, attach documents (optional), and submit.'),
      ('How do I track my complaint?', 'Use the Track screen to monitor real-time status updates on your submissions.'),
      ('What do the statuses mean?', 'Pending: awaiting review. In-Progress: being addressed. Resolved: closed.'),
      ('Can I update my personal info?', 'Yes — tap "Edit Profile" in Account Settings to change your name.'),
      ('Who handles urgent issues?', 'Contact the designated support email or your department administration.'),
    ];
    showDialog(context: context, builder: (_) => _DialogShell(
      headerIcon: Icons.help_outline_rounded, headerColor: _gradMid,
      title: 'Help & Support', subtitle: 'Frequently asked questions',
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: faqs.map((f) => _faqItem(f.$1, f.$2)).toList())),
      ),
      actions: _GradientButton(label: 'Got it', onTap: () => Navigator.pop(context)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: isLoading ? _buildLoader() : _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildLoader() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 36, height: 36,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation(_gradA),
          backgroundColor: _inkLight.withValues(alpha: 0.15),
          strokeWidth: 2.5,
        ),
      ),
      const SizedBox(height: 16),
      const Text('Loading profile…', style: TextStyle(color: _inkMid, fontSize: 13.5, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 44),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('ACCOUNT SETTINGS'),
                  const SizedBox(height: 14),
                  _buildSettingsCard(),
                  const SizedBox(height: 28),
                  _buildLogoutButton(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Header — full-bleed gradient card ────────────────────────────────

  Widget _buildHeroHeader() {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-bleed gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1280), Color(0xFF4A3BAA), Color(0xFF007D90)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App bar row ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Row(children: [
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      _editChip(),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Avatar + info ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatar(initials),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 6,
                                children: [
                                  _infoBadge(Icons.badge_outlined, 'ID · ${widget.userId}'),
                                  _infoBadge(Icons.school_rounded, 'Student'),
                                  _infoBadgeGreen(Icons.verified_rounded, 'Verified'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Bottom wave cutout ─────────────────────────────────
                  SizedBox(
                    height: 28,
                    child: CustomPaint(
                      size: const Size(double.infinity, 28),
                      painter: _WavePainter(color: _bg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Stack(clipBehavior: Clip.none, children: [
      // Outer glow ring
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ),
      // Online dot
      Positioned(
        bottom: 2,
        right: 2,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _green,
            border: Border.all(color: const Color(0xFF6A1280), width: 2),
          ),
        ),
      ),
    ]);
  }

  Widget _editChip() => GestureDetector(
    onTap: _editProfile,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.edit_outlined, color: Colors.white, size: 13),
        SizedBox(width: 6),
        Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _infoBadge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 11),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _infoBadgeGreen(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _green.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _green.withValues(alpha: 0.55), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _green, size: 11),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final pending = total - resolved;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        _statCard('$total',    'Total',    Icons.inbox_rounded,            const Color(0xFF9C27B0), const Color(0xFF6A1280)),
        const SizedBox(width: 12),
        _statCard('$resolved', 'Resolved', Icons.task_alt_rounded,         const Color(0xFF00C47D), const Color(0xFF008555)),
        const SizedBox(width: 12),
        _statCard('$pending',  'Pending',  Icons.pending_actions_rounded,  const Color(0xFFFF6D00), const Color(0xFFB84E00)),
      ]),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color light, Color dark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: light.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(color: light.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: light.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: light.withValues(alpha: 0.22), width: 1.5),
            ),
            child: Icon(icon, color: light, size: 19),
          ),
          const SizedBox(height: 12),
          // Value
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => LinearGradient(
              colors: [light, dark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(b),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _inkMid, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ]),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) => Row(children: [
    Container(
      width: 3, height: 14,
      decoration: BoxDecoration(gradient: _grad, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 9),
    Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _inkLight,
        letterSpacing: 2.2,
      ),
    ),
  ]);

  // ── Settings Card — refined tile list ────────────────────────────────────

  Widget _buildSettingsCard() {
    final tiles = [
      _TileData(icon: Icons.person_outline_rounded, label: 'Edit Profile',   subtitle: 'Update your display name',     gradColors: [_gradA, _gradMid], onTap: _editProfile),
      _TileData(icon: Icons.rate_review_outlined,   label: 'Send Feedback',  subtitle: 'Share your thoughts with us',  gradColors: [_gradMid, _gradB], onTap: _feedbackDialog),
      _TileData(icon: Icons.help_outline_rounded,   label: 'Help & Support', subtitle: 'FAQs and contact information', gradColors: [_gradB, const Color(0xFF00838F)], onTap: _helpAndSupport),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(color: _gradA.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final t       = tiles[i];
          final isFirst = i == 0;
          final isLast  = i == tiles.length - 1;

          return Column(children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: t.onTap,
                borderRadius: BorderRadius.vertical(
                  top:    isFirst ? const Radius.circular(22) : Radius.zero,
                  bottom: isLast  ? const Radius.circular(22) : Radius.zero,
                ),
                splashColor:    t.gradColors.first.withValues(alpha: 0.05),
                highlightColor: t.gradColors.first.withValues(alpha: 0.03),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    // Gradient icon box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [t.gradColors.first.withValues(alpha: 0.12), t.gradColors.last.withValues(alpha: 0.08)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: t.gradColors.first.withValues(alpha: 0.18), width: 1),
                      ),
                      child: Icon(t.icon, color: t.gradColors.first, size: 20),
                    ),
                    const SizedBox(width: 16),
                    // Text
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          t.label,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _inkDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.subtitle,
                          style: const TextStyle(fontSize: 12, color: _inkLight),
                        ),
                      ]),
                    ),
                    // Chevron
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) => LinearGradient(colors: t.gradColors).createShader(b),
                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            if (!isLast)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 80, right: 20),
                color: _border,
              ),
          ]);
        }),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Widget _buildLogoutButton() => GestureDetector(
    onTap: () => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: _red.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded, color: _red, size: 17),
        ),
        const SizedBox(width: 12),
        const Text(
          'Log Out',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _red, letterSpacing: -0.2),
        ),
      ]),
    ),
  );

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() => Center(
    child: Column(children: [
      _gradLine(width: 48, height: 1),
      const SizedBox(height: 14),
      Text(
        'University Complaint Management System',
        style: TextStyle(
          fontSize: 10.5,
          color: _inkLight.withValues(alpha: 0.8),
          letterSpacing: 0.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'ComplaintDesk AI  ·  v1.0.0',
        style: TextStyle(fontSize: 10, color: _inkLight.withValues(alpha: 0.45), letterSpacing: 0.5),
      ),
    ]),
  );

  // ── Bottom Nav — UNTOUCHED LOGIC, refined visuals ─────────────────────────

  Widget _buildBottomNav() {
    const tabs = [
      _NavTab('Home',       Icons.home_outlined,              Icons.home_rounded),
      _NavTab('Complaints', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
      _NavTab('Track',      Icons.track_changes_outlined,      Icons.track_changes_rounded),
      _NavTab('Profile',    Icons.person_outline_rounded,      Icons.person_rounded),
    ];
    const activeIndex = 3;

    void onTabTap(int i) {
      if (i == activeIndex) return;
      final routes = [
        () => HomeScreen(userId: widget.userId),
        () => ComplaintsScreen(userId: widget.userId),
        () => TrackComplaintsScreen(userId: widget.userId),
      ];
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => routes[i]()));
    }

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: const Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
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
              onTap: () => onTabTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_gradA.withValues(alpha: 0.10), _gradB.withValues(alpha: 0.07)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _gradA.withValues(alpha: 0.18), width: 1),
                      )
                    : const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(14))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  isActive
                      ? _gradMask(child: Icon(tab.activeIcon, size: 22, color: Colors.white))
                      : Icon(tab.icon, size: 22, color: _inkLight),
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
                            color: _inkLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── FAQ Item ──────────────────────────────────────────────────────────────

  Widget _faqItem(String question, String answer) {
    final isLast = question == 'Who handles urgent issues?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 21, height: 21,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradA.withValues(alpha: 0.15), _gradB.withValues(alpha: 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _gradA.withValues(alpha: 0.25), width: 1),
            ),
            child: const Icon(Icons.question_mark_rounded, color: _gradA, size: 12),
          ),
          Expanded(
            child: Text(
              question,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _inkDark, letterSpacing: -0.1),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 31, top: 6),
          child: Text(answer, style: const TextStyle(fontSize: 13, color: _inkMid, height: 1.6)),
        ),
        if (!isLast)
          const Padding(padding: EdgeInsets.only(top: 16), child: Divider(color: _border, height: 1)),
      ]),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.72, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

// ── Tile Data Model ───────────────────────────────────────────────────────────

class _TileData {
  final IconData     icon;
  final String       label;
  final String       subtitle;
  final List<Color>  gradColors;
  final VoidCallback onTap;
  const _TileData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradColors,
    required this.onTap,
  });
}