import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/firebase_service.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'loginscreen.dart';
import 'services/cloudinary_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const SubscriptionScreen({super.key, required this.adminData});

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
  final ImagePicker _picker = ImagePicker();

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.get('Proof uploaded successfully', languageNotifier.value))),
          );
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Please select a plan and upload payment proof.', isUrdu))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firebaseService.submitSubscriptionProof(
        adminId: widget.adminData['uid'],
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(Translations.get('Subscription', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _firebaseService.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
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
          _buildDetailRow('EasyPaisa', '0345-1234567', 'FeePal Solutions'),
          const Divider(height: 30),
          _buildDetailRow('JazzCash', '0300-7654321', 'FeePal School Tech'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String method, String number, String name) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!)),
          child: Icon(method == 'EasyPaisa' ? Icons.account_balance_wallet : Icons.money, color: const Color(0xFF2168F8), size: 20),
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
          icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
          onPressed: () {
            // Copy logic
          },
        )
      ],
    );
  }
}
