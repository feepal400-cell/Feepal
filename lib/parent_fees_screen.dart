import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'language_config.dart';
import 'parent_dashboard_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';
import 'navigation_helper.dart';

class ParentFeesScreen extends StatefulWidget {
  const ParentFeesScreen({super.key});

  @override
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;

  // Theme Colors
  final Color primaryColor = const Color(0xFF00BCD4); // Cyan
  final Color secondaryColor = const Color(0xFF009688); // Teal
  final Color accentColor = const Color(0xFFE0F7FA); // Light Cyan

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    final student = _firebaseService.selectedStudent;
    if (student != null) {
      setState(() {
        _parentData = student;
      });
    }
  }

  void _showUploadDialog(BuildContext context, bool isUrdu) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 20),
                Text(Translations.get('Processing payment proof...', isUrdu)),
                const SizedBox(height: 10),
                Text(
                  Translations.get('AI is validating your voucher...', isUrdu),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!context.mounted) return;
        Navigator.pop(context);

        await _firebaseService.submitPaymentProof(
          _parentData!['adminId'],
          _parentData!['docId'].toString(),
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.get('Voucher validated! Fee marked as Paid.', isUrdu)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_parentData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: StreamBuilder<DocumentSnapshot>(
              stream: _firebaseService.getStudentStream(_parentData!['adminId'], _parentData!['docId'].toString()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var studentData = snapshot.data!.data() as Map<String, dynamic>;
                String className = studentData['class']?.toString() ?? 'N/A';
                String studentName = studentData['studentName'] ?? 'Student';
                String rollNo = studentData['rollNumber']?.toString() ?? '';
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getClassFeesStream(_parentData!['adminId'], className),
                  builder: (context, feeSnapshot) {
                    double baseFee = 0.0;
                    double additionalCharge = 0.0;
                    String dueDateStr = "N/A";
                    
                    if (feeSnapshot.hasData && feeSnapshot.data!.docs.isNotEmpty) {
                      var feeData = feeSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      baseFee = double.tryParse(feeData['baseFee']?.toString() ?? '0') ?? 0.0;
                      additionalCharge = double.tryParse(feeData['additionalCharge']?.toString() ?? '0') ?? 0.0;
                      if (feeData['dueDateRaw'] != null) {
                        dueDateStr = DateFormat('MM/dd/yyyy').format((feeData['dueDateRaw'] as Timestamp).toDate());
                      }
                    }

                    double arrearsBalance = double.tryParse(studentData['arrearsBalance']?.toString() ?? '0') ?? 0.0;
                    double discountPercent = (studentData['siblingDiscountPercentage'] ?? 0).toDouble();
                    
                    double totalBeforeDiscount = baseFee + additionalCharge;
                    double discountAmount = (totalBeforeDiscount * discountPercent) / 100;
                    double currentMonthTotal = totalBeforeDiscount - discountAmount;

                    bool isPaid = studentData['feeStatus']?.toString().toLowerCase() == 'paid';
                    bool hasInstallments = studentData['hasInstallments'] ?? false;
                    List installments = studentData['installments'] as List? ?? [];

                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 120,
                          pinned: true,
                          backgroundColor: primaryColor,
                          elevation: 0,
                          automaticallyImplyLeading: false,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Translations.get('Fee Details', isUrdu),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '$studentName ($rollNo)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            centerTitle: false,
                            titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCard(className, currentMonthTotal, isPaid, isUrdu),
                                
                                const SizedBox(height: 25),

                                if (arrearsBalance > 0) ...[
                                  _buildArrearsCard(arrearsBalance, isUrdu),
                                  const SizedBox(height: 25),
                                ],

                                if (!isPaid) ...[
                                  _buildSectionHeader(Translations.get('Unpaid Fee', isUrdu)),
                                  const SizedBox(height: 10),
                                  _buildUnpaidFeeCard(
                                    className, 
                                    baseFee, 
                                    additionalCharge, 
                                    discountAmount, 
                                    discountPercent,
                                    currentMonthTotal, 
                                    dueDateStr, 
                                    hasInstallments,
                                    installments,
                                    isUrdu
                                  ),
                                  const SizedBox(height: 25),
                                ],

                                _buildSectionHeader(Translations.get('Payment History', isUrdu)),
                                const SizedBox(height: 10),
                                _buildPaymentHistory(studentData, isUrdu),
                                
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: _buildBottomNav(isUrdu),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildOverviewCard(String className, double total, bool isPaid, bool isUrdu) {
    double paidAmount = isPaid ? total : 0.0;
    double remaining = isPaid ? 0.0 : total;
    double progress = isPaid ? 1.0 : 0.0;
    String monthLabel = "${DateFormat('MMMM').format(DateTime.now())} ${Translations.get('Month', isUrdu)}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Academic Year 2025', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                'Total Fee',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                className,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'Rs. ${total.toInt()}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            monthLabel,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressInfo('Paid Amount', 'Rs. ${paidAmount.toInt()}', isUrdu),
              _buildProgressInfo('Remaining', 'Rs. ${remaining.toInt()}', isUrdu, isOrange: true),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, String amount, bool isUrdu, {bool isOrange = false}) {
    return Column(
      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(Translations.get(label, isUrdu), style: TextStyle(color: isOrange ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildArrearsCard(double amount, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Translations.get('Past Arrears', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text('Rs. ${amount.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidFeeCard(
    String className, 
    double base, 
    double additional, 
    double discount, 
    double discountPercent,
    double total, 
    String dueDate, 
    bool hasInstallments,
    List installments,
    bool isUrdu
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Rs. ${total.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text('Due: $dueDate', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              _buildBadge('Pending', Colors.orange),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          _buildDetailRow('Base Fee', 'Rs. ${base.toInt()}', isUrdu),
          _buildDetailRow('Additional Charges', 'Rs. ${additional.toInt()}', isUrdu),
          _buildDetailRow('Sibling Discount (${discountPercent.toInt()}%)', '- Rs. ${discount.toInt()}', isUrdu, isNegative: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          _buildDetailRow('Total Monthly Fee', 'Rs. ${total.toInt()}', isUrdu, isBold: true),
          
          if (hasInstallments && installments.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                _buildInstallmentBadge(installments[0]['label'] ?? 'Installment'),
              ],
            ),
          ],
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showUploadDialog(context, isUrdu),
              icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
              label: Text(Translations.get('Upload Payment Proof', isUrdu)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isUrdu, {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(Translations.get(label, isUrdu), style: TextStyle(color: isBold ? Colors.black87 : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isNegative ? Colors.red : (isBold ? primaryColor : Colors.black87), fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(Map<String, dynamic> studentData, bool isUrdu) {
    if (studentData['feeStatus']?.toString().toLowerCase() != 'paid') {
      return Center(child: Text(Translations.get('No payment history yet.', isUrdu), style: const TextStyle(color: Colors.grey)));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(studentData['class']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Rs. ${studentData['lastFeeAmount'] ?? '0'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 5),
              const Text('Paid on: Recently', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              _buildBadge('Paid', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInstallmentBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav(bool isUrdu) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: 26,
      onTap: (index) {
        if (index == 0) {
          navigateWithLoader(context, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
          });
        } else if (index == 2) {
          navigateWithLoader(context, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentVoucherScreen()));
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
    );
  }
}
