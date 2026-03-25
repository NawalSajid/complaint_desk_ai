import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.08;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.1),
              Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9C27B0).withAlpha(128)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Complaint',
                        style: TextStyle(color: Color(0xFF00BCD4), fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Desk.AI',
                        style: TextStyle(color: Color(0xFF9C27B0), fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              /// Icon
              Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: const BoxDecoration(
                  color: Color(0xFFB39DDB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_outlined, size: 50, color: Colors.black),
              ),

              SizedBox(height: size.height * 0.025),

              /// Form
              Container(
                padding: EdgeInsets.all(size.width * 0.06),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5).withAlpha(77),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFF3E5F5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// USERNAME
                    Text('USERNAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04)),
                    SizedBox(height: size.height * 0.01),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration('create username', size),
                    ),

                    SizedBox(height: size.height * 0.02),

                    /// EMAIL
                    Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04)),
                    SizedBox(height: size.height * 0.01),
                    TextField(
                      controller: emailController,
                      decoration: _inputDecoration('enter email', size),
                    ),

                    SizedBox(height: size.height * 0.02),

                    /// PASSWORD
                    Text('PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04)),
                    SizedBox(height: size.height * 0.01),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: _inputDecoration(
                        'create password',
                        size,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => isPasswordVisible = !isPasswordVisible);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    /// CONFIRM PASSWORD
                    Text('CONFIRM PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04)),
                    SizedBox(height: size.height * 0.01),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: _inputDecoration(
                        'confirm password',
                        size,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.03),

                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB39DDB),
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: size.height * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Login Here!",
                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Size size, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.015,
      ),
    );
  }
}
