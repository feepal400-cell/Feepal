import 'package:flutter/material.dart';
import 'language_config.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  @override
  void dispose() {
    _bankNameController.dispose();
    _ibanController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final bankName = _bankNameController.text.trim();
    final iban = _ibanController.text.trim();

    if (bankName.isEmpty || iban.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('Please fill in required fields', languageNotifier.value)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optional: local state/storage update logic goes here

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Translations.get('Bank details saved successfully', languageNotifier.value)),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isUrdu = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.get(label, isUrdu),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: Translations.get('Enter $label', isUrdu),
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.black54),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF2168F8)),
              ),
            ),
          ),
        ],
      ),
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
            backgroundColor: const Color(0xFFFAFAFA),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            Translations.get('Bank Details', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Container(
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _bankNameController,
                              label: 'Bank Name *',
                              icon: Icons.account_balance,
                              isUrdu: isUrdu,
                            ),
                            _buildTextField(
                              controller: _ibanController,
                              label: 'IBAN / Account Number *',
                              icon: Icons.numbers,
                              isUrdu: isUrdu,
                            ),
                            _buildTextField(
                              controller: _accountHolderController,
                              label: 'Account Holder Name (Optional)',
                              icon: Icons.person_outline,
                              isUrdu: isUrdu,
                            ),
                            
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      Translations.get('These bank details will be used for voucher generation', isUrdu),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFE65100),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2168F8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  Translations.get('Save', isUrdu),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
