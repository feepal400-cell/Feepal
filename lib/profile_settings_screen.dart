import 'package:flutter/material.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'welcome_screen.dart';
import 'navigation_helper.dart';
import 'bank_details_screen.dart';
import 'admin_subscription_details_screen.dart';
import 'services/firebase_service.dart';
import 'services/cloudinary_service.dart';
import 'chat_screen.dart';
import 'about_us_screen.dart';
import 'admin_change_password_screen.dart';
import 'admin_parent_chat_list_screen.dart';

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
  String _address = '';
  String? _schoolLogoUrl;
  bool _isBankDetailsMissing = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final data = await _firebaseService.getAdminProfile();
    if (mounted && data != null) {
      setState(() {
        _schoolName = data['schoolName']?.toString() ?? 'School Name';
        _adminName = data['adminName']?.toString() ?? 'Admin Name';
        _email = data['email']?.toString() ?? 'No Email';
        _phone = data['phoneNumber']?.toString() ?? 'No Phone';
        _address = data['schoolAddress']?.toString() ?? 'No Address Provided';
        _schoolLogoUrl = data['schoolLogoUrl']?.toString();
        isNotificationEnabled = data['isNotificationsEnabled'] ?? true;

        // Bank Validation Logic
        String bank = data['bankName']?.toString() ?? '';
        String title = data['accountTitle']?.toString() ?? '';
        String number = data['accountNumber']?.toString() ?? '';
        _isBankDetailsMissing = bank.isEmpty || title.isEmpty || number.isEmpty;

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
    String value, {
    bool isEditable = false,
  }) {
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
                Row(
                  children: [
                    Text(
                      Translations.get(label, languageNotifier.value),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                    if (isEditable) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.edit,
                        size: 12,
                        color: Color(0xFF2168F8),
                      ),
                    ],
                  ],
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

  void _showEditDialog(
    String title,
    String currentVal,
    Future<void> Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentVal);
    bool isUrdu = languageNotifier.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.get('Update $title', isUrdu)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: Translations.get('Enter $title', isUrdu),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.get('Cancel', isUrdu)),
          ),
          ElevatedButton(
            onPressed: () async {
              await onSave(controller.text);
              if (mounted) {
                Navigator.pop(context);
                _loadProfileData();
              }
            },
            child: Text(Translations.get('Save', isUrdu)),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      // Using 'School_Logos' as requested for Cloudinary folder organization
      String? url = await CloudinaryService.pickAndUploadImage(
        uploadPreset: 'School_Logos',
      );

      if (url != null) {
        await _firebaseService.updateAdminProfile(schoolLogoUrl: url);
        await _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Widget _buildSettingRow(
    IconData icon,
    Color iconColor,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool showDot = false,
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
              child: Row(
                children: [
                  Text(
                    Translations.get(title, languageNotifier.value),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (showDot)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.black26,
                ),
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
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              navigateWithLoader(context, () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                  (route) => false,
                );
              });
            },
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
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(40),
                                        child: _isUploadingLogo
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : (_schoolLogoUrl != null &&
                                                  _schoolLogoUrl!.isNotEmpty)
                                            ? Image.network(
                                                _schoolLogoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.school,
                                                      color: Color(0xFF2168F8),
                                                      size: 40,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.school,
                                                color: Color(0xFF2168F8),
                                                size: 40,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _isUploadingLogo
                                            ? null
                                            : _changeLogo,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2168F8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isLoading
                                            ? 'Loading...'
                                            : _schoolName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Translations.get(
                                          'Admin Account',
                                          isUrdu,
                                        ),
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
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2168F8),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showEditDialog(
                                          'School Name',
                                          _schoolName,
                                          (val) => _firebaseService
                                              .updateAdminProfile(
                                                schoolName: val,
                                              ),
                                        ),
                                        child: _buildInfoRow(
                                          Icons.account_balance,
                                          const Color(0xFF2168F8),
                                          'School Name',
                                          _schoolName,
                                          isEditable: true,
                                        ),
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
                                      GestureDetector(
                                        onTap: () => _showEditDialog(
                                          'School Address',
                                          _address,
                                          (val) => _firebaseService
                                              .updateAdminProfile(
                                                schoolAddress: val,
                                              ),
                                        ),
                                        child: _buildInfoRow(
                                          Icons.location_on_outlined,
                                          const Color(0xFF2168F8),
                                          'School Address',
                                          _address,
                                          isEditable: true,
                                        ),
                                      ),
                                      const Divider(
                                        height: 1,
                                        color: Colors.black12,
                                      ),
                                      _buildSettingRow(
                                        Icons.account_balance_wallet_outlined,
                                        const Color(0xFF4CAF50),
                                        'Bank Account Details',
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_isBankDetailsMissing)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF4CAF50),
                                                size: 20,
                                              ),
                                            if (_isBankDetailsMissing)
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.red,
                                                size: 22,
                                              ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const BankDetailsScreen(),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadProfileData(); // Refresh validation state
                                          }
                                        },
                                      ),
                                      _buildSettingRow(
                                        Icons.card_membership,
                                        const Color(0xFF673AB7),
                                        'Subscription Details',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AdminSubscriptionDetailsScreen(),
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
                                            const AdminChangePasswordScreen(),
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
                                    onChanged: (value) async {
                                      if (value == false) {
                                        // Show confirmation dialog before turning OFF
                                        _showNotificationConfirmDialog(
                                          context,
                                          isUrdu,
                                        );
                                      } else {
                                        // Turn ON immediately
                                        setState(() {
                                          isNotificationEnabled = true;
                                        });
                                        await _firebaseService
                                            .updateNotificationSettings(true);
                                      }
                                    },
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF2168F8),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFD3D3D3),
                                  ),
                                ),

                                StreamBuilder<bool>(
                                  stream: _firebaseService
                                      .hasUnreadParentMessagesStream(
                                        _firebaseService.currentAdminId ?? '',
                                      ),
                                  builder: (context, snapshot) {
                                    bool hasUnread = snapshot.data ?? false;
                                    return _buildSettingRow(
                                      Icons.forum_outlined,
                                      const Color(0xFFE91E63), // Pink
                                      'Parent Message Requests',
                                      showDot: hasUnread,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminParentChatListScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                StreamBuilder<bool>(
                                  stream: _firebaseService
                                      .hasUnreadForAdminStream(
                                        _firebaseService.currentAdminId ?? '',
                                      ),
                                  builder: (context, snapshot) {
                                    bool hasUnread = snapshot.data ?? false;
                                    return _buildSettingRow(
                                      Icons.chat_rounded,
                                      Colors.blue,
                                      'Contact Support',
                                      showDot: hasUnread,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ChatScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                _buildSettingRow(
                                  Icons.info_outline,
                                  Colors.blueGrey,
                                  'About Us',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutUsScreen(),
                                      ),
                                    );
                                  },
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
                              onPressed: () =>
                                  _showLogoutConfirmation(context, isUrdu),
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
          ),
        );
      },
    );
  }

  void _showNotificationConfirmDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_off_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(Translations.get('Disable Notifications?', isUrdu)),
            ),
          ],
        ),
        content: Text(
          Translations.get(
            'If you toggle the notifications to OFF you won\'t be able to recieve push notifications.',
            isUrdu,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              Translations.get('Cancel', isUrdu),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                isNotificationEnabled = false;
              });
              await _firebaseService.updateNotificationSettings(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2168F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              Translations.get('Turn Off', isUrdu),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog

              // Show Loader Dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2168F8)),
                ),
              );

              try {
                await _firebaseService.logout();
              } catch (e) {
                debugPrint("Logout Error: $e");
              }

              if (context.mounted) {
                Navigator.pop(context); // Remove Loader Dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              Translations.get('Logout', isUrdu),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
