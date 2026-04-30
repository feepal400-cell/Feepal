import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_config.dart';
import 'parent_fees_screen.dart';
import 'parent_voucher_screen.dart';
import 'parent_alerts_screen.dart';
import 'parent_profile_screen.dart';
import 'navigation_helper.dart';
import 'loginscreen.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'services/firebase_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _parentData;

  @override
  void initState() {
    super.initState();
    // Use the active student from the session
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _parentData = _firebaseService.selectedStudent;
    });
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

  void _handleLogout() {
    _firebaseService.logoutParent();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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

  Widget _buildProfileCard(bool isUrdu) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _getStudentStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        String name = data['studentName'] ?? 'No Name';
        String className = data['class'] ?? 'N/A';
        String displayClass = className.toLowerCase().contains('class')
            ? className
            : 'Class $className';
        String rollNo = data['rollNumber'] ?? 'N/A';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF00D4FF),
                  size: 35,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$displayClass | Roll No: $rollNo",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildSelector(bool isUrdu) {
    final children = _firebaseService.currentParentSession ?? [];
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: children.length,
        itemBuilder: (context, index) {
          bool isSelected = _firebaseService.activeStudentIndex == index;
          var child = children[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _firebaseService.activeStudentIndex = index;
                _refreshData();
              });
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00D4FF) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00D4FF)
                      : Colors.grey[200]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    child['studentName']?.split(' ').first ?? 'Child',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  Widget _buildNotificationItem(
    IconData icon,
    Color iconColor,
    Color bgColor,
    String title,
    String time, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_parentData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Session Expired"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _handleLogout,
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: StreamBuilder<DocumentSnapshot>(
              stream: _getStudentStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading data"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Student data not found."));
                }

                var student = snapshot.data!.data() as Map<String, dynamic>;
                String parentName = student['parentName'] ?? 'Parent';
                String studentName = student['studentName'] ?? 'Student';
                String className = student['class'] ?? '-';
                String displayClass = className.toLowerCase().contains('class')
                    ? className
                    : 'Class $className';
                String rollNo = student['rollNumber'] ?? '-';
                String feeStatus =
                    student['feeStatus']?.toString().toLowerCase() ?? 'unpaid';
                double arrearsBalance =
                    double.tryParse(
                      student['arrearsBalance']?.toString() ?? '0',
                    ) ??
                    0.0;
                double discountPercent =
                    (student['siblingDiscountPercentage'] ?? 0).toDouble();

                return StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getClassFeesStream(
                    _parentData!['adminId'],
                    className,
                  ),
                  builder: (context, feeSnapshot) {
                    double baseFee = 0.0;
                    double additionalCharge = 0.0;

                    if (feeSnapshot.hasData &&
                        feeSnapshot.data!.docs.isNotEmpty) {
                      var feeData =
                          feeSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                      baseFee =
                          double.tryParse(
                            feeData['baseFee']?.toString() ?? '0',
                          ) ??
                          0.0;
                      additionalCharge =
                          double.tryParse(
                            feeData['additionalCharge']?.toString() ?? '0',
                          ) ??
                          0.0;
                    }

                    double totalBeforeDiscount = baseFee + additionalCharge;
                    double discountAmount =
                        (totalBeforeDiscount * discountPercent) / 100;
                    double currentMonthTotal =
                        totalBeforeDiscount - discountAmount;

                    bool isPaid = feeStatus == 'paid';
                    double totalDue =
                        arrearsBalance + (isPaid ? 0.0 : currentMonthTotal);

                    String currentMonthName = DateFormat(
                      'MMMM',
                    ).format(DateTime.now());

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Child Selector UI (if multi-student)
                          if (_firebaseService.currentParentSession != null &&
                              _firebaseService.currentParentSession!.length > 1)
                            _buildChildSelector(isUrdu),

                          // Student Profile Summary
                          _buildProfileCard(isUrdu),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  parentName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Translations.get('Parent Portal', isUrdu),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF00D4FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.school,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  studentName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$displayClass Roll No:$rollNo',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "$currentMonthName ${Translations.get('Status', isUrdu)}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00D4FF),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                Translations.get(
                                                  'Current Month',
                                                  isUrdu,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Rs. ${currentMonthTotal.toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                Translations.get(
                                                  'Total Due',
                                                  isUrdu,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Rs. ${totalDue.toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                Translations.get(
                                                  'Status',
                                                  isUrdu,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: totalDue == 0
                                                      ? Colors.green
                                                      : Colors.deepOrange,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                totalDue == 0
                                                    ? Translations.get(
                                                        'Paid',
                                                        isUrdu,
                                                      )
                                                    : Translations.get(
                                                        'Unpaid',
                                                        isUrdu,
                                                      ),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: totalDue == 0
                                                      ? Colors.green
                                                      : Colors.deepOrange,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Payment Due Alert (Dynamic based on Unpaid)
                                if (!isPaid && totalDue > 0)
                                  GestureDetector(
                                    onTap: () {
                                      navigateWithLoader(context, () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ParentFeesScreen(),
                                          ),
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF6C00),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
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
                                            child: const Icon(
                                              Icons.priority_high,
                                              color: Color(0xFFEF6C00),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  Translations.get(
                                                    'Payment Due',
                                                    isUrdu,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  Translations.get(
                                                    'Please clear pending dues',
                                                    isUrdu,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (!isPaid && totalDue > 0)
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ParentFeesScreen(),
                                        ),
                                      );
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ParentVoucherScreen(),
                                        ),
                                      );
                                    });
                                  },
                                ),

                                _buildActionCard(
                                  context,
                                  icon: Icons.notifications_none_outlined,
                                  iconColor: const Color(0xFF6554C0), // Purple
                                  title: 'Show Alerts',
                                  subtitle: 'Alert & reminders',
                                  onTap: () {
                                    navigateWithLoader(context, () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ParentAlertsScreen(),
                                        ),
                                      );
                                    });
                                  },
                                ),

                                const SizedBox(height: 25),

                                // Recent Notifications Title
                                Text(
                                  Translations.get(
                                    'Recent Notifications',
                                    isUrdu,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Recent Notifications List Container
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firebaseService
                                      .getNotificationsStream(
                                        _parentData!['adminId'],
                                        _parentData!['docId'].toString(),
                                      ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            Translations.get(
                                              'No notifications yet',
                                              isUrdu,
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: snapshot.data!.docs.take(2).map((
                                          doc,
                                        ) {
                                          var data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          bool isWelcome =
                                              data['iconType'] == 'welcome';
                                          bool isFee =
                                              data['iconType'] == 'fee';

                                          IconData icon;
                                          Color color;
                                          Color bgColor;

                                          if (isWelcome) {
                                            icon = Icons.celebration;
                                            color = Colors.orange;
                                            bgColor = Colors.orange.withValues(
                                              alpha: 0.1,
                                            );
                                          } else if (isFee) {
                                            icon = Icons.account_balance_wallet;
                                            color = Colors.amber[800]!;
                                            bgColor = Colors.amber.withValues(
                                              alpha: 0.1,
                                            );
                                          } else {
                                            icon = Icons.notifications_none;
                                            color = const Color(0xFF2168F8);
                                            bgColor = const Color(0xFFE3F2FD);
                                          }

                                          return _buildNotificationItem(
                                            icon,
                                            color,
                                            bgColor,
                                            data['title'] ?? 'Notification',
                                            _getTimeAgo(data['timestamp']),
                                            onTap: () {
                                              navigateWithLoader(context, () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ParentAlertsScreen(),
                                                  ),
                                                );
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
                } else if (index == 4) {
                  navigateWithLoader(context, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentProfileScreen(),
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
