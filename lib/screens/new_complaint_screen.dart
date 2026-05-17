// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// ── Theme tokens ──────────────────────────────────────────────────────────────
const Color _primary   = Color.fromRGBO(156, 39, 176, 1);
const Color _accent    = Color.fromRGBO(0, 188, 212, 1);
const Color _surface   = Color(0xFFF4F4FA);
const Color _cardBg    = Colors.white;
const Color _inkDark   = Color(0xFF14142B);
const Color _inkMid    = Color(0xFF6B6B8A);
const Color _inkLight  = Color(0xFFB0B0C8);
const Color _border    = Color(0xFFE8E8F0);
const Color _green     = Color(0xFF0BAB64);

class NewComplaintScreen extends StatefulWidget {
  final String userId;
  const NewComplaintScreen({super.key, required this.userId});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen>
    with SingleTickerProviderStateMixin {

  static const _categories = [
    _CategoryMeta(
      label: 'Academic',
      subtitle: 'Faculty & courses',
      icon: Icons.school_outlined,
      accent: Color(0xFF2979FF),
      bg: Color(0xFFEBF2FF),
    ),
    _CategoryMeta(
      label: 'Hostel',
      subtitle: 'Accommodation',
      icon: Icons.apartment_outlined,
      accent: Color(0xFFE67E22),
      bg: Color(0xFFFFF4E8),
    ),
    _CategoryMeta(
      label: 'Transport',
      subtitle: 'Bus & routes',
      icon: Icons.directions_bus_outlined,
      accent: Color(0xFF7B35CC),
      bg: Color(0xFFF0EBFF),
    ),
    _CategoryMeta(
      label: 'Harassment',
      subtitle: 'Misconduct',
      icon: Icons.shield_outlined,
      accent: Color(0xFF0BAB64),
      bg: Color(0xFFE8F9F3),
    ),
    _CategoryMeta(
      label: 'General',
      subtitle: 'Other issues',
      icon: Icons.chat_bubble_outline_rounded,
      accent: Color(0xFFE84393),
      bg: Color(0xFFFFF0F7),
    ),
  ];

  String selectedCategory = '';
  String? _fileName;
  final TextEditingController descriptionController = TextEditingController();
  bool isSubmitting = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ── BACKEND LOGIC — UNTOUCHED ─────────────────────────────────────────────

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
    );
    if (result != null) {
      setState(() => _fileName = result.files.single.name);
    }
  }

  Future<void> submitComplaint({bool dummy = false}) async {
    String category    = dummy ? 'General' : selectedCategory;
    String description = dummy ? 'This is a test complaint' : descriptionController.text;

    if (!dummy && (category.isEmpty || description.isEmpty)) {
      _showSnackBar(
        message: 'Please select a category and enter a description.',
        icon: Icons.info_outline_rounded,
        isError: true,
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': int.parse(widget.userId),
          'category': category,
          'description': description,
          'document': _fileName ?? '',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSnackBar(
          message: 'Complaint submitted successfully.',
          icon: Icons.check_circle_outline_rounded,
          isError: false,
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          message: data['message'] ?? 'Failed to submit complaint.',
          icon: Icons.error_outline_rounded,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      if (!mounted) return;
      _showSnackBar(
        message: 'Unable to connect. Please try again.',
        icon: Icons.wifi_off_rounded,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ── Professional Snackbar ─────────────────────────────────────────────────

  void _showSnackBar({
    required String message,
    required IconData icon,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        backgroundColor: const Color.fromARGB(255, 56, 31, 67),
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 56, 31, 67),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.white.withValues(alpha: 0.08)
                      : _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isError ? const Color(0xFFCCCCDD) : _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8E8F0),
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(Icons.grid_view_rounded, 'SELECT CATEGORY'),
                      const SizedBox(height: 14),
                      _buildCategoryGrid(),
                      const SizedBox(height: 30),
                      _buildSectionLabel(Icons.edit_outlined, 'DESCRIBE YOUR ISSUE'),
                      const SizedBox(height: 14),
                      _buildDescriptionField(),
                      const SizedBox(height: 12),
                      _buildSectionLabel(Icons.attach_file_rounded, 'SUPPORTING DOCUMENT'),
                      const SizedBox(height: 14),
                      _buildAttachmentSection(),
                      const SizedBox(height: 16),
                      _buildPrivacyNote(),
                      const SizedBox(height: 30),
                      _buildSubmitButton(),
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  _NavBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  _BrandTitle(),
                  const Spacer(),
                  _HeaderBadge(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: _HeroCard(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 17,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_primary, _accent],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Icon(icon, size: 12, color: _primary.withValues(alpha: 0.85)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _primary,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  // ── Category Grid ─────────────────────────────────────────────────────────

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: _categories
          .map((c) => _CategoryTile(
                meta: c,
                isSelected: selectedCategory == c.label,
                onTap: () => setState(() => selectedCategory = c.label),
              ))
          .toList(),
    );
  }

  // ── Description Field ─────────────────────────────────────────────────────

  Widget _buildDescriptionField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: descriptionController.text.isNotEmpty
              ? _primary.withValues(alpha: 0.35)
              : _border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.025),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 14, color: _primary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Describe your issue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _inkDark,
                    letterSpacing: -0.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AI ASSISTED',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: descriptionController,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 13.5,
              color: _inkDark,
              height: 1.7,
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              hintText:
                  'Include relevant dates, names, and details that help us understand your concern…',
              hintStyle: TextStyle(
                color: _inkLight.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.65,
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: _inkLight),
                const SizedBox(width: 6),
                const Text(
                  'More detail leads to faster resolution',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _inkLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Text(
                  '${descriptionController.text.length} chars',
                  style: TextStyle(
                    fontSize: 10,
                    color: descriptionController.text.length > 20
                        ? _green.withValues(alpha: 0.8)
                        : _inkLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment Section (redesigned) ───────────────────────────────────────

  Widget _buildAttachmentSection() {
    final attached = _fileName != null;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: attached ? _green.withValues(alpha: 0.35) : _border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Info row ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              color: attached
                  ? _green.withValues(alpha: 0.03)
                  : _surface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: attached
                        ? _green.withValues(alpha: 0.1)
                        : _inkLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    attached ? Icons.task_alt_rounded : Icons.attach_file_rounded,
                    size: 16,
                    color: attached ? _green : _inkMid,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attached ? 'Document attached' : 'Attach a document',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: attached ? _green : _inkDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attached ? _fileName! : 'JPG, PNG, PDF or DOC · Max 10 MB',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: attached ? _green.withValues(alpha: 0.75) : _inkLight,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const Spacer(),
                if (attached)
                  GestureDetector(
                    onTap: () => setState(() => _fileName = null),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _inkLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 15, color: _inkMid),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _inkLight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border, width: 1),
                    ),
                    child: const Text(
                      'Optional',
                      style: TextStyle(
                        fontSize: 10,
                        color: _inkLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Upload area ───────────────────────────────────────────────
          if (!attached)
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _inkLight.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.upload_file_outlined,
                        size: 22,
                        color: _inkMid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tap to browse',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primary.withValues(alpha: 0.85),
                              letterSpacing: -0.1,
                            ),
                          ),
                          const TextSpan(
                            text: '  or drag a file here',
                            style: TextStyle(
                              fontSize: 13,
                              color: _inkMid,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Screenshots, photos or documents related to your complaint',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: _inkLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Attached preview ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _fileColor(_fileName!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_fileIcon(_fileName!),
                        color: _fileColor(_fileName!), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _inkDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Ready to submit with your complaint',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                ],
              ),
            ),

          // ── Format footer ─────────────────────────────────────────────
          if (!attached)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  _FormatChip(icon: Icons.image_outlined,        label: 'JPG / PNG'),
                  const SizedBox(width: 8),
                  _FormatChip(icon: Icons.picture_as_pdf_outlined, label: 'PDF'),
                  const SizedBox(width: 8),
                  _FormatChip(icon: Icons.description_outlined,  label: 'DOC'),
                ],
              ),
            ),

          if (attached)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: _border,
            ),
          if (attached)
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 14, color: _inkLight),
                    const SizedBox(width: 6),
                    Text(
                      'Replace file',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _inkLight,
                        fontWeight: FontWeight.w600,
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

  // ── File helpers ──────────────────────────────────────────────────────────

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf')                           return Icons.picture_as_pdf_outlined;
    if (ext == 'doc' || ext == 'docx')          return Icons.description_outlined;
    if (['jpg','jpeg','png'].contains(ext))     return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _fileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf')                           return const Color(0xFFE53935);
    if (ext == 'doc' || ext == 'docx')          return const Color(0xFF1565C0);
    if (['jpg','jpeg','png'].contains(ext))     return const Color(0xFF00897B);
    return _primary;
  }

  // ── Privacy Note ──────────────────────────────────────────────────────────

  Widget _buildPrivacyNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 11, color: _inkLight.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          const Text(
            'Your submission is encrypted and kept confidential.',
            style: TextStyle(fontSize: 10.5, color: _inkLight, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }

  // ── Submit Button (clean & professional) ──────────────────────────────────

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: isSubmitting ? null : () => submitComplaint(dummy: false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: isSubmitting ? const Color(0xFF9E3BB5) : _primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSubmitting
                    ? []
                    : [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Submitting…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 9),
                          Text(
                            'Submit Complaint',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'We respond within 24 hours · Reference ID generated on submit',
            style: TextStyle(
              fontSize: 10,
              color: _inkLight.withValues(alpha: 0.8),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Extracted Stateless Header Widgets ────────────────────────────────────────

class _NavBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _primary.withValues(alpha: 0.12), width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 15),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Complaint',
            style: TextStyle(
              color: _accent,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Desk',
            style: TextStyle(
              color: _primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: '.AI',
            style: TextStyle(
              color: _primary,
              fontSize: 15,
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text(
            'Active',
            style: TextStyle(fontSize: 10.5, color: _green, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color.fromRGBO(92, 53, 204, 1)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.32),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -25,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15), width: 1),
                      ),
                      child: const Text(
                        'NEW SUBMISSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Tell us what\nhappened',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _HeroChip(icon: Icons.access_time_rounded, label: '24h response'),
                        const SizedBox(width: 8),
                        _HeroChip(icon: Icons.lock_rounded, label: 'Confidential'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16), width: 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              color: Colors.white.withValues(alpha: 0.95), size: 20),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Text(
                          'Powered',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white60),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Format chip ───────────────────────────────────────────────────────────────

class _FormatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FormatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _inkLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _inkMid),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 9.5, color: _inkMid, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Category metadata ─────────────────────────────────────────────────────────

class _CategoryMeta {
  final String   label;
  final String   subtitle;
  final IconData icon;
  final Color    accent;
  final Color    bg;
  const _CategoryMeta({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bg,
  });
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  final _CategoryMeta meta;
  final bool          isSelected;
  final VoidCallback  onTap;

  const _CategoryTile({
    required this.meta,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final m   = widget.meta;
    final sel = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: sel ? m.bg : _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel ? m.accent.withValues(alpha: 0.5) : _border,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: m.accent.withValues(alpha: sel ? 0.14 : 0.04),
                blurRadius: sel ? 16 : 6,
                spreadRadius: sel ? 0 : -1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: m.accent.withValues(alpha: sel ? 0.18 : 0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(m.icon, color: m.accent, size: 18),
                  ),
                  if (sel)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: m.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardBg, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: m.accent.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, size: 7, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: sel ? m.accent : _inkDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.subtitle,
                style: const TextStyle(fontSize: 9.5, color: _inkLight, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}