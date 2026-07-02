import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_config.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'fee_management_screen.dart';
import 'profile_settings_screen.dart';
import 'navigation_helper.dart';
import 'services/firebase_service.dart';
import 'package:intl/intl.dart' hide TextDirection;

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  // Selection State
  final Set<String> _selectedStudentIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData iconData,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardReminders(bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getStandardUnpaidStudentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingStudents = snapshot.data!.docs;

        if (pendingStudents.isEmpty) {
          return _buildEmptyState(
            'No pending dues for standard parents.',
            Icons.check_circle_outline,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            for (var doc in pendingStudents) {
                              _selectedStudentIds.add(doc.id);
                            }
                          });
                        },
                        icon: const Icon(Icons.select_all),
                        label: const Text('Select All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2168F8),
                          side: const BorderSide(color: Color(0xFF2168F8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        '${pendingStudents.length} Standard Parents Pending',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (_isSelectionMode) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedStudentIds.isEmpty
                            ? null
                            : () =>
                                  _sendBatchAlertsBySelection(pendingStudents),
                        icon: const Icon(Icons.send),
                        label: Text('Send (${_selectedStudentIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2168F8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else if (pendingStudents.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () => setState(() => _isSelectionMode = true),
                      icon: const Icon(Icons.checklist, size: 20),
                      label: const Text('Select'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2168F8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: pendingStudents.length,
                itemBuilder: (context, index) {
                  var doc = pendingStudents[index];
                  var student = doc.data() as Map<String, dynamic>;
                  String studentId = doc.id;

                  bool isSelected = _selectedStudentIds.contains(studentId);

                  return _buildReminderCard(
                    student,
                    studentId,
                    isSelected,
                    isUrdu,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityAction(bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getPriorityUnpaidStudentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingStudents = snapshot.data!.docs;

        if (pendingStudents.isEmpty) {
          return _buildEmptyState(
            'All priority parents are up to date.',
            Icons.check_circle_outline,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            for (var doc in pendingStudents) {
                              _selectedStudentIds.add(doc.id);
                            }
                          });
                        },
                        icon: const Icon(Icons.select_all),
                        label: const Text('Select All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9800),
                          side: const BorderSide(color: Color(0xFFFF9800)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        '${pendingStudents.length} Priority Parents Pending',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (_isSelectionMode) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedStudentIds.isEmpty
                            ? null
                            : () =>
                                  _sendBatchAlertsBySelection(pendingStudents),
                        icon: const Icon(Icons.priority_high),
                        label: Text('Send (${_selectedStudentIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else if (pendingStudents.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () => setState(() => _isSelectionMode = true),
                      icon: const Icon(Icons.checklist, size: 20),
                      label: const Text('Select'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: pendingStudents.length,
                itemBuilder: (context, index) {
                  var doc = pendingStudents[index];
                  var student = doc.data() as Map<String, dynamic>;
                  String studentId = doc.id;

                  bool isSelected = _selectedStudentIds.contains(studentId);

                  return _buildReminderCard(
                    student,
                    studentId,
                    isSelected,
                    isUrdu,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(
    Map<String, dynamic> student,
    String studentId,
    bool isSelected,
    bool isUrdu,
  ) {
    return InkWell(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedStudentIds.add(studentId);
        });
      },
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (_selectedStudentIds.contains(studentId)) {
                  _selectedStudentIds.remove(studentId);
                  if (_selectedStudentIds.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedStudentIds.add(studentId);
                }
              });
            }
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2168F8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: _isSelectionMode
                  ? Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? const Color(0xFF2168F8) : Colors.grey,
                    )
                  : null,
              title: Text(
                "${student['studentName'] ?? 'Student'} (${student['rollNumber'] ?? '-'})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Parent: ${student['parentName'] ?? '-'}"),
              trailing: student['feeDueDate'] != null
                  ? Text(
                      DateFormat(
                        'dd MMM',
                      ).format((student['feeDueDate'] as Timestamp).toDate()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firebaseService.getStudentStream(
                _firebaseService.currentAdminId ?? '',
                studentId,
              ),
              builder: (context, studentSnapshot) {
                var freshData =
                    studentSnapshot.data?.data() as Map<String, dynamic>? ??
                    student;
                DateTime? lastAlert = freshData['lastManualAlertAt'] != null
                    ? (freshData['lastManualAlertAt'] as Timestamp).toDate()
                    : null;

                String parentStatus = freshData['parentStatus'] ?? 'Standard';
                int cooldownDays = (parentStatus == 'Priority') ? 5 : 7;

                int daysPassed = lastAlert != null
                    ? _firebaseService.secureTime.difference(lastAlert).inDays
                    : 99;
                bool isCurrentlyBlocked =
                    lastAlert != null && daysPassed < cooldownDays;
                int daysLeft = cooldownDays - daysPassed;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: isCurrentlyBlocked
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: parentStatus == 'Priority'
                                  ? Colors.amber[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: parentStatus == 'Priority'
                                    ? Colors.amber[200]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: parentStatus == 'Priority'
                                      ? Colors.amber[800]
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cooldown: $daysLeft days left',
                                  style: TextStyle(
                                    color: parentStatus == 'Priority'
                                        ? Colors.amber[900]
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _isSelectionMode
                                ? null
                                : () => _handleManualReminder(
                                    freshData,
                                    false,
                                    lastAlert,
                                    cooldownDays,
                                    docId: studentId,
                                  ),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Send Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: parentStatus == 'Priority'
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF2168F8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendBatchAlertsBySelection(
    List<QueryDocumentSnapshot> allPossibleDocs,
  ) async {
    int count = 0;
    for (var doc in allPossibleDocs) {
      if (_selectedStudentIds.contains(doc.id)) {
        var data = doc.data() as Map<String, dynamic>;
        String parentStatus = data['parentStatus'] ?? 'Standard';
        int gapDays = (parentStatus == 'Priority') ? 5 : 7;

        DateTime? lastAlert = data['lastManualAlertAt'] != null
            ? (data['lastManualAlertAt'] as Timestamp).toDate()
            : null;

        bool isBlocked =
            lastAlert != null &&
            _firebaseService.secureTime.difference(lastAlert).inDays < gapDays;

        if (!isBlocked) {
          var mutableData = Map<String, dynamic>.from(data);
          mutableData['docId'] = doc.id;

          await _firebaseService.sendReminder(
            studentData: mutableData,
            type: 'Manual',
            studentId: doc.id,
          );
          count++;
        }
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent reminders to $count selected parents.')),
      );
    }
  }

  void _handleManualReminder(
    Map<String, dynamic> student,
    bool isBlocked,
    DateTime? lastAlert,
    int gapDays, {
    String? docId,
  }) async {
    if (isBlocked && lastAlert != null) {
      String timeStr = DateFormat('hh:mm a, dd MMM').format(lastAlert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An alert to parent has already sent on $timeStr'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF9800),
        ),
      );
      return;
    }

    String alertTitle = student['parentStatus'] == 'Priority'
        ? 'Priority Alert'
        : 'Fee Alert';

    await _firebaseService.sendReminder(
      studentData: student,
      type: 'Manual',
      studentId: docId ?? student['docId'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Reminder sent successfully',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _sendBatchAlerts(
    List<QueryDocumentSnapshot> docs,
    String type,
    int gapDays,
  ) async {
    int count = 0;
    final now = _firebaseService.secureTime;

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      String parentStatus = data['parentStatus'] ?? 'Standard';
      int cooldown = (parentStatus == 'Priority') ? 5 : 7;

      DateTime? lastAlert = data['lastManualAlertAt'] != null
          ? (data['lastManualAlertAt'] as Timestamp).toDate()
          : null;

      bool isBlocked =
          lastAlert != null && now.difference(lastAlert).inDays < cooldown;

      if (!isBlocked) {
        var mutableData = Map<String, dynamic>.from(data);
        mutableData['docId'] = doc.id;

        await _firebaseService.sendReminder(
          studentData: mutableData,
          type: type,
          studentId: doc.id,
        );
        count++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch complete! Sent reminders to $count parents.'),
        ),
      );
    }
  }

  Widget _buildReminderHistory(bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getReminderLogsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return _buildEmptyState('No reminder history found.', Icons.history);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            var log = logs[index].data() as Map<String, dynamic>;
            DateTime time = (log['timestamp'] as Timestamp).toDate();
            bool isAuto = log['type'] == 'Auto-System';
            String parentStatus = log['parentStatus'] ?? 'Standard';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAuto ? Colors.blue[50] : Colors.orange[50],
                  child: Icon(
                    isAuto ? Icons.auto_awesome : Icons.person,
                    color: isAuto ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  log['studentName'] ?? 'Student',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${log['type']} • ${DateFormat('hh:mm a, dd MMM').format(time)}",
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: parentStatus == 'Priority'
                            ? Colors.red[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        parentStatus,
                        style: TextStyle(
                          fontSize: 10,
                          color: parentStatus == 'Priority'
                              ? Colors.red
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(msg, style: const TextStyle(color: Colors.grey)),
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
              appBar: AppBar(
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9E38FF), Color(0xFFC078FF)],
                    ),
                  ),
                ),
                title: Text(
                  Translations.get('Reminders & Notifications', isUrdu),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  if (_isSelectionMode)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedStudentIds.clear();
                      }),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.sync, color: Colors.white),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await _firebaseService.syncAllStudentsFeeStatus(
                              user.uid,
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Alerts synchronized successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sync failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Standard'),
                    Tab(text: 'Priority'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildStandardReminders(isUrdu),
                  _buildPriorityAction(isUrdu),
                  _buildReminderHistory(isUrdu),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 3,
                selectedItemColor: const Color(0xFF2168F8),
                onTap: (index) {
                  if (index == 0) {
                    navigateWithLoader(
                      context,
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      ),
                    );
                  }
                  if (index == 1) {
                    navigateWithLoader(
                      context,
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentManagementScreen(),
                        ),
                      ),
                    );
                  }
                  if (index == 2) {
                    navigateWithLoader(
                      context,
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeeManagementScreen(),
                        ),
                      ),
                    );
                  }
                  if (index == 4) {
                    navigateWithLoader(
                      context,
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      ),
                    );
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
}
