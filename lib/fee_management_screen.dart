import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'bank_details_screen.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedClass;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _additionalController = TextEditingController();
  final TextEditingController _penaltyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _isInstallmentAllowed = true;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _additionalController.dispose();
    _penaltyController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _showCreateFeeBottomSheet(BuildContext context, bool isUrdu, {Map<String, dynamic>? existingFee}) async {
    // Bank Details Enforcement
    if (existingFee == null) { // Only block for NEW templates
      final profile = await _firebaseService.getAdminProfile();
      if (profile == null || 
          (profile['bankName']?.toString().trim().isEmpty ?? true) ||
          (profile['accountTitle']?.toString().trim().isEmpty ?? true) ||
          (profile['accountNumber']?.toString().trim().isEmpty ?? true)) {
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF2168F8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Translations.get('Bank Details Required', isUrdu),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(Translations.get('You must complete your bank details profile before creating fee templates. These details are required for student vouchers.', isUrdu)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Translations.get('Cancel', isUrdu), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BankDetailsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2168F8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(Translations.get('Go to Bank Details', isUrdu), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    if (existingFee != null) {
      _selectedClass = existingFee['className'];
      _amountController.text = (existingFee['baseFee'] ?? 0).toString().replaceAll(RegExp(r'\.0$'), '');
      _additionalController.text = (existingFee['additionalCharges'] ?? 0).toString().replaceAll(RegExp(r'\.0$'), '');
      _penaltyController.text = (existingFee['latePenalty'] ?? 0).toString().replaceAll(RegExp(r'\.0$'), '');
      _isInstallmentAllowed = existingFee['isInstallmentAllowed'] ?? true;
      if (existingFee['dueDateRaw'] != null) {
        _selectedDueDate = (existingFee['dueDateRaw'] as Timestamp).toDate();
      } else {
        _selectedDueDate = null;
      }
    } else {
      _selectedClass = 'Class: 1';
      _amountController.clear();
      _additionalController.clear();
      _penaltyController.clear();
      _selectedDueDate = null;
      _isInstallmentAllowed = true;
    }

    bool duplicateError = false;
    String? sheetError;
    final ScrollController sheetScrollController = ScrollController();
    bool triedSubmit = false;
    bool sheetIsSaving = false;

    String nextMonthYearStr = DateFormat('MM-yyyy').format(DateTime(_firebaseService.secureTime.year, _firebaseService.secureTime.month + 1, 1));
    bool isNextMonth = existingFee != null 
        ? existingFee['monthYear'] == nextMonthYearStr
        : _tabController.index == 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(25, 25, 25, MediaQuery.of(context).viewInsets.bottom + 10),
            child: SingleChildScrollView(
              controller: sheetScrollController,
              child: StatefulBuilder(
                builder: (context, setInternalState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingFee == null 
                            ? Translations.get('Create Monthly Template', isUrdu)
                            : Translations.get('Edit Fee Template', isUrdu), 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (isNextMonth)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF2168F8), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Translations.get(
                                  "Note: The Next Month Fee Template is only for updating or increasing the next month's fee. Due dates are carried over automatically.",
                                  isUrdu,
                                ),
                                style: const TextStyle(color: Color(0xFF2168F8), fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (sheetError != null || duplicateError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.red[100]!),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Text(
                                                duplicateError 
                                                  ? Translations.get('Fee templates duplication is not allowed', isUrdu)
                                                  : Translations.get(sheetError ?? '', isUrdu),
                                                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Class Selector
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedClass,
                                    decoration: InputDecoration(
                                      labelText: Translations.get('Select Class', isUrdu),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: ['Class: 1', 'Class: 2', 'Class: 3', 'Class: 4', 'Class: 5', 'Class: 6', 'Class: 7', 'Class: 8', 'Class: 9', 'Class: 10']
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (val) {
                                      setInternalState(() {
                                        _selectedClass = val;
                                        duplicateError = false;
                                        sheetError = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildPopupField(
                                    Translations.get('Base Fee', isUrdu), 
                                    _amountController,
                                    isMandatory: true,
                                    hasError: triedSubmit && _amountController.text.trim().isEmpty,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildPopupField(Translations.get('Additional Charges', isUrdu), _additionalController),
                                  const SizedBox(height: 15),
                                  _buildPopupField(Translations.get('Late Penalty', isUrdu), _penaltyController),
                                  const SizedBox(height: 15),
                                  // Due Date Picker
                                  if (!isNextMonth)
                                    Column(
                                      children: [
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(Translations.get('Due Date', isUrdu)),
                                          subtitle: Text(_selectedDueDate == null 
                                            ? 'Not set (Default: Due in 10 days)' 
                                            : DateFormat('dd MMMM, yyyy').format(_selectedDueDate!)),
                                          trailing: const Icon(Icons.calendar_month, color: Color(0xFF2168F8)),
                                          onTap: () async {
                                            DateTime? picked = await showDatePicker(
                                              context: context,
                                              initialDate: (_selectedDueDate != null && _selectedDueDate!.isAfter(_firebaseService.secureTime)) 
                                                  ? _selectedDueDate! 
                                                  : _firebaseService.secureTime,
                                              firstDate: _firebaseService.secureTime,
                                              lastDate: _firebaseService.secureTime.add(const Duration(days: 365)),
                                            );
                                            if (picked != null) {
                                              setInternalState(() {
                                                _selectedDueDate = picked;
                                                sheetError = null;
                                              });
                                            }
                                          },
                                        ),
                                        const Divider(),
                                        // Installment Toggle
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(Translations.get('Allow Installments', isUrdu)),
                                          subtitle: Text(Translations.get('Parents can choose to pay in two halves', isUrdu)),
                                          value: _isInstallmentAllowed,
                                          activeThumbColor: const Color(0xFF2168F8),
                                          onChanged: (val) {
                                            setInternalState(() => _isInstallmentAllowed = val);
                                          },
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 25),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: sheetIsSaving ? null : () async {
                                        if (_selectedClass == null) return;
                                        
                                        setInternalState(() {
                                          triedSubmit = true;
                                          sheetError = null;
                                          duplicateError = false;
                                        });

                                        // 1. Validate Base Fee
                                        if (_amountController.text.trim().isEmpty) {
                                          setInternalState(() => sheetError = 'You must enter base fee.');
                                          sheetScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                          return;
                                        }
                                        
                                        // 2. Validate Due Date
                                        if (_selectedDueDate != null) {
                                          DateTime serverTime = _firebaseService.secureTime;
                                          DateTime today = DateTime(serverTime.year, serverTime.month, serverTime.day);
                                          if (_selectedDueDate!.isBefore(today)) {
                                            setInternalState(() => sheetError = 'Due date cannot be in the past');
                                            sheetScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                            return;
                                          }
                                        }
                                        
                                        setInternalState(() => sheetIsSaving = true);
                                        try {
                                          String month = existingFee != null 
                                              ? existingFee['monthYear']
                                              : (_tabController.index == 1 
                                                  ? DateFormat('MM-yyyy').format(_firebaseService.secureTime)
                                                  : (_tabController.index == 2 
                                                      ? DateFormat('MM-yyyy').format(DateTime(_firebaseService.secureTime.year, _firebaseService.secureTime.month + 1, 1))
                                                      : DateFormat('MM-yyyy').format(DateTime(_firebaseService.secureTime.year, _firebaseService.secureTime.month - 1, 1))));
                                          
                                          if (existingFee == null) {
                                            bool exists = await _firebaseService.checkIfFeeTemplateExists(_selectedClass!, month);
                                            if (exists) {
                                              if (mounted) {
                                                setInternalState(() {
                                                  duplicateError = true;
                                                  sheetIsSaving = false;
                                                });
                                                sheetScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                              }
                                              return;
                                            }
                                          }

                                          DateTime serverTime = _firebaseService.secureTime;
                                          DateTime defaultDueDate = serverTime.add(const Duration(days: 10));

                                          if (isNextMonth && _selectedClass != null) {
                                            String currentMonthStr = DateFormat('MM-yyyy').format(serverTime);
                                            try {
                                              var snapshot = await FirebaseFirestore.instance
                                                  .collection('admins')
                                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                                  .collection('monthly_fees')
                                                  .doc('${_selectedClass!}_$currentMonthStr')
                                                  .get();
                                              if (snapshot.exists && snapshot.data() != null) {
                                                var currentTemplate = snapshot.data()!;
                                                if (currentTemplate['dueDateRaw'] != null) {
                                                  DateTime currentDue = (currentTemplate['dueDateRaw'] as Timestamp).toDate();
                                                  int newDay = currentDue.day;
                                                  DateTime nextMonthStart = DateTime(serverTime.year, serverTime.month + 1, 1);
                                                  int maxDays = DateTime(nextMonthStart.year, nextMonthStart.month + 1, 0).day;
                                                  if (newDay > maxDays) newDay = maxDays;
                                                  defaultDueDate = DateTime(nextMonthStart.year, nextMonthStart.month, newDay);
                                                }
                                              }
                                            } catch (e) {
                                              debugPrint("Error fetching current month template for due date: $e");
                                            }
                                          }

                                          await _firebaseService.saveMonthlyFeeTemplate({
                                            'className': _selectedClass ?? 'Class 1',
                                            'monthYear': month,
                                            'baseFee': (double.tryParse(_amountController.text) ?? 0).toInt(),
                                            'additionalCharges': (double.tryParse(_additionalController.text) ?? 0).toInt(),
                                            'latePenalty': (double.tryParse(_penaltyController.text) ?? 0).toInt(),
                                            'isInstallmentAllowed': isNextMonth ? true : _isInstallmentAllowed, // Keep true or inherit if next month
                                            'dueDate': !isNextMonth && _selectedDueDate != null 
                                                ? DateFormat('dd-MM-yyyy').format(_selectedDueDate!) 
                                                : DateFormat('dd-MM-yyyy').format(defaultDueDate),
                                            'dueDateRaw': !isNextMonth && _selectedDueDate != null 
                                                ? Timestamp.fromDate(_selectedDueDate!) 
                                                : Timestamp.fromDate(defaultDueDate),
                                          });
                                          
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _showSuccessOverlay(context, isUrdu);
                                          }
                                        } catch (e) {
                                          debugPrint("Error: $e");
                                        } finally {
                                          if (mounted) setInternalState(() => sheetIsSaving = false);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2168F8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: sheetIsSaving 
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            existingFee == null 
                                              ? Translations.get('Save Template', isUrdu)
                                              : Translations.get('Update Template', isUrdu), 
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ),
            ),
          ),
        ),
      ),
    );
}

  Widget _buildFeeCard(Map<String, dynamic> fee, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
              Text(fee['className'] ?? 'Class', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF2168F8), size: 20),
                    onPressed: () => _showCreateFeeBottomSheet(context, isUrdu, existingFee: fee),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDelete(fee, isUrdu),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text('${Translations.get('Issued for', isUrdu)}: ${_formatMonthYear(fee['monthYear'])}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_available, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          '${Translations.get('Due Date', isUrdu)}: ${fee['dueDate'] ?? 'N/A'}',
                          style: TextStyle(
                            color: (fee['dueDateRaw'] != null && (fee['dueDateRaw'] as Timestamp).toDate().isBefore(_firebaseService.secureTime)) 
                              ? Colors.redAccent 
                              : Colors.grey, 
                            fontSize: 13,
                            fontWeight: (fee['dueDateRaw'] != null && (fee['dueDateRaw'] as Timestamp).toDate().isBefore(_firebaseService.secureTime)) 
                              ? FontWeight.bold 
                              : FontWeight.normal
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Rs. ${(fee['baseFee'] ?? 0) + (fee['additionalCharges'] ?? 0)}', 
                  style: const TextStyle(color: Color(0xFF2168F8), fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> fee, bool isUrdu) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(Translations.get('Delete Fee Template', isUrdu)),
        content: Text(Translations.get('Are you sure? This will also remove vouchers for all students in this class.', isUrdu)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(Translations.get('Cancel', isUrdu))),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              Navigator.pop(dialogContext); // Close confirmation dialog
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await _firebaseService.deleteMonthlyFeeTemplate(fee['className'], fee['monthYear']);
                
                // Close loading dialog
                navigator.pop(); 
                
                if (context.mounted) _showDeleteSuccessOverlay(context, isUrdu);
              } catch (e) {
                // Close loading dialog if open
                navigator.pop();
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                );
              }
            },
            child: Text(Translations.get('Delete', isUrdu), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context, bool isUrdu) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('Success!', isUrdu),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    Translations.get('New Monthly Fee Template has been created and issued to all students.', isUrdu),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showDeleteSuccessOverlay(BuildContext context, bool isUrdu) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('Deleted!', isUrdu),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    Translations.get('Fee template deleted successfully', isUrdu),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildPopupField(String label, TextEditingController controller, {bool isMandatory = false, bool hasError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
            children: [
              if (isMandatory)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey(label),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: label,
            filled: hasError,
            fillColor: hasError ? Colors.red[50] : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.black12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  (route) => false,
                );
              });
            },
            child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: Column(
              children: [
                // Top Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        children: [
                          Text(
                            Translations.get('Fee Management', isUrdu),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: Translations.get('Search Class...', isUrdu),
                            prefixIcon: const Icon(Icons.search, color: Colors.black38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF2168F8),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF2168F8),
                    tabs: [
                      Tab(text: Translations.get('Previous Month', isUrdu)),
                      Tab(text: Translations.get('Current Month', isUrdu)),
                      Tab(text: Translations.get('Next Month', isUrdu)),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMonthTab(DateFormat('MM-yyyy').format(DateTime(_firebaseService.secureTime.year, _firebaseService.secureTime.month - 1, 1)), isUrdu),
                      _buildMonthTab(DateFormat('MM-yyyy').format(_firebaseService.secureTime), isUrdu),
                      _buildMonthTab(DateFormat('MM-yyyy').format(DateTime(_firebaseService.secureTime.year, _firebaseService.secureTime.month + 1, 1)), isUrdu),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _tabController.index == 0 
                ? null 
                : FloatingActionButton(
                    onPressed: () => _showCreateFeeBottomSheet(context, isUrdu),
                    backgroundColor: const Color(0xFF2168F8),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 2,
              selectedItemColor: const Color(0xFF2168F8),
              onTap: (index) {
                if (index == 0) {
                  navigateWithLoader(context, () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      (route) => false,
                    );
                  });
                } else if (index == 1) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentManagementScreen()),
                    );
                  });
                } else if (index == 3) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AlertsScreen()),
                    );
                  });
                } else if (index == 4) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                    );
                  });
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), label: Translations.get('Students', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: Translations.get('Fees', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), label: Translations.get('Alerts', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: Translations.get('Profile', isUrdu)),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthTab(String monthYear, bool isUrdu) {
    String formattedMonth = _formatMonthYear(monthYear);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 15),
            child: Text(formattedMonth, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getClassFeesTemplatesStream(monthYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var fees = snapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];

                // Numeric sorting for Class names (Class 1, Class 2... Class 10)
                fees.sort((a, b) {
                  String nameA = a['className']?.toString() ?? '';
                  String nameB = b['className']?.toString() ?? '';
                  
                  int numA = int.tryParse(nameA.replaceAll(RegExp(r'\D'), '')) ?? 0;
                  int numB = int.tryParse(nameB.replaceAll(RegExp(r'\D'), '')) ?? 0;
                  
                  return numA.compareTo(numB);
                });

                if (_searchController.text.isNotEmpty) {
                  fees = fees.where((f) => f['className'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                }

                if (fees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(Translations.get('No fee templates for this month', isUrdu), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: fees.length,
                  itemBuilder: (context, index) => _buildFeeCard(fees[index], isUrdu),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
