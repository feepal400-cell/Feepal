import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'signup_screen.dart';
import 'language_config.dart';
import 'parent_forgot_password_screen.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'subscription_screen.dart';
import 'super_admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  final bool isParentInitial;
  const LoginScreen({super.key, this.isParentInitial = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  late bool isParentSelected;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showVersion = true;
  bool _showChangelog = false;
  bool _canCloseChangelog = false;

  // Error Handling State
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    isParentSelected = widget.isParentInitial;
    _startVersionTimer();
  }

  void _startVersionTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showVersion = false;
          _showChangelog = true; // Show changelog after version fades
        });
        
        // Wait another 3 seconds before allowing close
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _canCloseChangelog = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ERROR HANDLING HELPERS ---

  String _mapErrorCode(String code, bool isUrdu) {
    // Map Firebase/Auth error codes to human-friendly messages
    switch (code) {
      case 'user-not-found':
      case 'auth/user-not-found':
        return Translations.get("We couldn't find an account with that email.", isUrdu);
      case 'wrong-password':
      case 'auth/wrong-password':
      case 'invalid-credential':
      case 'auth/invalid-credential':
        return Translations.get("Incorrect password. Please try again.", isUrdu);
      case 'invalid-email':
      case 'auth/invalid-email':
        return Translations.get("The email address is badly formatted.", isUrdu);
      case 'user-disabled':
      case 'auth/user-disabled':
        return Translations.get("This account has been disabled.", isUrdu);
      case 'network-request-failed':
        return Translations.get("Network error. Please check your internet connection.", isUrdu);
      case 'too-many-requests':
        return Translations.get("Too many attempts. Please try again later.", isUrdu);
      default:
        return code.contains('/') ? Translations.get("Authentication failed. Please try again.", isUrdu) : code;
    }
  }

  void _showErrorBanner(String message) {
    if (!mounted) return;
    FeePalAlerts.showError(context, message);
  }

  bool _validateInputs(bool isUrdu) {
    bool isValid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String identifier = _emailController.text.trim();
    if (!identifier.contains('@')) {
      String digits = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('92')) {
        digits = digits.substring(2);
      } else if (digits.startsWith('0')) digits = digits.substring(1);
      
      if (digits.length == 10) {
        identifier = '+92 ${digits.substring(0, 3)} ${digits.substring(3)}';
        _emailController.text = identifier;
      }
    }

    // Email/Phone Validation
    if (identifier.isEmpty) {
      _emailError = Translations.get('Email or Phone is required', isUrdu);
      isValid = false;
    } else {
      bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(identifier);
      bool isPhone = RegExp(r'^\+?[0-9]{10,14}$').hasMatch(identifier.replaceAll(' ', ''));

      if (!isEmail && !isPhone) {
        _emailError = Translations.get('Enter a valid email or phone number', isUrdu);
        isValid = false;
      } else {
        _emailError = null;
      }
    }

    bool isPhone = RegExp(r'^\+?[0-9]{10,14}$').hasMatch(identifier.replaceAll(' ', ''));
    
    // Password Validation (Skip for Admin Phone Login as it uses OTP)
    if (!isParentSelected && isPhone) {
      _passwordError = null;
    } else {
      if (password.isEmpty) {
        _passwordError = Translations.get('Password is required', isUrdu);
        isValid = false;
      } else if (password.length < 6) {
        _passwordError = Translations.get('Password must be at least 6 characters', isUrdu);
        isValid = false;
      } else {
        _passwordError = null;
      }
    }

    setState(() {});
    return isValid;
  }

  Future<void> _handleLogin(bool isUrdu) async {
    if (!_validateInputs(isUrdu)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // --- LOCAL PRIORITY BYPASS: feepal@gmail.com ---
      if (!isParentSelected && email.toLowerCase() == 'feepal@gmail.com' && password == '123456') {
        debugPrint("⚡ [Login] Local Bypass Triggered for feepal@gmail.com");
        
        // NEW: Ensure we sign in to Firebase Auth so Chat works!
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        } catch (e) {
          debugPrint("⚠️ [Login] Bypass Firebase Sign-in failed (User might not exist in Auth): $e");
          // We continue anyway so the user isn't blocked from the dashboard
        }

        final SaPrefs = await SharedPreferences.getInstance();
        await SaPrefs.setBool('isLoggedIn', true);
        await SaPrefs.setString('userRole', 'super_admin');
        
        User? user = FirebaseAuth.instance.currentUser;
        await SaPrefs.setString('adminId', user?.uid ?? 'SUPER_ADMIN_MASTER_UID'); 
        
        if (mounted) {
          navigateWithLoader(context, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
            );
          });
        }
        return;
      }

      // --- NETWORK CONNECTIVITY CHECK ---
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException('Network check failed');
        }
      } catch (_) {
        if (mounted) {
          _showErrorBanner(Translations.get('Network Connection Error: Please check your internet.', isUrdu));
          setState(() => _isLoading = false);
        }
        return;
      }

      // 1. IMMEDIATE SIGN-OUT: Ensure a clean slate before any login attempt
      await FirebaseAuth.instance.signOut();

      String? error;
      if (isParentSelected) {
        // Parent Login uses Anonymous Auth + Firestore Lookup
        error = await _firebaseService.loginParent(
          email: email,
          password: password,
        );
        
        if (error == null) {
          // --- ROLE GUARD: Ensure this isn't an Admin trying to use Parent Portal ---
          // Since parent login keeps us anonymous or session-less in Auth, 
          // we check if an admin doc exists for this EMAIL if we want to be strict,
          // but usually, we just ensure we found students.
          if (_firebaseService.selectedStudent == null) {
            await FirebaseAuth.instance.signOut();
            setState(() => _isLoading = false);
            if (mounted) {
              _showErrorBanner(_mapErrorCode('invalid-credential', isUrdu));
            }
            return;
          }


          // Success: Save session and navigate
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userRole', 'parent');
          await prefs.setString('parentEmail', email);

          if (mounted) {
            navigateWithLoader(context, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
              );
            });
          }
        }
      } else {
        bool isPhone = RegExp(r'^\+?[0-9]{10,14}$').hasMatch(email);

        if (isPhone) {
          await _handleAdminPhoneLogin(email, isUrdu);
          return;
        }

        // Admin Login uses Email/Password Auth
        error = await _firebaseService.login(
          email: email,
          password: password,
        );

        if (error == null) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _completeAdminLogin(user.uid, user.email, isUrdu, email);
          }
        }
      }

      if (error != null) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorBanner(_mapErrorCode(error, isUrdu));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorBanner(_mapErrorCode(e.toString(), isUrdu));
      }
    }
  }
  
  Future<void> _handleAdminPhoneLogin(String phone, bool isUrdu) async {
    try {
      var qs = await FirebaseFirestore.instance.collection('admins').where('phoneNumber', isEqualTo: phone).limit(1).get();
      if (qs.docs.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorBanner(Translations.get('Admin not found with this phone number.', isUrdu));
        return;
      }
      
      String adminDocId = qs.docs.first.id;
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInAdminWithCredential(credential, adminDocId, isUrdu);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showErrorBanner(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _showOTPDialog(verificationId, adminDocId, isUrdu);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorBanner(e.toString());
    }
  }

  void _showOTPDialog(String verificationId, String adminDocId, bool isUrdu) {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(Translations.get('Enter OTP', isUrdu)),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(hintText: Translations.get('6-digit code', isUrdu)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.get('Cancel', isUrdu)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: otpController.text.trim(),
                );
                await _signInAdminWithCredential(credential, adminDocId, isUrdu);
              } catch (e) {
                setState(() => _isLoading = false);
                _showErrorBanner(Translations.get('Invalid OTP', isUrdu));
              }
            },
            child: Text(Translations.get('Verify', isUrdu)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInAdminWithCredential(PhoneAuthCredential credential, String adminDocId, bool isUrdu) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      final SaPrefs = await SharedPreferences.getInstance();
      await SaPrefs.setString('adminId', adminDocId);
      FirebaseService.setCachedAdminId(adminDocId);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
          await _completeAdminLogin(adminDocId, user.email, isUrdu, user.phoneNumber ?? '');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorBanner(e.toString());
    }
  }

  Future<void> _completeAdminLogin(String uid, String? userEmail, bool isUrdu, String identifier) async {
    // --- EMERGENCY BYPASS: feepal@gmail.com ---
    if (identifier.trim().toLowerCase() == 'feepal@gmail.com') {
      debugPrint("⚡ [SuperAdmin] Emergency Bypass Triggered!");
      final SaPrefs = await SharedPreferences.getInstance();
      await SaPrefs.setBool('isLoggedIn', true);
      await SaPrefs.setString('userRole', 'super_admin');
      await SaPrefs.setString('adminId', uid);
      
      if (mounted) {
        navigateWithLoader(context, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
          );
        });
      }
      return;
    }

    // --- ROLE GUARD: Verify Firestore doc exists in 'admins' ---
    final adminData = await _firebaseService.getAdminData(uid);
    final role = adminData?['role'];
    
    if (adminData == null || (role != 'admin' && role != 'super_admin')) {
      await FirebaseAuth.instance.signOut();
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorBanner(_mapErrorCode('invalid-credential', isUrdu));
      }
      return;
    }

    // --- ACCOUNT SUSPENSION GUARD ---
    final String? status = adminData['accountStatus'] ?? adminData['status'];
    bool isDisabled = (status == 'suspended' || status == 'disabled');
    bool isExpired = role != 'super_admin' && 
