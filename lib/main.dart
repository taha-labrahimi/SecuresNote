import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secure_notes_app/screens/admin/admin_dashboard_screen.dart';
import 'package:secure_notes_app/screens/login/create_account_screen.dart';
import 'package:secure_notes_app/screens/login/login_screen.dart';
import 'package:secure_notes_app/screens/home/home_screen.dart';
import 'package:secure_notes_app/widgets/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins', // Apply Poppins globally
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      home: const SplashScreen(), // Start with the splash screen
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/signup', page: () => const CreateAccountScreen()),
        GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
      ],
    );
  }
}
