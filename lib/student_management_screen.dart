import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'student_details_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/phone_formatter.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';

// Note: dart:io is only used for the File type in a local context to avoid web crashes

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPasswordController =
      TextEditingController();
  bool _obscureParentPasswordInSheet = true;
  bool _isParentLocked = false;
  bool _triedSubmit = false;
  bool _isImporting = false;
  bool _isBulkDeleting = false;
  final Set<String> _selectedIds = {};

  // Search and Pagination State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 20;

  final List<String> _classOptions = [
    'Class: 1',
    'Class: 2',
    'Class: 3',
    'Class: 4',
    'Class: 5',
    'Class: 6',
    'Class: 7',
    'Class: 8',
    'Class: 9',
    'Class: 10',
  ];

  Color _getSiblingColor(Map<String, dynamic> student) {
    String? email = student['parentEmail'];
    String? phone = student['parentPhone'];
    String identifier = (email != null && email.isNotEmpty)
        ? email
        : (phone ?? '');

    if (identifier.isEmpty) return Colors.black87;

    // Check if it's actually a sibling group (this is simplified as we don't know the count here,
    // but applying the color based on identifier is consistent for all siblings)
    final List<Color> siblingColors = [
      const Color(0xFF2168F8), // Standard Blue
      const Color(0xFFBE185D), // Deep Pink
      const Color(0xFF15803D), // Deep Green
      const Color(0xFF7E22CE), // Deep Purple
      const Color(0xFFC2410C), // Deep Orange
      const Color(0xFF0F766E), // Deep Teal
      const Color(0xFFB91C1C), // Deep Red
      const Color(0xFF4338CA), // Deep Indigo
      const Color(0xFF0891B2), // Cyan
      const Color(0xFF4D7C0F), // Lime
    ];

    // Ensure "Priority" still stands out if needed, but the user specifically asked for sibling coloring
    int index =
        identifier.toLowerCase().trim().hashCode.abs() % siblingColors.length;
    return siblingColors[index];
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isUrdu) {
    String name = student['studentName'] ?? 'No Name';
    String rollNo = student['rollNumber'] ?? 'N/A';
    String effectiveStatus =
        (student['feeStatus']?.toString().toLowerCase() == 'unpaid')
        ? 'unpaid'
        : 'paid';
    bool isMissingEmail = (student['parentEmail'] ?? '').isEmpty;
    String docId = student['docId'] ?? '';

    return GestureDetector(
      onTap: () {
        if (_selectedIds.isNotEmpty) {
          setState(() {
            if (_selectedIds.contains(docId)) {
              _selectedIds.remove(docId);
            } else {
              _selectedIds.add(docId);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsScreen(studentData: student),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _selectedIds.contains(docId)
                ? const Color(0xFF2168F8)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: _selectedIds.contains(docId),
              activeColor: const Color(0xFF2168F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(docId);
                  } else {
                    _selectedIds.remove(docId);
                  }
                });
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getSiblingColor(student),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (student['parentStatus'] == 'Priority' ? Colors.orange : Colors.blue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: (student['parentStatus'] == 'Priority' ? Colors.orange : Colors.blue).withOpacity(0.3)),
                              ),
                              child: Text(
                                Translations.get(student['parentStatus'] ?? 'Standard', isUrdu),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: student['parentStatus'] == 'Priority' ? Colors.orange : Colors.blue,
                                ),
                              ),
                            ),
                            if (isMissingEmail) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.info,
                                color: Colors.red,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Builder(
                          builder: (context) {
                            String classVal = student['class'] ?? '-';
                            if (classVal.toLowerCase().startsWith('class: ')) {
                              classVal = classVal.substring(7).trim();
                            } else if (classVal.toLowerCase().startsWith(
                              'class ',
                            )) {
                              classVal = classVal.substring(6).trim();
                            }
                            return Text(
                              "Class: $classVal | Roll No: $rollNo",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2168F8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF2168F8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${Translations.get('Status:', isUrdu)} ${Translations.get(effectiveStatus.toUpperCase(), isUrdu)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: effectiveStatus == 'paid'
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 15),
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length >= 10) {
      return "+92 ${digits.substring(0, 3)} ${digits.substring(3)}";
    }
    return value.startsWith('+92') ? value : "+92 $value";
  }

  String _capitalizeName(String value) {
    return value
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1).toLowerCase() : '');
        })
        .join(' ');
  }

  Widget _buildTextField(
    String hint,
    bool isUrdu,
    TextEditingController controller, {
    bool enabled = true,
    String? suffix,
    Widget? suffixIcon,
    bool isMandatory = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool isError =
        isMandatory && _triedSubmit && controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: Translations.get(hint, isUrdu),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            children: [
              if (isMandatory)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          inputFormatters: inputFormatters,
          onChanged: (val) {
            if (_triedSubmit) setState(() {});
          },
          decoration: InputDecoration(
            hintText: Translations.get(hint, isUrdu),
            hintStyle: const TextStyle(color: Colors.black38),
            suffixText: suffix,
            suffixIcon: suffixIcon,
            filled: isError,
            fillColor: isError ? Colors.red.withOpacity(0.1) : null,
            suffixStyle: const TextStyle(color: Colors.black45, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.red : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.red : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.red : const Color(0xFF2168F8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddStudentBottomSheet(
    BuildContext context,
    bool isUrdu, {
    Map<String, dynamic>? studentData,
  }) {
    final bool isEditing = studentData != null;
    String selectedStatus = studentData?['feeStatus'] ?? 'Paid';
    String selectedParentStatus = studentData?['parentStatus'] ?? 'Standard';
    String? sheetError; // Local error state for the sheet
    final ScrollController sheetScrollController = ScrollController();

    if (isEditing) {
      _obscureParentPasswordInSheet = true; // Reset visibility on edit
      _nameController.text = studentData['studentName'] ?? '';
      _classController.text = studentData['class'] ?? '';
      _rollController.text = studentData['rollNumber'] ?? '';
      _parentNameController.text = studentData['parentName'] ?? '';
      _parentPhoneController.text = studentData['parentPhone'] ?? '';
      _parentEmailController.text = studentData['parentEmail'] ?? '';
      _parentPasswordController.text =
          studentData['parentPassword']?.toString() ?? '';
      _isParentLocked = isEditing;
    } else {
      _nameController.clear();
      _classController.clear();
      _rollController.clear();
      _parentNameController.clear();
      _parentPhoneController.clear();
      _parentEmailController.clear();
      _parentPasswordController.clear();
      _isParentLocked = false;
      _obscureParentPasswordInSheet = true; // Reset visibility on add
      _parentPasswordController.text = _firebaseService.generatePassword();
    }

    bool smsAlertsEnabled = false;
    if (isEditing) {
      final prefs = studentData['notificationPreferences'] as Map?;
      smsAlertsEnabled = prefs?['sms'] == true || studentData['notifications_preference'] == 'SMS Alerts';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      30,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: SingleChildScrollView(
                  controller: sheetScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.get(
                              isEditing ? 'Edit Student' : 'Add New Student',
                              isUrdu,
                            ),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (sheetError != null) ...[
                        _buildSheetErrorBanner(sheetError!, isUrdu),
                        const SizedBox(height: 15),
                      ],
                      const SizedBox(height: 10),
                      _buildTextField(
                        'Student Name',
                        isUrdu,
                        _nameController,
                        suffix: 'Name',
                      ),
                      const SizedBox(height: 15),
                      // Class Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: Translations.get('Class', isUrdu),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                              children: const [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  (_triedSubmit &&
                                      _classController.text.isEmpty)
                                  ? Colors.red.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (_triedSubmit &&
                                        _classController.text.isEmpty)
                                    ? Colors.red
                                    : Colors.black12,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value:
                                    _classOptions.contains(
                                      _classController.text,
                                    )
                                    ? _classController.text
                                    : null,
                                hint: Text(
                                  Translations.get('Select Class', isUrdu),
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 14,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                items: _classOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(
                                      () => _classController.text = val,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'Roll Number',
                        isUrdu,
                        _rollController,
                        enabled: true,
                        suffix: 'Roll No',
                      ),
                      const SizedBox(height: 15),

                      // Parent Lookup Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Parent Email',
                              isUrdu,
                              _parentEmailController,
                              suffix: 'Email',
                              enabled: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!isEditing)
                            IconButton.filled(
                              onPressed: () async {
                                if (_parentEmailController.text.isEmpty) return;
                                final parentData = await _firebaseService
                                    .findParentByEmail(
                                      _parentEmailController.text,
                                    );
                                if (parentData != null) {
                                  setSheetState(() {
                                    _parentNameController.text =
                                        parentData['parentName'] ?? '';
                                    _parentPhoneController.text =
                                        parentData['parentPhone'] ?? '';
                                    _parentPasswordController.text =
                                        parentData['parentPassword'] ?? '';
                                    selectedParentStatus =
                                        parentData['parentStatus'] ??
                                        'Standard';
                                    _isParentLocked = true;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Existing Parent Found! Credentials Locked.',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No existing parent found with this email.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.person_search),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF2168F8),
                              ),
                            ),
                          if (_isParentLocked && !isEditing)
                            IconButton.filled(
                              onPressed: () =>
                                  setSheetState(() => _isParentLocked = false),
                              icon: const Icon(Icons.lock_open),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'Parent Name',
                        isUrdu,
                        _parentNameController,
                        suffix: 'Parent',
                        enabled: true,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'Parent Phone',
                        isUrdu,
                        _parentPhoneController,
                        suffix: 'Phone',
                        enabled: true,
                        inputFormatters: [CustomPhoneFormatter()],
                      ),
                      const SizedBox(height: 15),

                      // Parent Status Dropdown
                      Text(
                        Translations.get('Parent Status', isUrdu),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedParentStatus,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            items: ['Standard', 'Priority'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedParentStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (selectedParentStatus == 'Priority')
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            Translations.get('Priority parents will be reminded twice in a week.', isUrdu),
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 15),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _parentPasswordController,
                        enabled: true,
                        obscureText: _obscureParentPasswordInSheet,
                        decoration: InputDecoration(
                          hintText: Translations.get('Parent Password', isUrdu),
                          hintStyle: const TextStyle(color: Colors.black38),
                          suffixText: 'Pass',
                          suffixStyle: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                          prefixIcon: IconButton(
                            icon: Icon(
                              _obscureParentPasswordInSheet
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF2168F8),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _obscureParentPasswordInSheet =
                                    !_obscureParentPasswordInSheet;
                              });
                            },
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF2168F8),
                            ),
                            onPressed: () {
                              _showRegenerateConfirmDialog(context, isUrdu, () {
                                setSheetState(() {
                                  _parentPasswordController.text =
                                      _firebaseService.generatePassword();
                                });
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2168F8),
                            ),
                          ),
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
                                    color: smsAlertsEnabled ? const Color(0xFF2168F8).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.sms_outlined,
                                    size: 20,
                                    color: smsAlertsEnabled ? const Color(0xFF2168F8) : Colors.grey,
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
                                      smsAlertsEnabled 
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
                              value: smsAlertsEnabled,
                              onChanged: (val) {
                                setSheetState(() => smsAlertsEnabled = val);
                              },
                              activeThumbColor: const Color(0xFF2168F8),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final studentName = _capitalizeName(
                                    _nameController.text,
                                  );
                                  final parentName = _capitalizeName(
                                    _parentNameController.text,
                                  );
                                  final parentPhone = _formatPhone(
                                    _parentPhoneController.text,
                                  );

                                  setSheetState(() {
                                    isSaving = true;
                                    _triedSubmit = true;
                                    _nameController.text = studentName;
                                    _parentNameController.text = parentName;
                                    _parentPhoneController.text = parentPhone;
                                  });

                                  if (_nameController.text.isEmpty ||
                                      _rollController.text.isEmpty ||
                                      _classController.text.isEmpty ||
                                      _parentPhoneController.text.isEmpty) {
                                    setSheetState(() {
                                      isSaving = false;
                                      sheetError =
                                          'Please fill all mandatory fields.';
                                    });
                                    sheetScrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                    return;
                                  }

                                  final studentPayload = {
                                    'studentName': studentName,
                                    'class': _normalizeClassName(
                                      _classController.text,
                                    ),
                                    'rollNumber': _rollController.text,
                                    'parentName': parentName,
                                    'parentPhone': parentPhone,
                                    'parentEmail': _parentEmailController.text
                                        .trim()
                                        .toLowerCase(),
                                    'parentStatus': selectedParentStatus,
                                    'parentPassword':
                                        _parentPasswordController.text,
                                    'notifications_preference': smsAlertsEnabled ? 'SMS Alerts' : 'Email Alerts',
                                    'notificationPreferences': {
                                      'sms': smsAlertsEnabled,
                                      'email': !smsAlertsEnabled,
                                      'app': true,
                                    },
                                  };

                                  try {
                                    await _firebaseService.addOrUpdateStudent(
                                      studentPayload,
                                      oldDocId: studentData?['docId'],
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing
                                                ? 'Changes Saved!'
                                                : 'Student added successfully!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF2AA943,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint("❌ Save error: $e");
                                    if (context.mounted) {
                                      setSheetState(() {
                                        sheetError = e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        );
                                        isSaving = false;
                                      });
                                      sheetScrollController.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setSheetState(() => isSaving = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2168F8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  Translations.get(
                                    isEditing
                                        ? 'Save Changes'
                                        : 'Add New Student',
                                    isUrdu,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: () => _showDeleteConfirmDialog(
                              context,
                              studentData['docId'],
                              isUrdu,
                              studentData['studentName'] ?? 'Unknown',
                              studentData['rollNumber'] ?? '',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              Translations.get('Delete Student', isUrdu),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetErrorBanner(String message, bool isUrdu) {
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
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Intelligence Engine: Detects columns based on keywords in row 0
  Map<String, int> _getColumnMap(List<dynamic> headerRow) {
    Map<String, int> colMap = {};
    for (int i = 0; i < headerRow.length; i++) {
      var cellValue = headerRow[i];
      String cell = '';
      if (cellValue is excel_pkg.Data) {
        cell = cellValue.value?.toString().toLowerCase().trim() ?? '';
      } else {
        cell = cellValue?.toString().toLowerCase().trim() ?? '';
      }

      if (cell == 'roll no' ||
          cell == 'roll' ||
          cell == 'no.' ||
          (cell.contains('roll') && cell.contains('no'))) {
        colMap['roll'] = i;
      } else if ((cell.contains('student') || cell.contains('name')) &&
          !cell.contains('parent')) {
        colMap['name'] = i;
      } else if (cell.contains('parent') &&
          (cell.contains('name') || cell.contains('guardian'))) {
        colMap['pname'] = i;
      } else if (cell.contains('class') ||
          cell.contains('grade') ||
          cell.contains('level')) {
        colMap['class'] = i;
      } else if (cell.contains('fee') ||
          cell.contains('monthly') ||
          cell.contains('amount')) {
        colMap['fee'] = i;
      } else if (cell.contains('status')) {
        colMap['status'] = i;
      } else if (cell.contains('phone') ||
          cell.contains('contact') ||
          cell.contains('mobile') ||
          cell.contains('whatsapp')) {
        colMap['phone'] = i;
      } else if (cell.contains('email') || cell.contains('mail')) {
        colMap['email'] = i;
      }
    }
    return colMap;
  }

  void _showExcelFormatInstructions(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2168F8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Translations.get(
                      'Format Guide (Excel/CSV/Google Sheets)',
                      isUrdu,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get(
                      'Please ensure your file (Excel, CSV, or Google Sheets export) matches this structure:',
                      isUrdu,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Stylized Spreadsheet Guide
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Letter Labels (A, B, C...)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
                            ),
                            child: Row(
                              children: ['A', 'B', 'C', 'D', 'E', 'F'].map((label) => Container(
                                width: 120,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                                ),
                                child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              )).toList(),
                            ),
                          ),
                          // Header Row
                          Container(
                            color: const Color(0xFF2168F8).withOpacity(0.05),
                            child: Row(
                              children: [
                                _buildExcelHeader(Translations.get('Roll Number', isUrdu), isUrdu),
                                _buildExcelHeader(Translations.get('Student Name', isUrdu), isUrdu),
                                _buildExcelHeader(Translations.get('Class', isUrdu), isUrdu),
                                _buildExcelHeader(Translations.get('Parent Name', isUrdu), isUrdu),
                                _buildExcelHeader(Translations.get('Parent Phone', isUrdu), isUrdu),
                                _buildExcelHeader(Translations.get('Parent Email', isUrdu), isUrdu),
                              ],
                            ),
                          ),
                          // Sample Row
                          Row(
                            children: [
                              _buildExcelCell('201'),
                              _buildExcelCell('Yahya'),
                              _buildExcelCell('Class: 2'),
                              _buildExcelCell('Irfan'),
                              _buildExcelCell('0312...'),
                              _buildExcelCell('irfan@...'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Translations.get(
                              'Warning: If any mandatory detail is missing, you will have to manually fill them after import.',
                              isUrdu,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Translations.get('Cancel', isUrdu),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndImportExcel(isUrdu);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AA943),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  Translations.get('Got it, Import', isUrdu),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndImportExcel(bool isUrdu) async {
    setState(() => _isImporting = true);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      Uint8List? bytes = result.files.single.bytes;
      String fileName = result.files.single.name;

      if (bytes == null && result.files.single.path != null) {
        bytes = await File(result.files.single.path!).readAsBytes();
      }

      if (!mounted) return;

      if (bytes == null) throw Exception("Could not read file data.");

      List<Map<String, dynamic>> students = [];

      if (fileName.toLowerCase().endsWith('.csv')) {
        String csvString = "";
        try {
          csvString = utf8.decode(bytes);
        } catch (_) {
          csvString = latin1.decode(bytes);
        }
        List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
        );
        if (rows.length > 1) {
          Map<String, int> colMap = _getColumnMap(rows[0]);
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty ||
                row.every(
                  (element) =>
                      element == null || element.toString().trim().isEmpty,
                )) {
              continue;
            }

            students.add(_parseRow(row, colMap));
          }
        }
      } else {
        var excel = excel_pkg.Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows;
          if (rows == null || rows.length < 2) continue;

          Map<String, int> colMap = _getColumnMap(rows[0]);
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;

            // Extract values from Data objects
            List<dynamic> values = row
                .map((cell) => cell?.value?.toString() ?? '')
                .toList();
            if (values.every((v) => v.toString().trim().isEmpty)) continue;

            students.add(_parseRow(values, colMap));
          }
        }
      }

      if (students.isEmpty) {
        throw Exception("No valid student records found in the file.");
      }

      if (mounted) {
        _showImportPreview(students, isUrdu);
      }
    } catch (e) {
      debugPrint("❌ Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Map<String, dynamic> _parseRow(List<dynamic> row, Map<String, int> colMap) {
    String getVal(String key) {
      int? idx = colMap[key];
      if (idx != null && idx < row.length) {
        return row[idx]?.toString().trim() ?? '';
      }
      return '';
    }

    return {
      'rollNumber': getVal('roll'),
      'studentName': _capitalizeName(getVal('name')),
      'parentName': _capitalizeName(getVal('pname')),
      'class': _normalizeClassName(getVal('class')),
      'lastFeeAmount': getVal('fee').isEmpty ? '0' : getVal('fee'),
      'feeStatus':
          getVal('status').toLowerCase().contains('paid') &&
              !getVal('status').toLowerCase().contains('unpaid')
          ? 'Paid'
          : 'Paid',
      'parentPhone': _formatPhone(getVal('phone')),
      'parentEmail': getVal('email'),
    };
  }

  void _showImportPreview(List<Map<String, dynamic>> students, bool isUrdu) {
    bool isProcessing = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "${Translations.get('Preview Import', isUrdu)} (${students.length} students)",
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length > 5 ? 5 : students.length,
                  itemBuilder: (context, index) {
                    var s = students[index];
                    return ListTile(
                      title: Text(s['studentName']),
                      subtitle: Text(
                        "${s['class']} | Roll: ${s['rollNumber']}",
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: Text(
                    Translations.get('Cancel', isUrdu),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          try {
                            await _firebaseService.batchImportStudents(
                              students,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {
                                _currentPage = 1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    Translations.get(
                                      'Students Record imported successfully!',
                                      isUrdu,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF2AA943),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Import Failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AA943),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          Translations.get('Import', isUrdu),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
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
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                  (route) => false,
                );
              });
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: Stack(
                children: [
                  Column(
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
                                  Translations.get(
                                    'Student Management',
                                    isUrdu,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                    _currentPage =
                                        1; // Reset to first page on search
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: Translations.get(
                                    'Search Student by Name or Roll no',
                                    isUrdu,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black38,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.black38,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _currentPage = 1;
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              children: [
                                // Import from Excel Button (Green)
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showExcelFormatInstructions(
                                          context,
                                          isUrdu,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2AA943),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.file_upload,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          Translations.get(
                                            'Import from Excel',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Add New Student Button (Blue)
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () => _showAddStudentBottomSheet(
                                      context,
                                      isUrdu,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2168F8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          Translations.get(
                                            'Add New Student',
                                            isUrdu,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Realtime Student List
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firebaseService.getStudentsStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 50,
                                          ),
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 50),
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF2168F8),
                                          ),
                                        ),
                                      );
                                    }

                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 50),
                                          Icon(
                                            Icons.school_outlined,
                                            size: 80,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'No students found.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // 1. Filter local list based on query
                                    var allDocs = snapshot.data!.docs;
                                    var filteredDocs = allDocs.where((doc) {
                                      var data =
                                          doc.data() as Map<String, dynamic>;
                                      String name = (data['studentName'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      String roll = (data['rollNumber'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      return name.contains(_searchQuery) ||
                                          roll.contains(_searchQuery);
                                    }).toList();

                                    if (filteredDocs.isEmpty) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 50),
                                          Icon(
                                            Icons.search_off_outlined,
                                            size: 80,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'No matching students found.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // 2. Natural Numeric Sorting for Classes (Ensures Class 10 is at the end)
                                    filteredDocs.sort((a, b) {
                                      var dataA = a.data() as Map<String, dynamic>;
                                      var dataB = b.data() as Map<String, dynamic>;
                                      
                                      String classA = (dataA['class'] ?? '').toString();
                                      String classB = (dataB['class'] ?? '').toString();
                                      
                                      int numA = int.tryParse(classA.replaceAll(RegExp(r'\D'), '')) ?? 0;
                                      int numB = int.tryParse(classB.replaceAll(RegExp(r'\D'), '')) ?? 0;
                                      
                                      if (numA != numB) {
                                        return numA.compareTo(numB);
                                      }
                                      
                                      // If classes are same, sort by name
                                      String nameA = (dataA['studentName'] ?? '').toString().toLowerCase();
                                      String nameB = (dataB['studentName'] ?? '').toString().toLowerCase();
                                      return nameA.compareTo(nameB);
                                    });

                                    // 3. Pagination Logic
                                    int totalFiltered = filteredDocs.length;
                                    int totalPages = (totalFiltered / _pageSize)
                                        .ceil();

                                    // Ensure current page is valid
                                    if (_currentPage > totalPages) {
                                      _currentPage = totalPages;
                                    }
                                    if (_currentPage < 1) _currentPage = 1;

                                    int startIndex =
                                        (_currentPage - 1) * _pageSize;
                                    int endIndex = startIndex + _pageSize;
                                    if (endIndex > totalFiltered) {
                                      endIndex = totalFiltered;
                                    }

                                    var pageDocs = filteredDocs.sublist(
                                      startIndex,
                                      endIndex,
                                    );

                                    return Column(
                                      children: [
                                        if (filteredDocs.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 15,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value:
                                                      _selectedIds.isNotEmpty &&
                                                      _selectedIds.length ==
                                                          filteredDocs.length,
                                                  tristate:
                                                      _selectedIds.isNotEmpty &&
                                                      _selectedIds.length <
                                                          filteredDocs.length,
                                                  activeColor: const Color(
                                                    0xFF2168F8,
                                                  ),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      if (val == true) {
                                                        _selectedIds.addAll(
                                                          filteredDocs.map(
                                                            (doc) => doc.id,
                                                          ),
                                                        );
                                                      } else {
                                                        _selectedIds.clear();
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  _selectedIds.isEmpty
                                                      ? Translations.get(
                                                          'Select All',
                                                          isUrdu,
                                                        )
                                                      : "${_selectedIds.length} ${Translations.get('Selected', isUrdu)}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (_selectedIds.isNotEmpty)
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        _showBulkDeleteConfirmDialog(
                                                          context,
                                                          _selectedIds.length,
                                                          isUrdu,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    label: Text(
                                                      Translations.get(
                                                        'Remove',
                                                        isUrdu,
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: pageDocs.length,
                                          itemBuilder: (context, index) {
                                            var doc = pageDocs[index];
                                            var student =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            student['docId'] = doc.id;
                                            student['adminId'] =
                                                _firebaseService.currentAdminId;
                                            return _buildStudentCard(
                                              student,
                                              isUrdu,
                                            );
                                          },
                                        ),

                                        // Pagination Controls
                                        if (totalPages > 1) ...[
                                          const SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: _currentPage > 1
                                                    ? () => setState(
                                                        () => _currentPage--,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_left,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      _currentPage > 1
                                                      ? const Color(
                                                          0xFF2168F8,
                                                        ).withOpacity(0.1)
                                                      : Colors.grey[100],
                                                  foregroundColor:
                                                      _currentPage > 1
                                                      ? const Color(0xFF2168F8)
                                                      : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                "Page $_currentPage of $totalPages",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              IconButton(
                                                onPressed:
                                                    _currentPage < totalPages
                                                    ? () => setState(
                                                        () => _currentPage++,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      _currentPage < totalPages
                                                      ? const Color(
                                                          0xFF2168F8,
                                                        ).withOpacity(0.1)
                                                      : Colors.grey[100],
                                                  foregroundColor:
                                                      _currentPage < totalPages
                                                      ? const Color(0xFF2168F8)
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Showing ${startIndex + 1} to $endIndex of $totalFiltered students",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isImporting || _isBulkDeleting)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF2168F8),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  Translations.get(
                                    _isImporting
                                        ? 'Picking & Parsing File...'
                                        : 'Removing Students...',
                                    isUrdu,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 1, // Focus on Students tab
                selectedItemColor: const Color(0xFF2168F8),
                unselectedItemColor: Colors.grey,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                iconSize: 26,
                onTap: (index) {
                  if (index == 0) {
                    navigateWithLoader(context, () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                        (route) => false,
                      );
                    });
                  } else if (index == 2) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeeManagementScreen(),
                        ),
                      );
                    });
                  } else if (index == 3) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AlertsScreen(),
                        ),
                      );
                    });
                  } else if (index == 4) {
                    navigateWithLoader(context, () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
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
                    icon: const Icon(Icons.school_outlined),
                    label: Translations.get('Students', isUrdu),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Translations.get('Fees', isUrdu),
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

  void _showRegenerateConfirmDialog(
    BuildContext context,
    bool isUrdu,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(Translations.get('Regenerate Password?', isUrdu)),
            content: Text(
              Translations.get(
                'This will create a new complex password for the parent. Are you sure?',
                isUrdu,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Translations.get('Cancel', isUrdu),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  onConfirm();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2168F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  Translations.get('Regenerate', isUrdu),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String studentId,
    bool isUrdu,
    String studentName,
    String rollNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(Translations.get('Are you sure?', isUrdu)),
            content: Text(
              Translations.get('This action cannot be undone.', isUrdu),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Translations.get('Cancel', isUrdu),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Capture messenger BEFORE popping context
                  final messenger = ScaffoldMessenger.of(context);

                  // 1. Close both menus immediately for an instant feel
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet

                  // 2. Perform deletion in the background
                  try {
                    _firebaseService
                        .deleteStudent(studentId, studentName, rollNumber)
                        .then((_) {
                          debugPrint(
                            "✅ Student successfully removed in background",
                          );
                        });

                    // 3. Show success message on the main screen
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Student Removed Successfully'),
                        backgroundColor: Color(0xFFE53E3E), // Red for deletion
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    debugPrint("❌ Deletion error: $e");
                  }
                },
                child: Text(
                  Translations.get('Delete', isUrdu),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBulkDeleteConfirmDialog(
    BuildContext context,
    int count,
    bool isUrdu,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "${Translations.get('Remove', isUrdu)} $count ${Translations.get('Students', isUrdu)}?",
            ),
            content: Text(
              Translations.get(
                'This will permanently remove all selected students and their data. This action cannot be undone.',
                isUrdu,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Translations.get('Cancel', isUrdu),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Capture messenger BEFORE popping context
                  final messenger = ScaffoldMessenger.of(context);

                  Navigator.pop(context); // Close dialog
                  setState(() => _isBulkDeleting = true);

                  try {
                    final idsToDelete = _selectedIds.toList();
                    await _firebaseService.bulkDeleteStudents(idsToDelete);

                    if (mounted) {
                      setState(() {
                        _selectedIds.clear();
                        _isBulkDeleting = false;
                        _currentPage =
                            1; // Reset to first page as items changed
                      });

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            "$count ${Translations.get('Students record removed successfully', isUrdu)}",
                          ),
                          backgroundColor: const Color(0xFFE53E3E),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isBulkDeleting = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  Translations.get('Remove', isUrdu),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _normalizeClassName(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return 'Unknown';

    // Extract digits for standard "Class: X" format
    String digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      return 'Class: $digits';
    }

    if (trimmed.toLowerCase().startsWith('class:')) return trimmed;

    return 'Class: $trimmed';
  }

  Widget _buildExcelHeader(String label, bool isUrdu) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blue.shade900,
        ),
        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildExcelCell(String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
