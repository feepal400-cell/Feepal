import 'package:flutter/material.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';

class ParentVoucherScreen extends StatefulWidget {
  const ParentVoucherScreen({super.key});

  @override
  State<ParentVoucherScreen> createState() => _ParentVoucherScreenState();
}

class _ParentVoucherScreenState extends State<ParentVoucherScreen> {
  bool _isInstallmentsMode = false;
  int _selectedInstallment = -1; // -1 means none selected

  Widget _buildInstallmentPill(String text, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA), // Light cyan bg
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        Translations.get(text, isUrdu),
        style: const TextStyle(
          color: Color(0xFF0097A7), // Darker cyan text
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRadioBox(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected 
        ? const Icon(Icons.check, color: Colors.white, size: 16)
        : null,
    );
  }

  bool get _canGenerateVoucher {
    if (!_isInstallmentsMode) return true; // Allow generating for full fee when in initial state
    return _selectedInstallment != -1; // Must select an installment if in installment mode
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
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header and Summary Card (Wrapping)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF009BCB)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                // Header Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        Translations.get('Generate Voucher', isUrdu),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Student Info Summary Card
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Labels
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Translations.get('Student Name', isUrdu),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            Translations.get('Class', isUrdu),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      // Row 2: Values
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Translations.get('Zain Muhammad', isUrdu),
                                            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const Text(
                                            '10',
                                            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 25),
                                      
                                      // Row 3: Current Month Label
                                      Text(
                                        Translations.get('Current Month', isUrdu),
                                        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // Row 4: Fee Breakdown
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                Translations.get('Total Fee', isUrdu),
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(height: 5),
                                              const Text(
                                                'Rs. 5,000',
                                                style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                Translations.get('Paid', isUrdu),
                                                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(height: 5),
                                              const Text(
                                                'Rs. 0',
                                                style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                Translations.get('Remaining', isUrdu),
                                                style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(height: 5),
                                              const Text(
                                                'Rs. 5,000',
                                                style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                        
                        // Dynamic Fees/Installment Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          child: Text(
                            Translations.get(_isInstallmentsMode ? 'Select Installment' : 'Fees', isUrdu),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        
                        // Dynamic Content Block 
                        if (!_isInstallmentsMode)
                          // Single Full Fee Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Translations.get('Class 10', isUrdu),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    const Text(
                                      'Rs. 5,000',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${Translations.get('Due:', isUrdu)} 12/15/2025',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                
                                // Create Installments Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isInstallmentsMode = true;
                                        _selectedInstallment = -1; // Reset selection
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D4FF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      Translations.get('Create Installments', isUrdu),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Expanded Installments View
                          Column(
                            children: [
                              // Installment Choice 1
                              _buildInstallmentChoiceCard(0, 'Installment 1', '12/15/2025', 'Rs. 2,500', isUrdu),
                              // Installment Choice 2
                              _buildInstallmentChoiceCard(1, 'Installment 2', '1/15/2026', 'Rs. 2,500', isUrdu),
                            ],
                          ),
                          
                        // Bottom padding for scroll view
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Fixed Bottom Generate Voucher Button Area
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canGenerateVoucher ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Translations.get('Generating voucher...', isUrdu)),
                            backgroundColor: const Color(0xFF00D4FF),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canGenerateVoucher ? const Color(0xFF00D4FF) : const Color(0xFFB0BEC5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB0BEC5),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), 
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        Translations.get('Generate Voucher', isUrdu),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // App Global Bottom Navigation Layout
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 2, // Voucher is index 2
              selectedItemColor: const Color(0xFF00D4FF),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
                  });
                } else if (index == 1) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentFeesScreen()));
                  });
                } else if (index == 3) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentAlertsScreen()));
                  });
                } else if (index == 4) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentProfileScreen()));
                  });
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: Translations.get('Fees', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: Translations.get('Voucher', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), label: Translations.get('Alerts', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: Translations.get('Profile', isUrdu)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstallmentChoiceCard(int index, String installmentLabel, String dueDate, String amount, bool isUrdu) {
    bool isSelected = _selectedInstallment == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInstallment = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.get('Class 10', isUrdu),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  amount,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Middle Row
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 5),
                Text(
                  '${Translations.get('Due:', isUrdu)} $dueDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInstallmentPill(installmentLabel, isUrdu),
                _buildRadioBox(isSelected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
