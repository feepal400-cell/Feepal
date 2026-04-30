import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(String title, String count, IconData iconData, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 5),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardReminders(bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getStandardNearingDueStudentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final now = DateTime.now();
        final nearingStudents = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['feeDueDate'] == null) return false;
          DateTime dueDate = (data['feeDueDate'] as Timestamp).toDate();
          int daysRemaining = dueDate.difference(now).inDays;
          return daysRemaining >= 0 && daysRemaining <= 3;
        }).toList();

        if (nearingStudents.isEmpty) {
          return _buildEmptyState('No upcoming dues in the next 3 days.', Icons.calendar_today_outlined);
        }

        return Column(
          children: [
            if (nearingStudents.length >= 10)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _sendBatchAlerts(nearingStudents, 'Manual', 5),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E38FF), foregroundColor: Colors.white),
                    child: const Text('Send Alert to All Standard Parents'),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: nearingStudents.length,
                itemBuilder: (context, index) {
                  var student = nearingStudents[index].data() as Map<String, dynamic>;
                  DateTime dueDate = (student['feeDueDate'] as Timestamp).toDate();
                  DateTime? lastAlert = student['lastManualAlertAt'] != null 
                      ? (student['lastManualAlertAt'] as Timestamp).toDate() 
                      : null;
                  
                  bool isBlocked = lastAlert != null && DateTime.now().difference(lastAlert).inDays < 5;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(student['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Due on: ${DateFormat('dd MMM yyyy').format(dueDate)}"),
                          trailing: isBlocked 
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            : const Icon(Icons.warning, color: Colors.amber),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleManualReminder(student, isBlocked, lastAlert, 5),
                              icon: const Icon(Icons.send, size: 16),
                              label: Text(isBlocked ? 'Alerted Recently' : 'Send Reminder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBlocked ? Colors.grey[200] : const Color(0xFF2168F8),
                                foregroundColor: isBlocked ? Colors.grey : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!.docs;

        if (students.isEmpty) {
          return _buildEmptyState('All priority parents are up to date.', Icons.check_circle_outline);
        }

        return Column(
          children: [
            if (students.length >= 10)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _sendBatchAlerts(students, 'Manual', 3),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
                    child: const Text('Send Priority Alert to All'),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var student = students[index].data() as Map<String, dynamic>;
                  DateTime? lastAlert = student['lastManualAlertAt'] != null 
                      ? (student['lastManualAlertAt'] as Timestamp).toDate() 
                      : null;
                  
                  bool isBlocked = lastAlert != null && DateTime.now().difference(lastAlert).inDays < 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(student['parentName'] ?? 'Parent', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Student: ${student['studentName']}"),
                          trailing: isBlocked 
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                                child: const Text('Alert Sent Recently', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              )
                            : null,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleManualReminder(student, isBlocked, lastAlert, 3),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBlocked ? Colors.amber[100] : const Color(0xFFFF9800),
                              foregroundColor: isBlocked ? Colors.amber[900] : Colors.white,
                              elevation: isBlocked ? 0 : 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleManualReminder(Map<String, dynamic> student, bool isBlocked, DateTime? lastAlert, int gapDays) async {
    if (isBlocked && lastAlert != null) {
      String timeStr = DateFormat('hh:mm a, dd MMM').format(lastAlert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An alert to parent has already sent on $timeStr'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF9800),
        )
      );
      return;
    }

    final adminId = _firebaseService.currentAdminId ?? '';
    await _firebaseService.sendReminder(
      studentData: student, 
      type: 'Manual',
      title: 'Fee Alert',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent!')));
  }

  void _sendBatchAlerts(List<QueryDocumentSnapshot> docs, String type, int gapDays) async {
    int count = 0;
    final adminId = _firebaseService.currentAdminId ?? '';
    final now = DateTime.now();

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime? lastAlert = data['lastManualAlertAt'] != null 
          ? (data['lastManualAlertAt'] as Timestamp).toDate() 
          : null;
      
      bool isBlocked = lastAlert != null && now.difference(lastAlert).inDays < gapDays;
      
      if (!isBlocked) {
        await _firebaseService.sendReminder(
          studentData: data, 
          type: type,
          title: 'Batch Fee Alert',
        );
        count++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch complete! Sent reminders to $count parents.'))
      );
    }
  }

  Widget _buildReminderHistory(bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getReminderLogsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isAuto ? Colors.blue[50] : Colors.orange[50],
                child: Icon(isAuto ? Icons.auto_awesome : Icons.person, color: isAuto ? Colors.blue : Colors.orange, size: 20),
              ),
              title: Text(log['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${log['type']} • ${DateFormat('hh:mm a, dd MMM').format(time)}"),
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
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
          child: Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF9E38FF), Color(0xFFC078FF)]),
                ),
              ),
              title: Text(
                Translations.get('Reminders & Notifications', isUrdu),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              automaticallyImplyLeading: false,
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
                if (index == 0) navigateWithLoader(context, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())));
                if (index == 1) navigateWithLoader(context, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen())));
                if (index == 2) navigateWithLoader(context, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen())));
                if (index == 4) navigateWithLoader(context, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSettingsScreen())));
              },
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: Translations.get('Home', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), label: Translations.get('Students', isUrdu)),
                BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), label: Translations.get('Fees', isUrdu)),
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
