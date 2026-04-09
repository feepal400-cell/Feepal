import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool isNotificationEnabled = true;

  Widget _buildInfoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get(label, languageNotifier.value),
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, Color iconColor, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              Translations.get(title, languageNotifier.value),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          if (trailing != null) trailing,
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
                        colors: [Color(0xFF2168F8), Color(0xFF00D4FF)], // Blue gradient
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              Translations.get('Profile & Settings', isUrdu),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Admin Account Card
                        Container(
                          padding: const EdgeInsets.all(20),
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
                                padding: const EdgeInsets.all(15),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D4FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SIT ISLAMIC SCHOOL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Translations.get('Admin Account', isUrdu),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                        // School Information Title
                        Text(
                          Translations.get('School Information', isUrdu),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                          const SizedBox(height: 15),

                          // Information Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.account_balance, const Color(0xFF2168F8), 'School Name', 'SIT ISLAMIC SCHOOL'),
                                _buildInfoRow(Icons.person_outline, const Color(0xFF2168F8), 'Admin Name', 'Zoraiz Mustafa'),
                                _buildInfoRow(Icons.email_outlined, const Color(0xFF2168F8), 'Email', 'Admin@SIT_islamic.edu'),
                                _buildInfoRow(Icons.phone_outlined, const Color(0xFF2168F8), 'Phone', '+92 300 1234567'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Settings Title
                          Text(
                            Translations.get('Settings', isUrdu),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          const SizedBox(height: 15),

                          // Settings Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildSettingRow(Icons.lock_outline, const Color(0xFF9E38FF), 'Change Password'),
                                _buildSettingRow(Icons.language, const Color(0xFF00D4FF), 'Language', trailing: Text(isUrdu ? 'Urdu' : 'English', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700))),
                                _buildSettingRow(Icons.notifications_none, const Color(0xFFFF9800), 'Notification', trailing: Switch(
                                  value: isNotificationEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isNotificationEnabled = value;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF2168F8),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFD3D3D3),
                                )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 35),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // Perform logout logic
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF44336), // Red color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout, color: Colors.white, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    Translations.get('Logout', isUrdu),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
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
              currentIndex: 4, // Profile index
              selectedItemColor: const Color(0xFF2168F8),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()), (route) => false);
                } else if (index == 1) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
                } else if (index == 2) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen()));
                } else if (index == 3) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
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
