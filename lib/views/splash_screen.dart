import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await SharedPrefs.isLoggedIn();
    if (loggedIn) {
      final user = await SharedPrefs.getUser();
      final userName = user != null && user['name'] != null ? user['name'] : '';
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              userName: userName,
              onLetsGo: (ctx) {
                Navigator.pushReplacement(
                  ctx,
                  MaterialPageRoute(builder: (ctx) => const HomeScreen()),
                );
              },
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/mindlabs_logo.png', height: 114),
      ),
    );
  }
}