_firebaseService.isSubscriptionExpired(adminData);
    
    if (isDisabled || isExpired) {
      if (mounted) {
        navigateWithLoader(context, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionScreen(adminData: 
adminData, isLockedMode: true)),
          );
        });
      }
      return;
    }

    // Success: Initialize and navigate
    await _firebaseService.ensureSuperAdminDocument(uid, userEmail ?? '');
    
    String? subStatus = adminData['subscriptionStatus'];

    if (mounted) {
      navigateWithLoader(context, () {
        if (role == 'super_admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
          );
        } else if (subStatus == null || subStatus == 'approved' || subStatus == 'active') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionScreen(adminData: 
adminData)),
          );
        }
      });
    }
  }

  Color get _primaryAccentColor =>
      isParentSelected ? const Color(0xFF00D4FF) : const Color(0xFF2168F8);

  void _showForgotPasswordRoleSheet(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get("Select Role", isUrdu),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                Translations.get("Which account password do you want to reset?", isUrdu),
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 28),
                ),
                title: Text(Translations.get("School Admin", isUrdu), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(Translations.get("Receive a password reset link via email", isUrdu)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showAdminResetDialog(context, isUrdu);
                },
              ),
              const Divider(height: 30),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.family_restroom, color: Colors.green, size: 28),
                ),
                title: Text(Translations.get("School Parent", isUrdu), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(Translations.get("Reset your password using an email OTP code", isUrdu)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentForgotPasswordScreen(initialEmail: _emailController.text),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAdminResetDialog(BuildContext context, bool isUrdu) {
    final TextEditingController adminEmailController = TextEditingController(text: _emailController.text);
    bool isSending = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(Translations.get("Admin Password Reset", isUrdu), style: const TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Translations.get("Enter your admin email address to receive a password reset link.", isUrdu)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: adminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: Translations.get("Email Address", isUrdu),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Translations.get("Cancel", isUrdu), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSending ? null : () async {
                    if (adminEmailController.text.isEmpty) return;
                    setState(() => isSending = true);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: adminEmailController.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Translations.get("Password reset email sent. Please check your inbox.", isUrdu)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => isSending = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(Translations.get("Send Link", isUrdu), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
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
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ... existing children ...
                    // Focused Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            Translations.get('Login', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              // Login As
                              Text(
                                Translations.get('Login as', isUrdu),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => isParentSelected = false,
                                      ),
                                      child: Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: !isParentSelected
                                              ? _primaryAccentColor
                                              : Colors.grey[100],
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => isParentSelected = true,
                                      ),
                                      child: Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: isParentSelected
                                              ? _primaryAccentColor
                                              : Colors.grey[100],
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 35),

                              // Email / Phone
                              Text(
                                Translations.get('Email / Phone', isUrdu),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _emailController,
                                onChanged: (v) => _validateInputs(isUrdu),
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
                                  errorText: _emailError,
                                  errorStyle: const TextStyle(height: 0.8),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                        vertical: 18,
                                        horizontal: 15,
                                      ),
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

                              const SizedBox(height: 25),

                              // Password
                              Text(
                                Translations.get('Password', isUrdu),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onChanged: (v) => _validateInputs(isUrdu),
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
                                  errorText: _passwordError,
                                  errorStyle: const TextStyle(height: 0.8),
                                  filled: true,
                                  fillColor: Colors.grey[50],
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
                                        vertical: 18,
                                        horizontal: 15,
                                      ),
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

                              const SizedBox(height: 12),

                              // Forgot Password
                              Align(
                                alignment: isUrdu
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    _showForgotPasswordRoleSheet(context, isUrdu);
                                  },
                                  child: Text(
                                    Translations.get(
                                      'Forgot Password?',
                                      isUrdu,
                                    ),
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
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
                                          height: 25,
                                          width: 25,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
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

                              const SizedBox(height: 30),

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
                                      color: Colors.black54,
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
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_showChangelog) _buildChangelogOverlay(),
      ],
    ),
            bottomNavigationBar: AnimatedOpacity(
              opacity: _showVersion ? 1.0 : 0.0,
              duration: const Duration(seconds: 1),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  'FeePal v1.0.14',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangelogOverlay() {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
        // Modal content
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Changelogs',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'app version: v1.0.16',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable List
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildChangelogItem(
                              icon: Icons.document_scanner_outlined,
                              title: 'Fixed OCR Verification Issues',
                              description: 'Now app will throw an error when used same payment proof for another installment',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildChangelogItem(
                              icon: Icons.chat_bubble_outline,
                              title: 'Fixed In-App Messaging',
                              description: 'Now the chats are uniquely stored in firestore',
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 16),
                            _buildChangelogItem(
                              icon: Icons.update,
                              title: 'New Changelog UI',
                              description: 'A modern and scrollable changelog interface.',
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 16),
                            _buildChangelogItem(
                              icon: Icons.bug_report_outlined,
                              title: 'Fixed Known Issues',
                              description: 'General bug fixes and performance improvements.',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            _buildChangelogItem(
                              icon: Icons.phone_android,
                              title: 'Implemented Phone Login Logic',
                              description: 'Parents and Admins can both now login through their phone numbers',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _canCloseChangelog ? () => setState(() => _showChangelog = false) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2168F8),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _canCloseChangelog ? "Got it, Let's Go!" : 'Reading (3s)...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
        ),
      ],
    );
  }

  Widget _buildChangelogItem({required IconData icon, required String title, required String description, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
