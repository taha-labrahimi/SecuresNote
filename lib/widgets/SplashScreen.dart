import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:secure_notes_app/screens/login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Start animation and navigate after it completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
  }

  void _navigateToNext() {
    Get.off(() => const LoginScreen());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EB), 
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          // Centered Animation
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6, 
              height: MediaQuery.of(context).size.width * 0.6, 
              child: Lottie.asset(
                'assets/animations/Animation2.json', 
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.forward();
                },
              ),
            ),
          ),
          const SizedBox(height: 16), 
          // Creative Text
          const Text(
            "Secure Notes",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C3C3C), 
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your notes, your security.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFFA0A0A0),
            ),
          ),
        ],
      ),
    );
  }
}
