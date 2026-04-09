import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'language_config.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  Widget _buildTextField({
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
                              color: Colors.white.withOpacity(0.3),
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
                                label: Translations.get('School Name', isUrdu),
                                hintText: Translations.get(
                                  'Enter school name',
                                  isUrdu,
                                ),
                                icon: Icons.account_balance_outlined,
                              ),
                              _buildTextField(
                                label: Translations.get('Admin Name', isUrdu),
                                hintText: Translations.get(
                                  'Enter your name',
                                  isUrdu,
                                ),
                                icon: Icons.person_outline,
                              ),
                              _buildTextField(
                                label: Translations.get('Email', isUrdu),
                                hintText: 'admin@school.com',
                                icon: Icons.email_outlined,
                              ),
                              _buildTextField(
                                label: Translations.get('Phone Number', isUrdu),
                                hintText: '+92 300 1234567',
                                icon: Icons.phone_outlined,
                              ),
                              _buildTextField(
                                label: Translations.get('Password', isUrdu),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),
                              _buildTextField(
                                label: Translations.get(
                                  'Confirm Password',
                                  isUrdu,
                                ),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),
                              _buildTextField(
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
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const OtpScreen(),
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
