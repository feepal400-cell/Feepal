import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_config.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'alerts_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'activity_history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _schoolName = 'Loading...';
  String _adminName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // Check and renew fees in the background
    _firebaseService.checkAndRenewExpiredFees().catchError((e) {
      debugPrint("Error renewing fees: $e");
    });

    // Trigger automated checks for penalties and priority alerts
    _firebaseService.runAutomatedChecks().catchError((e) {
      debugPrint("Error running automated checks: $e");
    });

    final data = await _firebaseService.getAdminProfile();
    if (mounted && data != null) {
      setState(() {
        _schoolName = data['schoolName'] ?? 'School Name';
        _adminName = data['adminName'] ?? '';
        _isLoading = false;
      });
      
      // Check for subscription welcome popup
      _checkSubscriptionWelcome(data);
    } else if (mounted) {
      setState(() {
        _schoolName = 'FeePal School';
        _isLoading = false;
      });
    }
  }

  void _checkSubscriptionWelcome(Map<String, dynamic> data) {
    final subStatus = data['subscriptionStatus'];
    final hasSeenWelcome = data['hasSeenWelcome'] ?? true;
    final isUrdu = languageNotifier.value;

    if (subStatus == 'approved' && !hasSeenWelcome) {
      // Delay slightly to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showWelcomePopup(isUrdu, data['uid']);
        }
      });
    }
  }

  void _showWelcomePopup(bool isUrdu, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.celebration, color: Colors.orange, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Translations.get('Congratulations!', isUrdu),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              Translations.get('Your subscription has been successfully enabled by FeePal Team.', isUrdu),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            Text(
              Translations.get('Make sure to update your bank details and school profile.', isUrdu),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                _firebaseService.updateWelcomeFlag(uid);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2168F8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(Translations.get('Get Started', isUrdu), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    Color color,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
                          Translations.get(
                                'Welcome back,',
                                isUrdu,
                              ) +
                              (_adminName.isNotEmpty ? ' $_adminName' : ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _schoolName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Translations.get('Admin Dashboard', isUrdu),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2168F8),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid
                          StreamBuilder<QuerySnapshot>(
                            stream: _firebaseService.getStudentsStream(),
                            builder: (context, snapshot) {
                              int studentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      const Color(0xFF4C8DFF),
                                      Icons.person_outline,
                                      'Total Students',
                                      studentCount.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      const Color(0xFF4CAF50),
                                      Icons.attach_money,
                                      'Fees Collected',
                                      'Rs. 0',
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<int>(
                                  stream: _firebaseService.getUnpaidStudentsCountStream(),
                                  builder: (context, snapshot) {
                                    return _buildStatCard(
                                      context,
                                      const Color(0xFFFF8A00),
                                      Icons.access_time,
                                      'Pending Payments',
                                      (snapshot.data ?? 0).toString(),
                                    );
                                  }
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: StreamBuilder<int>(
                                  stream: _firebaseService.getOverdueStudentsCountStream(),
                                  builder: (context, snapshot) {
                                    return _buildStatCard(
                                      context,
                                      const Color(0xFFEF5350),
                                      Icons.error_outline,
                                      'Overdue',
                                      (snapshot.data ?? 0).toString(),
                                    );
                                  }
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 35),

                          // Quick Actions
                          Text(
                            Translations.get('Quick Actions', isUrdu),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildQuickAction(
                            'Add Student',
                            Icons.person_add_alt_1,
                            const Color(0xFF2168F8),
                            onTap: () {
                              navigateWithLoader(context, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const StudentManagementScreen(),
                                  ),
                                );
                              });
                            },
                          ),
                          _buildQuickAction(
                            'Create Fee',
                            Icons.receipt_long,
                            const Color(0xFF00D4FF),
                            onTap: () {
                              navigateWithLoader(context, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const FeeManagementScreen(),
                                  ),
                                );
                              });
                            },
                          ),
                          _buildQuickAction(
                            'Send Reminder',
                            Icons.notifications_active,
                            const Color(0xFF6554C0),
                            onTap: () {
                              navigateWithLoader(context, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AlertsScreen(),
                                  ),
                                );
                              });
                            },
                          ),

                          const SizedBox(height: 35),

                          // Recent Activity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Translations.get('Recent Activity', isUrdu),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ActivityHistoryScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  Translations.get('View All', isUrdu),
                                  style: const TextStyle(
                                    color: Color(0xFF2168F8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          StreamBuilder<QuerySnapshot>(
                            stream: _firebaseService.getAdminActivityStream(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 30,
                                  ),
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
                                  child: const Center(
                                    child: Text(
                                      'No recent activity yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: snapshot.data!.docs.take(5).map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  IconData icon;
                                  Color color;

                                  switch (data['iconType']) {
                                    case 'welcome':
                                      icon = Icons.celebration_outlined;
                                      color = Colors.orange;
                                      break;
                                    case 'student':
                                      icon = Icons.person_add_outlined;
                                      color = Colors.blue;
                                      break;
                                    case 'fee':
                                      icon = Icons.receipt_long_outlined;
                                      color = Colors.green;
                                      break;
                                    case 'alert':
                                    case 'notification':
                                      icon = Icons.notifications_active_outlined;
                                      color = Colors.purple;
                                      break;
                                    default:
                                      icon = Icons.info_outline;
                                      color = Colors.grey;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(icon, color: color, size: 24),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                data['subtitle'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }
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
