import 'package:flutter/material.dart';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'change_password_otp_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String role; // 'admin' or 'parent'
  const ChangePasswordScreen({super.key, required this.role});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Error Handling State
  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _bannerMessage;
  bool _showBanner = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- ERROR HANDLING HELPERS ---

  String _mapErrorCode(String code, bool isUrdu) {
    switch (code) {
      case 'wrong-password':
      case 'auth/wrong-password':
      case 'incorrect-password':
        return Translations.get("Incorrect current password.", isUrdu);
      case 'network-request-failed':
        return Translations.get("Network error. Please check your internet connection.", isUrdu);
      case 'too-many-requests':
        return Translations.get("Too many attempts. Please try again later.", isUrdu);
      default:
        return code.contains('/') ? Translations.get("Operation failed. Please try again.", isUrdu) : code;
    }
  }

  void _showErrorBanner(String message) {
    if (!mounted) return;
    setState(() {
      _bannerMessage = message;
      _showBanner = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showBanner = false);
      }
    });
  }

  bool _validateInputs(bool isUrdu) {
    bool isValid = true;
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Current Password
    if (currentPass.isEmpty) {
      _currentError = Translations.get('Password is required', isUrdu);
      isValid = false;
    } else {
      _currentError = null;
    }

    // New Password
    if (newPass.isEmpty) {
      _newError = Translations.get('Password is required', isUrdu);
      isValid = false;
    } else if (newPass.length < 6) {
      _newError = Translations.get('Minimum 6 characters', isUrdu);
      isValid = false;
    } else if (newPass == currentPass && currentPass.isNotEmpty) {
      _newError = Translations.get('New password cannot be same as current', isUrdu);
      isValid = false;
    } else {
      _newError = null;
    }

    // Confirm Password
    if (confirmPass.isEmpty) {
      _confirmError = Translations.get('Password is required', isUrdu);
      isValid = false;
    } else if (confirmPass != newPass) {
      _confirmError = Translations.get('Passwords do not match', isUrdu);
      isValid = false;
    } else {
      _confirmError = null;
    }

    setState(() {});
    return isValid;
  }

  void _handleChangePassword() async {
    final isUrdu = languageNotifier.value;
    if (!_validateInputs(isUrdu)) return;

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    setState(() {
      _isLoading = true;
      _showBanner = false;
    });

    try {
      // 1. Verify Current Password
      final isCurrentCorrect = await _firebaseService.verifyCurrentPassword(currentPass, widget.role);
      
      if (!isCurrentCorrect) {
        setState(() => _isLoading = false);
        _showErrorBanner(_mapErrorCode('incorrect-password', isUrdu));
        return;
      }

      // 2. Get User Email/Info
      String? email;
      String? uid;
      
      if (widget.role == 'admin') {
        final profile = await _firebaseService.getAdminProfile();
        email = profile?['email'];
        uid = _firebaseService.currentAdminId;
      } else {
        final session = _firebaseService.selectedStudent;
        email = session?['parentEmail'] ?? session?['parentPhone']; // identifier
        uid = session?['docId'];
      }

      if (email == null || email.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorBanner(Translations.get('User contact info not found.', isUrdu));
        return;
      }

      // 3. Send OTP
      final student = _firebaseService.selectedStudent;
      bool otpSent = await _firebaseService.sendOTP(
        email: email, 
        uid: uid ?? "", 
        isParent: widget.role == 'parent',
        adminId: widget.role == 'parent' ? (student?['adminId'] as String?) : null,
      );

      if (otpSent) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordOTPScreen(
                email: email!,
                uid: uid ?? "",
                role: widget.role,
                newPassword: newPass,
                currentPassword: currentPass,
                adminId: widget.role == 'parent' ? (student?['adminId'] as String?) : null,
              ),
            ),
          );
        }
      } else {
        _showErrorBanner(Translations.get('Failed to send OTP. Please try again.', isUrdu));
      }
    } catch (e) {
      _showErrorBanner(_mapErrorCode(e.toString(), isUrdu));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final bool isParent = widget.role == 'parent';
    final List<Color> gradientColors = isParent 
        ? [const Color(0xFF00D4FF), const Color(0xFF009BCB)]
        : [const Color(0xFF2168F8), const Color(0xFF00D4FF)];

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                Translations.get('Change Password', isUrdu),
                                style: TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold, 
                                  color: gradientColors[0],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                Translations.get('Secure your account by updating your password.', isUrdu),
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 40),
                              
                              _buildTextField(
                                controller: _currentPasswordController,
                                label: Translations.get('Current Password', isUrdu),
                                hint: '********',
                                icon: Icons.lock_outline,
                                obscureText: _obscureCurrent,
                                errorText: _currentError,
                                onChanged: (v) => _validateInputs(isUrdu),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              _buildTextField(
                                controller: _newPasswordController,
                                label: Translations.get('New Password', isUrdu),
                                hint: Translations.get('Minimum 6 characters', isUrdu),
                                icon: Icons.vpn_key_outlined,
                                obscureText: _obscureNew,
                                errorText: _newError,
                                onChanged: (v) => _validateInputs(isUrdu),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: Translations.get('Confirm New Password', isUrdu),
                                hint: Translations.get('Repeat your password', isUrdu),
                                icon: Icons.lock_reset_outlined,
                                obscureText: _obscureConfirm,
                                errorText: _confirmError,
                                onChanged: (v) => _validateInputs(isUrdu),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              _buildPrimaryButton(
                                text: Translations.get('Change Password', isUrdu),
                                color: gradientColors[0],
                                onPressed: _handleChangePassword,
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
                _topBannerNotifier(),
              ],
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
            Translations.get('Settings', isUrdu),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorStyle: const TextStyle(height: 0.8),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBannerNotifier() {
    final bool isUrdu = languageNotifier.value;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      top: _showBanner ? 40 : -120,
      left: 20,
      right: 20,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFF5F5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Translations.get('Change Password Error', isUrdu),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _bannerMessage ?? "",
                      style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: Colors.redAccent),
                onPressed: () => setState(() => _showBanner = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
