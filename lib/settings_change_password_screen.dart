import 'package:flutter/material.dart';
import 'language_config.dart';
import 'forgot_password_screen.dart';
import 'user_login_screen.dart';
import 'services/firebase_service.dart';

class SettingsChangePasswordScreen extends StatefulWidget {
  const SettingsChangePasswordScreen({super.key});

  @override
  State<SettingsChangePasswordScreen> createState() => _SettingsChangePasswordScreenState();
}

class _SettingsChangePasswordScreenState extends State<SettingsChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isUpdating = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _handleChangePassword() async {
    bool isUrdu = languageNotifier.value;
    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _showError(Translations.get('Please enter current password', isUrdu));
      return;
    }

    if (newPassword.isEmpty) {
      _showError(Translations.get('Please enter new password', isUrdu));
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError(Translations.get('Please confirm new password', isUrdu));
      return;
    }

    if (newPassword.length < 6) {
      _showError(Translations.get('Password must be at least 6 characters', isUrdu));
      return;
    }

    if (newPassword != confirmPassword) {
      _showError(Translations.get('Passwords do not match', isUrdu));
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // 1. Re-authenticate or just try to update
      // Firebase usually requires recent login for password changes.
      // For simplicity here, we assume recent login or use the service method.
      await _firebaseService.updateAdminPassword(newPassword);

      if (mounted) {
        // Show success popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Directionality(
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                      const SizedBox(height: 15),
                      Text(
                        Translations.get('Password changed successfully', isUrdu),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close success dialog
                            _performAutoLogout(isUrdu);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2168F8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(Translations.get('OK', isUrdu), style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('requires-recent-login')) {
          errorMsg = Translations.get('Please login again to change password', isUrdu);
        }
        _showError(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _performAutoLogout(bool isUrdu) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UserLoginScreen()),
      (route) => false,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                            Translations.get('Change Password', isUrdu),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_outline, size: 70, color: Color(0xFF2168F8)),
                                ),
                              ),
                              const SizedBox(height: 35),
                              Text(
                                Translations.get('Current Password', isUrdu),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                                TextField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrent,
                                  decoration: InputDecoration(
                                    hintText: Translations.get('Enter current password', isUrdu),
                                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                Translations.get('New Password', isUrdu),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  decoration: InputDecoration(
                                    hintText: Translations.get('Enter new password', isUrdu),
                                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                Translations.get('Confirm Password', isUrdu),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: Translations.get('Confirm new password', isUrdu),
                                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black26)),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              Align(
                                alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen(isLoggedIn: true)),
                                    );
                                  },
                                  child: Text(
                                    Translations.get('Forgot Password?', isUrdu),
                                    style: const TextStyle(color: Color(0xFF2168F8), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isUpdating ? null : _handleChangePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2168F8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 0,
                                  ),
                                  child: _isUpdating 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        Translations.get('Change Password', isUrdu),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
