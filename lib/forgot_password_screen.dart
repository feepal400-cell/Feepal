import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'language_config.dart';
import 'change_password_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final bool isLoggedIn;
  const ForgotPasswordScreen({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2168F8), // Top blue colour
                    Color(0xFF00D4FF), // Bottom cyan colour
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            Translations.get('Forgot Password', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                Translations.get(
                                  'Enter your registered email or phone number to receive a verification code.',
                                  isUrdu,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Email / Phone
                              Text(
                                Translations.get('Email / Phone', isUrdu),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: Translations.get(
                                    'Enter email or phone',
                                    isUrdu,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Colors.black54,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 15,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                      color: Colors.black26,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Send OTP Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OtpScreen(
                                          onVerify: () {
                                            // Close the OTP screen entirely when moving forward?
                                            // Actually replace simply moves from OTP to Change Password.
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangePasswordScreen(isLoggedIn: isLoggedIn),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2972FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    Translations.get('Send OTP', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
