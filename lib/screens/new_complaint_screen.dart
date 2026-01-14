import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class NewComplaintScreen extends StatefulWidget {
  final String userId;
  const NewComplaintScreen({super.key, required this.userId});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  String selectedCategory = '';
  String? _fileName;
  TextEditingController descriptionController = TextEditingController();
  bool isSubmitting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
    );
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> submitComplaint({bool dummy = false}) async {
    // If dummy is true, we ignore empty fields
    String category = dummy ? 'General' : selectedCategory;
    String description =
        dummy ? 'This is a test complaint' : descriptionController.text;

    if (!dummy && (category.isEmpty || description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and enter description')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint added successfully')),
        );
        Navigator.pop(context, true); // Refresh ComplaintsScreen
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to add complaint')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Complaint',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple Banner
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
                    'ADD A COMPLAINT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Category Selection
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _buildCategoryButton('Academic', const Color(0xFFE1F5FE)),
                  _buildCategoryButton('Hostel', const Color(0xFFFFFDE7)),
                  _buildCategoryButton('Transport', const Color(0xFFF3E5F5)),
                  _buildCategoryButton('Harassment', const Color(0xFFE8F5E9)),
                  _buildCategoryButton('General', const Color(0xFFFFEBEE)),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              TextField(
                controller: descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your complaint here',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: const Color(0xFF9C27B0).withAlpha(50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // File Upload
              TextButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, color: Color(0xFF9C27B0)),
                label: const Text(
                  'Upload Document (Image/PDF)',
                  style: TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold),
                ),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text('Selected: $_fileName', style: const TextStyle(color: Colors.green, fontSize: 12)),
                ),
              const SizedBox(height: 40),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => submitComplaint(dummy: false), // submit user actual complaints
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA68C8),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label, Color color) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA68C8).withAlpha(50) : color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFBA68C8), width: 2) : null,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
