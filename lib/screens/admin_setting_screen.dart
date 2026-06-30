// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/download_helper.dart';
import 'rolebased_screen.dart';
import '../constants.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COLOR TOKENS
// ══════════════════════════════════════════════════════════════════════════════
const Color kViolet      = Color(0xFF9C27B0);
const Color kDeepViolet  = Color(0xFF7B1FA2);
const Color kDarkViolet  = Color(0xFF4A148C);
const Color kVioletMid   = Color(0xFF6A1B9A);
const Color kCyan        = Color(0xFF00BCD4);
const Color kSurface     = Color(0xFFF5F0FC);
const Color kWhite       = Colors.white;
const Color kInkDark     = Color(0xFF1A1A2E);
const Color kInkMid      = Color(0xFF4A4A6A);
const Color kInkLight    = Color(0xFF8888A0);
const Color kBorder      = Color(0xFFEEEEF5);
const Color kVioletLight = Color(0xFFEDE8FF);
const Color kRedLight    = Color(0xFFFCEBEB);
const Color kRedDark     = Color(0xFFA32D2D);
const Color kRed         = Color(0xFFE24B4A);
const Color kGreenLight  = Color(0xFFEAF3DE);
const Color kGreenDark   = Color(0xFF3B6D11);
const Color kAmberLight  = Color(0xFFFFF5EC);
const Color kAmberDark   = Color(0xFF854F0B);

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class AdminSettingsScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  final int navIndex;
  final ValueNotifier<int> refreshNotifier;
  final void Function() onRefreshAll;

  const AdminSettingsScreen({
    super.key,
    required this.onNavTap,
    required this.navIndex,
    required this.refreshNotifier,
    required this.onRefreshAll,
  });

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {

  // ── Toggle states ──────────────────────────────────────────────────────────
  int  _resolutionDeadlineHours = 24;
  bool _isSaving                = false;
  bool _isLoading               = true;
  bool _isExportingCsv          = false;
  bool _isExportingPdf          = false;

  // ── Admin name ─────────────────────────────────────────────────────────────
  String _adminName = 'Nawal Admin';

  // ── Password controllers ───────────────────────────────────────────────────
  final _curPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _conPwCtrl = TextEditingController();
  bool _curObscure = true;
  bool _newObscure = true;
  bool _conObscure = true;

  // ── Entry animation ────────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
    _fetchSettings();
  }

  // ── Load settings from API ─────────────────────────────────────────────────
  Future<void> _fetchSettings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/settings'));
      if (res.statusCode == 200 && mounted) {
        final s = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _resolutionDeadlineHours = (s['resolution_deadline_hours'] ?? 24) as int;
          _adminName               = (s['admin_name'] ?? 'Nawal Admin') as String;
          _isLoading               = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Save settings to API ───────────────────────────────────────────────────
  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/admin/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resolution_deadline_hours': _resolutionDeadlineHours,
          'admin_name':                _adminName,
        }),
      );
      if (mounted) {
        _snack(
          res.statusCode == 200 ? 'Settings saved' : 'Failed to save settings',
          icon: res.statusCode == 200
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          isError: res.statusCode != 200,
        );
      }
    } catch (_) {
      if (mounted) _snack('Error connecting to server', icon: Icons.wifi_off_rounded, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Change password API call ───────────────────────────────────────────────
  Future<void> _changePassword({
    required String current,
    required String newPw,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/admin/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_password': current,
          'new_password': newPw,
        }),
      );
      if (mounted) {
        _snack(
          res.statusCode == 200
              ? 'Password updated successfully'
              : 'Incorrect current password',
          icon: res.statusCode == 200
              ? Icons.lock_open_rounded
              : Icons.lock_outline_rounded,
          isError: res.statusCode != 200,
        );
      }
    } catch (e) {
      if (mounted) {
        _snack('Error connecting to server', icon: Icons.wifi_off_rounded, isError: true);
      }
    }
  }

  // ── Export CSV ─────────────────────────────────────────────────────────────
 Future<void> _exportCsv() async {
  if (_isExportingCsv) return;
  setState(() => _isExportingCsv = true);
  _snack('Preparing CSV export…', icon: Icons.hourglass_top_rounded);
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/export/complaints.csv'),
    );
    if (res.statusCode == 200) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = 'Complaints_$timestamp.csv';
      await saveAndDownload(bytes: utf8.encode(res.body), filename: filename);
      if (mounted) {
        _snack('CSV downloaded: $filename', icon: Icons.download_done_rounded);
      }
    } else {
      if (mounted) _snack('CSV export failed', icon: Icons.error_outline_rounded, isError: true);
    }
  } catch (_) {
    if (mounted) _snack('Error connecting to server', icon: Icons.wifi_off_rounded, isError: true);
  } finally {
    if (mounted) setState(() => _isExportingCsv = false);
  }
}

  // ── Export PDF ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
  if (_isExportingPdf) return;
  setState(() => _isExportingPdf = true);
  _snack('Generating PDF report…', icon: Icons.hourglass_top_rounded);
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/export/complaints.pdf'),
    );
    if (res.statusCode == 200) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = 'ComplaintDesk_Report_$timestamp.pdf';
      await saveAndDownload(bytes: res.bodyBytes, filename: filename);
      if (mounted) {
        _snack('PDF downloaded: $filename', icon: Icons.picture_as_pdf_rounded);
      }
    } else {
      if (mounted) _snack('PDF export failed', icon: Icons.error_outline_rounded, isError: true);
    }
  } catch (e) {
  if (mounted) _snack('Error: $e', icon: Icons.wifi_off_rounded, isError: true);
}finally {
    if (mounted) setState(() => _isExportingPdf = false);
  }
}

  // ── Export options bottom sheet ────────────────────────────────────────────
  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // Icon + title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_outlined, color: kGreenDark, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Complaints',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kInkDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose your preferred export format',
                      style: TextStyle(fontSize: 12, color: kInkLight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CSV option
            _ExportFormatTile(
              icon: Icons.table_chart_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              title: 'Export as CSV',
              subtitle: 'Spreadsheet format — compatible with Excel, Google Sheets',
              badge: 'CSV',
              badgeBg: const Color(0xFFE8F5E9),
              badgeColor: const Color(0xFF2E7D32),
              isLoading: _isExportingCsv,
              onTap: () {
                Navigator.pop(context);
                _exportCsv();
              },
            ),
            const SizedBox(height: 12),

            // PDF option
            _ExportFormatTile(
              icon: Icons.picture_as_pdf_outlined,
              iconBg: const Color(0xFFFCE4EC),
              iconColor: const Color(0xFFC62828),
              title: 'Export as PDF',
              subtitle: 'Professional report — ready to print or share',
              badge: 'PDF',
              badgeBg: const Color(0xFFFCE4EC),
              badgeColor: const Color(0xFFC62828),
              isLoading: _isExportingPdf,
              onTap: () {
                Navigator.pop(context);
                _exportPdf();
              },
            ),
            const SizedBox(height: 20),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kInkMid,
                  side: const BorderSide(color: kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _curPwCtrl.dispose();
    _newPwCtrl.dispose();
    _conPwCtrl.dispose();
    super.dispose();
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────
  void _snack(String msg, {IconData icon = Icons.info_outline_rounded, bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: kWhite, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFF6A1B9A) : kDeepViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Generic confirm bottom sheet ───────────────────────────────────────────
  Future<bool> _confirmSheet({
    required IconData icon,
    required Color    iconColor,
    required Color    iconBg,
    required String   title,
    required String   subtitle,
    required String   confirmLabel,
    required Color    confirmColor,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        icon:         icon,
        iconColor:    iconColor,
        iconBg:       iconBg,
        title:        title,
        subtitle:     subtitle,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  // ── Edit name bottom sheet ─────────────────────────────────────────────────
  void _openEditNameSheet() {
    final nameCtrl = TextEditingController(text: _adminName);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38, height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: kVioletLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline_rounded, color: kDeepViolet, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit display name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInkDark, letterSpacing: -0.3)),
                      SizedBox(height: 2),
                      Text('Update the name displayed for admin',
                          style: TextStyle(fontSize: 12, color: kInkLight)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 15, color: kInkDark, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Nawal Admin',
                  hintStyle: const TextStyle(color: kInkLight),
                  filled: true, fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kViolet, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kInkMid,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          _snack('Name cannot be empty', icon: Icons.warning_amber_rounded, isError: true);
                          return;
                        }
                        setState(() => _adminName = name);
                        Navigator.pop(ctx);
                        await _saveSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeepViolet, foregroundColor: kWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save name', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change password bottom sheet ───────────────────────────────────────────
  void _openPasswordSheet() {
    _curPwCtrl.clear();
    _newPwCtrl.clear();
    _conPwCtrl.clear();
    _curObscure = true;
    _newObscure = true;
    _conObscure = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38, height: 4,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kVioletLight, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.lock_outline_rounded, color: kDeepViolet, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInkDark, letterSpacing: -0.3)),
                          SizedBox(height: 2),
                          Text('Minimum 6 characters required',
                              style: TextStyle(fontSize: 12, color: kInkLight)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _PwField(controller: _curPwCtrl, hint: 'Current password', obscure: _curObscure, onToggle: () => setSheetState(() => _curObscure = !_curObscure)),
                  const SizedBox(height: 10),
                  _PwField(controller: _newPwCtrl, hint: 'New password', obscure: _newObscure, onToggle: () => setSheetState(() => _newObscure = !_newObscure)),
                  const SizedBox(height: 10),
                  _PwField(controller: _conPwCtrl, hint: 'Confirm new password', obscure: _conObscure, onToggle: () => setSheetState(() => _conObscure = !_conObscure)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kInkMid,
                            side: const BorderSide(color: kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final cur = _curPwCtrl.text.trim();
                            final np  = _newPwCtrl.text.trim();
                            final cp  = _conPwCtrl.text.trim();
                            if (cur.isEmpty || np.isEmpty || cp.isEmpty) {
                              _snack('Please fill all fields', icon: Icons.warning_amber_rounded, isError: true);
                              return;
                            }
                            if (np != cp) {
                              _snack('Passwords do not match', icon: Icons.warning_amber_rounded, isError: true);
                              return;
                            }
                            if (np.length < 6) {
                              _snack('Minimum 6 characters required', icon: Icons.warning_amber_rounded, isError: true);
                              return;
                            }
                            Navigator.pop(ctx);
                            await _changePassword(current: cur, newPw: np);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDeepViolet, foregroundColor: kWhite,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Update password', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Resolution deadline picker ─────────────────────────────────────────────
  void _openDeadlinePicker() {
    final ctrl = TextEditingController(text: _resolutionDeadlineHours.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38, height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: kAmberLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.timer_outlined, color: kAmberDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resolution deadline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInkDark, letterSpacing: -0.3)),
                      SizedBox(height: 2),
                      Text('Set default hours per complaint',
                          style: TextStyle(fontSize: 12, color: kInkLight)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 15, color: kInkDark, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. 24',
                  hintStyle: const TextStyle(color: kInkLight),
                  suffixText: 'hours',
                  suffixStyle: const TextStyle(color: kInkLight, fontSize: 13),
                  filled: true, fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kViolet, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kInkMid,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(ctrl.text.trim());
                        if (val == null || val <= 0) {
                          _snack('Enter a valid number of hours', icon: Icons.warning_amber_rounded, isError: true);
                          return;
                        }
                        setState(() => _resolutionDeadlineHours = val);
                        Navigator.pop(ctx);
                        _saveSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeepViolet, foregroundColor: kWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kViolet))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverHeader(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Profile card ───────────────────────────────
                          _buildProfileCard(),
                          const SizedBox(height: 16),

                          // ── Complaint Management ───────────────────────
                          const _SectionLabel(label: 'Complaint Management'),
                          _buildManagementCard(),
                          const SizedBox(height: 16),

                          // ── Security ───────────────────────────────────
                          const _SectionLabel(label: 'Security'),
                          _buildSecurityCard(),
                          const SizedBox(height: 16),

                          // ── Data & Account ─────────────────────────────
                          const _SectionLabel(label: 'Data & Account'),
                          _buildAccountCard(),
                          const SizedBox(height: 16),

                          // ── Footer ─────────────────────────────────────
                          _buildFooter(),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: kViolet,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeaderBackground(),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final parts    = _adminName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : _adminName.substring(0, _adminName.length.clamp(0, 2)).toUpperCase();

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: kDeepViolet,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kVioletLight, width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(color: kWhite, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_adminName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: kInkDark, letterSpacing: -0.3)),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: kVioletLight, borderRadius: BorderRadius.circular(99)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 11, color: kDeepViolet),
                        SizedBox(width: 4),
                        Text('Super Administrator', style: TextStyle(fontSize: 10, color: kDeepViolet, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _openEditNameSheet,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kVioletLight, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.edit_rounded, color: kDeepViolet, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Management card ────────────────────────────────────────────────────────
  Widget _buildManagementCard() {
    return _Card(
      child: Column(
        children: [
          _TapRow(
            icon: Icons.timer_outlined,
            iconBg: kAmberLight,
            iconColor: kAmberDark,
            title: 'Resolution deadline',
            subtitle: 'Default SLA per complaint',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: kAmberLight,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: kAmberDark.withAlpha(50)),
              ),
              child: Text('$_resolutionDeadlineHours hrs',
                  style: const TextStyle(fontSize: 10.5, color: kAmberDark, fontWeight: FontWeight.w700)),
            ),
            onTap: _openDeadlinePicker,
          ),
        ],
      ),
    );
  }

  // ── Security card ──────────────────────────────────────────────────────────
  Widget _buildSecurityCard() {
    return _Card(
      child: Column(
        children: [
          _TapRow(
            icon: Icons.lock_outline_rounded,
            iconBg: kVioletLight,
            iconColor: kDeepViolet,
            title: 'Change password',
            subtitle: 'Update your account credentials',
            trailing: const Icon(Icons.chevron_right_rounded, color: kInkLight, size: 20),
            onTap: _openPasswordSheet,
          ),
        ],
      ),
    );
  }

  // ── Data & Account card ────────────────────────────────────────────────────
  Widget _buildAccountCard() {
    return _Card(
      child: Column(
        children: [
          // ── Export complaints (opens format picker) ──
          _TapRow(
            icon: Icons.download_outlined,
            iconBg: kGreenLight,
            iconColor: kGreenDark,
            title: 'Export complaints',
            subtitle: 'Download records as CSV or PDF report',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small format badges
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('CSV', style: TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('PDF', style: TextStyle(fontSize: 9, color: Color(0xFFC62828), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: kInkLight, size: 20),
              ],
            ),
            onTap: _openExportSheet,
          ),
          const _RowDivider(),
          _TapRow(
            icon: Icons.logout_rounded,
            iconBg: kRedLight,
            iconColor: kRedDark,
            title: 'Sign out',
            subtitle: 'Log out of your admin account',
            titleColor: kRedDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: kRedDark, size: 20),
            onTap: () async {
              final ok = await _confirmSheet(
                icon:         Icons.logout_rounded,
                iconColor:    kDeepViolet,
                iconBg:       kVioletLight,
                title:        'Sign out?',
                subtitle:     'You will be returned to the login screen. Any unsaved changes will be lost.',
                confirmLabel: 'Sign out',
                confirmColor: kDeepViolet,
              );
              if (ok && mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: kVioletLight, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.support_agent_rounded, size: 12, color: kDeepViolet),
              ),
              const SizedBox(width: 6),
              const Text('ComplaintDesk.AI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kInkMid, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Version 1.0.0 · Admin Portal',
              style: TextStyle(fontSize: 11, color: kInkLight)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT FORMAT TILE
// ══════════════════════════════════════════════════════════════════════════════
class _ExportFormatTile extends StatelessWidget {
  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final String   badge;
  final Color    badgeBg;
  final Color    badgeColor;
  final bool     isLoading;
  final VoidCallback onTap;

  const _ExportFormatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(11),
                      child: CircularProgressIndicator(color: iconColor, strokeWidth: 2),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInkDark)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11.5, color: kInkLight)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
              child: Text(badge,
                  style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kViolet, kDeepViolet],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48, top: -48,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kWhite.withAlpha(12), width: 1),
              ),
            ),
          ),
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kVioletMid.withAlpha(60)),
            ),
          ),
          Positioned(
            left: -36, bottom: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kCyan.withAlpha(18)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: kCyan.withAlpha(28),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: kCyan.withAlpha(80), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF80DEEA), size: 12),
                            SizedBox(width: 5),
                            Text('Admin', style: TextStyle(color: Color(0xFF80DEEA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Settings', style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.6, height: 1)),
                  const SizedBox(height: 3),
                  Text('Manage your portal preferences', style: TextStyle(color: kWhite.withAlpha(150), fontSize: 12.5)),
                  const SizedBox(height: 18),
                  const Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Auto Assign', value: 'Role-based', icon: Icons.auto_fix_high, color: Color(0xFF80CBC4)),
                      _StatChip(label: 'Live Tracking', value: 'Real-Time', icon: Icons.location_searching_rounded, color: Color(0xFF80CBC4)),
                      _StatChip(label: 'Response Time', value: '24h Support', icon: Icons.support_agent_rounded, color: Color(0xFF80DEEA)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: kWhite.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kWhite.withAlpha(20), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: kWhite.withAlpha(130), fontSize: 9.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONFIRM BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   subtitle;
  final String   confirmLabel;
  final Color    confirmColor;

  const _ConfirmSheet({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle,
    required this.confirmLabel, required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38, height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInkDark, letterSpacing: -0.3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: kInkMid, height: 1.55)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kInkMid,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor, foregroundColor: kWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(confirmLabel, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: kViolet.withAlpha(10), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInkLight, letterSpacing: 1.1)),
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData     icon;
  final Color        iconBg;
  final Color        iconColor;
  final String       title;
  final String       subtitle;
  final Widget       trailing;
  final VoidCallback onTap;
  final Color        titleColor;

  const _TapRow({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle,
    required this.trailing, required this.onTap,
    this.titleColor = kInkDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: kViolet.withAlpha(12),
      highlightColor: kViolet.withAlpha(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: titleColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: kInkLight)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    bg;
  final Color    color;

  const _IconBox({required this.icon, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 62, endIndent: 14, color: kBorder);
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final bool                  obscure;
  final VoidCallback          onToggle;

  const _PwField({required this.controller, required this.hint, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13.5, color: kInkDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kInkLight, fontSize: 13.5),
        filled: true, fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: kViolet, width: 1.5)),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kInkLight, size: 18),
        ),
      ),
    );
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
      (Icons.grid_view_outlined,   Icons.grid_view_rounded,   'Home'),
      (Icons.list_alt_outlined,    Icons.list_alt_rounded,    'Complaints'),
      (Icons.bar_chart_outlined,   Icons.bar_chart_rounded,   'Analytics'),
      (Icons.settings_outlined,    Icons.settings_rounded,    'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [BoxShadow(color: kViolet.withAlpha(16), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == activeIndex;
              final item     = items[i];
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); onTap(i); },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? kViolet.withAlpha(16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isActive ? item.$2 : item.$1, size: 22, color: isActive ? kViolet : Colors.grey.shade400),
                      const SizedBox(height: 3),
                      Text(item.$3, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? kViolet : Colors.grey.shade400)),
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