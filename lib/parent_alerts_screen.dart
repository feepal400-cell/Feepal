import 'package:flutter/material.dart';
import 'language_config.dart';
import 'navigation_helper.dart';
import 'parent_dashboard_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_profile_screen.dart';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationFilter { all, unread, reminders, important }

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
  final FirebaseService _firebaseService = FirebaseService();
  NotificationFilter _currentFilter = NotificationFilter.all;
  Map<String, dynamic>? _parentData;

  @override
  void initState() {
    super.initState();
    _parentData = _firebaseService.selectedStudent;
  }

  void _markAllAsRead() {
    if (_parentData == null) return;
    _firebaseService.markAllNotificationsAsRead(
      _parentData!['adminId'],
      _parentData!['docId'].toString(),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'just now';
    if (timestamp is! Timestamp) return 'just now';
    DateTime dt = timestamp.toDate();
    Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

  Widget _buildNotificationCard(Map<String, dynamic> data, bool isRead, bool isUrdu) {
    bool isWelcome = data['iconType'] == 'welcome';
    bool isFee = data['iconType'] == 'fee';
    
    IconData icon;
    Color iconColor;
    
    if (isWelcome) {
      icon = Icons.celebration;
      iconColor = Colors.orange;
    } else if (isFee) {
      icon = Icons.account_balance_wallet;
      iconColor = Colors.amber[800]!;
    } else if (data['iconType'] == 'priority') {
      icon = Icons.report_problem;
      iconColor = Colors.red;
    } else if (data['isReminder'] == true) {
      icon = Icons.alarm;
      iconColor = Colors.red;
    } else {
      icon = Icons.notifications_none;
      iconColor = const Color(0xFF00D4FF);
    }
    
    Color iconBgColor = iconColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: !isRead 
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
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Notification',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTimeAgo(data['timestamp']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) const SizedBox(width: 25),
            ],
          ),
          
          if (!isRead)
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
                
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.getNotificationsStream(
                      _parentData!['adminId'],
                      _parentData!['docId'].toString(),
                    ),
                    builder: (context, snapshot) {
                      var allDocs = snapshot.data?.docs ?? [];
                      var filteredDocs = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        if (_currentFilter == NotificationFilter.unread) {
                          return data['isRead'] == false;
                        } else if (_currentFilter == NotificationFilter.reminders) {
                          return data['isReminder'] == true;
                        } else if (_currentFilter == NotificationFilter.important) {
                          return data['isImportant'] == true;
                        }
                        return true;
                      }).toList();

                      return Column(
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
                                  _buildFilterChip('Important', NotificationFilter.important, isUrdu),
                                ],
                              ),
                            ),
                          ),
                          
                          Expanded(
                            child: snapshot.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : (filteredDocs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                                        const SizedBox(height: 15),
                                        Text(
                                          Translations.get('No notifications yet', isUrdu),
                                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, index) {
                                      var doc = filteredDocs[index];
                                      var data = doc.data() as Map<String, dynamic>;
                                      return _buildNotificationCard(data, data['isRead'] ?? false, isUrdu);
                                    },
                                  )),
                          ),

                          // Fixed Bottom "Mark All as Read" Button Area
                          if (allDocs.any((doc) => (doc.data() as Map<String, dynamic>)['isRead'] == false))
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
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    Translations.get('Mark All as Read', isUrdu),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
