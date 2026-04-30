import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'settings_change_password_screen.dart';
import 'user_login_screen.dart';
import 'navigation_helper.dart';
import 'bank_details_screen.dart';
import 'services/firebase_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isNotificationEnabled = true;
  bool _isLoading = true;
  String _schoolName = '';
  String _adminName = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final data = await _firebaseService.getAdminProfile();
    if (mounted && data != null) {
      setState(() {
        _schoolName = data['schoolName'] ?? 'School Name';
        _adminName = data['adminName'] ?? 'Admin Name';
        _email = data['email'] ?? 'No Email';
        _phone = data['phoneNumber'] ?? 'No Phone';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    Color iconColor,
    String label,
    String value,
  ) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    Color iconColor,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null ? () => navigateWithLoader(context, onTap) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                Translations.get(title, languageNotifier.value),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
              ),
            ),
          ),
          ?trailing,
        ],
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
                        colors: [
                          Color(0xFF2168F8),
                          Color(0xFF00D4FF),
                        ], // Blue gradient
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
                                color: Colors.black.withValues(alpha: 0.08),
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
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoading ? 'Loading...' : _schoolName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
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
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isLoading 
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(color: Color(0xFF2168F8)),
                              ))
                            : Column(
                            children: [
                              _buildInfoRow(
                                Icons.account_balance,
                                const Color(0xFF2168F8),
                                'School Name',
                                _schoolName,
                              ),
                              _buildInfoRow(
                                Icons.person_outline,
                                const Color(0xFF2168F8),
                                'Admin Name',
                                _adminName,
                              ),
                              _buildInfoRow(
                                Icons.email_outlined,
                                const Color(0xFF2168F8),
                                'Email',
                                _email,
                              ),
                              _buildInfoRow(
                                Icons.phone_outlined,
                                const Color(0xFF2168F8),
                                'Phone',
                                _phone,
                              ),
                              const Divider(height: 1, color: Colors.black12),
                              _buildSettingRow(
                                Icons.account_balance_wallet_outlined,
                                const Color(0xFF4CAF50),
                                'Bank Account Details',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BankDetailsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Settings Title
                        Text(
                          Translations.get('Settings', isUrdu),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Settings Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingRow(
                                Icons.lock_outline,
                                const Color(0xFF9E38FF),
                                'Change Password',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsChangePasswordScreen(),
                                    ),
                                  );
                                },
                              ),

                              _buildSettingRow(
                                Icons.language,
                                const Color(0xFF00D4FF),
                                'Language',
                                onTap: () {
                                  languageNotifier.toggle();
                                },
                                trailing: Text(
                                  isUrdu ? 'Urdu' : 'English',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _buildSettingRow(
                                Icons.notifications_none,
                                const Color(0xFFFF9800),
                                'Notification',
                                trailing: Switch(
                                  value: isNotificationEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isNotificationEnabled = value;
                                    });
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF2168F8),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFD3D3D3),
                                ),
                              ),
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
                              navigateWithLoader(context, () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UserLoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF44336,
                              ), // Red color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  Translations.get('Logout', isUrdu),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
