import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class SuperAdminStudentListScreen extends StatefulWidget {
  final String adminId;
  final String schoolName;

  const SuperAdminStudentListScreen({
    super.key,
    required this.adminId,
    required this.schoolName,
  });

  @override
  State<SuperAdminStudentListScreen> createState() => _SuperAdminStudentListScreenState();
}

class _SuperAdminStudentListScreenState extends State<SuperAdminStudentListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            Text(widget.schoolName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF2168F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(15),
            color: const Color(0xFF2168F8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Name or Roll No...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Students List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getSchoolStudents(widget.adminId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students found in this school.'));
                }

                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['studentName'] ?? '').toString().toLowerCase();
                  final roll = (data['rollNo'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || roll.contains(_searchQuery);
                }).toList();

                if (students.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index].data() as Map<String, dynamic>;
                    String docId = students[index].id;

                    return Dismissible(
                      key: Key(docId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) => _showDeleteConfirmation(docId),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2168F8).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Color(0xFF2168F8)),
                          ),
                          title: Text(student['studentName'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Roll No: ${student['rollNo'] ?? 'N/A'} • Class: ${student['class'] ?? 'N/A'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                            onPressed: () => _showEditDialog(docId, student),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(String studentId) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('This will permanently remove the student record and their fee history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firebaseService.deleteStudentRecord(widget.adminId, studentId);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String studentId, Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['studentName']);
    final rollController = TextEditingController(text: student['rollNo']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
            TextField(controller: rollController, decoration: const InputDecoration(labelText: 'Roll Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _firebaseService.updateStudentDetails(widget.adminId, studentId, {
                'studentName': nameController.text.trim(),
                'rollNo': rollController.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
