import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'language_config.dart';
import 'services/firebase_service.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentDetailsScreen({super.key, required this.studentData});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Profile Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPasswordController = TextEditingController();
  
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _obscurePassword = true;
  String _selectedParentStatus = 'Standard';
  bool _smsAlertsEnabled = false;
  String? _profileError;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initProfileFields();
  }

  void _initProfileFields() {
    _nameController.text = widget.studentData['studentName'] ?? '';
    _classController.text = widget.studentData['class'] ?? '';
    _rollController.text = widget.studentData['rollNumber'] ?? '';
    _parentNameController.text = widget.studentData['parentName'] ?? '';
    _parentPhoneController.text = widget.studentData['parentPhone'] ?? '';
    _parentEmailController.text = widget.studentData['parentEmail'] ?? '';
    _parentPasswordController.text = widget.studentData['parentPassword'] ?? '';
    _selectedParentStatus = widget.studentData['parentStatus'] ?? 'Standard';
    
    // Initialize SMS Preference
    final prefs = widget.studentData['notificationPreferences'] as Map?;
    _smsAlertsEnabled = prefs?['sms'] == true || widget.studentData['notifications_preference'] == 'SMS Alerts';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      final payload = {
        'studentName': _nameController.text,
        'class': _classController.text,
        'rollNumber': _rollController.text,
        'parentName': _parentNameController.text,
        'parentPhone': _parentPhoneController.text,
        'parentEmail': _parentEmailController.text,
        'parentPassword': _parentPasswordController.text,
        'parentStatus': _selectedParentStatus,
        'notifications_preference': _smsAlertsEnabled ? 'SMS Alerts' : 'Email Alerts',
        'notificationPreferences': {
          'sms': _smsAlertsEnabled,
          'email': !_smsAlertsEnabled,
          'app': true,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebaseService.addOrUpdateStudent(payload, oldDocId: widget.studentData['docId']);
      
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
          _isEditingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
          _profileError = e.toString().replaceAll('Exception: ', '');
        });
        _scrollController.animateTo(
          0, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isUrdu = languageNotifier.value;
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(Translations.get('Student Details', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              labelColor: const Color(0xFF2168F8),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2168F8),
              tabs: [
                Tab(text: Translations.get('Profile', isUrdu)),
                Tab(text: Translations.get('Fee Management', isUrdu)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Profile Tab
              SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              if (_profileError != null) ...[
                _buildErrorBanner(_profileError!, isUrdu),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translations.get('Student Profile', isUrdu),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: Icon(_isEditingProfile ? Icons.close : Icons.edit, color: const Color(0xFF2168F8)),
                    onPressed: () => setState(() => _isEditingProfile = !_isEditingProfile),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoField('Student Name', _nameController, Icons.person_outline, isUrdu),
              const SizedBox(height: 15),
              _buildInfoField('Class', _classController, Icons.school_outlined, isUrdu),
              const SizedBox(height: 15),
              _buildInfoField('Roll Number', _rollController, Icons.numbers_outlined, isUrdu),
              const SizedBox(height: 25),
              Text(
                Translations.get('Parent Information', isUrdu),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 15),
              _buildInfoField('Parent Name', _parentNameController, Icons.family_restroom_outlined, isUrdu),
              const SizedBox(height: 15),
              _buildInfoField('Parent Email', _parentEmailController, Icons.email_outlined, isUrdu),
              const SizedBox(height: 15),
              _buildInfoField('Parent Phone', _parentPhoneController, Icons.phone_outlined, isUrdu),
              const SizedBox(height: 15),
              _buildPasswordField(isUrdu),
              const SizedBox(height: 15),
              _buildParentStatusDropdown(isUrdu),
              const SizedBox(height: 30),
              
              if (_isEditingProfile)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2168F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isSavingProfile
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(Translations.get('Save Changes', isUrdu), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              
                ],
              ),
            ),
            
            // Fee Management Tab
            _buildFeeManagementTab(isUrdu),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFeeManagementTab(bool isUrdu) {
    if (widget.studentData['adminId'] == null || widget.studentData['docId'] == null) {
      return const Center(child: Text("Error: Missing student or admin ID."));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getStudentVouchersStream(widget.studentData['adminId'], widget.studentData['docId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  Translations.get('No vouchers issued yet.', isUrdu),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final vouchers = snapshot.data!.docs;
        final now = _firebaseService.secureTime;
        final currentMonthStr = DateFormat('MM-yyyy').format(now);
        final currentMonthDate = DateTime(now.year, now.month);

        List<DocumentSnapshot> pastVouchers = [];
        List<DocumentSnapshot> currentVouchers = [];
        List<DocumentSnapshot> nextVouchers = [];

        for (var doc in vouchers) {
          final data = doc.data() as Map<String, dynamic>;
          final monthYear = data['monthYear'] as String? ?? '';
          try {
            final voucherDate = DateFormat('MM-yyyy').parse(monthYear);
            if (monthYear == currentMonthStr) {
              currentVouchers.add(doc);
            } else if (voucherDate.isBefore(currentMonthDate)) {
              pastVouchers.add(doc);
            } else {
              nextVouchers.add(doc);
            }
          } catch (_) {
            pastVouchers.add(doc);
          }
        }

        // Sort each category chronologically (Descending for past, Ascending for next)
        pastVouchers.sort((a, b) => _parseMonthYear(b['monthYear']).compareTo(_parseMonthYear(a['monthYear'])));
        nextVouchers.sort((a, b) => _parseMonthYear(a['monthYear']).compareTo(_parseMonthYear(b['monthYear'])));

        return DefaultTabController(
          length: 3,
          initialIndex: 1, // Focus Current by default
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: [
                    Tab(text: Translations.get('Previous', isUrdu)),
                    Tab(text: Translations.get('Current', isUrdu)),
                    Tab(text: Translations.get('Next', isUrdu)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildVoucherList(pastVouchers, isUrdu, 'No previous vouchers'),
                    _buildVoucherList(currentVouchers, isUrdu, 'No vouchers for current month'),
                    _buildVoucherList(nextVouchers, isUrdu, 'No future vouchers'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherList(List<DocumentSnapshot> vouchers, bool isUrdu, String emptyMsg) {
    if (vouchers.isEmpty) {
      return Center(
        child: Text(Translations.get(emptyMsg, isUrdu), style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) => _buildVoucherCard(vouchers[index], isUrdu),
    );
  }

  DateTime _parseMonthYear(String? my) {
    if (my == null) return DateTime(2000);
    try {
      return DateFormat('MM-yyyy').parse(my);
    } catch (_) {
      return DateTime(2000);
    }
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.8), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(DocumentSnapshot doc, bool isUrdu) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'unpaid';
    final monthYear = data['monthYear'] as String? ?? 'N/A';
    final baseFee = (data['baseFee'] ?? 0).toDouble();
    final additional = (data['additionalCharge'] ?? 0).toDouble();
    final penalty = (data['latePenalty'] ?? 0).toDouble();
    final total = baseFee + additional + (status == 'unpaid' ? _calculatePenaltyIfOverdue(data) : (data['latePenaltyApplied'] ?? 0).toDouble());
    
    final installments = data['installments'] as List? ?? [];
    final isInstallment = installments.isNotEmpty;

    String monthName = monthYear;
    try {
      DateTime dt = DateFormat('MM-yyyy').parse(monthYear);
      monthName = DateFormat('MMMM yyyy').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        isInstallment ? Translations.get('Installment Plan', isUrdu) : Translations.get('Standard Voucher', isUrdu),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isInstallment)
                  _buildProofAndStatus(data['voucherImageUrl'] ?? data['paymentProofUrl'], status, isUrdu, () => _toggleVoucherStatus(doc.id, status)),
              ],
            ),
          ),
          
          if (isInstallment)
            ...installments.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> inst = entry.value;
              return _buildInstallmentRow(doc.id, idx, inst, isUrdu);
            }),

          const Divider(height: 1),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Translations.get('Total Amount', isUrdu), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text(
                  '${total.toInt()} PKR',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePenaltyIfOverdue(Map<String, dynamic> data) {
    if (data['dueDateRaw'] is Timestamp) {
      DateTime due = (data['dueDateRaw'] as Timestamp).toDate();
      DateTime endOfDueDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
      if (_firebaseService.secureTime.isAfter(endOfDueDay)) {
        return (data['latePenalty'] ?? 0).toDouble();
      }
    }
    return 0.0;
  }

  Widget _buildProofAndStatus(String? proofUrl, String status, bool isUrdu, VoidCallback onToggle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (proofUrl != null && proofUrl.isNotEmpty) ...[
          InkWell(
            onTap: () => _showImageDialog(proofUrl),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: DecorationImage(image: NetworkImage(proofUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Translations.get('No proof', isUrdu),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
        ],
        _buildStatusBadge(status, isUrdu, onToggle),
      ],
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url, 
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isUrdu, VoidCallback onToggle) {
    bool isPaid = status == 'paid';
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPaid ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPaid ? Icons.check_circle : Icons.pending, size: 14, color: isPaid ? Colors.green : Colors.orange),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                Translations.get(isPaid ? 'Paid' : 'Unpaid', isUrdu),
                style: TextStyle(
                  color: isPaid ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentRow(String voucherId, int index, Map<String, dynamic> inst, bool isUrdu) {
    bool isPaid = inst['status'] == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.pie_chart_outline, size: 20, color: Colors.blue.shade300),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get(inst['label'] ?? 'Installment', isUrdu),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${inst['amount']} PKR',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildProofAndStatus(inst['voucherImageUrl'] ?? inst['paymentProofUrl'], inst['status'], isUrdu, () => _toggleInstallmentStatus(voucherId, index, inst['status'])),
        ],
      ),
    );
  }

  void _toggleVoucherStatus(String voucherId, String currentStatus) async {
    String newStatus = currentStatus == 'paid' ? 'unpaid' : 'paid';
    try {
      await _firebaseService.adminUpdateVoucherStatus(
        adminId: widget.studentData['adminId'],
        studentId: widget.studentData['docId'],
        voucherId: voucherId,
        newStatus: newStatus,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _toggleInstallmentStatus(String voucherId, int index, String currentStatus) async {
    String newStatus = currentStatus == 'paid' ? 'unpaid' : 'paid';
    try {
      await _firebaseService.adminUpdateVoucherStatus(
        adminId: widget.studentData['adminId'],
        studentId: widget.studentData['docId'],
        voucherId: voucherId,
        newStatus: newStatus,
        installmentIndex: index,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildErrorBanner(String message, bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon, bool isUrdu, {String? hint}) {
    return TextField(
      controller: controller,
      enabled: _isEditingProfile,
      decoration: InputDecoration(
        labelText: Translations.get(label, isUrdu),
        hintText: hint != null ? Translations.get(hint, isUrdu) : null,
        prefixIcon: Icon(icon, color: const Color(0xFF2168F8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildParentStatusDropdown(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.get('Parent Status', isUrdu),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isEditingProfile ? Colors.grey : Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedParentStatus,
              isExpanded: true,
              dropdownColor: Colors.white,
              onChanged: _isEditingProfile ? (val) => setState(() => _selectedParentStatus = val!) : null,
              items: ['Standard', 'Priority'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
          ),
        ),
        if (_selectedParentStatus == 'Priority')
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              Translations.get('Priority parents will be reminded twice in a week.', isUrdu),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: 20),
        
        // SMS Alert Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _smsAlertsEnabled ? const Color(0xFF2168F8).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 20,
                      color: _smsAlertsEnabled ? const Color(0xFF2168F8) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('Send SMS Alert', isUrdu),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _smsAlertsEnabled 
                          ? Translations.get('SMS prioritized over Email', isUrdu)
                          : Translations.get('Email Alert active by default', isUrdu),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _smsAlertsEnabled,
                onChanged: _isEditingProfile ? (val) => setState(() => _smsAlertsEnabled = val) : null,
                activeThumbColor: const Color(0xFF2168F8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _parentPasswordController,
          enabled: _isEditingProfile,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: Translations.get('Parent Password', isUrdu),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2168F8)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                if (_isEditingProfile)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF2168F8)),
                    onPressed: () {
                      _showRegenerateConfirmDialog(context, isUrdu, () {
                        setState(() {
                          _parentPasswordController.text = _firebaseService.generatePassword();
                        });
                      });
                    },
                  ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showRegenerateConfirmDialog(BuildContext context, bool isUrdu, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.get('Reset Password?', isUrdu)),
        content: Text(Translations.get('This will generate a new random password for the parent. You must save changes to apply it.', isUrdu)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Translations.get('Cancel', isUrdu))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(Translations.get('Regenerate', isUrdu)),
          ),
        ],
      ),
    );
  }
}
