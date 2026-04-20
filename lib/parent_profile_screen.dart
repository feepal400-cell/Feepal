import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'settings_change_password_screen.dart';
import 'user_login_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool _notificationsEnabled = true;

  void _showLogoutConfirmation(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Translations.get('Logout', isUrdu),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          Translations.get('Are you sure you want to logout?', isUrdu),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Translations.get('Cancel', isUrdu),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              navigateWithLoader(context, () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserLoginScreen(),
                  ),
                  (route) => false,
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              Translations.get('Logout', isUrdu),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey, bool isUrdu) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 10),
      child: Text(
        Translations.get(titleKey, isUrdu),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String labelKey,
    required String valueKey,
    required bool isUrdu,
    bool hideBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: hideBorder
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
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
                  Translations.get(labelKey, isUrdu),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Translations.get(valueKey, isUrdu),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String titleKey,
    required bool isUrdu,
    Widget? trailingWidget,
    String? trailingTextKey,
    bool hideBorder = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: hideBorder
              ? null
              : Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                Translations.get(titleKey, isUrdu),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingTextKey != null)
              Text(
                Translations.get(trailingTextKey, isUrdu),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (trailingWidget != null) ...[
              if (trailingTextKey != null)
                const SizedBox(width: 10)
              else
                const SizedBox(),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLinkRow(
    String titleKey,
    bool isUrdu, {
    bool hideBorder = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: hideBorder
              ? null
              : Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
        ),
        child: Text(
          Translations.get(titleKey, isUrdu),
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
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
                  // Main Profile Header Card (Top Header)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 50, bottom: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF009BCB)],
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
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            Translations.get('Profile & Settings', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Avatar and Intro Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00BCD4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Translations.get('Ali Muhammad', isUrdu),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Translations.get(
                                        'Parent Account',
                                        isUrdu,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
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

                  const SizedBox(height: 10),

                  // Parent Information
                  _buildSectionHeader('Parent Information', isUrdu),
                  _buildCardContainer(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF00BCD4),
                          labelKey: 'Name',
                          valueKey: 'Ali Muhammad',
                          isUrdu: isUrdu,
                        ),
                        _buildInfoRow(
                          icon: Icons.mail_outline,
                          iconColor: const Color(0xFF00BCD4),
                          labelKey: 'Email',
                          valueKey: 'Ali.muhammad@gmail.com',
                          isUrdu: isUrdu,
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF00BCD4),
                          labelKey: 'Phone',
                          valueKey: '+92 300 1234567',
                          isUrdu: isUrdu,
                          hideBorder: true,
                        ),
                      ],
                    ),
                  ),

                  // Student Information
                  _buildSectionHeader('Student Information', isUrdu),
                  _buildCardContainer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF2962FF),
                              size: 24,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('Student Name', isUrdu),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Translations.get('Zain Muhammad', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const SizedBox(width: 39),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('Class', isUrdu),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Translations.get('Class 10', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('Roll No', isUrdu),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Translations.get('101', isUrdu),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Settings
                  _buildSectionHeader('Settings', isUrdu),
                  _buildCardContainer(
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          icon: Icons.lock_outline,
                          iconColor: const Color(0xFF9C27B0), // Purple wrapper
                          titleKey: 'Change Password',
                          isUrdu: isUrdu,
                          onTap: () {
                            navigateWithLoader(context, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsChangePasswordScreen(),
                                ),
                              );
                            });
                          },
                        ),
                        _buildSettingsRow(
                          icon: Icons.language_outlined,
                          iconColor: const Color(0xFF00BCD4),
                          titleKey: 'Language',
                          trailingTextKey: isUrdu ? 'Urdu' : 'English',
                          isUrdu: isUrdu,
                          onTap: () {
                            languageNotifier.toggle();
                          },
                        ),
                        _buildSettingsRow(
                          icon: Icons.notifications_none_outlined,
                          iconColor: const Color(0xFFFF9800), // Orange
                          titleKey: 'Notification Preferences',
                          isUrdu: isUrdu,
                          trailingWidget: SizedBox(
                            height: 24,
                            child: CupertinoSwitch(
                              value: _notificationsEnabled,
                              activeTrackColor: const Color(
                                0xFF2962FF,
                              ), // Blue active state
                              onChanged: (val) {
                                setState(() {
                                  _notificationsEnabled = val;
                                });
                              },
                            ),
                          ),
                          hideBorder: true,
                        ),
                      ],
                    ),
                  ),

                  // Help & Support
                  _buildSectionHeader('Help & Support', isUrdu),
                  _buildCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSimpleLinkRow(
                          'FAQ',
                          isUrdu,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  Translations.get('Coming Soon', isUrdu),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSimpleLinkRow(
                          'Contact Support',
                          isUrdu,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  Translations.get('Coming Soon', isUrdu),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSimpleLinkRow(
                          'Terms & Conditions',
                          isUrdu,
                          hideBorder: true,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  Translations.get('Coming Soon', isUrdu),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showLogoutConfirmation(context, isUrdu);
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Text(
                          Translations.get('Logout', isUrdu),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFF4B4B,
                          ), // Bright red
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 4, // Profile is index 4
              selectedItemColor: const Color(0xFF00BCD4),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentDashboardScreen(),
                      ),
                    );
                  });
                } else if (index == 1) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentFeesScreen(),
                      ),
                    );
                  });
                } else if (index == 2) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentVoucherScreen(),
                      ),
                    );
                  });
                } else if (index == 3) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentAlertsScreen(),
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
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Translations.get('Fees', isUrdu),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Translations.get('Voucher', isUrdu),
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
