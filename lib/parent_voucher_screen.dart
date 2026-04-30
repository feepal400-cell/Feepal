import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';
import 'services/firebase_service.dart';

class ParentVoucherScreen extends StatefulWidget {
  const ParentVoucherScreen({super.key});

  @override
  State<ParentVoucherScreen> createState() => _ParentVoucherScreenState();
}

class _ParentVoucherScreenState extends State<ParentVoucherScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;
  bool _isInstallmentsMode = false;
  bool _isArrearsInstallmentsMode = false;
  int _selectedInstallment = -1; // -1 means none selected
  bool _isDownloading = false;
  String _selectedVoucherType = 'monthly';
  bool _selectionInitialized = false;

  @override
  void initState() {
    super.initState();
    _parentData = _firebaseService.selectedStudent;
  }

  Stream<DocumentSnapshot>? _getStudentStream() {
    if (_parentData == null) return null;
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(_parentData!['adminId'])
        .collection('students')
        .doc(_parentData!['docId'].toString())
        .snapshots();
  }

  Stream<QuerySnapshot>? _getFeeStream(String className) {
    if (_parentData == null) return null;
    return _firebaseService.getFeeStream(_parentData!['adminId'], className);
  }

  Widget _buildInstallmentPill(String text, bool isUrdu) {
    String translatedText = text;
    if (text.contains('Arrears Installment')) {
      translatedText = text.replaceFirst('Arrears Installment', Translations.get('Arrears Installment', isUrdu));
    } else if (text.contains('Installment')) {
      translatedText = text.replaceFirst('Installment', Translations.get('Installment', isUrdu));
    } else {
      translatedText = Translations.get(text, isUrdu);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA), // Light cyan bg
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        translatedText,
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

  bool _canGenerateVoucherFunc(bool showingInstallments) {
    if (!showingInstallments) return true; 
    return _selectedInstallment != -1;
  }

  @override
  Widget build(BuildContext context) {
    if (_parentData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Session expired. Please log in again.")),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: StreamBuilder<DocumentSnapshot>(
              stream: _getStudentStream(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
                   return const Center(child: Text("Student not found."));
                }

                var student = studentSnapshot.data!.data() as Map<String, dynamic>;
                String studentName = student['studentName'] ?? 'Unknown';
                String className = student['class'] ?? '';
                String feeStatus = student['feeStatus']?.toString().toLowerCase() ?? 'unpaid';
                 bool isPaid = feeStatus == 'paid';
                
                bool dbHasInstallments = student['hasInstallments'] ?? false;
                bool dbHasArrearsInstallments = student['hasArrearsInstallments'] ?? false;
                
                bool showInstallments = false;
                if (_selectedVoucherType == 'monthly') {
                  showInstallments = _isInstallmentsMode || dbHasInstallments;
                } else {
                  showInstallments = _isArrearsInstallmentsMode || dbHasArrearsInstallments;
                }
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _getFeeStream(className),
                  builder: (context, feeSnapshot) {
                    if (feeSnapshot.hasData && feeSnapshot.data!.docs.isEmpty && dbHasInstallments) {
                      Future.microtask(() {
                        if (context.mounted) {
                          _firebaseService.updateStudentInstallments(
                            _parentData!['adminId'],
                            _parentData!['docId'].toString(),
                            [],
                          );
                        }
                      });
                    }

                    double totalFee = 0.0;
                    String dueDate = 'N/A';
                    bool allowInstallments = false;

                    if (feeSnapshot.hasData && feeSnapshot.data!.docs.isNotEmpty) {
                      var docs = List.from(feeSnapshot.data!.docs);
                      docs.sort((a, b) {
                        var at = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        var bt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        if (at == null) return 1;
                        if (bt == null) return -1;
                        return bt.compareTo(at);
                      });

                      var feeData = docs.first.data() as Map<String, dynamic>;
                      totalFee = double.tryParse(feeData['amount']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0;
                      allowInstallments = feeData['allowInstallments'] ?? false;
                      
                      String fallbackDate = 'N/A';
                      if (feeData['dueDateRaw'] != null) {
                        try {
                          DateTime d = (feeData['dueDateRaw'] as Timestamp).toDate();
                          fallbackDate = "${d.month}/${d.day}/${d.year}";
                        } catch (e) {}
                      } else if (feeData['createdAt'] != null) {
                         try {
                          DateTime d = (feeData['createdAt'] as Timestamp).toDate().add(const Duration(days: 30)); 
                          fallbackDate = "${d.month}/${d.day}/${d.year}";
                        } catch (e) {}
                      }
                      dueDate = feeData['dueDate'] ?? fallbackDate;

                      num discountPercent = student['siblingDiscountPercentage'] ?? 0;
                      double totalBeforeDiscount = totalFee;
                      double discountAmount = (totalBeforeDiscount * discountPercent) / 100;
                      totalFee = totalBeforeDiscount - discountAmount;
                    }

                    double arrears = double.tryParse(student['arrearsBalance']?.toString() ?? '0') ?? 0.0;
                    double finalTotalDue = arrears + (isPaid ? 0.0 : totalFee);
                    double currentMonthPaid = isPaid ? totalFee : 0.0;

                    if (!_selectionInitialized && arrears > 0) {
                      _selectedVoucherType = 'arrears';
                      _selectionInitialized = true;
                    } else if (!_selectionInitialized) {
                      _selectedVoucherType = 'monthly';
                      _selectionInitialized = true;
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                                          child: Text(
                                            Translations.get('Generate Voucher', isUrdu),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        
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
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    studentName,
                                                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    className,
                                                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 25),
                                              
                                              Text(
                                                '${DateFormat('MMMM').format(DateTime.now())} ${Translations.get('Fee', isUrdu)}',
                                                style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10),
                                              
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        Translations.get('Monthly Fee', isUrdu),
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        'Rs. ${totalFee.toInt()}',
                                                        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        Translations.get('Current Paid', isUrdu),
                                                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        'Rs. ${currentMonthPaid.toInt()}',
                                                        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        Translations.get('Total Due', isUrdu),
                                                        style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w500),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        'Rs. ${finalTotalDue.toInt()}',
                                                        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  if (arrears > 0)
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          Translations.get('Arrears', isUrdu),
                                                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          'Rs. ${arrears.toInt()}',
                                                          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
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
                                
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                                  child: Text(
                                    Translations.get(showInstallments ? 'Select Installment' : 'Fees', isUrdu),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                
                                if (isPaid)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Center(
                                      child: Text(
                                        Translations.get('Fees are already paid.', isUrdu),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                      ),
                                    ),
                                  )
                                else if (!showInstallments)
                                  Column(
                                    children: [
                                      if (arrears > 0) ...[
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedVoucherType = 'arrears';
                                            _selectedInstallment = -1;
                                          }),
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 20),
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(
                                                color: _selectedVoucherType == 'arrears' ? const Color(0xFF00D4FF) : Colors.transparent,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      Translations.get('Arrears', isUrdu),
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                    ),
                                                    Text(
                                                      'Rs. ${arrears.toInt()}',
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
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
                                                if (_selectedVoucherType == 'arrears') ...[
                                                  if (dbHasArrearsInstallments) ...[
                                                    const SizedBox(height: 20),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 40,
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          await _firebaseService.updateStudentArrearsInstallments(_parentData!['adminId'], _parentData!['docId'].toString(), []);
                                                          setState(() {
                                                            _isArrearsInstallmentsMode = false;
                                                            _selectedInstallment = -1;
                                                          });
                                                        },
                                                        style: OutlinedButton.styleFrom(
                                                          side: const BorderSide(color: Colors.redAccent),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        child: Text(Translations.get('Reset Installments', isUrdu), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                  ] else if (arrears > 5000) ...[
                                                    const SizedBox(height: 20),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 45,
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          double half = arrears / 2;
                                                          List<Map<String, dynamic>> insts = [
                                                            {'label': 'Arrears Installment 1', 'amount': half.toInt()},
                                                            {'label': 'Arrears Installment 2', 'amount': half.toInt()},
                                                          ];
                                                          await _firebaseService.updateStudentArrearsInstallments(_parentData!['adminId'], _parentData!['docId'].toString(), insts);
                                                          setState(() => _isArrearsInstallmentsMode = true);
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.redAccent,
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                          elevation: 0,
                                                        ),
                                                        child: Text(Translations.get('Split into 2 installments', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Center(
                                                      child: Text(
                                                        Translations.get('Arrears over Rs. 5000 can be split', isUrdu),
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                      ],

                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedVoucherType = 'monthly';
                                          _selectedInstallment = -1;
                                        }),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: _selectedVoucherType == 'monthly' ? const Color(0xFF00D4FF) : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    className.toLowerCase().contains('class') ? className : '${Translations.get('Class', isUrdu)} $className',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                                  ),
                                                  Text(
                                                    'Rs. ${totalFee.toInt()}',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
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
                                              if (dbHasInstallments && _selectedVoucherType == 'monthly') ...[
                                                const SizedBox(height: 20),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 40,
                                                  child: OutlinedButton(
                                                    onPressed: () async {
                                                      await _firebaseService.updateStudentInstallments(_parentData!['adminId'], _parentData!['docId'].toString(), []);
                                                      setState(() {
                                                        _isInstallmentsMode = false;
                                                        _selectedInstallment = -1;
                                                      });
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(color: Colors.redAccent),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                    child: Text(Translations.get('Reset Installments', isUrdu), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ] else if (allowInstallments && _selectedVoucherType == 'monthly') ...[
                                                const SizedBox(height: 25),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 45,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      bool canProceed = await _firebaseService.canGenerateCurrentVoucher(
                                                        _parentData!['adminId'], 
                                                        _parentData!['docId'].toString()
                                                      );
                                                      if (!canProceed) {
                                                        if (context.mounted) _showBlockingDialog(context, isUrdu);
                                                        return;
                                                      }
                                                      setState(() => _isInstallmentsMode = true);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF00D4FF),
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(Translations.get('Create Installments', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ] else if (!allowInstallments && _selectedVoucherType == 'monthly') ...[
                                                const SizedBox(height: 25),
                                                Center(
                                                  child: Text(
                                                    Translations.get('Installment not allowed by school', isUrdu),
                                                    style: const TextStyle(color: Colors.deepOrange, fontSize: 14, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      ...(_selectedVoucherType == 'monthly' 
                                          ? (student['installments'] as List? ?? []) 
                                          : (student['arrearsInstallments'] as List? ?? []))
                                      .asMap().entries.map((entry) {
                                        int idx = entry.key;
                                        var inst = entry.value as Map<String, dynamic>;
                                        String displayDate = inst['dueDate'] ?? dueDate;
                                        if (idx == 1 && displayDate == dueDate) {
                                          try {
                                            List<String> parts = dueDate.split('/');
                                            if (parts.length == 3) {
                                              int month = int.parse(parts[0]);
                                              int day = int.parse(parts[1]);
                                              int year = int.parse(parts[2]);
                                              DateTime baseDate = DateTime(year, month, day);
                                              DateTime extDate = baseDate.add(const Duration(days: 14));
                                              displayDate = "${extDate.month}/${extDate.day}/${extDate.year}";
                                            }
                                          } catch (e) {}
                                        }
                                        String labelText = inst['label'] ?? 'Installment';
                                        return _buildInstallmentChoiceCard(idx, labelText, displayDate, 'Rs. ${inst['amount']}', className, isUrdu);
                                      }),
                                    ],
                                  ),
                                  
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        
                        Container(
                          color: const Color(0xFFFAFAFA),
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55, 
                            child: _isDownloading 
                              ? const SizedBox.shrink() 
                              : ElevatedButton(
                                onPressed: (!isPaid && !_isDownloading) ? () async {
                                  if (_selectedVoucherType == 'monthly') {
                                    bool canProceed = await _firebaseService.canGenerateCurrentVoucher(
                                      _parentData!['adminId'], 
                                      _parentData!['docId'].toString()
                                    );
                                    if (!canProceed) {
                                      if (context.mounted) _showBlockingDialog(context, isUrdu);
                                      return;
                                    }
                                  }

                                  if (showInstallments && _selectedInstallment == -1) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(Translations.get('Please select an installment', isUrdu), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                                        duration: const Duration(seconds: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isDownloading = true);
                                  final controller = ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF009BCB)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                            const SizedBox(width: 15),
                                            Text(Translations.get('Downloading voucher...', isUrdu), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  await controller.closed;
                                  if (mounted) setState(() => _isDownloading = false);
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isPaid ? const Color(0xFF00D4FF) : const Color(0xFFB0BEC5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isDownloading) ...[
                                      const Icon(Icons.file_download, size: 22),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      Translations.get(_isDownloading ? 'Downloading...' : 'Download Voucher', isUrdu),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                          ),
                        ),
                      ],
                    );
                  }
                );
              }
            ),
            
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 2,
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

  Widget _buildInstallmentChoiceCard(int index, String installmentLabel, String dueDate, String amount, String className, bool isUrdu) {
    bool isSelected = _selectedInstallment == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedInstallment == index) {
            _selectedInstallment = -1;
          } else {
            _selectedInstallment = index;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(className.toLowerCase().contains('class') ? className : '${Translations.get('Class', isUrdu)} $className', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 5),
                Text('${Translations.get('Due:', isUrdu)} $dueDate', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 20),
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

  void _showBlockingDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            Text(Translations.get('Action Blocked', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(Translations.get('Please clear previous dues and pending installments before generating the current month\'s voucher.', isUrdu), style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(Translations.get('OK', isUrdu), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
