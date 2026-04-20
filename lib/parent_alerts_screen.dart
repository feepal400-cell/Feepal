import 'package:flutter/material.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_profile_screen.dart';

enum NotificationFilter { all, unread, reminders }

class NotificationItem {
  final int id;
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  bool isUnread;
  final bool isReminder;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isUnread,
    required this.isReminder,
  });
}

class ParentAlertsScreen extends StatefulWidget {
  const ParentAlertsScreen({super.key});

  @override
  State<ParentAlertsScreen> createState() => _ParentAlertsScreenState();
}

class _ParentAlertsScreenState extends State<ParentAlertsScreen> {
  NotificationFilter _currentFilter = NotificationFilter.all;
  
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 1,
      title: 'Payment reminder',
      description: 'Your next installment of Rs. 2,500 is due on January 05, 2026',
      timeAgo: '2 hours ago',
      icon: Icons.notifications_none,
      iconColor: const Color(0xFF1976D2), // Blue
      iconBgColor: const Color(0xFFBBDEFB), // Light Blue
      isUnread: true,
      isReminder: true,
    ),
    NotificationItem(
      id: 2,
      title: 'Payment Verified',
      description: 'Your payment of Rs. 2,500 has been verified and approved',
      timeAgo: '3 hours ago',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF388E3C), // Green
      iconBgColor: const Color(0xFFC8E6C9), // Light Green
      isUnread: true,
      isReminder: false,
    ),
    NotificationItem(
      id: 3,
      title: 'Payment Received',
      description: 'Your payment voucher has been received and is under verification',
      timeAgo: '3 hours ago',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF388E3C),
      iconBgColor: const Color(0xFFC8E6C9),
      isUnread: false,
      isReminder: false,
    ),
    NotificationItem(
      id: 4,
      title: 'Due Date Approaching',
      description: 'Only 5 days left until your payment due date',
      timeAgo: '8 hours ago',
      icon: Icons.priority_high,
      iconColor: const Color(0xFFF57C00), // Orange
      iconBgColor: const Color(0xFFFFE0B2), // Light Orange
      isUnread: false,
      isReminder: true,
    ),
    NotificationItem(
      id: 5,
      title: 'Fee Structure Updated',
      description: 'New fee structure for next semester has been released',
      timeAgo: '9 days ago',
      icon: Icons.notifications_none,
      iconColor: const Color(0xFF1976D2),
      iconBgColor: const Color(0xFFBBDEFB),
      isUnread: false,
      isReminder: true,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    switch (_currentFilter) {
      case NotificationFilter.all:
        return _notifications;
      case NotificationFilter.unread:
        return _notifications.where((n) => n.isUnread).toList();
      case NotificationFilter.reminders:
        return _notifications.where((n) => n.isReminder).toList();
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  Widget _buildFilterChip(String labelKey, NotificationFilter filterValue, bool isUrdu) {
    bool isSelected = _currentFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filterValue;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          Translations.get(labelKey, isUrdu),
          style: TextStyle(
            color: isSelected ? const Color(0xFF00D4FF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: item.isUnread 
          ? Border.all(color: const Color(0xFF00D4FF), width: 1.5)
          : Border.all(color: Colors.transparent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Map
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              // Content Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get(item.title, isUrdu),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      Translations.get(item.description, isUrdu),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Translations.get(item.timeAgo, isUrdu),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Right side padding space for the unread dot
              if (item.isUnread) const SizedBox(width: 25),
            ],
          ),
          
          if (item.isUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D4FF), width: 2),
                  color: Colors.white,
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
            body: Column(
              children: [
                // Cyan Rounded Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF009BCB)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                      child: Text(
                        Translations.get('Notifications', isUrdu),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Scrolling Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Filter Chips Row
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', NotificationFilter.all, isUrdu),
                              _buildFilterChip('Unread', NotificationFilter.unread, isUrdu),
                              _buildFilterChip('Reminders', NotificationFilter.reminders, isUrdu),
                            ],
                          ),
                        ),
                      ),
                      
                      // List of Alerts
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(_filteredNotifications[index], isUrdu);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Fixed Bottom "Mark All as Read" Button Area
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _markAllAsRead();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Translations.get('All notifications marked as read', isUrdu)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00D4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), 
                        ),
                        elevation: 2, // Slight floating shadow per design
                      ),
                      child: Text(
                        Translations.get('Mark All as Read', isUrdu),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Global Bottom Navigation Bar
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 3, // Alerts is index 3
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
                BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: Translations.get('Alerts', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: Translations.get('Profile', isUrdu)),
              ],
            ),
          ),
        );
      },
    );
  }
}
