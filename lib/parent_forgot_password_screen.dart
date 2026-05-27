import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'language_config.dart';
import 'services/email_service.dart';
import 'services/firebase_service.dart';
import 'widgets/throttled_button.dart';

enum ParentForgotPasswordStep { email, otp }

class ParentForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ParentForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ParentForgotPasswordScreen> createState() => _ParentForgotPasswordScreenState();
}

class _ParentForgotPasswordScreenState extends State<ParentForgotPasswordScreen> with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  final EmailService _emailService = EmailService();
  
  String? _otpError;
  
  // Step 0: Email
  final TextEditingController _emailController = TextEditingController();
  
  // Step 1: OTP
  final TextEditingController _otpController = TextEditingController();
  String? _generatedOTP;
  Map<String, dynamic>? _userTypeData;

  ParentForgotPasswordStep _currentStep = ParentForgotPasswordStep.email;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOTP();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentStep == ParentForgotPasswordStep.otp) {
      _checkClipboardForOTP();
    }
  }

  Future<void> _checkClipboardForOTP() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (RegExp(r'^\d{6}$').hasMatch(text)) {
      setState(() {
        _otpController.text = text;
        _otpError = null;
      });
      _verifyOTP();
    }
  }

  void _sendOTP() async {
    final email = _emailController.text.trim();
    final isUrdu = languageNotifier.value;

    if (email.isEmpty) {
      _showSnack(Translations.get('Please enter email', isUrdu));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await _firebaseService.checkUserType(email);
      if (userData == null || userData['role'] != 'parent') {
        _showSnack(Translations.get('No parent account found with this email.', isUrdu));
        return;
      }

      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOTP = otp;
      _userTypeData = userData;

      final success = await _emailService.sendVerificationOTP(
        userEmail: email, 
        otpCode: otp, 
        reason: 'password reset',
      );

      if (success) {
        setState(() => _currentStep = ParentForgotPasswordStep.otp);
        _showSnack('${Translations.get('OTP sent to', isUrdu)} $email', isError: false);
      } else {
        _showSnack(Translations.get('Failed to send OTP. Please try again.', isUrdu));
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() {
    setState(() => _otpError = null);
    if (_otpController.text.trim() == _generatedOTP) {
      _showResetPasswordBottomSheet();
    } else {
      setState(() => _otpError = Translations.get('Invalid OTP code. Please check again.', languageNotifier.value));
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }

  void _showSuccessDialog() {
    final isUrdu = languageNotifier.value;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Password Updated!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(Translations.get('Your password has been reset successfully. You can now login with your new password.', isUrdu), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                // Return to login screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(Translations.get('OK', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordBottomSheet() {
    final isUrdu = languageNotifier.value;
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscurePasswords = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                left: 24,
                right: 24,
                top: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('New Password', isUrdu),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Translations.get('Please set a strong password for your account.', isUrdu),
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  _buildBottomSheetTextField(
                    controller: newPasswordController,
                    label: Translations.get('New Password', isUrdu),
                    hint: Translations.get('Minimum 6 characters', isUrdu),
                    icon: Icons.lock_outline,
                    obscureText: obscurePasswords,
                    suffixIcon: IconButton(
                      icon: Icon(obscurePasswords ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setSheetState(() => obscurePasswords = !obscurePasswords),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBottomSheetTextField(
                    controller: confirmPasswordController,
                    label: Translations.get('Confirm New Password', isUrdu),
                    hint: Translations.get('Repeat your password', isUrdu),
                    icon: Icons.lock_reset_outlined,
                    obscureText: obscurePasswords,
                    suffixIcon: IconButton(
                      icon: Icon(obscurePasswords ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setSheetState(() => obscurePasswords = !obscurePasswords),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ThrottledButton.elevated(
                      onPressed: isSaving ? () {} : () async {
                        final newPass = newPasswordController.text;
                        final confirmPass = confirmPasswordController.text;

                        if (newPass.length < 6) {
                          _showSnack(Translations.get('Password must be at least 6 characters.', isUrdu));
                          return;
                        }
                        if (newPass != confirmPass) {
                          _showSnack(Translations.get('Passwords do not match.', isUrdu));
                          return;
                        }

                        setSheetState(() => isSaving = true);

                        try {
                          final success = await _firebaseService.resetPasswordManual(
                            _emailController.text.trim(),
                            newPass,
                            'parent',
                          );

                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context); // Close bottom sheet
                              _showSuccessDialog();
                            } else {
                              _showSnack(Translations.get('Failed to update password. Please try again.', isUrdu));
                            }
                          }
                        } catch (e) {
                          _showSnack(e.toString());
                        } finally {
                          if (mounted) setSheetState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2972FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(Translations.get('Update Password', isUrdu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildBottomSheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF2168F8))),
          ),
        ),
      ],
    );
  }

  // --- UI BUILDERS ---

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
                    _buildTopBar(isUrdu),
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
                          child: _buildStepContent(isUrdu),
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

  Widget _buildTopBar(bool isUrdu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            height: 45, width: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            Translations.get('Forgot Password', isUrdu),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isUrdu) {
    switch (_currentStep) {
      case ParentForgotPasswordStep.email:
        return _buildEmailStep(isUrdu);
      case ParentForgotPasswordStep.otp:
        return _buildOTPStep(isUrdu);
    }
  }

  Widget _buildEmailStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          Translations.get('Enter your registered email to receive a verification OTP code.', isUrdu),
          style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _emailController,
          label: Translations.get('Email Address', isUrdu),
          hint: Translations.get('Enter your email', isUrdu),
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          text: Translations.get('Send OTP', isUrdu),
          onPressed: _sendOTP,
        ),
      ],
    );
  }

  Widget _buildOTPStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          Translations.get('Verify OTP', isUrdu),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
        ),
        const SizedBox(height: 10),
        Text(
          '${Translations.get('We have sent a 6-digit verification code to', isUrdu)} ${_emailController.text}. ${Translations.get('Please enter it below.', isUrdu)}',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _otpController,
          label: Translations.get('OTP Code', isUrdu),
          hint: Translations.get('Enter 6-digit code', isUrdu),
          icon: Icons.lock_clock_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (val) {
            if (val.length == 6) {
              _verifyOTP();
            } else if (_otpError != null) {
              setState(() => _otpError = null);
            }
          },
        ),
        if (_otpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _otpError!,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          text: Translations.get('Verify Code', isUrdu),
          onPressed: _verifyOTP,
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = ParentForgotPasswordStep.email),
            child: Text(Translations.get('Change Email', isUrdu), style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF2168F8))),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ThrottledButton.elevated(
        onPressed: _isLoading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2972FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
