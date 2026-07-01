import 'dart:convert';

import 'package:complaint_desk_ai/screens/admin_complaint_screen.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/register_screen.dart';
import 'package:complaint_desk_ai/screens/rolebased_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF9C27B0);
  static const Color _accent = Color(0xFF00BCD4);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  bool get _isAdmin => widget.role == 'admin';
  Color get _roleColor => _isAdmin ? _primary : _accent;
  List<Color> get _roleGradient => _isAdmin
      ? [_primary, const Color(0xFF7B1FA2)]
      : [_accent, const Color(0xFF0097A7)];
  IconData get _roleIcon =>
      _isAdmin ? Icons.shield_rounded : Icons.person_rounded;
  String get _roleLabel => _isAdmin ? 'Admin Portal' : 'User Portal';
  String get _roleSubtitle => _isAdmin
      ? 'Sign in to manage complaints & operations'
      : 'Sign in to submit & track your complaints';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter email and password');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': widget.role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String returnedRole = data['role'] ?? 'user';
        final userId = data['userId'];

        if (userId == null) {
          showMessage('Server did not return userId');
          return;
        }

        if (!mounted) return;

        if (returnedRole != widget.role) {
          showMessage('Role mismatch. Please login from the correct portal.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
          return;
        }

        // ── ROUTING: Admin → AdminDashboardScreen, User → HomeScreen ──
        if (_isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminRoot(adminId: userId.toString()),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(userId: userId.toString()),
            ),
          );
        }
      } else {
        showMessage(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      showMessage('Error connecting to server');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF5FF),
                  Color(0xFFF0FAFE),
                  Color(0xFFFAF5FF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_primary.withAlpha(28), _primary.withAlpha(0)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.06,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.48,
              height: size.width * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withAlpha(28), _accent.withAlpha(0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primary.withAlpha(20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: _roleColor,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _primary.withAlpha(200),
                                        _accent.withAlpha(200),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primary.withAlpha(60),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Complaint',
                                        style: TextStyle(
                                          color: _accent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Desk',
                                        style: TextStyle(
                                          color: _primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '.AI',
                                        style: TextStyle(
                                          color: _primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.045),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _roleColor.withAlpha(18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: _roleColor.withAlpha(55),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_roleIcon, size: 14, color: _roleColor),
                              const SizedBox(width: 6),
                              Text(
                                _roleLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _roleGradient,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _roleColor.withAlpha(70),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(_roleIcon, color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _roleSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF888888),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 3.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _roleGradient),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _roleColor.withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Email Address'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: emailController,
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                roleColor: _roleColor,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel(label: 'Password'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: passwordController,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline_rounded,
                                roleColor: _roleColor,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 0,
                                    ),
                                  ),
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                      color: _roleColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : loginUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: _roleGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        if (!_isAdmin)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                    pageBuilder: (_, __, ___) =>
                                        const RegisterScreen(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Register Here',
                                  style: TextStyle(
                                    color: _roleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _roleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: size.height * 0.04),
                        Text(
                          'v1.0.0  •  University Complaint Cell',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color roleColor;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.roleColor,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
        filled: true,
        fillColor: const Color(0xFFF8F5FF),
        prefixIcon: Icon(icon, color: roleColor.withAlpha(180), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roleColor.withAlpha(40), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roleColor.withAlpha(160), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}