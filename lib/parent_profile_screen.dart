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
        title: Text(Translations.get('Logout', isUrdu), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(Translations.get('Are you sure you want to logout?', isUrdu)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.get('Cancel', isUrdu), style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              navigateWithLoader(context, () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                  (route) => false,
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(Translations.get('Logout', isUrdu), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey, bool isUrdu) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      child: Text(
        Translations.get(titleKey, isUrdu),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
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
          : Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get(labelKey, isUrdu),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  Translations.get(valueKey, isUrdu),
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: hideBorder 
            ? null 
            : Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                Translations.get(titleKey, isUrdu),
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
            if (trailingTextKey != null)
              Text(
                Translations.get(trailingTextKey, isUrdu),
                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ?trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRow(String titleKey, bool isUrdu, {bool hideBorder = false, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        width: double.infinity,
        decoration: BoxDecoration(
          border: hideBorder 
            ? null 
            : Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Text(
          Translations.get(titleKey, isUrdu),
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
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
            body: Stack(
              children: [
                // Top Cyan Gradient Background Container
                Container(
                  height: 180,
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
                ),
                
                // Scrolling Content
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row (Back Button + Title)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BBD4),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                Translations.get('Profile & Settings', isUrdu),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Top Summary Card
                        Container(
                          margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D4FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline, color: Colors.white, size: 35),
                              ),
                              const SizedBox(width: 15),
                              // Info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('Ali Muhammad', isUrdu),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    Translations.get('Parent Account', isUrdu),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Parent Information
                        _buildSectionHeader('Parent Information', isUrdu),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                iconColor: const Color(0xFF00BBD4),
                                labelKey: 'Name',
                                valueKey: 'Ali Muhammad',
                                isUrdu: isUrdu,
                              ),
                              _buildInfoRow(
                                icon: Icons.mail_outline,
                                iconColor: const Color(0xFF00BBD4),
                                labelKey: 'Email',
                                valueKey: 'Ali.muhammad@gmail.com', // Typically not translated but safe
                                isUrdu: isUrdu,
                              ),
                              _buildInfoRow(
                                icon: Icons.phone_outlined,
                                iconColor: const Color(0xFF00BBD4),
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
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top Name Row
                              Row(
                                children: [
                                  const Icon(Icons.school_outlined, color: Color(0xFF1976D2), size: 22),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Translations.get('Student Name', isUrdu),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          Translations.get('Zain Muhammad', isUrdu),
                                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Bottom Split Info (Class / Roll No)
                              Row(
                                children: [
                                  // Alignment spacer to match icon width offset
                                  const SizedBox(width: 37), 
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Translations.get('Class', isUrdu),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          Translations.get('Class 10', isUrdu),
                                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
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
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          Translations.get('101', isUrdu),
                                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
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
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsRow(
                                icon: Icons.lock_outline,
                                iconColor: const Color(0xFF9C27B0), // Purple
                                titleKey: 'Change Password',
                                isUrdu: isUrdu,
                                onTap: () {
                                  navigateWithLoader(context, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsChangePasswordScreen()));
                                  });
                                },
                              ),
                              _buildSettingsRow(
                                icon: Icons.language_outlined,
                                iconColor: const Color(0xFF00BBD4),
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
                                  height: 24, // Keep switch compact
                                  child: CupertinoSwitch(
                                    value: _notificationsEnabled,
                                    activeTrackColor: const Color(0xFF2962FF), // Blue active state
                                    onChanged: (val) {
                                      setState(() { _notificationsEnabled = val; });
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
                         Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSimpleRow('FAQ', isUrdu, onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.get('Coming Soon', isUrdu))));
                              }),
                              _buildSimpleRow('Contact Support', isUrdu, onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.get('Coming Soon', isUrdu))));
                              }),
                              _buildSimpleRow('Terms & Conditions', isUrdu, hideBorder: true, onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.get('Coming Soon', isUrdu))));
                              }),
                            ],
                          ),
                        ),
                        
                        // Logout Button
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showLogoutConfirmation(context, isUrdu);
                              },
                              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                              label: Text(
                                Translations.get('Logout', isUrdu),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4B4B), // Red button
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Flat rectangle rounding per design
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Global Bottom Navigation Bar
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 4, // Profile is index 4
              selectedItemColor: const Color(0xFF00D4FF),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 0) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
                  });
                } else if (index == 1) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentFeesScreen()));
                  });
                } else if (index == 2) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentVoucherScreen()));
                  });
                } else if (index == 3) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentAlertsScreen()));
                  });
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), label: Translations.get('Fees', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: Translations.get('Voucher', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.notifications_none_outlined), label: Translations.get('Alerts', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.person), label: Translations.get('Profile', isUrdu)),
              ],
            ),
          ),
        );
      },
    );
  }
}
