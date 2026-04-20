import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'services/firebase_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolCodeController = TextEditingController();

  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(bool isUrdu) async {
    final schoolName = _schoolNameController.text.trim();
    final adminName = _adminNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final schoolCode = _schoolCodeController.text.trim();

    if (schoolName.isEmpty ||
        adminName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('Please fill in all required fields.', isUrdu),
          ),
        ),
      );
      return;
    }

    // Basic Email Validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('Invalid email format.', isUrdu)),
        ),
      );
      return;
    }

    // Password Length Validation
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('Password must be at least 6 characters.', isUrdu),
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('Passwords do not match.', isUrdu)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("⏳ [SignUpScreen] Attempting signup service call...");
      
      // Use .timeout to prevent infinite hangs
      final error = await _firebaseService.signUpAdmin(
        schoolName: schoolName,
        adminName: adminName,
        email: email,
        phoneNumber: phone,
        password: password,
        schoolCode: schoolCode.isEmpty ? null : schoolCode,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint("⏰ [SignUpScreen] Signup request timed out after 20s");
          return "Request timed out. Please check your internet connection and try again.";
        },
      );

      debugPrint("📩 [SignUpScreen] Service returned: ${error ?? 'Success (null)'}");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        debugPrint("🎉 [SignUpScreen] Success! Navigating to AdminDashboard...");
        // Success: Show Success Snackbar and Navigate to Admin Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.get('Account Created Successfully.', isUrdu),
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          (route) => false, // Clear all the stack underneath
        );
      } else {
        debugPrint("⚠️ [SignUpScreen] Showing error SnackBar: $error");
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      debugPrint("🚨 [SignUpScreen] Caught exception in _handleSignUp: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

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
                            Translations.get('Sign Up', isUrdu),
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
                              _buildTextField(
                                controller: _schoolNameController,
                                label: Translations.get('School Name', isUrdu),
                                hintText: Translations.get(
                                  'Enter school name',
                                  isUrdu,
                                ),
                                icon: Icons.account_balance_outlined,
                              ),
                              _buildTextField(
                                controller: _adminNameController,
                                label: Translations.get('Admin Name', isUrdu),
                                hintText: Translations.get(
                                  'Enter your name',
                                  isUrdu,
                                ),
                                icon: Icons.person_outline,
                              ),
                              _buildTextField(
                                controller: _emailController,
                                label: Translations.get('Email', isUrdu),
                                hintText: 'admin@school.com',
                                icon: Icons.email_outlined,
                              ),
                              _buildTextField(
                                controller: _phoneController,
                                label: Translations.get('Phone Number', isUrdu),
                                hintText: '+92 300 1234567',
                                icon: Icons.phone_outlined,
                              ),
                              _buildTextField(
                                controller: _passwordController,
                                label: Translations.get('Password', isUrdu),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: Translations.get(
                                  'Confirm Password',
                                  isUrdu,
                                ),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),
                              _buildTextField(
                                controller: _schoolCodeController,
                                label: Translations.get(
                                  'School Code (Optional)',
                                  isUrdu,
                                ),
                                hintText: 'SCH - 12345',
                                icon: Icons.vpn_key_outlined,
                              ),

                              const SizedBox(height: 10),

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _handleSignUp(isUrdu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2972FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          Translations.get('Create Account', isUrdu),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Translations.get(
                                      "Already have an account? ",
                                      isUrdu,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(
                                        context,
                                      ); // Go back to login
                                    },
                                    child: Text(
                                      Translations.get('Login', isUrdu),
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
