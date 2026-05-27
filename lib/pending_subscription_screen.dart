import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'services/firebase_service.dart';
import 'language_config.dart';
import 'welcome_screen.dart';
import 'admin_dashboard_screen.dart';
import 'subscription_screen.dart';

class PendingSubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const PendingSubscriptionScreen({super.key, required this.adminData});

  @override
  State<PendingSubscriptionScreen> createState() => _PendingSubscriptionScreenState();
}

class _PendingSubscriptionScreenState extends State<PendingSubscriptionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late ConfettiController _confettiController;
  bool _hasCelebrated = false;
  DateTime? _lastBackPressTime;
  
  bool _isRejected = false;
  String _rejectionReason = '';
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showSuccessDialog(bool isUrdu) {
    if (_hasCelebrated) return;
    _hasCelebrated = true;
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.orange, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Congratulations!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Welcome to FeePal. Manage your school fee management without stress!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
          ],
        ),
      ),
    );

    // Auto-navigate after celebration
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          (route) => false,
        );
      }
    });
  }

  void _handleRejection(String reason) {
    if (_isRejected) return;
    setState(() {
      _isRejected = true;
      _rejectionReason = reason;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_countdown > 1) {
          setState(() {
            _countdown--;
          });
        } else {
          _timer?.cancel();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => SubscriptionScreen(adminData: widget.adminData),
            ),
            (route) => false,
          );
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isUrdu = languageNotifier.value;
    String adminId = widget.adminData['uid'];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('admins').doc(adminId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            String status = data['subscriptionStatus'] ?? 'pending';
            if (status == 'approved' || status == 'active') {
              WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccessDialog(isUrdu));
            } else if (status == 'rejected') {
              String reason = data['rejectionReason'] ?? 'No reason specified';
              WidgetsBinding.instance.addPostFrameCallback((_) => _handleRejection(reason));
            }
          }
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final now = _firebaseService.secureTime;
            if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Translations.get('Tap again to exit', isUrdu)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              return;
            }
            SystemNavigator.pop();
          },
          child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2168F8).withValues(alpha: 0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration/Icon
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2168F8).withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 80,
                          color: Color(0xFF2168F8),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      Text(
                        "Subscription Pending",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isRejected ? Colors.red : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        "You're pending subscription. You will see a notification and get an email alert regarding your subscription request.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 50),
                      
                      if (_isRejected) ...[
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          "Subscription Rejected",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Your subscription request has been rejected for:\n\"$_rejectionReason\"",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "Redirecting in $_countdown...",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2168F8)),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Verifying your payment...",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Logout Option
                      TextButton.icon(
                        onPressed: () async {
                          await _firebaseService.logout();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}
