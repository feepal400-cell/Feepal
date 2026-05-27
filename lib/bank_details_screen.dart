import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'utils/ui_utils.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _accountNumberController = TextEditingController(); 
  final TextEditingController _accountTitleController = TextEditingController(); 
  final FocusNode _accountNumberFocusNode = FocusNode();
  
  bool _isLoading = true;
  bool _isIbanValid = true;
  String _ibanErrorMessage = '';
  
  String? _selectedBank;
  
  final List<String> _pakistaniBanks = [
    "Habib Bank Limited (HBL)",
    "Meezan Bank",
    "United Bank Limited (UBL)",
    "MCB Bank",
    "Allied Bank (ABL)",
    "Bank Alfalah",
    "Faysal Bank",
    "Askari Bank",
    "Bank Al Habib",
    "Standard Chartered Pakistan",
    "National Bank of Pakistan (NBP)",
    "Easypaisa",
    "JazzCash",
    "NayaPay",
    "SadaPay"
  ];

  @override
  void initState() {
    super.initState();
    _accountNumberFocusNode.addListener(() {
      if (!_accountNumberFocusNode.hasFocus) {
        _checkIbanValidation();
      }
    });
    _loadBankDetails();
  }

  void _checkIbanValidation() {
    String cleaned = _accountNumberController.text.replaceAll(' ', '').toUpperCase();
    if (cleaned.isEmpty) {
      setState(() {
        _isIbanValid = true;
        _ibanErrorMessage = '';
      });
      return;
    }
    RegExp regExp = RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$');
    bool isValid = regExp.hasMatch(cleaned);
    setState(() {
      _isIbanValid = isValid;
      if (!isValid) {
        _ibanErrorMessage = 'Please enter a valid 24-character Pakistani IBAN (e.g., PK00 BANK 0000 0000 0000 0000).';
      } else {
        _ibanErrorMessage = '';
      }
    });
  }

  Future<void> _loadBankDetails() async {
    final data = await _firebaseService.getAdminProfile();
    if (mounted && data != null) {
      setState(() {
        final existingBank = data['bankName'];
        if (existingBank != null && _pakistaniBanks.contains(existingBank)) {
          _selectedBank = existingBank;
        } else if (existingBank != null && existingBank.toString().isNotEmpty) {
           // If they had a custom bank not in the list, we can either append it or leave blank.
           // Let's add it to the list to avoid breaking existing data.
           _pakistaniBanks.add(existingBank);
           _selectedBank = existingBank;
        }
        
        _accountTitleController.text = data['accountTitle'] ?? '';
        
        String accNum = data['accountNumber'] ?? '';
        String formattedAccNum = '';
        String cleaned = accNum.replaceAll(' ', '');
        for (int i = 0; i < cleaned.length; i++) {
          if (i > 0 && i % 4 == 0) {
            formattedAccNum += ' ';
          }
          formattedAccNum += cleaned[i];
        }
        _accountNumberController.text = formattedAccNum;
        
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountTitleController.dispose();
    _accountNumberFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final bankName = _selectedBank ?? '';
    final accountTitle = _accountTitleController.text.trim();
    final accountNumber = _accountNumberController.text.replaceAll(' ', '').toUpperCase();

    if (bankName.isEmpty || accountTitle.isEmpty || accountNumber.isEmpty) {
      FeePalAlerts.showError(context, Translations.get('Please fill in all bank details', languageNotifier.value));
      return;
    }

    RegExp regExp = RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$');
    if (!regExp.hasMatch(accountNumber)) {
      setState(() {
        _isIbanValid = false;
        _ibanErrorMessage = 'Please enter a valid 24-character Pakistani IBAN (e.g., PK00 BANK 0000 0000 0000 0000).';
      });
      return;
    } else {
      setState(() {
        _isIbanValid = true;
        _ibanErrorMessage = '';
      });
    }

    try {
      setState(() => _isLoading = true);
      await _firebaseService.updateBankDetails(bankName, accountTitle, accountNumber);
      
      if (mounted) {
        FeePalAlerts.showSuccess(context, Translations.get('Bank details saved successfully', languageNotifier.value));
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        FeePalAlerts.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdownField({
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
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              hintText: Translations.get('Select $label', isUrdu),
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
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            items: _pakistaniBanks.map((String bank) {
              return DropdownMenuItem<String>(
                value: bank,
                child: Text(
                  bank,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedBank = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isUrdu = false,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    bool hasError = false,
    String errorMessage = '',
    ValueChanged<String>? onChanged,
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
            focusNode: focusNode,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: Translations.get('Enter $label', isUrdu),
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              prefixIcon: Icon(icon, color: hasError ? Colors.red : Colors.black54),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF2168F8)),
              ),
            ),
          ),
          if (hasError && errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      Translations.get(errorMessage, isUrdu),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                        child: _isLoading 
                          ? const Center(child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(color: Color(0xFF2168F8)),
                            ))
                          : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField(
                              label: 'Bank Name *',
                              icon: Icons.account_balance,
                              isUrdu: isUrdu,
                            ),
                            _buildTextField(
                              controller: _accountTitleController,
                              label: 'Account Title *',
                              icon: Icons.person_outline,
                              isUrdu: isUrdu,
                            ),
                            _buildTextField(
                              controller: _accountNumberController,
                              label: 'Account Number *',
                              icon: Icons.numbers,
                              isUrdu: isUrdu,
                              focusNode: _accountNumberFocusNode,
                              inputFormatters: [IbanInputFormatter()],
                              hasError: !_isIbanValid,
                              errorMessage: _ibanErrorMessage,
                              onChanged: (val) {
                                if (!_isIbanValid) {
                                  setState(() {
                                    _isIbanValid = true;
                                    _ibanErrorMessage = '';
                                  });
                                }
                              },
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

class IbanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.length > 24) {
      text = text.substring(0, 24);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
