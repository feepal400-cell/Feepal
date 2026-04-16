import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'language_config.dart';
import 'forgot_password_screen.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'navigation_helper.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  bool isParentSelected = false;

  Color get _primaryAccentColor =>
      isParentSelected ? const Color(0xFF00D4FF) : const Color(0xFF2168F8);

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
                    Color(0xFF2168F8),
                    Color(0xFF00D4FF),
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
                        horizontal: 20.0,
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
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            Translations.get('Login', isUrdu),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Logo Card
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(25.0),
                                  child: Image.asset(
                                    'assets/Feepal Logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Form Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.all(25.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Login As
                                  Text(
                                    Translations.get('Login as', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => isParentSelected = false,
                                          ),
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: !isParentSelected
                                                  ? _primaryAccentColor
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                Translations.get('Admin', isUrdu),
                                                style: TextStyle(
                                                  color: !isParentSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => isParentSelected = true),
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: isParentSelected
                                                  ? _primaryAccentColor
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                Translations.get('Parent', isUrdu),
                                                style: TextStyle(
                                                  color: isParentSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 25),

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
                                      hintText: Translations.get('Enter email or phone', isUrdu),
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

                                  const SizedBox(height: 20),

                                  // Password
                                  Text(
                                    Translations.get('Password', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: '********',
                                      hintStyle: const TextStyle(
                                        color: Colors.black38,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
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

                                  const SizedBox(height: 10),

                                  // Forgot Password
                                  Align(
                                    alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        navigateWithLoader(context, () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ForgotPasswordScreen(),
                                            ),
                                          );
                                        });
                                      },
                                      child: Text(
                                        Translations.get('Forgot Password?', isUrdu),
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (!isParentSelected) {
                                          navigateWithLoader(context, () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const AdminDashboardScreen(),
                                              ),
                                            );
                                          });
                                        } else {
                                          navigateWithLoader(context, () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ParentDashboardScreen(),
                                              ),
                                            );
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryAccentColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        Translations.get('Login', isUrdu),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Sign up
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        Translations.get("Don't have an account? ", isUrdu),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          navigateWithLoader(context, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const SignUpScreen(),
                                              ),
                                            );
                                          });
                                        },
                                        child: Text(
                                          Translations.get('Sign up', isUrdu),
                                          style: TextStyle(
                                            color: Colors.blue[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Urdu Switch Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextButton(
                          onPressed: () {
                            languageNotifier.toggle();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            Translations.get('Switch to Urdu | اردو', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
