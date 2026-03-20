import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/shared_prefs.dart';
import '../utils/api_config.dart';
import 'package:flockdesk/views/welcome_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginScreenBody();
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody({Key? key}) : super(key: key);

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody> {
  final TextEditingController _mobileEmailController = TextEditingController();
  final TextEditingController _otpField1Controller = TextEditingController();
  final TextEditingController _otpField2Controller = TextEditingController();
  final TextEditingController _otpField3Controller = TextEditingController();
  final TextEditingController _otpField4Controller = TextEditingController();
  final TextEditingController _otpField5Controller = TextEditingController();
  final TextEditingController _otpField6Controller = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileEmailController.dispose();
    _otpField1Controller.dispose();
    _otpField2Controller.dispose();
    _otpField3Controller.dispose();
    _otpField4Controller.dispose();
    _otpField5Controller.dispose();
    _otpField6Controller.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final email = _mobileEmailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/sendOtp')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully')),
        );
      } else {
        if (responseData['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['error'][0])),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send OTP')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyOtp() async {
    final email = _mobileEmailController.text.trim();
    final otp = _otpField1Controller.text +
        _otpField2Controller.text +
        _otpField3Controller.text +
        _otpField4Controller.text +
        _otpField5Controller.text +
        _otpField6Controller.text;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/loginWithotp')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await SharedPrefs.setToken(responseData['token']);
        final user = responseData['user'];
        if (user != null && user['profile_image'] != null) {
          user['profile_image'] = user['profile_image'];
        }
        await SharedPrefs.setUser(user);
        await SharedPrefs.setLoggedIn(true);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WelcomeScreen(
                userName: user['name'] ?? '',
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
        if (responseData['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['error'][0])),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to verify OTP')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isOtpSent ? _buildOtpVerificationForm() : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 25),
        const Text(
          'Hello There!\nLet’s Sign you in.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 36,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Welcome back you have been missed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF828282),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.50,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Enter your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF828282),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.30,
          ),
        ),
        SizedBox(height: 8,),
        Container(
          width: 371,
          height: 59,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: const Color(0xFFA9A9A9),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child:  TextField(
            controller: _mobileEmailController,
            keyboardType: TextInputType.text,

            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              // prefixIcon: Padding(
              //   padding: const EdgeInsets.all(12.0),
              //   child: Icon(Icons.email_outlined, color: Color(0xFFA9A9A9)),
              // ),

              hintStyle: const TextStyle(color: Color(0xFFA9A9A9), fontSize: 16),
              filled: true,
              fillColor: const Color(0x00ffffff),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),

            ),
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_right_alt, color: Colors.white, size: 24),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOtpVerificationForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 25),
        const Text(
          'We just send \nan SMS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 36,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter the security code we send to',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF828282),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.50,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mobileEmailController.text,
                style: TextStyle(
                  color: const Color(0xFF313131),
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  height: 1.50,
                ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, color: Color(0xFF828282), size: 20),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOtpTextField(_otpField1Controller, true),
            _buildOtpTextField(_otpField2Controller, false),
            _buildOtpTextField(_otpField3Controller, false),
            _buildOtpTextField(_otpField4Controller, false),
            _buildOtpTextField(_otpField5Controller, false),
            _buildOtpTextField(_otpField6Controller, false),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/resend_ic.png',
                height: 15,
                width: 15,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 5,),
              const Text(
                'Resent OTP',
                style: TextStyle(
                  color: const Color(0xFF2F2F2F),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  letterSpacing: 0.37,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOtpTextField(TextEditingController controller, bool autoFocus) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFEFEFEF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFEFEFEF), width: 1.0),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty) {
            FocusScope.of(context).previousFocus();
          }
          
          // Check if all 6 OTP fields are filled and auto-verify
          _checkAndAutoVerifyOtp();
        },
      ),
    );
  }

  void _checkAndAutoVerifyOtp() {
    final otp = _otpField1Controller.text +
        _otpField2Controller.text +
        _otpField3Controller.text +
        _otpField4Controller.text +
        _otpField5Controller.text +
        _otpField6Controller.text;

    if (otp.length == 6) {
      // Hide keyboard when all digits are entered
      FocusScope.of(context).unfocus();
      
      // Auto-verify OTP after a short delay to allow the last digit to be entered
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _verifyOtp();
        }
      });
    }
  }
}