import 'package:flutter/material.dart';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/cloudinary_service.dart';
import 'utils/phone_formatter.dart';
import 'package:flutter/services.dart';
import 'utils/ui_utils.dart';

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
  final _schoolAddressController = TextEditingController();

  Uint8List? _logoBytes;
  bool _isUploadingLogo = false;
  String? _uploadedLogoUrl;

  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _triedSubmit = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolAddressController.dispose();
    super.dispose();
  }

  String formatName(String value) {
    // Remove numbers
    String clean = value.replaceAll(RegExp(r'[0-9]'), '');
    // Capitalize first letter of each word
    return clean
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1).toLowerCase() : '');
        })
        .join(' ');
  }

  Future<void> _handleLogoUpload() async {
    setState(() {
      _isUploadingLogo = true;
    });

    try {
      String? url = await CloudinaryService.pickAndUploadImage(
        uploadPreset: 'School_Logos',
      );

      if (url != null) {
        setState(() {
          _uploadedLogoUrl = url;
        });
        if (mounted) {
          FeePalAlerts.showSuccess(
            context,
            Translations.get(
              'Logo uploaded successfully',
              languageNotifier.value,
            ),
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint("📡 [Network Error] SocketException during logo upload: $e");
      if (mounted) {
        FeePalAlerts.showError(
          context,
          'Network Error: Please check your internet connection and try uploading the logo again.',
        );
      }
    } catch (e) {
      debugPrint("❌ [Logo Upload Error] Unexpected error: $e");
      if (mounted) {
        FeePalAlerts.showError(context, 'Logo upload failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compression
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final sizeInMb = bytes.lengthInBytes / (1024 * 1024);

      if (sizeInMb > 2) {
        if (mounted) {
          FeePalAlerts.showError(context, 'Image size must be less than 2MB');
        }
        return;
      }

      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  String _formatPhone(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length >= 10) {
      return "+92 ${digits.substring(0, 3)} ${digits.substring(3)}";
    }
    return value.startsWith('+92') ? value : "+92 $value";
  }

  Future<void> _handleSignUp(bool isUrdu) async {
    final schoolName = formatName(_schoolNameController.text.trim());
    final adminName = formatName(_adminNameController.text.trim());
    final email = _emailController.text.trim();
    final phone = _formatPhone(_phoneController.text.trim());
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final schoolAddress = _schoolAddressController.text.trim();

    setState(() {
      _triedSubmit = true;
      // Update controllers with formatted names
      _schoolNameController.text = schoolName;
      _adminNameController.text = adminName;
      _phoneController.text = phone;
    });

    // 1. Basic Field Check
    if (schoolName.isEmpty ||
        adminName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        schoolAddress.isEmpty) {
      FeePalAlerts.showError(
        context,
        Translations.get('Please fill in all required fields.', isUrdu),
      );
      return;
    }

    // 2. Logo Check
    if (_logoBytes == null && _uploadedLogoUrl == null) {
      FeePalAlerts.showError(
        context,
        Translations.get('Please upload school logo.', isUrdu),
      );
      return;
    }

    // 3. Email Validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      FeePalAlerts.showError(
        context,
        Translations.get('Invalid email format.', isUrdu),
      );
      return;
    }

    // 4. Phone Validation (+92)
    if (!phone.startsWith('+92') || phone.replaceAll(' ', '').length < 13) {
      FeePalAlerts.showError(
        context,
        Translations.get(
          'Invalid phone number format. Must start with +92.',
          isUrdu,
        ),
      );
      return;
    }

    // 5. Password Validation
    if (password.length < 6) {
      FeePalAlerts.showError(
        context,
        Translations.get('Password must be at least 6 characters.', isUrdu),
      );
      return;
    }
    if (password != confirmPassword) {
      FeePalAlerts.showError(
        context,
        Translations.get('Passwords do not match.', isUrdu),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("⏳ [SignUpScreen] Attempting signup service call...");

      final error = await _firebaseService.signUpAdmin(
        schoolName: schoolName,
        adminName: adminName,
        email: email,
        phoneNumber: phone,
        password: password,
        schoolAddress: schoolAddress,
        logoBytes: _logoBytes,
        externalLogoUrl: _uploadedLogoUrl,
      );

      debugPrint(
        "📩 [SignUpScreen] Service returned: ${error ?? 'Success (null)'}",
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        FeePalAlerts.showSuccess(
          context,
          Translations.get('Account Created Successfully.', isUrdu),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final adminData = await _firebaseService.getAdminData(user.uid);
          if (mounted && adminData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(
                  email: email,
                  uid: user.uid,
                  adminData: adminData,
                ),
              ),
            );
          }
        }
      } else {
        FeePalAlerts.showError(context, error);
      }
    } on SocketException catch (e) {
      debugPrint("📡 [Network Error] SocketException during signup: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        FeePalAlerts.showError(
          context,
          'Network Error: Could not connect to FeePal. Please check your internet.',
        );
      }
    } catch (e) {
      debugPrint("🚨 [SignUpScreen] Caught exception in _handleSignUp: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        FeePalAlerts.showError(context, 'An unexpected error occurred: $e');
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool isError = _triedSubmit && controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          inputFormatters: inputFormatters,
          onChanged: (val) {
            if (_triedSubmit) setState(() {});
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF2168F8),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: isError,
            fillColor: isError ? Colors.red.withValues(alpha: 0.1) : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isError ? Colors.red : Colors.black26,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isError ? Colors.red : Colors.black26,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isError ? Colors.red : const Color(0xFF2972FF),
                width: 2,
              ),
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
                              // Section: School Information
                              _buildSectionHeader(
                                Translations.get('School Information', isUrdu),
                              ),
                              const SizedBox(height: 15),

                              // Logo Picker
                              Center(
                                child: GestureDetector(
                                  onTap: _isUploadingLogo
                                      ? null
                                      : _handleLogoUpload,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue.withValues(
                                              alpha: 0.5,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _isUploadingLogo
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : (_uploadedLogoUrl != null
                                                    ? Image.network(
                                                        _uploadedLogoUrl!,
                                                        fit: BoxFit.cover,
                                                        width: 100,
                                                        height: 100,
                                                        loadingBuilder:
                                                            (
                                                              context,
                                                              child,
                                                              loadingProgress,
                                                            ) {
                                                              if (loadingProgress ==
                                                                  null) {
                                                                return child;
                                                              }
                                                              return const Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              );
                                                            },
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              debugPrint(
                                                                "❌ Network Image Error: $error",
                                                              );
                                                              return const Icon(
                                                                Icons
                                                                    .error_outline,
                                                                color:
                                                                    Colors.red,
                                                              );
                                                            },
                                                      )
                                                    : (_logoBytes != null
                                                          ? Image.memory(
                                                              _logoBytes!,
                                                              fit: BoxFit.cover,
                                                              width: 100,
                                                              height: 100,
                                                            )
                                                          : const Icon(
                                                              Icons.camera_alt,
                                                              color:
                                                                  Colors.blue,
                                                              size: 30,
                                                            ))),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          text: _isUploadingLogo
                                              ? Translations.get(
                                                  'Processing...',
                                                  isUrdu,
                                                )
                                              : Translations.get(
                                                  'Upload School Logo',
                                                  isUrdu,
                                                ),
                                          style: TextStyle(
                                            color:
                                                (_triedSubmit &&
                                                    _logoBytes == null &&
                                                    _uploadedLogoUrl == null)
                                                ? Colors.red
                                                : Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

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
                                controller: _schoolAddressController,
                                label: Translations.get(
                                  'School Address',
                                  isUrdu,
                                ),
                                hintText: Translations.get(
                                  'Enter school address',
                                  isUrdu,
                                ),
                                icon: Icons.location_on_outlined,
                              ),

                              const SizedBox(height: 10),
                              // Section: Admin Information
                              _buildSectionHeader(
                                Translations.get('Admin Information', isUrdu),
                              ),
                              const SizedBox(height: 15),

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
                                inputFormatters: [CustomPhoneFormatter()],
                              ),
                              _buildTextField(
                                controller: _passwordController,
                                label: Translations.get('Password', isUrdu),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: _obscurePassword,
                                onToggleVisibility: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: Translations.get(
                                  'Confirm Password',
                                  isUrdu,
                                ),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: _obscurePassword,
                                onToggleVisibility: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handleSignUp(isUrdu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2972FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          Translations.get(
                                            'Create Account',
                                            isUrdu,
                                          ),
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
                                    onTap: () => Navigator.pop(context),
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

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2168F8),
        ),
      ),
    );
  }
}
