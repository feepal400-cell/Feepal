import 'package:flutter/material.dart';
import 'loginscreen.dart';

void main() {
  runApp(const FeePalApp());
}

class FeePalApp extends StatelessWidget {
  const FeePalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FeePal',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily:
            'Inter', // You can use google_fonts package for a better match
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for 3 seconds before navigating to the Welcome Screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Image.asset('assets/Feepal Logo.png')));
  }
}
