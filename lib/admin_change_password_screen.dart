import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'login_screen.dart';

enum AdminPasswordFlowState {
  initial,
  otpSent,
  otpVerified,
}

class AdminChangePasswordScreen extends StatefulWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  State<AdminChangePasswordScreen> createState() => _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState extends State<AdminChangePasswordScreen> with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AdminPasswordFlowState _flowState = AdminPasswordFlowState.initial;
  
  // Input Controllers
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  
  String? _adminEmail;
  String? _adminUid;
  
  int _resendTimer = 60;
  Timer? _timer;

  // Error Handling State
  String? _bannerMessage;
  bool _showBanner = false;
  
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAdminData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _flowState == AdminPasswordFlowState.otpSent) {
      _checkClipboardForOTP();
    }
  }

  Future<void> _loadAdminData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _adminEmail = user.email;
        _adminUid = user.uid;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkClipboardForOTP() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        String text = data!.text!.trim();
        RegExp otpRegExp = RegExp(r'^\d{6}$');
        if (otpRegExp.hasMatch(text)) {
          for (int i = 0; i < 6; i++) {
            _otpControllers[i].text = text[i];
          }
          _verifyOTP();
        }
      }
    } catch (e) {
      debugPrint("Clipboard error: $e");
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

  String _mapErrorCode(String code, bool isUrdu) {
    switch (code) {
      case 'invalid-otp':
      case 'Wrong OTP Code':
        return Translations.get('Wrong OTP Code', isUrdu);
      case 'network-request-failed':
        return Translations.get("Network error. Please check your internet connection.", isUrdu);
      case 'too-many-requests':
        return Translations.get("Too many attempts. Please try again later.", isUrdu);
      case 'requires-recent-login':
        return Translations.get("Session expired. Please re-authenticate.", isUrdu);
      default:
        return code.contains('/') ? Translations.get("Operation failed. Please try again.", isUrdu) : code;
    }
  }

  Future<void> _sendOTP() async {
    if (_adminEmail == null || _adminUid == null) {
      _showErrorBanner(Translations.get('User info not found. Please log out and log in again.', languageNotifier.value));
      return;
    }

    setState(() {
      _isLoading = true;
      _showBanner = false;
    });

    bool otpSent = await _firebaseService.sendOTP(
      email: _adminEmail!,
      uid: _adminUid!,
      isParent: false,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (otpSent) {
        setState(() {
          _flowState = AdminPasswordFlowState.otpSent;
        });
        _startTimer();
      } else {
        _showErrorBanner(Translations.get('Failed to send OTP. Please try again.', languageNotifier.value));
      }
    }
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _showBanner = false;
    });
    
    final isUrdu = languageNotifier.value;

    try {
      final result = await _firebaseService.verifyOTP(
        uid: _adminUid!,
        code: otp,
        isParent: false,
      );

      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _flowState = AdminPasswordFlowState.otpVerified;
          });
        }
      } else {
        _showErrorBanner(_mapErrorCode('invalid-otp', isUrdu));
      }
    } catch (e) {
      _showErrorBanner(_mapErrorCode(e.toString(), isUrdu));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateNewPassword(bool isUrdu) {
    bool isValid = true;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      _newError = Translations.get('Password is required', isUrdu);
      isValid = false;
    } else if (newPass.length < 6) {
      _newError = Translations.get('Minimum 6 characters', isUrdu);
      isValid = false;
    } else {
      _newError = null;
    }

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

  Future<void> _updatePassword() async {
    final isUrdu = languageNotifier.value;
    if (!_validateNewPassword(isUrdu)) return;

    final newPass = _newPasswordController.text;

    setState(() {
      _isLoading = true;
      _showBanner = false;
    });

    try {
      await _auth.currentUser!.updatePassword(newPass);
      // Success
      await _handleSuccessfulUpdate(isUrdu);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() => _isLoading = false);
        _promptForReauthentication(isUrdu, newPass);
      } else {
        _showErrorBanner(_mapErrorCode(e.code, isUrdu));
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorBanner(_mapErrorCode(e.toString(), isUrdu));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulUpdate(bool isUrdu) async {
    try {
      await _firebaseService.logout();
    } catch (e) {
      debugPrint("Logout error after password change: $e");
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            Translations.get('Password Changed!', isUrdu),
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            Translations.get(
              'Your password has been successfully updated. You must login again.',
              isUrdu,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(
                Translations.get('Login Now', isUrdu),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _promptForReauthentication(bool isUrdu, String newPass) {
    final TextEditingController currentPasswordController = TextEditingController();
    bool isDialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                Translations.get('Session Expired', isUrdu),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('Please enter your current password to confirm your identity.', isUrdu),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: Translations.get('Current Password', isUrdu),
                      errorText: dialogError,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    Translations.get('Cancel', isUrdu),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          final currentPass = currentPasswordController.text;
                          if (currentPass.isEmpty) {
                            setDialogState(() => dialogError = Translations.get('Password is required', isUrdu));
                            return;
                          }

                          setDialogState(() {
                            isDialogLoading = true;
                            dialogError = null;
                          });

                          try {
                            AuthCredential credential = EmailAuthProvider.credential(
                              email: _adminEmail!,
                              password: currentPass,
                            );
                            await _auth.currentUser!.reauthenticateWithCredential(credential);
                            
                            // Re-authentication successful, now retry updating password
                            await _auth.currentUser!.updatePassword(newPass);
                            
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext); // close dialog
                            }
                            
                            await _handleSuccessfulUpdate(isUrdu);
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isDialogLoading = false;
                              if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                                dialogError = Translations.get('Incorrect current password.', isUrdu);
                              } else {
                                dialogError = _mapErrorCode(e.code, isUrdu);
                              }
                            });
                          } catch (e) {
                            setDialogState(() {
                              isDialogLoading = false;
                              dialogError = Translations.get('Operation failed. Please try again.', isUrdu);
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2168F8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isDialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          Translations.get('Verify & Update', isUrdu),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
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
            body: Stack(
              children: [
                Container(
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: _buildFlowContent(isUrdu),
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
            Translations.get('Change Password', isUrdu),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowContent(bool isUrdu) {
    if (_flowState == AdminPasswordFlowState.initial) {
      return _buildInitialState(isUrdu);
    } else if (_flowState == AdminPasswordFlowState.otpSent) {
      return _buildOTPState(isUrdu);
    } else {
      return _buildUpdatePasswordState(isUrdu);
    }
  }

  Widget _buildInitialState(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Icon(Icons.mark_email_read_outlined, size: 80, color: Color(0xFF2168F8)),
        ),
        const SizedBox(height: 30),
        Text(
          Translations.get('Email Verification Required', isUrdu),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          Translations.get('To securely change your password, we need to verify your identity. We will send a One-Time Password (OTP) to your registered email: ', isUrdu) + 
          (_adminEmail ?? 'your email'),
          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          text: Translations.get('Send OTP', isUrdu),
          color: const Color(0xFF2168F8),
          onPressed: _sendOTP,
        ),
      ],
    );
  }

  Widget _buildOTPState(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.lock_clock_outlined, size: 80, color: Color(0xFF2168F8)),
        const SizedBox(height: 30),
        Text(
          Translations.get('Verify OTP', isUrdu),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
        ),
        const SizedBox(height: 15),
        Text(
          Translations.get('Please enter the 6-digit code sent to ', isUrdu) + (_adminEmail ?? ''),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) => _buildOTPField(index)),
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          text: Translations.get('Verify', isUrdu),
          color: const Color(0xFF2168F8),
          onPressed: _verifyOTP,
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Translations.get("Didn't receive code? ", isUrdu),
              style: const TextStyle(color: Colors.black54),
            ),
            _resendTimer > 0
                ? Text(
                    "${Translations.get('Resend in', isUrdu)} ${_resendTimer}s",
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  )
                : GestureDetector(
                    onTap: _sendOTP,
                    child: Text(
                      Translations.get('Resend', isUrdu),
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdatePasswordState(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          Translations.get('Set New Password', isUrdu),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
        ),
        const SizedBox(height: 10),
        Text(
          Translations.get('Your identity has been verified. You can now set a new password.', isUrdu),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        
        _buildTextField(
          controller: _newPasswordController,
          label: Translations.get('New Password', isUrdu),
          hint: Translations.get('Minimum 6 characters', isUrdu),
          icon: Icons.vpn_key_outlined,
          obscureText: _obscureNew,
          errorText: _newError,
          onChanged: (v) => _validateNewPassword(isUrdu),
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
          onChanged: (v) => _validateNewPassword(isUrdu),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        
        const SizedBox(height: 40),
        
        _buildPrimaryButton(
          text: Translations.get('Update Password', isUrdu),
          color: const Color(0xFF2168F8),
          onPressed: _updatePassword,
        ),
      ],
    );
  }

  Widget _buildOTPField(int index) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        constraints: const BoxConstraints(maxWidth: 50),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2168F8), width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            }
            if (value.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
            if (_otpControllers.every((c) => c.text.isNotEmpty)) {
              _verifyOTP();
            }
          },
        ),
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
                      Translations.get('Error', isUrdu),
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
}
