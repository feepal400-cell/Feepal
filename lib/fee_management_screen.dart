import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Widget _buildFeeCard(
    Map<String, dynamic> fee,
    bool isUrdu,
  ) {
    String className = fee['className'] ?? 'Unknown Class';
    String amount = fee['amount'] ?? '0';
    String dueDate = fee['dueDate'] ?? 'N/A';
    bool hasInstallments = fee['allowInstallments'] ?? false;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                className,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF2168F8), size: 22),
                    onPressed: () => _showCreateFeeBottomSheet(context, isUrdu, feeData: fee),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () => _showDeleteConfirmDialog(className, isUrdu),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.grey, size: 18),
              const SizedBox(width: 5),
              Text(
                "Rs. $amount",
                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(
                'Due: $dueDate',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          if (hasInstallments) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                'Installments Available',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String feeId, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(Translations.get('Delete Fee?', isUrdu)),
        content: Text(Translations.get('Are you sure you want to delete this fee structure?', isUrdu)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firebaseService.deleteFee(feeId);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateFeeBottomSheet(BuildContext context, bool isUrdu, {Map<String, dynamic>? feeData}) {
    final bool isEditing = feeData != null;
    String? selectedClass = feeData?['className'];
    bool allowInstallments = feeData?['allowInstallments'] ?? false;
    DateTime? selectedDate = feeData?['dueDateRaw'] != null ? (feeData!['dueDateRaw'] as Timestamp).toDate() : null;
    
    if (isEditing) {
      _amountController.text = feeData!['amount'] ?? '';
    } else {
      _amountController.clear();
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
          builder: (BuildContext context, StateSetter setSheetState) {
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
                            Translations.get(isEditing ? 'Edit Fee' : 'Create New Fee', isUrdu),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Class Selection
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          labelText: Translations.get('Class', isUrdu),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: selectedClass,
                        items: List.generate(12, (i) => 'Class ${i + 1}').map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: isEditing ? null : (val) => setSheetState(() => selectedClass = val),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Fee Amount
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: Translations.get('Fee Amount (Rs.)', isUrdu),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Due Date Picker
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2168F8))),
                              child: child!,
                            ),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedDate == null ? 'Select Due Date' : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                              const Icon(Icons.calendar_today, color: Color(0xFF2168F8)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Installments Switch
                      SwitchListTile(
                        title: Text(Translations.get('Allow Installments', isUrdu)),
                        value: allowInstallments,
                        onChanged: (val) => setSheetState(() => allowInstallments = val),
                        activeColor: const Color(0xFF2168F8),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedClass == null || _amountController.text.isEmpty || selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required.')));
                              return;
                            }
                            
                            final feeData = {
                              'className': selectedClass,
                              'amount': _amountController.text,
                              'dueDate': "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                              'dueDateRaw': selectedDate,
                              'allowInstallments': allowInstallments,
                            };
                            
                            await _firebaseService.saveClassFee(feeData);
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2168F8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: Text(Translations.get('Save Fee', isUrdu), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () => _showCreateFeeBottomSheet(context, isUrdu),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2168F8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(Translations.get('Create New Fee', isUrdu), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          StreamBuilder<QuerySnapshot>(
                            stream: _firebaseService.getFeesStream(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const CircularProgressIndicator();
                              
                              var fees = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                              
                              // Filtering
                              if (_searchController.text.isNotEmpty) {
                                fees = fees.where((f) => f['className'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                              }

                              if (fees.isEmpty) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 50),
                                    Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[200]),
                                    const SizedBox(height: 10),
                                    const Text('No fees created yet.', style: TextStyle(color: Colors.grey)),
                                  ],
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: fees.length,
                                itemBuilder: (context, index) => _buildFeeCard(fees[index], isUrdu),
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
        );
      },
    );
  }
}
