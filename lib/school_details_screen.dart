import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/firebase_service.dart';
import 'super_admin_student_list_screen.dart';
import 'super_admin_parent_list_screen.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> schoolData;
  const SchoolDetailsScreen({super.key, required this.schoolData});

  @override
  State<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide filter icon
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firebaseService.getSchoolStats(widget.schoolData['uid']);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2168F8),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.schoolData['schoolName'] ?? 'School Details', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2168F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_tabController.index == 1) ...[
            if (_startDate != null)
              IconButton(
                icon: const Icon(Icons.filter_list_off, color: Colors.white),
                onPressed: _clearFilter,
                tooltip: 'Clear Filter',
              ),
            IconButton(
              icon: const Icon(Icons.date_range, color: Colors.white),
              onPressed: _selectDateRange,
              tooltip: 'Filter by Date',
            ),
          ]
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  void _showEditAdminSheet() {
    final nameController = TextEditingController(text: widget.schoolData['adminName']);
    final emailController = TextEditingController(text: widget.schoolData['email']);
    final phoneController = TextEditingController(text: widget.schoolData['phoneNumber']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Admin Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Admin Name', prefixIcon: Icon(Icons.person))),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await _firebaseService.updateAdminDetails(widget.schoolData['uid'], {
                    'adminName': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin info updated')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2168F8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Update Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _toggleStatus() async {
    // SECURITY GUARD: Prevent disabling Super Admin
    if (widget.schoolData['role'] == 'super_admin' || widget.schoolData['email'] == 'feepal@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Critical Error: Super Admin account cannot be disabled.'), backgroundColor: Colors.red),
      );
      return;
    }

    String currentStatus = widget.schoolData['status'] ?? widget.schoolData['subscriptionStatus'] ?? 'active';
    String newStatus = (currentStatus.toLowerCase() == 'disabled') ? 'active' : 'disabled';
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus == 'active' ? 'Enable' : 'Disable'} Account?'),
        content: Text('Are you sure you want to change the school status to $newStatus? ${newStatus == 'disabled' ? 'The admin will be logged out immediately.' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: newStatus == 'active' ? Colors.green : Colors.red),
            child: Text(newStatus.toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.updateSchoolStatus(widget.schoolData['uid'], newStatus);
      if (mounted) {
        setState(() {
          widget.schoolData['status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('School is now $newStatus')));
      }
    }
  }

  Widget _buildOverviewTab() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Admin Information'),
              IconButton(
                icon: const Icon(Icons.edit_note, color: Color(0xFF2168F8)),
                onPressed: _showEditAdminSheet,
                tooltip: 'Edit Admin Details',
              ),
            ],
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person, 'Admin Name', widget.schoolData['adminName'] ?? 'N/A'),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.email, 'Email', widget.schoolData['email'] ?? 'N/A'),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.phone, 'Phone', widget.schoolData['phoneNumber'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Metrics
          _buildSectionHeader('School Metrics'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Total Students', 
                _stats?['totalStudents']?.toString() ?? '0', 
                Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SuperAdminStudentListScreen(
                    adminId: widget.schoolData['uid'],
                    schoolName: widget.schoolData['schoolName'] ?? 'School',
                  )),
                ),
              ),
              _buildMetricCard(
                'Total Parents', 
                _stats?['totalParents']?.toString() ?? '0', 
                Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SuperAdminParentListScreen(
                    adminId: widget.schoolData['uid'],
                    schoolName: widget.schoolData['schoolName'] ?? 'School',
                  )),
                ),
              ),
              _buildMetricCard('Fees Created', _stats?['totalFeesCount']?.toString() ?? '0', Colors.green),
              _buildMetricCard(
                'Status', 
                widget.schoolData['status']?.toString().toUpperCase() ?? widget.schoolData['subscriptionStatus']?.toString().toUpperCase() ?? 'NONE', 
                Colors.purple,
                onTap: _toggleStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        if (_startDate != null && _endDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFF2168F8).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 16, color: Color(0xFF2168F8)),
                const SizedBox(width: 10),
                Text(
                  'Showing: ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
                ),
                const Spacer(),
                TextButton(onPressed: _clearFilter, child: const Text('Clear')),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getSchoolActivitiesStream(
              widget.schoolData['uid'],
              startDate: _startDate,
              endDate: _endDate,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(_startDate != null ? 'No logs found for this date range.' : 'No activity logs found.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var activity = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  DateTime? ts = (activity['timestamp'] as Timestamp?)?.toDate();
                  String timeStr = ts != null ? DateFormat('MMM d, h:mm a').format(ts) : '--:--';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getIconColor(activity['iconType']).withValues(alpha: 0.1),
                        child: Icon(_getIcon(activity['iconType']), color: _getIconColor(activity['iconType']), size: 20),
                      ),
                      title: Text(activity['title'] ?? 'Activity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity['subtitle'] ?? '', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 5),
                          Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        )
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, {VoidCallback? onTap}) {
    String displayValue = value;
    Color displayColor = color;

    // Helper: Format and Color-Code the Status
    if (label == 'Status') {
      if (value.toUpperCase() == 'DISABLED') {
        displayValue = 'Disabled';
        displayColor = Colors.red;
      } else if (value.toUpperCase() == 'PENDING_SUBSCRIPTION' || value.toUpperCase() == 'PENDING') {
        displayValue = 'Pending';
        displayColor = Colors.orange; 
      } else if (value.toUpperCase() == 'APPROVED' || value.toUpperCase() == 'ACTIVE') {
        displayValue = 'Active';
        displayColor = Colors.green; 
      } else if (value.toUpperCase() == 'NONE') {
        displayValue = 'No Subscription';
        displayColor = Colors.grey;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: displayColor.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: displayColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prevent overflow by automatically scaling down long text
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayValue,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: displayColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 10, color: Colors.grey[400]),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'welcome': return Icons.celebration;
      case 'fee': return Icons.money;
      case 'student': return Icons.person;
      case 'alert': return Icons.notifications;
      default: return Icons.info;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'welcome': return Colors.orange;
      case 'fee': return Colors.green;
      case 'student': return Colors.blue;
      case 'alert': return Colors.red;
      default: return Colors.blueGrey;
    }
  }
}
