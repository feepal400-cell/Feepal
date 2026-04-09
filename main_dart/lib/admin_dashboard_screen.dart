import 'package:flutter/material.dart';
import 'language_config.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget _buildStatCard(BuildContext context, Color color, IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 15),
          Text(
            Translations.get(label, languageNotifier.value),
            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Text(
            Translations.get(title, languageNotifier.value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRecentActivity(IconData icon, Color iconColor, Color bgColor, String title, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        Translations.get(title, languageNotifier.value),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          Translations.get(time, languageNotifier.value),
          style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
        ),
      ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          Translations.get('Welcome back,', isUrdu),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SIT ISLAMIC SCHOOL',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 26, 
                            fontWeight: FontWeight.w800, 
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Translations.get('Admin Dashboard', isUrdu),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(context, const Color(0xFF4C8DFF), Icons.person_outline, 'Total Students', '0')),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStatCard(context, const Color(0xFF4CAF50), Icons.attach_money, 'Fees Collected', 'Rs. 0')),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(context, const Color(0xFFFF8A00), Icons.access_time, 'Pending Payments', '0')),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStatCard(context, const Color(0xFFEF5350), Icons.error_outline, 'Overdue', '0')),
                          ],
                        ),

                        const SizedBox(height: 35),

                        // Quick Actions
                        Text(
                          Translations.get('Quick Actions', isUrdu),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15),
                        _buildQuickAction('Add Student', Icons.person_add_alt_1, const Color(0xFF2168F8), onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
                        }),
                        _buildQuickAction('Create Fee', Icons.receipt_long, const Color(0xFF00D4FF), onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen()));
                        }),
                        _buildQuickAction('Send Reminder', Icons.notifications_active, const Color(0xFF6554C0), onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
                        }),

                        const SizedBox(height: 35),

                        // Recent Activity
                        Text(
                          Translations.get('Recent Activity', isUrdu),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // TODO: Implement dynamic recent activity loading from backend database
                              /*
                              _buildRecentActivity(Icons.attach_money, const Color(0xFF4CAF50), const Color(0xFFE8F5E9), 'Payment received from Ahmed Khan', '2 hours ago'),
                              const Divider(height: 1, color: Colors.black12),
                              _buildRecentActivity(Icons.person_add_alt_1, const Color(0xFF2168F8), const Color(0xFFE3F2FD), 'New student added: Sara Ali', '5 hours ago'),
                              const Divider(height: 1, color: Colors.black12),
                              _buildRecentActivity(Icons.notifications_active, const Color(0xFFFF8A00), const Color(0xFFFFF3E0), 'Reminder sent to 45 parents', '1 day ago'),
                              */
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 0,
              selectedItemColor: const Color(0xFF2168F8),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 1) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
                } else if (index == 2) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen()));
                } else if (index == 3) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
                } else if (index == 4) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()));
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), label: Translations.get('Students', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), label: Translations.get('Fees', isUrdu)),
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
