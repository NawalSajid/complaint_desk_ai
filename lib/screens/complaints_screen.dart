import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/new_complaint_screen.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:complaint_desk_ai/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 
import '../constants.dart';

class ComplaintsScreen extends StatefulWidget {
  final String userId; // Required

  const ComplaintsScreen({super.key, required this.userId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> complaints = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          complaints = data;
        });
      } else {
        debugPrint('Failed to fetch complaints: ${response.statusCode}');
        showMessage('Failed to load complaints');
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
      showMessage('Error connecting to server');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// ✅ Helper to format timestamps like DB
  String formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate).toLocal(); // UTC → local
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt); // DB style
    } catch (e) {
      return rawDate; // fallback
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
                builder: (_) => HomeScreen(userId: widget.userId),
              ),
            );
          },
        ),
        title: const Text(
          'Complaints',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ADD A COMPLAINT Button
              Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () async {
                      bool? added = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NewComplaintScreen(userId: widget.userId),
                        ),
                      );

                      if (added == true) {
                        fetchComplaints();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(
                          color: const Color(0xFF9C27B0).withAlpha(80)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFF03A9F4),
                          child: Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'ADD A COMPLAINT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // RECENT COMPLAINTS Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT COMPLAINTS:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton(
                    onPressed: fetchComplaints,
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : complaints.isEmpty
                      ? const Text('No complaints found.')
                      : Column(
                          children: complaints
                              .map((c) => _buildComplaintCard(
                                    c['category'] ?? 'General',
                                    c['description'] ?? '',
                                    c['priority'] ?? 'Normal',
                                    c['status'] ?? 'Pending',
                                    c['category'] ?? 'General',
                                    formatDate(c['created_at'] ?? ''),
                                    '0 updates',
                                  ))
                              .toList(),
                        ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('HOME', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(userId: widget.userId)),
              );
            }),
            _buildNavItem('COMPLAINTS', true, () {}),
            _buildNavItem('TRACK', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TrackComplaintsScreen(userId: widget.userId)),
              );
            }),
            _buildNavItem('PROFILE', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: widget.userId)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(
    String title,
    String description,
    String priority,
    String status,
    String category,
    String time,
    String updates,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildTag(priority, const Color(0xFFFFEBEE), const Color(0xFFEF9A9A)),
              const SizedBox(width: 8),
              _buildTag(status, const Color(0xFFF3E5F5), const Color(0xFFCE93D8)),
              const SizedBox(width: 8),
              _buildTag(category, const Color(0xFFF5F5F5), Colors.black54),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.black54),
              const SizedBox(width: 5),
              Text(time,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(width: 15),
              const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.black54),
              const SizedBox(width: 5),
              Text(updates,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

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
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
