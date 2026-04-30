import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'language_config.dart';
import 'forgot_password_screen.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'navigation_helper.dart';
import 'package:main_dart/services/firebase_service.dart';
import 'subscription_screen.dart';
import 'super_admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool isParentSelected = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(bool isUrdu) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('Please fill in all required fields.', isUrdu),
          ),
        ),
      );
      return;
    }

    if (!isParentSelected) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.get('Invalid email format.', isUrdu)),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    String? error;
    if (isParentSelected) {
      error = await _firebaseService.loginParent(
        email: email,
        password: password,
      );
    } else {
      error = await _firebaseService.login(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      if (isParentSelected) {
        if (_firebaseService.selectedStudent != null) {
          final session = _firebaseService.selectedStudent!;
          _firebaseService.checkAndSendWelcomeNotification(
            session['adminId'],
            session['rollNumber'].toString(),
          );
        }
        navigateWithLoader(context, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
          );
        });
      } else {
        // Admin Login Logic
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Auto-initialize Super Admin document if email matches
          await _firebaseService.ensureSuperAdminDocument(user.uid, user.email ?? '');
          
          final adminData = await _firebaseService.getAdminData(user.uid);
          if (adminData != null) {
            String role = adminData['role'] ?? 'admin';
            String? subStatus = adminData['subscriptionStatus'];

            navigateWithLoader(context, () {
              if (role == 'super_admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
                );
              } else if (subStatus == null || subStatus == 'approved') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionScreen(adminData: adminData)),
                );
              }
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

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
                  colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
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
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
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
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                Translations.get(
                                                  'Admin',
                                                  isUrdu,
                                                ),
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
                                          onTap: () => setState(
                                            () => isParentSelected = true,
                                          ),
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: isParentSelected
                                                  ? _primaryAccentColor
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                Translations.get(
                                                  'Parent',
                                                  isUrdu,
                                                ),
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
                                    controller: _emailController,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
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
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: _primaryAccentColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    alignment: isUrdu
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        navigateWithLoader(context, () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          );
                                        });
                                      },
                                      child: Text(
                                        Translations.get(
                                          'Forgot Password?',
                                          isUrdu,
                                        ),
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
                                      onPressed: _isLoading
                                          ? null
                                          : () => _handleLogin(isUrdu),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryAccentColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
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
                                        Translations.get(
                                          "Don't have an account? ",
                                          isUrdu,
                                        ),
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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
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
