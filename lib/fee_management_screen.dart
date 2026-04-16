import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';

class FeeManagementScreen extends StatelessWidget {
  const FeeManagementScreen({super.key});

  // ignore: unused_element
  Widget _buildFeeCard(
    String className,
    String amount,
    String dueDate, {
    bool hasInstallments = false,
  }) {
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2168F8),
                    size: 20,
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.grey, size: 16),
              const SizedBox(width: 5),
              Text(
                amount,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                'Due: $dueDate',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          if (hasInstallments) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE), // Light blue background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF81D4FA), width: 1),
              ),
              child: const Text(
                'Installments Available',
                style: TextStyle(
                  color: Color(0xFF29B6F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, bool isUrdu) {
    return TextField(
      decoration: InputDecoration(
        hintText: Translations.get(label, isUrdu),
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2168F8)),
        ),
      ),
    );
  }

  void _showCreateFeeBottomSheet(BuildContext context, bool isUrdu) {
    String? selectedClass;
    bool allowInstallments = false;
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                            Translations.get('Create New Fee', isUrdu),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Translations.get('Class', isUrdu),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dropdown for Class
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
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
                        hint: Text(
                          Translations.get('Select Class', isUrdu),
                          style: const TextStyle(color: Colors.black38),
                        ),
                        initialValue: selectedClass,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items:
                            List.generate(
                              12,
                              (index) => 'Class ${index + 1}',
                            ).map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedClass = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      Text(
                        Translations.get('Fee Amount', isUrdu),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Enter amount', isUrdu),
                      const SizedBox(height: 15),
                      Text(
                        Translations.get('Due Date', isUrdu),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2168F8),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Text(
                            selectedDate == null
                                ? Translations.get('mm/dd/yyyy', isUrdu)
                                : "${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year}",
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.black38
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        Translations.get(
                          'Due date will automatic update each month',
                          isUrdu,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.get('Allow Installments', isUrdu),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Switch(
                            value: allowInstallments,
                            onChanged: (value) {
                              setState(() {
                                allowInstallments = value;
                              });
                            },
                            activeThumbColor: const Color(
                              0xFF2168F8,
                            ), // Blue thumb when active
                            activeTrackColor: const Color(0xFF2168F8)
                                .withValues(alpha: 
                                  0.3,
                                ), // Lighter blue track when active
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD3D3D3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2168F8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            Translations.get('Save Fee', isUrdu),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
            body: SingleChildScrollView(
              child: Column(
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
                              hintText: Translations.get(
                                'Search Class...',
                                isUrdu,
                              ),
                              hintStyle: const TextStyle(color: Colors.black38),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.black38,
                              ),
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

                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        // Create New Fee Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () =>
                                _showCreateFeeBottomSheet(context, isUrdu),
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
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  Translations.get('Create New Fee', isUrdu),
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

                        // Fee List
                        // Empty space since no classes/fees are added yet.
                        // Example usages:
                        // _buildFeeCard('Class 10', 'Rs. 5,000', '12/15/2025', hasInstallments: true),
                        // _buildFeeCard('Class 9', 'Rs. 4,500', '12/15/2025', hasInstallments: true),
                        // _buildFeeCard('Class 8', 'Rs. 4,000', '12/15/2025'),
                        // _buildFeeCard('Class 7', 'Rs. 3,500', '12/15/2025'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 2, // Focus on Fees tab
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
                } else if (index == 1) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentManagementScreen(),
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
        );
      },
    );
  }
}
