import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'change_password_screen.dart';
import 'welcome_screen.dart';
import 'services/firebase_service.dart';
import 'about_us_screen.dart';
import 'parent_admin_chat_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;
  bool _smsEnabled = false;
  bool _emailEnabled = true; // Enabled by default
  final bool _appNotificationsEnabled = true; // Mandatory

  @override
  void initState() {
    super.initState();
    _parentData = _firebaseService.selectedStudent;
  }

  Stream<DocumentSnapshot>? _getStudentStream() {
    if (_parentData == null) return null;
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(_parentData!['adminId'])
        .collection('students')
        .doc(_parentData!['docId'].toString())
        .snapshots();
  }

  void _showNotificationPreferences(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('Select notification channels', isUrdu),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: true,
                  onChanged: null, // Mandatory
                  title: Text(Translations.get('App Notifications', isUrdu)),
                  subtitle: Text(Translations.get('Mandatory', isUrdu), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  activeColor: const Color(0xFF2962FF),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                CheckboxListTile(
                  value: _smsEnabled,
                  onChanged: (val) async {
                    if (val == true) {
                      setModalState(() {
                        _smsEnabled = true;
                        _emailEnabled = false; // Exclusive choice
                      });
                      setState(() {});
                      await _updateNotificationPreferences();
                    }
                  },
                  title: Text(Translations.get('SMS Alert', isUrdu)),
                  activeColor: const Color(0xFF2962FF),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                CheckboxListTile(
                  value: _emailEnabled,
                  onChanged: (val) async {
                    if (val == true) {
                      setModalState(() {
                        _emailEnabled = true;
                        _smsEnabled = false; // Exclusive choice
                      });
                      setState(() {});
                      await _updateNotificationPreferences();
                    }
                  },
                  title: Text(Translations.get('Email Alert', isUrdu)),
                  activeColor: const Color(0xFF2962FF),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _updateNotificationPreferences() async {
    if (_parentData == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(_parentData!['adminId'])
          .collection('students')
          .doc(_parentData!['docId'].toString())
          .update({
            'notificationPreferences': {
              'sms': _smsEnabled,
              'email': _emailEnabled,
              'app': true,
            }
          });
    } catch (e) {
      debugPrint("Error updating notification preferences: $e");
    }
  }

  void _showLogoutConfirmation(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              Translations.get('Cancel', isUrdu),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog
              await _firebaseService.logoutParent();
              if (context.mounted) {
                navigateWithLoader(context, () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                });
              }
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
    bool showDot = false,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (showDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              navigateWithLoader(context, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
                );
              });
            },
            child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: StreamBuilder<DocumentSnapshot>(
              stream: _getStudentStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Profile data not found."));
                }

                var student = snapshot.data!.data() as Map<String, dynamic>;
                
                // Initialize preferences from Firestore if available
                var prefs = student['notificationPreferences'] as Map<String, dynamic>?;
                if (prefs != null) {
                  _smsEnabled = prefs['sms'] ?? false;
                  _emailEnabled = prefs['email'] ?? true; // Default to true if not specified
                } else {
                  // If no preferences record exists yet, ensure email is true by default
                  _emailEnabled = true;
                }

                String studentName = student['studentName'] ?? 'No Name';
                String parentName = student['parentName'] ?? 'No Name';
                String parentEmail = student['parentEmail'] ?? '-';
                String parentPhone = student['parentPhone'] ?? '-';
                String className = student['class'] ?? '-';
                String rollNo = student['rollNumber'] ?? '-';

                return SingleChildScrollView(
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
                                      parentName,
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
                          valueKey: parentName,
                          isUrdu: false, // Don't translate names
                        ),
                        _buildInfoRow(
                          icon: Icons.mail_outline,
                          iconColor: const Color(0xFF00BCD4),
                          labelKey: 'Email',
                          valueKey: parentEmail,
                          isUrdu: false,
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF00BCD4),
                          labelKey: 'Phone',
                          valueKey: parentPhone,
                          isUrdu: false,
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
                                    studentName,
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
                                    className.startsWith('Class:') 
                                        ? className.substring(6).trim() 
                                        : (className.toLowerCase().startsWith('class ') 
                                            ? className.substring(6).trim() 
                                            : className),
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
                                    rollNo,
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
                          icon: Icons.lock_outline,
                          iconColor: const Color(0xFF9E38FF), // Purple
                          titleKey: 'Change Password',
                          isUrdu: isUrdu,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChangePasswordScreen(role: 'parent'),
                              ),
                            );
                          },
                        ),
                        _buildSettingsRow(
                          icon: Icons.notifications_none_outlined,
                          iconColor: const Color(0xFFFF9800), // Orange
                          titleKey: 'Notification Preferences',
                          isUrdu: isUrdu,
                          trailingWidget: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => _showNotificationPreferences(context, isUrdu),
                          hideBorder: true,
                        ),
                      ],
                    ),
                  ),

                  // Help & Support
                  _buildSectionHeader('Help & Support', isUrdu),
                  _buildCardContainer(
                    child: Column(
                      children: [
                        StreamBuilder<bool>(
                          stream: _firebaseService.hasUnreadAdminMessagesStream(student['docId'].toString()),
                          builder: (context, snapshot) {
                            bool hasUnread = snapshot.data ?? false;
                            return _buildSettingsRow(
                              icon: Icons.chat_bubble_outline,
                              iconColor: const Color(0xFFE91E63), // Pink
                              titleKey: 'Contact School',
                              isUrdu: isUrdu,
                              showDot: hasUnread,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentAdminChatScreen(
                                      parentId: student['docId'].toString(),
                                      adminId: _parentData!['adminId'],
                                      parentName: parentName,
                                      role: 'parent',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        _buildSettingsRow(
                          icon: Icons.info_outline,
                          iconColor: const Color(0xFF4CAF50), // Green
                          titleKey: 'About Us',
                          isUrdu: isUrdu,
                          hideBorder: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutUsScreen(),
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
            );
          },
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
          ),
        );
      },
    );
  }
}
