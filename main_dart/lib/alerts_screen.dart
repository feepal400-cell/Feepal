import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'profile_settings_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Widget _buildStatCard(
    String title,
    String count,
    IconData iconData,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    String title,
    String recipients,
    String date,
    String status,
  ) {
    bool isSent = status == 'Sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$recipients Recipients',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                date,
                style: const TextStyle(fontSize: 14, color: Colors.black38),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSent ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isSent
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                        colors: [
                          Color(0xFF9E38FF),
                          Color(0xFFC078FF),
                        ], // Purple gradient
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          Translations.get('Reminders & Notifications', isUrdu),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat Cards Row
                        Row(
                          children: [
                            _buildStatCard(
                              Translations.get('Total Sent', isUrdu),
                              '0',
                              Icons.chat_bubble_outline,
                              const Color(0xFF2168F8),
                              Colors.white,
                            ),
                            const SizedBox(width: 20),
                            _buildStatCard(
                              Translations.get('Scheduled', isUrdu),
                              '0',
                              Icons.access_time,
                              const Color(0xFFFF9800),
                              Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Section Title
                        Text(
                          Translations.get('Reminder History', isUrdu),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // History List
                        // TODO: Implement dynamic history loading from backend database
                        /*
                        _buildHistoryCard(
                          Translations.get('Fee Due Reminder', isUrdu),
                          '87',
                          '12/10/2025',
                          'Sent',
                        ),
                        _buildHistoryCard(
                          Translations.get('Priority Alert', isUrdu),
                          '23',
                          '12/10/2025',
                          'Sent',
                        ),
                        _buildHistoryCard(
                          Translations.get('Payment Confirmation', isUrdu),
                          '45',
                          '12/10/2025',
                          'Sent',
                        ),
                        _buildHistoryCard(
                          Translations.get('Overdue Notice', isUrdu),
                          '12',
                          '12/10/2025',
                          'Scheduled',
                        ),
                        */
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 3, // Focus on Alerts tab
              selectedItemColor: const Color(0xFF2168F8),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                    (route) => false,
                  );
                } else if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentManagementScreen(),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeeManagementScreen(),
                    ),
                  );
                } else if (index == 4) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingsScreen(),
                    ),
                  );
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
