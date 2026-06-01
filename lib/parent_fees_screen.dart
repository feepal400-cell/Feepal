import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'services/cloudinary_service.dart';
import 'language_config.dart';
import 'widgets/throttled_button.dart';
import 'parent_dashboard_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';
import 'navigation_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/ocr_service.dart';
import 'services/push_notification_dispatcher.dart';
import 'services/notification_dispatcher.dart';
class ParentFeesScreen extends StatefulWidget {
  const ParentFeesScreen({super.key});

  @override
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;
  DateTime? _serverTime;

  // Theme Colors - Synchronized with Voucher Screen
  final Color primaryColor = const Color(0xFF00D4FF); // Theme Blue
  final Color secondaryColor = const Color(0xFF009BCB); // Darker Blue
  final Color greenColor = const Color(0xFF4CAF50);
  final Color orangeColor = const Color(0xFFFF9800);
  bool _isUploadingVoucher = false;

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
      _syncTime();
    }
  }

  Future<void> _syncTime() async {
    if (mounted) {
      setState(() {
        _serverTime = _firebaseService.secureTime;
      });
    }
  }

  String _formatMonthYear(String? monthYear) {
    if (monthYear == null || monthYear == 'N/A') return 'N/A';
    try {
      DateTime dt = DateFormat('MM-yyyy').parse(monthYear);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (e) {
      return monthYear;
    }
  }

  bool _isOverdue(dynamic dueDateRaw) {
    if (dueDateRaw == null) return false;
    DateTime due;
    if (dueDateRaw is Timestamp) {
      due = dueDateRaw.toDate();
    } else {
      return false;
    }
    DateTime endOfDueDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
    DateTime now = _firebaseService.secureTime;
    return now.isAfter(endOfDueDay);
  }

  Future<void> _handleVoucherUpload(Map<String, dynamic> voucher, {int? installmentIndex}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image == null) return;
    
    setState(() => _isUploadingVoucher = true);
    
    try {
      final File imageFile = File(image.path);
      
      final adminId = _parentData!['adminId'];
      final adminData = await _firebaseService.getAdminData(adminId);
      final String adminBankName = adminData?['bankName'] ?? '';
      
      final allVouchersSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(_parentData!['docId'].toString())
          .collection('vouchers')
          .get();
      final allVouchers = allVouchersSnapshot.docs.map((d) => d.data()).toList();
      
      double expectedAmount = 0;
      double base = double.tryParse(voucher['baseFee']?.toString() ?? '0') ?? 0.0;
      double add = double.tryParse(voucher['additionalCharge']?.toString() ?? '0') ?? 0.0;
      double pen = _isOverdue(voucher['dueDateRaw']) ? (double.tryParse(voucher['latePenalty']?.toString() ?? '0') ?? 0.0) : 0.0;

      if (installmentIndex != null && voucher['installments'] != null) {
        final inst = (voucher['installments'] as List)[installmentIndex];
        expectedAmount = double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0;
        
        bool overdue = _isOverdue(inst['dueDateRaw'] ?? voucher['dueDateRaw']);
        if (overdue && installmentIndex == _getFirstUnpaidIndex(voucher['installments'])) {
           double penalty = double.tryParse(voucher['latePenalty']?.toString() ?? '0') ?? 0.0;
           expectedAmount += penalty;
        }
      } else {
        expectedAmount = base + add + pen;
      }
      
      final result = await OcrService.validateVoucher(
        imageFile: imageFile,
        currentVoucher: voucher,
        allVouchers: allVouchers,
        expectedAmount: expectedAmount,
        adminBankName: adminBankName,
      );
      
      if (result.success) {
        String studentId = _parentData!['docId'].toString();
        String studentName = _parentData!['studentName'] ?? 'Unknown';
        String rollNo = _parentData!['rollNumber'] ?? 'Unknown';
        String month = voucher['monthYear'] ?? 'Unknown';
        
        String? secureUrl = await CloudinaryService.uploadDartIoFile(imageFile, uploadPreset: 'Payment_Proofs');
        
        Map<String, dynamic> updates = {};
        if (installmentIndex != null) {
           List installments = List.from(voucher['installments']);
           installments[installmentIndex]['status'] = 'paid';
           installments[installmentIndex]['paymentDate'] = Timestamp.now();
           installments[installmentIndex]['voucherImageUrl'] = secureUrl;
           
           bool allPaid = installments.every((i) => i['status'] == 'paid' || i['status'] == 'Paid');
           updates['installments'] = installments;
           if (allPaid) updates['status'] = 'paid';
        } else {
           updates['status'] = 'paid';
           updates['paymentDate'] = FieldValue.serverTimestamp();
           updates['voucherImageUrl'] = secureUrl;
        }
        
        await _firebaseService.updateVoucher(
          adminId, studentId, voucher['id'], updates, studentName, rollNo, month
        );
        
        // Dispatch Notifications in the background
        NotificationDispatcher.sendOcrSuccessAlert(
          parentData: _parentData!,
          studentName: studentName,
          rollNo: rollNo,
          monthYear: month,
        ).catchError((e) {
          debugPrint('Error dispatching OCR success alert: $e');
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Voucher verified and marked as Paid."), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          _showOcrFailedDialog(context, result.errorMessage ?? "Verification failed.", imageFile, voucher, adminId, installmentIndex: installmentIndex);
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingVoucher = false);
    }
  }

  void _showOcrFailedDialog(BuildContext context, String errorMessage, File imageFile, Map<String, dynamic> voucher, String adminId, {int? installmentIndex}) {
     showDialog(
       context: context,
       builder: (dialogContext) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         title: Row(
           children: [
             const Icon(Icons.error_outline, color: Colors.red),
             const SizedBox(width: 10),
             const Expanded(child: Text("Verification Failed", style: TextStyle(fontWeight: FontWeight.bold))),
           ],
         ),
         content: Text(errorMessage, style: const TextStyle(fontSize: 15)),
         actions: [
           TextButton(
             onPressed: () {
               Navigator.pop(dialogContext);
               _handleVoucherUpload(voucher, installmentIndex: installmentIndex);
             },
             child: const Text("Re-upload Properly", style: TextStyle(color: Colors.grey)),
           ),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(dialogContext);
               await _submitForManualVerification(imageFile, voucher, adminId, installmentIndex: installmentIndex);
             },
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
             child: const Text("Submit for Manual", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           ),
         ],
       ),
     );
  }

  Future<void> _submitForManualVerification(File imageFile, Map<String, dynamic> voucher, String adminId, {int? installmentIndex}) async {
      setState(() => _isUploadingVoucher = true);
      try {
        String studentId = _parentData!['docId'].toString();
        String studentName = _parentData!['studentName'] ?? 'Unknown';
        String rollNo = _parentData!['rollNumber'] ?? 'Unknown';
        String month = voucher['monthYear'] ?? 'Unknown';
        
        String? secureUrl = await CloudinaryService.uploadDartIoFile(imageFile, uploadPreset: 'Payment_Proofs');
        
        if (secureUrl != null) {
          Map<String, dynamic> updates = {};
          if (installmentIndex != null) {
             List installments = List.from(voucher['installments']);
             installments[installmentIndex]['status'] = 'pending_manual';
             installments[installmentIndex]['voucherImageUrl'] = secureUrl;
             updates['installments'] = installments;
          } else {
             updates['status'] = 'pending_manual';
             updates['voucherImageUrl'] = secureUrl;
          }
          
          await _firebaseService.updateVoucher(
            adminId, studentId, voucher['id'], updates, studentName, rollNo, month
          );
          
          PushNotificationDispatcher.sendNotificationToTopic(
             topic: 'admin_$adminId',
             title: 'Manual Verification Needed',
             body: 'Voucher uploaded by $studentName ($rollNo) for $month requires manual verification.',
             additionalData: {
               'route': 'FeeManagementScreen',
               'studentDocId': studentId,
               'rollNo': rollNo,
             }
          );
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitted for manual verification."), backgroundColor: Colors.blue));
          }
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image. Try again."), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
          }
      } finally {
        if (mounted) setState(() => _isUploadingVoucher = false);
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
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              navigateWithLoader(context, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
                );
              });
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getStudentVouchersStream(_parentData!['adminId'], _parentData!['docId']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final now = _firebaseService.secureTime;
                  var vouchers = snapshot.data!.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
                  
                  // 🔥 Filter vouchers: Hide future months until the 1st of that month
                  vouchers = vouchers.where((v) {
                    try {
                      String? monthYear = v['monthYear'];
                      if (monthYear == null || monthYear == 'N/A') return true;
                      DateTime voucherDate = DateFormat('MM-yyyy').parse(monthYear);
                      DateTime currentMonthStart = DateTime(now.year, now.month, 1);
                      return !voucherDate.isAfter(currentMonthStart);
                    } catch (e) {
                      return true;
                    }
                  }).toList();

                  var unpaidVouchers = vouchers.where((v) => v['status'] == 'unpaid' || v['status'] == 'pending_manual').toList();
                  var paidVouchers = vouchers.where((v) => v['status'] == 'paid').toList();
                  
                  String currentMonthKey = DateFormat('MM-yyyy').format(now);
                  var currentMonthVouchers = vouchers.where((v) => v['monthYear'] == currentMonthKey).toList();

                  double totalUnpaid = currentMonthVouchers.fold(0.0, (sum, v) {
                    if (v['status'] == 'paid') return sum;
                    List installments = v['installments'] as List? ?? [];
                    if (installments.isNotEmpty) {
                      double unpaidInst = installments
                          .where((inst) => inst['status'] == 'unpaid')
                          .fold(0.0, (s, inst) => s + (double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0));
                      return sum + unpaidInst;
                    }
                    double base = double.tryParse(v['baseFee']?.toString() ?? '0') ?? 0.0;
                    double add = double.tryParse(v['additionalCharge']?.toString() ?? '0') ?? 0.0;
                    double pen = _isOverdue(v['dueDateRaw']) ? (double.tryParse(v['latePenalty']?.toString() ?? '0') ?? 0.0) : 0.0;
                    return sum + (base + add + pen);
                  });

                  double totalPaid = currentMonthVouchers.fold(0.0, (sum, v) {
                    List installments = v['installments'] as List? ?? [];
                    if (v['status'] == 'paid') {
                      double base = double.tryParse(v['baseFee']?.toString() ?? '0') ?? 0.0;
                      double add = double.tryParse(v['additionalCharge']?.toString() ?? '0') ?? 0.0;
                      double pen = double.tryParse(v['latePenaltyApplied']?.toString() ?? v['latePenalty']?.toString() ?? '0') ?? 0.0;
                      return sum + (base + add + pen);
                    }
                    if (installments.isNotEmpty) {
                      double paidInst = installments
                          .where((inst) => inst['status'] == 'paid')
                          .fold(0.0, (s, inst) => s + (double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0));
                      return sum + paidInst;
                    }
                    return sum;
                  });

                  String className = _parentData!['class'] ?? 'N/A';

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header Section with Gradient Background
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              children: [
                                // App Bar Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          navigateWithLoader(context, () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
                                            );
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        Translations.get('Fee Details', isUrdu),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Summary Card - Sequential Flow
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                                  child: _buildOverviewCard(className, totalUnpaid + totalPaid, totalPaid, isUrdu),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              if (unpaidVouchers.isNotEmpty) ...[
                                _buildSectionHeader(Translations.get('Unpaid Fee', isUrdu)),
                                const SizedBox(height: 15),
                                ...unpaidVouchers.expand((v) {
                                  bool overdue = _isOverdue(v['dueDateRaw']);
                                  double penalty = double.tryParse(v['latePenalty']?.toString() ?? '0') ?? 0.0;
                                  
                                  List installments = v['installments'] as List? ?? [];
                                  if (installments.isNotEmpty) {
                                    List<Widget> installmentCards = [];
                                    for (int i = 0; i < installments.length; i++) {
                                      var inst = installments[i];
                                      installmentCards.add(
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (overdue && penalty > 0 && installmentCards.isEmpty) ...[
                                                _buildLateFeeWarning(penalty, isUrdu),
                                                const SizedBox(height: 8),
                                              ],
                                              _buildUnpaidInstallmentCard(v, inst, i, isUrdu),
                                            ],
                                          ),
                                        )
                                      );
                                    }
                                    return installmentCards;
                                  } else {
                                    return [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (overdue && penalty > 0) ...[
                                              _buildLateFeeWarning(penalty, isUrdu),
                                              const SizedBox(height: 8),
                                            ],
                                            _buildUnpaidVoucherCard(v, isUrdu),
                                          ],
                                        ),
                                      )
                                    ];
                                  }
                                }),
                              ],

                              const SizedBox(height: 10),

                              if (paidVouchers.isNotEmpty) ...[
                                _buildSectionHeader(Translations.get('Payment History', isUrdu)),
                                const SizedBox(height: 15),
                                ...paidVouchers.map((v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: _buildPaidVoucherCard(v, isUrdu),
                                )),
                              ],
                              
                              if (unpaidVouchers.isEmpty && paidVouchers.isEmpty)
                                Center(child: Text(Translations.get('No vouchers found.', isUrdu), style: const TextStyle(color: Colors.grey))),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              bottomNavigationBar: _buildBottomNav(isUrdu),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildOverviewCard(String className, double total, double paidAmount, bool isUrdu) {
    double remaining = total - paidAmount;
    double progress = total > 0 ? (paidAmount / total) : 0.0;
    String currentMonth = DateFormat('MMMM').format(_firebaseService.secureTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                '${Translations.get('Academic Year', isUrdu)} 2026',
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                Translations.get('Total Fee', isUrdu),
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                className,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'Rs. ${total.toInt()}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            currentMonth,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressInfo('Paid Amount', 'Rs. ${paidAmount.toInt()}', isUrdu, color: greenColor),
              _buildProgressInfo('Remaining', 'Rs. ${remaining.toInt()}', isUrdu, color: orangeColor),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 12,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '${(progress * 100).toInt()} %',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, String amount, bool isUrdu, {required Color color}) {
    return Column(
      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          Translations.get(label, isUrdu),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildUnpaidVoucherCard(Map<String, dynamic> voucher, bool isUrdu) {
    dynamic dueDateRaw = voucher['dueDateRaw'];
    bool overdue = _isOverdue(dueDateRaw);
    
    double base = double.tryParse(voucher['baseFee']?.toString() ?? '0') ?? 0.0;
    double additional = double.tryParse(voucher['additionalCharge']?.toString() ?? '0') ?? 0.0;
    double penalty = double.tryParse(voucher['latePenalty']?.toString() ?? '0') ?? 0.0;
    
    double total = base + additional + (overdue ? penalty : 0);
    
    String className = voucher['className'] ?? 'N/A';
    String dueDate = 'N/A';
    if (dueDateRaw is Timestamp) {
      dueDate = DateFormat('dd/MM/yyyy').format(dueDateRaw.toDate());
    }
    
    List installments = voucher['installments'] as List? ?? [];
    String installmentLabel = installments.isNotEmpty ? (installments[0]['label'] ?? 'Installment') : 'Standard Voucher';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                className,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'Rs. ${total.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${Translations.get('Due:', isUrdu)} $dueDate',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildBadge(
                (voucher['status'] == 'paid' || voucher['status'] == 'Paid') 
                    ? Translations.get('Paid', isUrdu) 
                    : (voucher['status'] == 'pending_manual' ? Translations.get('Review', isUrdu) : Translations.get('Pending', isUrdu)),
                (voucher['status'] == 'paid' || voucher['status'] == 'Paid') 
                    ? Colors.green 
                    : (voucher['status'] == 'pending_manual' ? Colors.orange : orangeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstallmentBadge(installmentLabel),
          
          const SizedBox(height: 20),
          if (voucher['status'] == 'pending_manual')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(Translations.get('Pending Admin Review', isUrdu), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
            )
          else if (voucher['status'] == 'paid' || voucher['status'] == 'Paid')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(Translations.get('Paid', isUrdu), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ThrottledButton.elevated(
                onPressed: _isUploadingVoucher ? () {} : () => _handleVoucherUpload(voucher),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isUploadingVoucher
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          Translations.get('Upload Payment Proof', isUrdu),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnpaidInstallmentCard(Map<String, dynamic> voucher, Map<String, dynamic> inst, int index, bool isUrdu) {
    String className = voucher['className'] ?? 'N/A';
    
    dynamic dueDateRaw = inst['dueDateRaw'] ?? voucher['dueDateRaw'];
    String dueDate = 'N/A';
    if (dueDateRaw is Timestamp) {
      dueDate = DateFormat('dd/MM/yyyy').format(dueDateRaw.toDate());
    } else if (voucher['dueDate'] != null) {
      dueDate = voucher['dueDate'];
    }

    String displayDate = inst['dueDate'] ?? dueDate;
    if (index == 1 && displayDate == dueDate) {
      try {
        List<String> parts = dueDate.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          DateTime baseDate = DateTime(year, month, day);
          DateTime extDate = baseDate.add(const Duration(days: 8));
          displayDate = "${extDate.day.toString().padLeft(2, '0')}/${extDate.month.toString().padLeft(2, '0')}/${extDate.year}";
        }
      } catch (e) {}
    }
    
    dueDate = displayDate;
    
    double amount = double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0;
    
    bool overdue = _isOverdue(dueDateRaw);
    if (overdue && index == _getFirstUnpaidIndex(voucher['installments'])) {
       double penalty = double.tryParse(voucher['latePenalty']?.toString() ?? '0') ?? 0.0;
       amount += penalty;
    }

    String installmentLabel = inst['label'] ?? 'Installment ${index + 1}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                className,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'Rs. ${amount.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${Translations.get('Due:', isUrdu)} $dueDate',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildBadge(
                (inst['status'] == 'paid' || inst['status'] == 'Paid') 
                    ? Translations.get('Paid', isUrdu) 
                    : (inst['status'] == 'pending_manual' ? Translations.get('Review', isUrdu) : Translations.get('Pending', isUrdu)),
                (inst['status'] == 'paid' || inst['status'] == 'Paid') 
                    ? Colors.green 
                    : (inst['status'] == 'pending_manual' ? Colors.orange : orangeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstallmentBadge(installmentLabel),
          
          const SizedBox(height: 20),
          if (inst['status'] == 'pending_manual')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(Translations.get('Pending Admin Review', isUrdu), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
            )
          else if (inst['status'] == 'paid' || inst['status'] == 'Paid')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(Translations.get('Paid', isUrdu), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ThrottledButton.elevated(
                onPressed: _isUploadingVoucher ? () {} : () => _handleVoucherUpload(voucher, installmentIndex: index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isUploadingVoucher
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          Translations.get('Upload Payment Proof', isUrdu),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
              ),
            ),
        ],
      ),
    );
  }

  int _getFirstUnpaidIndex(List installments) {
    return installments.indexWhere((inst) => inst['status'] == 'unpaid');
  }

  Widget _buildPaidVoucherCard(Map<String, dynamic> voucher, bool isUrdu) {
    double base = double.tryParse(voucher['baseFee']?.toString() ?? '0') ?? 0.0;
    double additional = double.tryParse(voucher['additionalCharge']?.toString() ?? '0') ?? 0.0;
    double penalty = double.tryParse(voucher['latePenaltyApplied']?.toString() ?? '0') ?? 0.0;
    double total = base + additional + penalty;
    
    String className = voucher['className'] ?? 'N/A';
    
    dynamic dueDateRaw = voucher['dueDateRaw'];
    String dueDate = 'N/A';
    if (dueDateRaw is Timestamp) {
      dueDate = DateFormat('dd/MM/yyyy').format(dueDateRaw.toDate());
    }

    List installments = voucher['installments'] as List? ?? [];
    String installmentLabel = installments.isNotEmpty ? (installments[0]['label'] ?? 'Installment') : 'Standard Voucher';

    dynamic paidDateRaw = voucher['paidAt'] ?? voucher['updatedAt'];
    String paidDate = 'N/A';
    if (paidDateRaw is Timestamp) {
      paidDate = DateFormat('dd/MM/yyyy').format(paidDateRaw.toDate());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                className,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'Rs. ${total.toInt()}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${Translations.get('Due:', isUrdu)} $dueDate',
                style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 20, color: Color(0xFF4CAF50)),
              const SizedBox(width: 5),
              Text(
                '${Translations.get('Paid on:', isUrdu)} $paidDate',
                style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildBadge('Paid', greenColor),
            ],
          ),
          const SizedBox(height: 15),
          _buildInstallmentBadge(installmentLabel),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        Translations.get(text, languageNotifier.value),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInstallmentBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        Translations.get(text, languageNotifier.value),
        style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLateFeeWarning(double penalty, bool isUrdu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE11D48), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${Translations.get('Note: A Late Fee Penalty of Rs.', isUrdu)} ${penalty.toInt()} ${Translations.get('has been added to your voucher.', isUrdu)}',
              style: const TextStyle(
                color: Color(0xFF9F1239),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isUrdu) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
        elevation: 0,
        backgroundColor: Colors.white,
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
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: Translations.get('Home', isUrdu)),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), activeIcon: const Icon(Icons.calendar_today), label: Translations.get('Fees', isUrdu)),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: Translations.get('Voucher', isUrdu)),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), activeIcon: const Icon(Icons.notifications), label: Translations.get('Alerts', isUrdu)),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: Translations.get('Profile', isUrdu)),
        ],
      ),
    );
  }
}
