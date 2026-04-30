import 'package:flutter/material.dart';
import 'user_login_screen.dart';
import 'signup_screen.dart';
import 'language_config.dart';
import 'navigation_helper.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenHeight = size.height;
    final screenWidth = size.width;

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      // White Card with Logo
                      Container(
                        height: screenHeight * 0.45,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.1),
                            child: Image.asset(
                              'assets/Feepal Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                      // Welcome Text
                      Text(
                        Translations.get('Welcome to FeePal', isUrdu),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Translations.get('Manage school payments effortlessly', isUrdu),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 2),
                      // Action Buttons
                      Column(
                        children: [
                          _buildButton(
                            text: Translations.get('Login', isUrdu),
                            color: Colors.white,
                            textColor: const Color(0xFF2168F8),
                            onPressed: () {
                              navigateWithLoader(context, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildButton(
                            text: Translations.get('Sign Up', isUrdu),
                            color: const Color(0xFF00D4FF),
                            textColor: Colors.white,
                            onPressed: () {
                              navigateWithLoader(context, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Urdu Switch Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: TextButton(
                              onPressed: () => languageNotifier.toggle(),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                Translations.get('Switch to Urdu | اردو', isUrdu),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
