import 'package:flockdesk/views/splash_screen.dart';

import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'views/inbox_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlockDeskApp());
}

class FlockDeskApp extends StatelessWidget {
  const FlockDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flock Desk',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
         ),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/inbox': (context) => const InboxScreen(),
      },
    );
  }
}