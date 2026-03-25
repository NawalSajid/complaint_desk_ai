import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/login_screen.dart';
import 'package:complaint_desk_ai/screens/home_screen.dart';
import 'package:complaint_desk_ai/screens/complaints_screen.dart';
import 'package:complaint_desk_ai/screens/track_complaints_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int total = 0;
  int resolved = 0;
  bool isLoading = true;

  String name = ''; // fetch from database

  @override
  void initState() {
    super.initState();
    fetchProfile();       // fetch name from backend
    fetchComplaints();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/${widget.userId}'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> complaints = jsonDecode(response.body);
        setState(() {
          total = complaints.length;
          resolved = complaints.where((c) => c['status'] == 'Resolved').length;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // EDIT PROFILE
  void _editProfile() {
    final nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: const Color(0xFFF6ECEF),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.edit, color: Color(0xFF9C27B0)),
                  SizedBox(width: 8),
                  Text('Edit Profile',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 25),
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color.fromARGB(143, 255, 255, 255),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isEmpty) return;

                      // Update local state
                      setState(() => name = newName);

                      // Send update to backend
                      try {
                        final response = await http.put(
                          Uri.parse('$baseUrl/api/users/${widget.userId}'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'name': newName}),
                        );

                        if (!mounted) return; 

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Name updated successfully'),
                              backgroundColor: Color.fromARGB(255, 65, 66, 66),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (_) {
                        if (!mounted) return; 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error connecting to server'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }

                      if (!mounted) return; 
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // FEEDBACK DIALOG 
  void _feedbackDialog() {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.feedback_outlined, color: Color(0xFF9C27B0)),
                  SizedBox(width: 8),
                  Text(
                    'Feedback',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write your feedback here...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          backgroundColor: Color.fromARGB(255, 64, 61, 64),
                        ),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // HELP & SUPPORT DIALOG
  void _helpAndSupport() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: Color(0xFF9C27B0)),
                          SizedBox(width: 8),
                          Text(
                            'Help & Support',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text('1. How can I submit a complaint?\nNavigate to the Complaints section, select the appropriate category, provide a detailed description, and attach any relevant documents(optional) before submitting.'),
                      SizedBox(height: 12),
                      Text('2. How do I track the status of my complaint?\nUse the Track Complaints screen to monitor the progress and status updates of your submitted complaints in real-time.'),
                      SizedBox(height: 12),
                      Text('3. What do the different complaint statuses indicate?\nPending: Complaint is received and awaiting review.\nIn-Progress: Complaint is actively being addressed.\nResolved: Complaint has been processed and closed.'),
                      SizedBox(height: 12),
                      Text('4. Can I update my personal information?\nYes, select "Edit Profile" in Account Settings to modify your name.'),
                      SizedBox(height: 12),
                      Text('5. Who should I contact for urgent or unresolved issues?\nPlease contact the designated support email or your department’s administration for further assistance.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              MaterialPageRoute(builder: (_) => TrackComplaintsScreen(userId: widget.userId)),
            );
          },
        ),
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_outline, size: 60, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      _stat(total.toString(), 'Total Complaints', const Color(0xFFE3F2FD), const Color(0xFF2196F3), icon: Icons.list_alt),
                      _stat(resolved.toString(), 'Resolved', const Color(0xFFE8F5E9), const Color(0xFF00C853), icon: Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  _settingTile('Edit Profile', Icons.edit, _editProfile),
                  const SizedBox(height: 12),
                  _settingTile('Feedback', Icons.feedback_outlined, _feedbackDialog),
                  const SizedBox(height: 12),
                  _settingTile('Help & Support', Icons.help_outline, _helpAndSupport),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'user',)));
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFF9C27B0)),
                    label: const Text('Log out', style: TextStyle(color: Color(0xFF9C27B0))),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem('HOME', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(userId: widget.userId)))),
            _navItem('COMPLAINTS', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ComplaintsScreen(userId: widget.userId)))),
            _navItem('TRACK', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrackComplaintsScreen(userId: widget.userId)))),
            _navItem('PROFILE', true, () {}),
          ],
        ),
      ),
    );
  }

  Widget _stat(String count, String label, Color bg, Color accent, {IconData? icon}) {
    Color innerColor;
    Color iconColor;
    if (label == 'Total Complaints') {
      innerColor = Colors.blue;
      iconColor =  const Color(0xFFE1F5FE);
    } else if (label == 'Resolved') {
      innerColor = const Color(0xFF00C853);
      iconColor = const Color(0xFFE8F5E9);
    } else {
      innerColor = Colors.white;
      iconColor = accent;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accent.withAlpha(80)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: innerColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.black.withAlpha(180), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _settingTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF9C27B0)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: Colors.grey.withAlpha(20),
    );
  }

  Widget _navItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)])
              : const LinearGradient(colors: [Color(0xFFCE93D8), Color(0xFFBA68C8)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
