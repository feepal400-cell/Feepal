import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Note: dart:io is only used for the File type in a local context to avoid web crashes

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _parentPasswordController = TextEditingController();

  Widget _buildStudentCard(Map<String, dynamic> student, bool isUrdu) {
    String name = student['studentName'] ?? 'No Name';
    String rollNo = student['rollNumber'] ?? 'N/A';
    String fee = student['lastFeeAmount'] ?? '0';
    bool isMissingEmail = (student['parentEmail'] ?? '').isEmpty;

    return GestureDetector(
      onTap: () => _showAddStudentBottomSheet(context, isUrdu, studentData: student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMissingEmail) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.info, color: Colors.red, size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Class: ${student['class'] ?? '-'} | Roll No: $rollNo",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2AA943),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
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
                const SizedBox(height: 20),
                Text(
                  "Rs. $fee",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, bool isUrdu, TextEditingController controller, {bool enabled = true, String? suffix, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: Translations.get(hint, isUrdu),
        hintStyle: const TextStyle(color: Colors.black38),
        suffixText: suffix,
        suffixIcon: suffixIcon,
        suffixStyle: const TextStyle(color: Colors.black26, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
          borderSide: const BorderSide(color: Color(0xFF2168F8)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  void _showAddStudentBottomSheet(BuildContext context, bool isUrdu, {Map<String, dynamic>? studentData}) {
    final bool isEditing = studentData != null;
    String selectedStatus = studentData?['feeStatus'] ?? 'Unpaid';

    if (isEditing) {
      _nameController.text = studentData['studentName'] ?? '';
      _classController.text = studentData['class'] ?? '';
      _rollController.text = studentData['rollNumber'] ?? '';
      _parentNameController.text = studentData['parentName'] ?? '';
      _parentPhoneController.text = studentData['parentPhone'] ?? '';
      _parentEmailController.text = studentData['parentEmail'] ?? '';
      _feeController.text = studentData['lastFeeAmount'] ?? '';
      _parentPasswordController.text = studentData['parentPassword'] ?? _firebaseService.generatePassword();
    } else {
      _nameController.clear();
      _classController.clear();
      _rollController.clear();
      _parentNameController.clear();
      _parentPhoneController.clear();
      _parentEmailController.clear();
      _feeController.clear();
      _parentPasswordController.text = _firebaseService.generatePassword();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.get(isEditing ? 'Edit Student' : 'Add New Student', isUrdu),
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
                      const SizedBox(height: 20),
                      _buildTextField('Student Name', isUrdu, _nameController, suffix: 'Name'),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Class', isUrdu, _classController, suffix: 'Class')),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              'Roll Number',
                              isUrdu,
                              _rollController,
                              enabled: !isEditing,
                              suffix: 'Roll No',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Fees (Rs.)', isUrdu, _feeController, suffix: 'Fee')),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedStatus,
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  items: ['Paid', 'Unpaid'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedStatus = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField('Parent Name', isUrdu, _parentNameController, suffix: 'Parent'),
                      const SizedBox(height: 15),
                      _buildTextField('Parent Phone', isUrdu, _parentPhoneController, suffix: 'Phone'),
                      const SizedBox(height: 15),
                      _buildTextField('Parent Email', isUrdu, _parentEmailController, suffix: 'Email'),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'Parent Password',
                        isUrdu,
                        _parentPasswordController,
                        suffix: 'Pass',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF2168F8)),
                          onPressed: () {
                            _showRegenerateConfirmDialog(context, isUrdu, () {
                              setSheetState(() {
                                _parentPasswordController.text = _firebaseService.generatePassword();
                              });
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_nameController.text.isEmpty || _rollController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name and Roll Number are required.')),
                              );
                              return;
                            }

                            final studentPayload = {
                              'studentName': _nameController.text,
                              'class': _classController.text,
                              'rollNumber': _rollController.text,
                              'parentName': _parentNameController.text,
                              'parentPhone': _parentPhoneController.text,
                              'parentEmail': _parentEmailController.text,
                              'lastFeeAmount': _feeController.text.isEmpty ? '0' : _feeController.text,
                              'feeStatus': selectedStatus,
                              'parentPassword': _parentPasswordController.text,
                            };

                            Navigator.pop(context);

                            try {
                              await _firebaseService.addOrUpdateStudent(studentPayload);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? 'Changes Saved!' : 'Student added successfully!'),
                                    backgroundColor: const Color(0xFF2AA943),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("❌ Save error: $e");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2168F8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: Text(
                            Translations.get(isEditing ? 'Save Changes' : 'Add New Student', isUrdu),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: () => _showDeleteConfirmDialog(context, _rollController.text, isUrdu),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              Translations.get('Delete Student', isUrdu),
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
          }
        );
      },
    );
  }

  /// Intelligence Engine: Detects columns based on keywords in row 0
  Map<String, int> _getExcelColumnMap(List<excel_pkg.Data?> headerRow) {
    Map<String, int> colMap = {};
    for (int i = 0; i < headerRow.length; i++) {
        String cell = headerRow[i]?.value?.toString().toLowerCase() ?? '';
        if (cell.contains('roll') || cell.contains('no')) {
          colMap['roll'] = i;
        } else if ((cell.contains('student') || cell.contains('name')) && !cell.contains('parent')) colMap['name'] = i;
        else if (cell.contains('parent') && cell.contains('name')) colMap['pname'] = i;
        else if (cell.contains('class') || cell.contains('grade')) colMap['class'] = i;
        else if (cell.contains('fee') || cell.contains('monthly') || cell.contains('amount')) colMap['fee'] = i;
        else if (cell.contains('status')) colMap['status'] = i;
        else if (cell.contains('phone') || cell.contains('contact') || cell.contains('mobile')) colMap['phone'] = i;
        else if (cell.contains('email')) colMap['email'] = i;
    }
    return colMap;
  }

  Future<void> _pickAndImportExcel(BuildContext context, bool isUrdu) async {
    try {
      debugPrint("📂 [StudentManagement] Opening file picker...");
      FilePickerResult? result;
      
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
          allowMultiple: false,
          withData: true, 
        );
      } catch (e) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      }

      if (result != null) {
        Uint8List bytes = result.files.single.bytes!;
        String fileName = result.files.single.name;
        
        var excel = excel_pkg.Excel.decodeBytes(bytes);
        List<Map<String, dynamic>> students = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]?.rows;
          if (rows == null || rows.isEmpty) continue;
          
          // Detect Map from Headers
          Map<String, int> colMap = _getExcelColumnMap(rows[0]);
          bool hasHeaders = colMap.containsKey('name') || colMap.containsKey('roll');
          int startIdx = hasHeaders ? 1 : 0;

          for (int i = startIdx; i < rows.length; i++) {
            var row = rows[i];
            if (row.length < 2) continue;
            
            // Extract using smart Map OR fallback to old 8-column format
            String rollNo = hasHeaders ? (colMap['roll'] != null ? row[colMap['roll']!]?.value?.toString().trim() ?? '' : '') : row[0]?.value?.toString().trim() ?? '';
            String name = hasHeaders ? (colMap['name'] != null ? row[colMap['name']!]?.value?.toString().trim() ?? '' : '') : (row.length > 1 ? row[1]?.value?.toString().trim() ?? '' : '');
            String pName = hasHeaders ? (colMap['pname'] != null ? row[colMap['pname']!]?.value?.toString().trim() ?? '' : '') : (row.length > 2 ? row[2]?.value?.toString().trim() ?? '' : '');
            String className = hasHeaders ? (colMap['class'] != null ? row[colMap['class']!]?.value?.toString().trim() ?? '' : '') : (row.length > 3 ? row[3]?.value?.toString().trim() ?? '' : '');
            String fee = hasHeaders ? (colMap['fee'] != null ? row[colMap['fee']!]?.value?.toString().trim() ?? '0' : '0') : (row.length > 4 ? row[4]?.value?.toString().trim() ?? '0' : '0');
            String status = hasHeaders ? (colMap['status'] != null ? row[colMap['status']!]?.value?.toString().trim() ?? 'Unpaid' : 'Unpaid') : (row.length > 5 ? row[5]?.value?.toString().trim() ?? 'Unpaid' : 'Unpaid');
            String pPhone = hasHeaders ? (colMap['phone'] != null ? row[colMap['phone']!]?.value?.toString().trim() ?? '' : '') : (row.length > 6 ? row[6]?.value?.toString().trim() ?? '' : '');
            String pEmail = hasHeaders ? (colMap['email'] != null ? row[colMap['email']!]?.value?.toString().trim() ?? '' : '') : (row.length > 7 ? row[7]?.value?.toString().trim() ?? '' : '');

            // Clean up status
            if (status.toLowerCase().contains('paid') && !status.toLowerCase().contains('unpaid')) {
              status = 'Paid';
            } else {
              status = 'Unpaid';
            }

            if (name.isEmpty && rollNo.isEmpty) continue;

            students.add({
              'rollNumber': rollNo,
              'studentName': name,
              'parentName': pName,
              'class': className,
              'lastFeeAmount': fee,
              'feeStatus': status,
              'parentPhone': pPhone,
              'parentEmail': pEmail,
            });
          }
        }

        if (context.mounted) {
          _showImportConfirmDialog(context, students, isUrdu, fileName: fileName);
        }
      }
    } catch (e) {
      debugPrint("❌ [StudentManagement] Picker Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error reading file: $e")),
        );
      }
    }
  }

  void _showImportConfirmDialog(BuildContext context, List<Map<String, dynamic>> students, bool isUrdu, {required String fileName}) {
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  Text(Translations.get('Select Excel File', isUrdu)),
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          // Validation: check if email is missing specifically as requested
                          final bool isMissingEmail = student['parentEmail'].isEmpty;
                          final bool isMissingOther = student['studentName'].isEmpty || student['rollNumber'].isEmpty;

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2AA943).withValues(alpha: 0.1),
                              child: Text((index + 1).toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF2AA943))),
                            ),
                            title: Text(student['studentName'].isEmpty ? "No Name" : student['studentName']),
                            subtitle: Text("Roll: ${student['rollNumber']} | Status: ${student['feeStatus']}"),
                            trailing: isMissingEmail || isMissingOther
                              ? const Icon(Icons.info_outline, color: Colors.red, size: 20)
                              : const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    if (isProcessing) ...[
                      const SizedBox(height: 10),
                      const CircularProgressIndicator(color: Color(0xFF2AA943)),
                      const SizedBox(height: 10),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isProcessing || students.isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          try {
                            await _firebaseService.batchImportStudents(students);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(Translations.get('Students Record imported successfully!', isUrdu)),
                                  backgroundColor: const Color(0xFF2AA943),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Import Failed: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AA943)),
                  child: Text(Translations.get('Import', isUrdu), style: const TextStyle(color: Colors.white)),
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
                            Translations.get('Student Management', isUrdu),
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
                          decoration: InputDecoration(
                            hintText: Translations.get('Search Students...', isUrdu),
                            hintStyle: const TextStyle(color: Colors.black38),
                            prefixIcon: const Icon(Icons.search, color: Colors.black38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
                              onPressed: () => _pickAndImportExcel(context, isUrdu),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2AA943),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.file_upload, color: Colors.white, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    Translations.get('Import from Excel', isUrdu),
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
                              onPressed: () => _showAddStudentBottomSheet(context, isUrdu),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2168F8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    Translations.get('Add New Student', isUrdu),
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
                                    padding: const EdgeInsets.only(top: 50),
                                    child: Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 50),
                                    child: CircularProgressIndicator(color: Color(0xFF2168F8)),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 50),
                                    Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'No students found.',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var student = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                                  return _buildStudentCard(student, isUrdu);
                                },
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
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      (route) => false,
                    );
                  });
                } else if (index == 2) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const FeeManagementScreen()),
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
        );
      },
    );
  }

  void _showRegenerateConfirmDialog(BuildContext context, bool isUrdu, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(Translations.get('Regenerate Password?', isUrdu)),
            content: Text(Translations.get('This will create a new complex password for the parent. Are you sure?', isUrdu)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showDeleteConfirmDialog(BuildContext context, String rollNo, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(Translations.get('Are you sure?', isUrdu)),
            content: Text(Translations.get('This action cannot be undone.', isUrdu)),
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
                  // 1. Close both menus immediately for an instant feel
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  
                  // 2. Perform deletion in the background
                  try {
                    _firebaseService.deleteStudent(rollNo).then((_) {
                      debugPrint("✅ Student successfully removed in background");
                    });

                    // 3. Show success message on the main screen
                    ScaffoldMessenger.of(context).showSnackBar(
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
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
