import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class SuperAdminParentListScreen extends StatefulWidget {
  final String adminId;
  final String schoolName;

  const SuperAdminParentListScreen({
    super.key,
    required this.adminId,
    required this.schoolName,
  });

  @override
  State<SuperAdminParentListScreen> createState() => _SuperAdminParentListScreenState();
}

class _SuperAdminParentListScreenState extends State<SuperAdminParentListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Set<String> _visiblePasswords = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Parent Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            Text(widget.schoolName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF2168F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getSchoolStudents(widget.adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No parents found.'));
          }

          // Extract unique parents by email
          Map<String, Map<String, dynamic>> parentMap = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String? email = data['parentEmail'];
            if (email != null && email.isNotEmpty) {
              if (!parentMap.containsKey(email)) {
                parentMap[email] = {
                  'email': email,
                  'password': data['parentPassword'] ?? 'N/A',
                  'studentDocs': [doc.id],
                  'studentName': data['studentName'] ?? '',
                };
              } else {
                parentMap[email]!['studentDocs'].add(doc.id);
              }
            }
          }

          if (parentMap.isEmpty) {
            return const Center(child: Text('No parent credentials found.'));
          }

          var parents = parentMap.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: parents.length,
            itemBuilder: (context, index) {
              var parent = parents[index];
              String email = parent['email'];
              bool isVisible = _visiblePasswords.contains(email);

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Parent of: ${parent['studentName']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.password, color: Colors.blue.withValues(alpha: 0.7)),
                            onPressed: () => _showResetDialog(email, parent['studentDocs']),
                            tooltip: 'Reset Password',
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      Row(
                        children: [
                          const Icon(Icons.key, size: 16, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Text('Password: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                            isVisible ? parent['password'] : '••••••••',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                if (isVisible) {
                                  _visiblePasswords.remove(email);
                                } else {
                                  _visiblePasswords.add(email);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showResetDialog(String email, List<dynamic> studentDocIds) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for $email'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'New Password', hintText: 'Enter new password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String newPass = passwordController.text.trim();
              if (newPass.isNotEmpty) {
                for (var docId in studentDocIds) {
                  await _firebaseService.updateParentPasswordDirect(widget.adminId, docId, newPass);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
