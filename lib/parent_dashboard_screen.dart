import 'package:flutter/material.dart';
import 'language_config.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';
import 'navigation_helper.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get(title, languageNotifier.value),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.get(subtitle, languageNotifier.value),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(IconData icon, Color iconColor, Color bgColor, String title, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          Translations.get(time, languageNotifier.value),
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                        Text(
                          Translations.get('Welcome,', isUrdu),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ali Muhammad',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 26, 
                            fontWeight: FontWeight.w800, 
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Translations.get('Parent Portal', isUrdu),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Summary Card
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00D4FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school, color: Colors.white, size: 36),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Zain Muhammad',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Class 10-A Roll No:101',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                Translations.get('Current Month', isUrdu),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF)),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(Translations.get('Total Fee', isUrdu), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                      const SizedBox(height: 5),
                                      const Text('Rs. 5,000', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(Translations.get('Paid', isUrdu), style: const TextStyle(fontSize: 13, color: Colors.green)),
                                      const SizedBox(height: 5),
                                      const Text('Rs. 2,500', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(Translations.get('Remaining', isUrdu), style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
                                      const SizedBox(height: 5),
                                      const Text('Rs. 2,500', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Payment Due Alert
                        GestureDetector(
                          onTap: () {
                            navigateWithLoader(context, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentFeesScreen()));
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF6C00),
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
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.priority_high, color: Color(0xFFEF6C00), size: 24),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Translations.get('Payment Due', isUrdu),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Translations.get('Next installment due on January 15, 2026', isUrdu),
                                        style: const TextStyle(fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Action Buttons Layer
                        _buildActionCard(
                          context,
                          icon: Icons.calendar_today,
                          iconColor: const Color(0xFF2168F8), // Blue
                          title: 'Fee Details',
                          subtitle: 'View breakdown & installments',
                          onTap: () {
                            navigateWithLoader(context, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentFeesScreen()));
                            });
                          },
                        ),
                        
                        _buildActionCard(
                          context,
                          icon: Icons.receipt_long,
                          iconColor: const Color(0xFF00D4FF), // Cyan
                          title: 'Generate Voucher',
                          subtitle: 'Voucher generation & installments',
                          onTap: () {
                            navigateWithLoader(context, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentVoucherScreen()));
                            });
                          },
                        ),

                        _buildActionCard(
                          context,
                          icon: Icons.notifications_none_outlined,
                          iconColor: const Color(0xFF6554C0), // Purple
                          title: 'Get Alerts',
                          subtitle: 'Alert & reminders',
                          onTap: () {
                            navigateWithLoader(context, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentAlertsScreen()));
                            });
                          },
                        ),

                        const SizedBox(height: 25),

                        // Recent Notifications Title
                        Text(
                          Translations.get('Recent Notifications', isUrdu),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 15),
                        
                        // Recent Notifications List Container
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                          child: Column(
                            children: [
                              _buildNotificationItem(
                                Icons.notifications_none,
                                const Color(0xFF2168F8),
                                const Color(0xFFE3F2FD),
                                'Payment reminder: Next installment due in 35 days',
                                '2 hours ago',
                              ),
                              const Divider(height: 1, color: Colors.black12, indent: 60, endIndent: 20),
                              _buildNotificationItem(
                                Icons.attach_money,
                                const Color(0xFF4CAF50),
                                const Color(0xFFE8F5E9),
                                'Payment verified: Rs. 2,500 received',
                                '3 hours ago',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 0,
              selectedItemColor: const Color(0xFF00D4FF),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 26,
              onTap: (index) {
                if (index == 1) {
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
                } else if (index == 4) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentProfileScreen()));
                  });
                }
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), label: Translations.get('Fees', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: Translations.get('Voucher', isUrdu)),
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
