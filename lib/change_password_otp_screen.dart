import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'login_screen.dart';

class ChangePasswordOTPScreen extends StatefulWidget {
  final String email;
  final String uid;
  final String role;
  final String newPassword;
  final String currentPassword;
  final String? adminId;

  const ChangePasswordOTPScreen({
    super.key,
    required this.email,
    required this.uid,
    required this.role,
    required this.newPassword,
    required this.currentPassword,
    this.adminId,
  });

  @override
  State<ChangePasswordOTPScreen> createState() =>
      _ChangePasswordOTPScreenState();
}

class _ChangePasswordOTPScreenState extends State<ChangePasswordOTPScreen>
    with WidgetsBindingObserver {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  // Error Handling State
  String? _bannerMessage;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _checkClipboardForOTP();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // --- ERROR HANDLING HELPERS ---

  String _mapErrorCode(String code, bool isUrdu) {
    switch (code) {
      case 'invalid-otp':
      case 'Wrong OTP Code':
        return Translations.get('Wrong OTP Code', isUrdu);
      case 'network-request-failed':
        return Translations.get("Network error. Please check your internet connection.", isUrdu);
      case 'too-many-requests':
        return Translations.get("Too many attempts. Please try again later.", isUrdu);
      default:
        return code.contains('/') ? Translations.get("Verification failed. Please try again.", isUrdu) : code;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForOTP();
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
            _controllers[i].text = text[i];
          }
          _verifyOTP();
        }
      }
    } catch (e) {
      debugPrint("Clipboard error: $e");
    }
  }

  void _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _showBanner = false;
    });
    final isUrdu = languageNotifier.value;

    try {
      final result = await _firebaseService.verifyOTP(
        uid: widget.uid,
        code: otp,
        isParent: widget.role == 'parent',
        adminId: widget.adminId,
      );

      if (result['success'] == true) {
        // Success: Update Password and Logout
        bool success = await _firebaseService.completePasswordChange(
          widget.newPassword,
          widget.role,
          widget.currentPassword,
        );
        if (success) {
          if (mounted) {
            _showSuccessDialog(isUrdu);
          }
        } else {
          _showErrorBanner(Translations.get('Failed to update password.', isUrdu));
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

  void _showSuccessDialog(bool isUrdu) {
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
            'Your password has been successfully updated. You have to login again.',
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
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 30),
                              const Icon(
                                Icons.mark_email_read_outlined,
                                size: 80,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 30),
                              Text(
                                Translations.get('Verify OTP', isUrdu),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: gradientColors[0],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                Translations.get(
                                      'Please enter the 6-digit code sent to ',
                                      isUrdu,
                                    ) +
                                    widget.email,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 40),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  6,
                                  (index) => _buildOTPField(index),
                                ),
                              ),

                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gradientColors[0],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          Translations.get(
                                            'Verify Now',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Translations.get(
                                      "Didn't receive code? ",
                                      isUrdu,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  _resendTimer > 0
                                      ? Text(
                                          "${Translations.get('Resend in', isUrdu)} ${_resendTimer}s",
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            final bool isParentVal =
                                                widget.role == 'parent';
                                            final student = _firebaseService
                                                .selectedStudent;
                                            _startTimer();
                                            _firebaseService.sendOTP(
                                              email: widget.email,
                                              uid: widget.uid,
                                              isParent: isParentVal,
                                              adminId: widget.adminId,
                                            );
                                          },
                                          child: Text(
                                            Translations.get('Resend', isUrdu),
                                            style: const TextStyle(
                                              color: Colors.blue,
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
            height: 45,
            width: 45,
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
            Translations.get('Verification', isUrdu),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        constraints: const BoxConstraints(maxWidth: 50),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
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
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
            if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            if (_controllers.every((c) => c.text.isNotEmpty)) {
              _verifyOTP();
            }
          },
        ),
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
                      Translations.get('OTP Error', isUrdu),
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
