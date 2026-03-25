import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? userId;

  const HomeScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Complaint',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Desk.AI',
                    style: TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Column(
                  children: [
                    Text(
                      'AI DASHBOARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'complaint management system',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Category Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  _buildCategoryCard(context, 'Academic', const Color(0xFFE1F5FE), const Color(0xFF03A9F4)),
                  _buildCategoryCard(context, 'Hostel', const Color(0xFFFFFDE7), const Color(0xFFFF9800)),
                  _buildCategoryCard(context, 'Transport', const Color(0xFFF3E5F5), const Color(0xFFCE93D8)),
                  _buildCategoryCard(context, 'Harassment', const Color(0xFFE8F5E9), const Color(0xFF00C853)),
                ],
              ),
              const SizedBox(height: 15),
              // General Card Centered
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = (MediaQuery.of(context).size.width - 55) / 2;
                    final double height = width / 1.2;

                    return SizedBox(
                      width: width,
                      height: height,
                      child: _buildCategoryCard(
                        context,
                        'General',
                        const Color(0xFFFFEBEE),
                        const Color(0xFFEF9A9A),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('HOME', true, () {
              if (userId != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen(userId: userId!)),
                );
              }
            }),
            _buildNavItem('COMPLAINTS', false, () {
              if (userId != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ComplaintsScreen(userId: userId!)),
                );
              }
            }),
            _buildNavItem('TRACK', false, () {
              if (userId != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TrackComplaintsScreen(userId: userId!)),
                );
              }
            }),
            _buildNavItem('PROFILE', false, () {
              if (userId != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId!)),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  // Category Card 
  Widget _buildCategoryCard(BuildContext context, String title, Color bgColor, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintsScreen(userId: userId!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Item
  Widget _buildNavItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)])
              : const LinearGradient(colors: [Color(0xFFCE93D8), Color(0xFFBA68C8)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
