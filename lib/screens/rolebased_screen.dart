import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
              SizedBox(height: size.height * 0.12),

              // APP LOGO (same as login screen)
              Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withAlpha(128),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Complaint',
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Desk.AI',
                        style: TextStyle(
                          color: Color(0xFF9C27B0),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.08),

              Text(
                'Continue as',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.05,
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // ADMIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(role: 'admin'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB39DDB),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.025),

              // USER BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(role: 'user'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person),
                  label: Text(
                    'User',
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
