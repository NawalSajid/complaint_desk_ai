import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrackComplaintsScreen extends StatefulWidget {
  final String userId;

  const TrackComplaintsScreen({super.key, required this.userId});

  @override
  State<TrackComplaintsScreen> createState() => _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen> {
  int total = 0;
  int pending = 0;
  int inProgress = 0;
  int resolved = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaintStats();
  }

  Future<void> fetchComplaintStats() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.69:5000/api/complaints?user_id=${widget.userId}'),
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintsScreen(userId: widget.userId),
      ),
    );
  },
),

        title: const Text(
          'Track Complaints',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 45),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: Text(
                          'TRACK THE COMPLAINTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ===== UPDATED GRIDVIEW VERSION =====
GridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  crossAxisSpacing: 20,
  mainAxisSpacing: 20,
  childAspectRatio: 0.75, // reduced to prevent overflow on small screens
  children: [
    _buildStatCard(
      total.toString(),
      'Total Complaints',
      const Color(0xFFE1F5FE),
      const Color(0xFF2196F3),
      icon: Icons.list_alt,
    ),
    _buildStatCard(
      pending.toString(),
      'Pending',
      const Color(0xFFFFFDE7),
      const Color(0xFFFF9800),
      icon: Icons.pending_actions,
    ),
    _buildStatCard(
      inProgress.toString(),
      'In-Progress',
      const Color(0xFFF3E5F5),
      const Color.fromARGB(255, 196, 94, 214),
      icon: Icons.history,
    ),
    _buildStatCard(
      resolved.toString(),
      'Resolved',
      const Color(0xFFE8F5E9),
      const Color(0xFF00C853),
      icon: Icons.check_circle,
    ),
  ],
),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

      // ===== BOTTOM NAV (UNCHANGED) =====
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('HOME', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(userId: widget.userId),
                ),
              );
            }),
            _buildNavItem('COMPLAINTS', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintsScreen(userId: widget.userId),
                ),
              );
            }),
            _buildNavItem('TRACK', true, () {}),
            _buildNavItem('PROFILE', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===== CARD WIDGET =====
  Widget _buildStatCard(
    String count,
    String label,
    Color bgColor,
    Color accentColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===== NAV ITEM =====
  Widget _buildNavItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFCE93D8), Color(0xFFBA68C8)],
                ),
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
