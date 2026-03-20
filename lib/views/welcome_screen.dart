import 'package:flutter/material.dart';


class WelcomeScreen extends StatelessWidget {
  final String userName;
  final void Function(BuildContext) onLetsGo;
  const WelcomeScreen({super.key, required this.userName, required this.onLetsGo});

  @override
  Widget build(BuildContext context) {
    return _WelcomeScreenBody(userName: userName, onLetsGo: onLetsGo);
  }
}

class _WelcomeScreenBody extends StatefulWidget {
  final String userName;
  final void Function(BuildContext) onLetsGo;
  const _WelcomeScreenBody({required this.userName, required this.onLetsGo});

  @override
  State<_WelcomeScreenBody> createState() => _WelcomeScreenBodyState();
}

class _WelcomeScreenBodyState extends State<_WelcomeScreenBody> {
  @override
  void initState() {
    super.initState();
    // Automatically redirect to home screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onLetsGo(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_small.png',
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 5,),
                      Text(
                        'Flock Desk',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 36),

                  Text(
                    'Welcome Back, \n${widget.userName}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What Happening with your\nBusiness today',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF828282),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/lets_go.png',
                        width: 250,
                        height: 250,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 