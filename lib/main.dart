import 'package:flutter/material.dart';
import 'package:complaint_desk_ai/screens/splash_screen.dart'; // Import SplashScreen

void main() {
  runApp(const ComplaintDeskAI());
}

class ComplaintDeskAI extends StatelessWidget {
  const ComplaintDeskAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComplaintDesk.AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C27B0)),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Set SplashScreen as initial route
    );
  }
}
