import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/firebase_service.dart';
import 'language_config.dart';
import 'services/cloudinary_service.dart';
import 'pending_subscription_screen.dart';
import 'login_screen.dart';
import 'utils/ui_utils.dart';

class SubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final bool isLockedMode;
  const SubscriptionScreen({super.key, required this.adminData, this.isLockedMode = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedPlan;
  File? _proofImage;
  String? _paymentProofUrl;
  bool _isSubmitting = false;
  bool _isUploadingProof = false;
  bool _isDeleting = false;
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastBackPressTime;

  Future<void> _handleProofUpload() async {
    setState(() {
      _isUploadingProof = true;
    });

    try {
      String? url = await CloudinaryService.pickAndUploadImage(
        uploadPreset: 'Subscription_Payment_Proofs',
      );

      if (url != null) {
        setState(() {
          _paymentProofUrl = url;
        });
        if (mounted) {
          FeePalAlerts.showSuccess(context, Translations.get('Proof uploaded successfully', languageNotifier.value));
        }
      }
    } on SocketException catch (e) {
      debugPrint("📡 [Network Error] SocketException during upload: $e");
      if (mounted) {
        FeePalAlerts.showError(context, 'Network Error: Please check your internet connection and try uploading the proof again.');
      }
    } catch (e) {
      debugPrint("❌ [Upload Error] Unexpected error: $e");
      if (mounted) {
        FeePalAlerts.showError(context, 'Upload failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProof = false;
        });
      }
    }
  }

  Future<void> _handleSubmit(bool isUrdu) async {
    if (_selectedPlan == null || (_proofImage == null && _paymentProofUrl == null)) {
      FeePalAlerts.showError(context, Translations.get('Please select a plan and upload payment proof.', isUrdu));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firebaseService.submitSubscriptionProof(
        adminId: widget.adminData['uid'] ?? '',
        plan: _selectedPlan!,
        imageFile: _proofImage,
        externalProofUrl: _paymentProofUrl,
        schoolName: widget.adminData['schoolName'] ?? 'Unknown School',
        adminName: widget.adminData['adminName'] ?? 'Unknown Admin',
        adminEmail: widget.adminData['email'] ?? 'No Email',
      );

      if (mounted) {
        _showSuccessDialog(isUrdu);
      }
    } on SocketException catch (e) {
      debugPrint("📡 [Network Error] SocketException during submission: $e");
      if (mounted) {
        FeePalAlerts.showError(context, 'Network Error: Could not reach the server. Please check your connection and try again.');
      }
    } catch (e) {
      if (mounted) {
        FeePalAlerts.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleLogout(bool isUrdu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translations.get('Logout', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translations.get('Are you sure you want to logout?', isUrdu)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2168F8).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2168F8).withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2168F8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Translations.get('The email and password you used to sign up, they can be used to log back in to continue purchasing the subscription', isUrdu),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.get('Cancel', isUrdu), style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2168F8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(Translations.get('Logout', isUrdu), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(bool isUrdu) async {
    // 0. Super Admin Protection
    if (widget.adminData['email'] == 'superadmin@feepal.com') {
      FeePalAlerts.showError(context, Translations.get('The Super Admin account cannot be deleted.', isUrdu));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.get('Delete Account', isUrdu)),
        content: Text(Translations.get('Are you sure you want to delete your account? This action is permanent and cannot be undone.', isUrdu)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Translations.get('Cancel', isUrdu))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Translations.get('Delete', isUrdu), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _firebaseService.deleteAdminAccountComplete(
          adminId: widget.adminData['uid'] ?? '',
          password: widget.adminData['password'] ?? '',
        );

        if (mounted) {
          FeePalAlerts.showSuccess(context, Translations.get('Account Deleted Successfully', isUrdu));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          FeePalAlerts.showError(context, 'Error: ${e.toString()}');
        }
      }
    }
  }

  void _showSuccessDialog(bool isUrdu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Translations.get('Purchase Request sent successfully to FeePal Team. They will verify and enable subscription within 24 hours.', isUrdu),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => PendingSubscriptionScreen(adminData: widget.adminData)),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2168F8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(Translations.get('OK', isUrdu), style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUrdu = languageNotifier.value;
    String status = widget.adminData['subscriptionStatus'] ?? 'none';
    bool isPending = status == 'pending';

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final now = _firebaseService.secureTime;
          if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            if (mounted) {
              FeePalAlerts.showWarning(context, Translations.get('Tap again to exit', isUrdu));
            }
            return;
          }
          SystemNavigator.pop();
        },
      child: Scaffold(
         appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(Translations.get('Subscription', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF2168F8)),
              onPressed: () => _handleLogout(isUrdu),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isDeleting ? null : () => _handleDeleteAccount(isUrdu),
            )
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isLockedMode) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            Translations.get('Account Suspended / Subscription Expired', isUrdu),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            Translations.get('Please renew your subscription to regain access.', isUrdu),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  if (isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.hourglass_empty, color: Colors.orange, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            Translations.get('Verification in Progress', isUrdu),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            Translations.get('FeePal Team is verifying your payment. This usually takes less than 24 hours.', isUrdu),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  
                  Text(
                    Translations.get('Choose Your Plan', isUrdu),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  
                  _buildPlanCard(
                    title: 'Monthly Plan',
                    price: '10,000 PKR',
                    features: [
                      'Automated Fee Generation',
                      'Late payer alerts (last 3 months)',
                      'SMS/Email Alerts',
                      'Installments (arrears + current dues)',
                      'Master Parent Dashboard',
                      'Voucher Validation',
                    ],
                    isSelected: _selectedPlan == 'Monthly',
                    isDisabled: isPending,
                    onTap: () => setState(() => _selectedPlan = 'Monthly'),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _buildPlanCard(
                    title: 'Yearly Plan',
                    price: '100,000 PKR',
                    features: [
                      'Same premium features',
                      'Discounted price',
                      'Priority support',
                    ],
                    isSelected: _selectedPlan == 'Yearly',
                    isDisabled: isPending,
                    onTap: () => setState(() => _selectedPlan = 'Yearly'),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    Translations.get('Account Details', isUrdu),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildAccountDetails(),
                  
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2168F8).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2168F8).withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2168F8), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Translations.get('In order to get your subscription plan, please make a payment on any account from the above and upload the payment receipt below, we will verify and activate your subscription as soon as possible.', isUrdu),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  Text(
                    Translations.get('Upload Payment Proof', isUrdu),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  GestureDetector(
                    onTap: (isPending || _isSubmitting || _isUploadingProof) ? null : _handleProofUpload,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!, width: 2),
                      ),
                      child: _isUploadingProof
                          ? const Center(child: CircularProgressIndicator())
                          : (_paymentProofUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _paymentProofUrl!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                                  ),
                                )
                              : (_proofImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(_proofImage!, fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                                          ]),
                                          child: Icon(Icons.add_a_photo_outlined, size: 30, color: const Color(0xFF2168F8)),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(Translations.get('Upload Proof (PDF/PNG/JPG)', isUrdu),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                                      ],
                                    ))),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (isPending || _isSubmitting) ? null : () => _handleSubmit(isUrdu),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2168F8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(Translations.get('Submit Proof', isUrdu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
            if (_isDeleting)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2168F8).withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF2168F8) : Colors.grey[200]!, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2168F8)),
                ],
              ),
              const SizedBox(height: 5),
              Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2168F8))),
              const Divider(height: 30),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow('EasyPaisa', '03134469206', 'Ali Muhammad', 'assets/easypaisa.png'),
          const Divider(height: 30),
          _buildDetailRow('JazzCash', '03134469206', 'Ali Muhammad', 'assets/jazzcash.png'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String method, String number, String name, String assetPath) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Color(0xFF2168F8), size: 30),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20, color: Color(0xFF2168F8)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: number));
            FeePalAlerts.showSuccess(context, '$method number copied to clipboard!');
          },
        )
      ],
    );
  }
}
