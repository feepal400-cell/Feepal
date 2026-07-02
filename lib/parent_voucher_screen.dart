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
import 'services/voucher_pdf_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ParentVoucherScreen extends StatefulWidget {
  const ParentVoucherScreen({super.key});

  @override
  State<ParentVoucherScreen> createState() => _ParentVoucherScreenState();
}

class _ParentVoucherScreenState extends State<ParentVoucherScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;
  String? _selectedVoucherId;
  int _selectedInstallment = -1; // -1 means none selected
  bool _isDownloading = false;
  bool _selectionInitialized = false;
  DateTime? _serverTime;

  @override
  void initState() {
    super.initState();
    _parentData = _firebaseService.selectedStudent;
    _syncTime();
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

  Stream<DocumentSnapshot>? _getStudentStream() {
    if (_parentData == null) return null;
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(_parentData!['adminId'])
        .collection('students')
        .doc(_parentData!['docId'].toString())
        .snapshots();
  }

  Widget _buildInstallmentPill(String text, bool isUrdu) {
    String translatedText = text;
    if (text.contains('Arrears Installment')) {
      translatedText = text.replaceFirst(
        'Arrears Installment',
        Translations.get('Arrears Installment', isUrdu),
      );
    } else if (text.contains('Installment')) {
      translatedText = text.replaceFirst(
        'Installment',
        Translations.get('Installment', isUrdu),
      );
    } else {
      translatedText = Translations.get(text, isUrdu);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(
          0xFF00D4FF,
        ).withValues(alpha: 0.12), // Parent theme blue with opacity
        borderRadius: BorderRadius.circular(20), // Fully rounded
      ),
      child: Text(
        translatedText,
        style: const TextStyle(
          color: Color(0xFF009BCB), // Darker theme blue
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
        body: const Center(
          child: Text("Session expired. Please log in again."),
        ),
      );
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
                  MaterialPageRoute(
                    builder: (context) => const ParentDashboardScreen(),
                  ),
                );
              });
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getStudentVouchersStream(
                  _parentData!['adminId'],
                  _parentData!['docId'],
                ),
                builder: (context, voucherSnapshot) {
                  if (voucherSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      _serverTime == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var allVouchers =
                      voucherSnapshot.data?.docs
                          .map(
                            (doc) => {
                              ...doc.data() as Map<String, dynamic>,
                              'id': doc.id,
                            },
                          )
                          .toList() ??
                      [];

                  // 🔥 Filter vouchers: Hide future months until the 1st of that month
                  var vouchers = allVouchers.where((v) {
                    try {
                      String? monthYear = v['monthYear'];
                      if (monthYear == null || monthYear == 'N/A') return true;
                      DateTime voucherDate = DateFormat(
                        'MM-yyyy',
                      ).parse(monthYear);
                      DateTime currentMonthStart = DateTime(
                        _serverTime!.year,
                        _serverTime!.month,
                        1,
                      );
                      return !voucherDate.isAfter(currentMonthStart);
                    } catch (e) {
                      return true;
                    }
                  }).toList();

                  var unpaidVouchers = vouchers
                      .where(
                        (v) =>
                            v['status'] == 'unpaid' ||
                            v['status'] == 'pending_manual',
                      )
                      .toList();

                  if (!_selectionInitialized && unpaidVouchers.isNotEmpty) {
                    _selectedVoucherId = unpaidVouchers.first['id'];
                    _selectionInitialized = true;
                  }

                  if (unpaidVouchers.isEmpty) {
                    return _buildEmptyState(isUrdu);
                  }

                  // Find the voucher using ID, fallback to first if not found
                  var voucher =
                      unpaidVouchers.any((v) => v['id'] == _selectedVoucherId)
                      ? unpaidVouchers.firstWhere(
                          (v) => v['id'] == _selectedVoucherId,
                        )
                      : unpaidVouchers.first;
                  String studentName = voucher['studentName'] ?? 'Unknown';
                  String className = voucher['className'] ?? '';
                  dynamic dueDateRaw = voucher['dueDateRaw'];
                  bool isInstallmentAllowed =
                      voucher['isInstallmentAllowed'] ?? false;
                  bool overdue = _isOverdue(dueDateRaw);

                  double baseFee =
                      double.tryParse(voucher['baseFee']?.toString() ?? '0') ??
                      0.0;
                  double additional =
                      double.tryParse(
                        voucher['additionalCharge']?.toString() ?? '0',
                      ) ??
                      0.0;
                  double penalty =
                      double.tryParse(
                        voucher['latePenalty']?.toString() ?? '0',
                      ) ??
                      0.0;

                  // Adjust for installments if selected
                  if (_selectedInstallment != -1) {
                    baseFee = baseFee / 2;
                    additional = additional / 2;
                    if (_selectedInstallment == 1) {
                      penalty = 0; // Penalty is usually in installment 1
                    }
                  }
                  double paidInstsTotal = 0.0;
                  List installmentsList =
                      voucher['installments'] as List? ?? [];
                  if (_selectedInstallment == -1 &&
                      installmentsList.isNotEmpty) {
                    paidInstsTotal = installmentsList
                        .where(
                          (inst) =>
                              inst['status'] == 'paid' ||
                              inst['status'] == 'Paid',
                        )
                        .fold(
                          0.0,
                          (s, inst) =>
                              s +
                              (double.tryParse(
                                    inst['amount']?.toString() ?? '0',
                                  ) ??
                                  0.0),
                        );
                  }

                  // Penalty ONLY added if overdue
                  double finalTotalDue =
                      baseFee +
                      additional +
                      (overdue ? penalty : 0) -
                      paidInstsTotal;

                  String dueDate = voucher['dueDate'] ?? 'N/A';
                  if (dueDateRaw is Timestamp) {
                    dueDate = DateFormat(
                      'dd/MM/yyyy',
                    ).format(dueDateRaw.toDate());
                  }

                  bool showInstallments =
                      (voucher['installments'] as List? ?? []).isNotEmpty;
                  bool allowInstallments = true;

                  String currentMonth = DateFormat(
                    'MM-yyyy',
                  ).format(_firebaseService.secureTime);
                  bool isCurrentMonth = voucher['monthYear'] == currentMonth;

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
                                    colors: [
                                      Color(0xFF00D4FF),
                                      Color(0xFF009BCB),
                                    ],
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                          vertical: 15.0,
                                        ),
                                        child: Text(
                                          Translations.get(
                                            'Generate Voucher',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15,
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  Translations.get(
                                                    'Student Name',
                                                    isUrdu,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  Translations.get(
                                                    'Class',
                                                    isUrdu,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  studentName,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  className,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 25),

                                            Text(
                                              '${_formatMonthYear(voucher['monthYear'])} ${Translations.get('Fee', isUrdu)}',
                                              style: const TextStyle(
                                                color: Color(0xFF00D4FF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      Translations.get(
                                                        'Monthly Fee',
                                                        isUrdu,
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Rs. ${baseFee.toInt()}',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      Translations.get(
                                                        'Additional',
                                                        isUrdu,
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.blueGrey,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Rs. ${additional.toInt()}',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      Translations.get(
                                                        'Total Due',
                                                        isUrdu,
                                                      ),
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.deepOrange,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Rs. ${finalTotalDue.toInt()}',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (!overdue &&
                                                penalty > 0 &&
                                                dueDateRaw is Timestamp) ...[
                                              const SizedBox(height: 15),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Payable with Rs. ${penalty.toInt()} late fee after ${DateFormat('dd/MM/yyyy').format(dueDateRaw.toDate())}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.amber.shade900,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 15.0,
                                ),
                                child: Text(
                                  Translations.get(
                                    showInstallments
                                        ? 'Select Installment'
                                        : 'Select Voucher',
                                    isUrdu,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              if (!showInstallments)
                                ...unpaidVouchers.map(
                                  (v) => GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedVoucherId = v['id'];
                                      _selectedInstallment = -1;
                                    }),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        bottom: 15,
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: _selectedVoucherId == v['id']
                                              ? const Color(0xFF00D4FF)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${Translations.get('Month', isUrdu)}: ${_formatMonthYear(v['monthYear'])}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Rs. ${((double.tryParse(v['baseFee']?.toString() ?? '0') ?? 0.0) + (double.tryParse(v['additionalCharge']?.toString() ?? '0') ?? 0.0) + (_isOverdue(v['dueDateRaw']) ? (double.tryParse(v['latePenalty']?.toString() ?? '0') ?? 0.0) : 0)).toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 14,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${Translations.get('Due:', isUrdu)} ${v['dueDateRaw'] is Timestamp ? DateFormat('dd/MM/yyyy').format((v['dueDateRaw'] as Timestamp).toDate()) : (v['dueDate'] ?? 'N/A')}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_selectedVoucherId == v['id'] &&
                                              isCurrentMonth &&
                                              (v['isInstallmentAllowed'] ??
                                                  false)) ...[
                                            const SizedBox(height: 20),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 45,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _showInstallmentConfirmationDialog(
                                                      context,
                                                      v['id'],
                                                      isUrdu,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF00D4FF,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  Translations.get(
                                                    'Create Installments',
                                                    isUrdu,
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    ...(voucher['installments'] as List? ?? [])
                                        .asMap()
                                        .entries
                                        .where((entry) {
                                          var inst =
                                              entry.value
                                                  as Map<String, dynamic>;
                                          return inst['status'] != 'paid' &&
                                              inst['status'] != 'Paid';
                                        })
                                        .map((entry) {
                                          int idx = entry.key;
                                          var inst =
                                              entry.value
                                                  as Map<String, dynamic>;
                                          String displayDate =
                                              inst['dueDate'] ?? dueDate;
                                          if (idx == 1 &&
                                              displayDate == dueDate) {
                                            try {
                                              List<String> parts = dueDate
                                                  .split('/');
                                              if (parts.length == 3) {
                                                // Handle both MM/DD and DD/MM by checking which one is likely the day
                                                // But since we just set it to dd/MM/yyyy, parts[0] is day, parts[1] is month
                                                int day = int.parse(parts[0]);
                                                int month = int.parse(parts[1]);
                                                int year = int.parse(parts[2]);
                                                DateTime baseDate = DateTime(
                                                  year,
                                                  month,
                                                  day,
                                                );
                                                DateTime extDate = baseDate.add(
                                                  const Duration(days: 8),
                                                );
                                                displayDate =
                                                    "${extDate.day}/${extDate.month}/${extDate.year}";
                                              }
                                            } catch (e) {}
                                          }
                                          String labelText =
                                              inst['label'] ?? 'Installment';
                                          return _buildInstallmentChoiceCard(
                                            idx,
                                            labelText,
                                            displayDate,
                                            'Rs. ${inst['amount']}',
                                            className,
                                            isUrdu,
                                          );
                                        }),

                                    const SizedBox(height: 10),
                                  ],
                                ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      if (showInstallments && _selectedInstallment == -1)
                        const SizedBox.shrink()
                      else
                        Container(
                          color: const Color(0xFFFAFAFA),
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isDownloading
                                  ? null
                                  : () async {
                                      if (showInstallments &&
                                          _selectedInstallment == -1) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              Translations.get(
                                                'Please select an installment',
                                                isUrdu,
                                              ),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                              bottom: 30,
                                              left: 30,
                                              right: 30,
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => _isDownloading = true);

                                      try {
                                        debugPrint(
                                          "--------------------------------------------------",
                                        );
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Download button clicked!",
                                        );
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Voucher ID: ${voucher['id']}",
                                        );
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Installment Selected: $_selectedInstallment",
                                        );

                                        // 1. Fetch School Data
                                        final adminId = _parentData!['adminId'];
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Fetching Admin Data for: $adminId",
                                        );
                                        final adminData = await _firebaseService
                                            .getAdminData(adminId);
                                        if (adminData == null) {
                                          throw Exception(
                                            "Could not fetch school details",
                                          );
                                        }
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Admin Data Fetched: ${adminData['schoolName']}",
                                        );

                                        // 2. Fetch Logo Bytes if available
                                        Uint8List? logoBytes;
                                        final logoUrl =
                                            adminData['schoolLogoUrl'];
                                        if (logoUrl != null &&
                                            logoUrl.toString().isNotEmpty) {
                                          debugPrint(
                                            "📥 [VOUCHER DEBUG] Fetching Logo from: $logoUrl",
                                          );
                                          try {
                                            final response = await http.get(
                                              Uri.parse(logoUrl.toString()),
                                            );
                                            if (response.statusCode == 200) {
                                              logoBytes = response.bodyBytes;
                                              debugPrint(
                                                "📥 [VOUCHER DEBUG] Logo Fetched (${logoBytes.length} bytes)",
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint(
                                              "📥 [VOUCHER DEBUG] Logo fetch failed: $e",
                                            );
                                          }
                                        }

                                        // 3. Prepare Voucher Data
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Preparing Data Structures...",
                                        );
                                        // Handle Installment logic
                                        final bool isInstallment =
                                            _selectedInstallment != -1;
                                        Map<String, dynamic> currentFeeData =
                                            Map.from(voucher);

                                        if (isInstallment) {
                                          final inst =
                                              (voucher['installments']
                                                  as List)[_selectedInstallment];
                                          currentFeeData['paymentType'] =
                                              'Installment';
                                          currentFeeData['totalAmount'] =
                                              inst['amount'];
                                          currentFeeData['installmentNumber'] =
                                              _selectedInstallment + 1;
                                          currentFeeData['totalInstallments'] =
                                              (voucher['installments'] as List)
                                                  .length;
                                          currentFeeData['dueDate'] =
                                              inst['dueDate'] ??
                                              currentFeeData['dueDate'];
                                        } else {
                                          currentFeeData['paymentType'] =
                                              'Standard';
                                          currentFeeData['totalAmount'] =
                                              finalTotalDue;
                                        }

                                        // Terminology mapping & Sibling Discount Removal (implicit in fee calculation)
                                        final studentInfo = {
                                          'studentName': studentName,
                                          'parentName':
                                              _parentData!['parentName'] ??
                                              'N/A',
                                          'rollNumber':
                                              _parentData!['rollNumber'] ??
                                              'N/A',
                                          'class': className,
                                        };

                                        final feeInfo = {
                                          'voucherId': voucher['id'],
                                          'feeMonth': _formatMonthYear(
                                            voucher['monthYear'],
                                          ),
                                          'baseFee': baseFee,
                                          'additionalCharges': additional,
                                          'totalAmount': isInstallment
                                              ? currentFeeData['totalAmount']
                                              : finalTotalDue,
                                          'dueDate': isInstallment
                                              ? currentFeeData['dueDate']
                                              : dueDate,
                                          'lateFeeAmount': penalty,
                                          'paymentType':
                                              currentFeeData['paymentType'],
                                          'installmentNumber':
                                              currentFeeData['installmentNumber'],
                                          'totalInstallments':
                                              currentFeeData['totalInstallments'],
                                        };

                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Data Prepared. Calling PDF Service...",
                                        );

                                        // 4. Generate & Print
                                        final doc =
                                            await VoucherPdfService.generateVoucher(
                                              schoolData: adminData,
                                              studentData: studentInfo,
                                              feeData: feeInfo,
                                              logoBytes: logoBytes,
                                            );

                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] PDF Generated by Service. Passing to Printing...",
                                        );
                                        await VoucherPdfService.printVoucher(
                                          doc,
                                          "Voucher_${voucher['monthYear']}.pdf",
                                        );
                                        debugPrint(
                                          "📥 [VOUCHER DEBUG] Download flow finished successfully.",
                                        );
                                        debugPrint(
                                          "--------------------------------------------------",
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("Error: $e"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isDownloading = false,
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: _isDownloading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          Translations.get(
                                            'Downloading...',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          Translations.get(
                                            'Download Voucher',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentDashboardScreen(),
                        ),
                      );
                    });
                  } else if (index == 1) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentFeesScreen(),
                        ),
                      );
                    });
                  } else if (index == 3) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentAlertsScreen(),
                        ),
                      );
                    });
                  } else if (index == 4) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentProfileScreen(),
                        ),
                      );
                    });
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    label: Translations.get('Home', isUrdu),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_today),
                    label: Translations.get('Fees', isUrdu),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Translations.get('Voucher', isUrdu),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.notifications_none_outlined),
                    label: Translations.get('Alerts', isUrdu),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    label: Translations.get('Profile', isUrdu),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstallmentChoiceCard(
    int index,
    String installmentLabel,
    String dueDate,
    String amount,
    String className,
    bool isUrdu,
  ) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  className.toLowerCase().contains('class')
                      ? className
                      : '${Translations.get('Class', isUrdu)} $className',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 5),
                Text(
                  '${Translations.get('Due:', isUrdu)} $dueDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
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
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(
              Translations.get('Action Blocked', isUrdu),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          Translations.get(
            'Please clear previous dues and pending installments before generating the current month\'s voucher.',
            isUrdu,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              Translations.get('OK', isUrdu),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallmentConfirmationDialog(
    BuildContext context,
    String voucherId,
    bool isUrdu,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Translations.get('Create Installments?', isUrdu),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          Translations.get(
            'Installments once made cannot be reverted.',
            isUrdu,
          ),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              Translations.get('Cancel', isUrdu),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _firebaseService.splitVoucherIntoInstallments(
                _parentData!['adminId'],
                _parentData!['docId'].toString(),
                voucherId,
              );
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              Translations.get('Yes Make installments', isUrdu),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isUrdu) {
    String studentName = _parentData?['studentName'] ?? 'Student';
    String rollNo = _parentData?['rollNumber'] ?? 'N/A';
    String className = _parentData?['class'] ?? 'N/A';

    return Column(
      children: [
        // 1. Top Header (Blue Gradient)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 15.0,
                  ),
                  child: Text(
                    Translations.get('Voucher Status', isUrdu),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 2. Overlapping Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            Translations.get('Roll No', isUrdu),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            rollNo,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.get('Fee Status', isUrdu),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            Translations.get('PAID', isUrdu),
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.green.shade700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "100%",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Animated Body
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.green,
                          size: 100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          Translations.get('All Dues Clear!', isUrdu),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            Translations.get(
                              'Your record is up to date. No pending months found for the current period.',
                              isUrdu,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Optional: A small "Refreshed" text
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 0.4),
                        child: child,
                      );
                    },
                    child: Text(
                      'Last updated: ${DateFormat('hh:mm a').format(_firebaseService.secureTime.toUtc().add(const Duration(hours: 5)))}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
