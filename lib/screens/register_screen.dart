import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme colors (same as LoginScreen) ───────────────────────
  static const Color _primary = Color(0xFF9C27B0);
  static const Color _accent = Color(0xFF00BCD4);
  static const List<Color> _gradient = [_accent, Color(0xFF0097A7)];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Backend logic (untouched) ─────────────────────────────────
  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        showMessage('Registration successful');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        showMessage(data['message'] ?? 'Registration failed');
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
          // ── Background gradient ───────────────────────────────
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

          // ── Decorative circles ────────────────────────────────
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

          // ── Main content ──────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // ── Top bar: back button + centered logo ──
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
                                    color: _accent,
                                  ),
                                ),
                              ),
                            ),
                            // Logo centered
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
                                        const Color.fromRGBO(156, 39, 176, 1).withAlpha(200),
                                        const Color.fromRGBO(0, 188, 212, 1).withAlpha(200),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(156, 39, 176, 1).withAlpha(60),
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
                                  text: const TextSpan(
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
                                          color: Color.fromRGBO(156, 39, 176, 1),
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

                        SizedBox(height: size.height * 0.035),

                        // ── Role badge ────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accent.withAlpha(18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: _accent.withAlpha(55),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_rounded,
                                  size: 14, color: _accent),
                              const SizedBox(width: 6),
                              Text(
                                'User Portal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Avatar icon ───────────────────────────
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _gradient,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withAlpha(70),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Heading ───────────────────────────────
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign up to submit & track your complaints',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF888888),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Accent underline ──────────────────────
                        Container(
                          width: 40,
                          height: 3.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _gradient),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        SizedBox(height: size.height * 0.035),

                        // ── Form card ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Username ───────────────────────
                              _FieldLabel(label: 'Username'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: nameController,
                                hint: 'Create a username',
                                icon: Icons.badge_outlined,
                                roleColor: _accent,
                              ),

                              const SizedBox(height: 18),

                              // ── Email ──────────────────────────
                              _FieldLabel(label: 'Email Address'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: emailController,
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                roleColor: _accent,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 18),

                              // ── Password ───────────────────────
                              _FieldLabel(label: 'Password'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: passwordController,
                                hint: 'Create a password',
                                icon: Icons.lock_outline_rounded,
                                roleColor: _accent,
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
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Confirm Password ───────────────
                              _FieldLabel(label: 'Confirm Password'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: confirmPasswordController,
                                hint: 'Re-enter your password',
                                icon: Icons.lock_outline_rounded,
                                roleColor: _accent,
                                obscure: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),

                              const SizedBox(height: 26),

                              // ── Register button ────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : registerUser,
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
                                        colors: _gradient,
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
                                                  'Create Account',
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

                        // ── Login link ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Login Here',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _accent,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.04),

                        // ── Footer ────────────────────────────────
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

// ── Field Label ───────────────────────────────────────────────────────────────

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

// ── Input Field ───────────────────────────────────────────────────────────────

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
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
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
          borderSide: BorderSide(
            color: roleColor.withAlpha(40),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: roleColor.withAlpha(160),
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}