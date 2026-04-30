import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'loginscreen.dart';
import 'school_details_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('FeePal Super Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2168F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              _firebaseService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: _selectedIndex == 0 ? _buildPendingSubscriptions() : _buildRegisteredSchools(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF2168F8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Schools'),
        ],
      ),
    );
  }

  Widget _buildPendingSubscriptions() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getPendingSubscriptionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending subscriptions.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var sub = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String subId = snapshot.data!.docs[index].id;
            
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
                        Text(sub['schoolName'] ?? 'Unknown School', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(sub['selectedPlan'] ?? 'N/A', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.person, sub['adminName'] ?? 'Admin'),
                    _buildInfoRow(Icons.email, sub['adminEmail'] ?? 'Email'),
                    const Divider(height: 30),
                    const Text('Payment Proof:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showImageDialog(sub['paymentProofUrl']),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(image: NetworkImage(sub['paymentProofUrl'] ?? ''), fit: BoxFit.cover),
                        ),
                        child: const Center(child: Icon(Icons.zoom_in, color: Colors.white, size: 40)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _approveSubscription(subId, sub['adminId']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Approve Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRegisteredSchools() {
    final currentUid = _firebaseService.currentAdminId;

    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getAllSchoolsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No schools registered yet.'));
        }

        // Temporarily showing ALL documents to debug
        final schools = snapshot.data!.docs;

        if (schools.isEmpty) {
          return const Center(child: Text('No documents found in admins collection.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: schools.length,
          itemBuilder: (context, index) {
            var school = schools[index].data() as Map<String, dynamic>;
            bool isSubscribed = school['subscriptionStatus'] == 'approved';
            String docId = schools[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SchoolDetailsScreen(schoolData: school),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: isSubscribed ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  child: Icon(Icons.school, color: isSubscribed ? Colors.green : Colors.grey),
                ),
                title: Text(school['schoolName'] ?? 'Doc ID: $docId', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(school['adminName'] ?? 'No Admin Name'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        ],
      ),
    );
  }

  void _showImageDialog(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Future<void> _approveSubscription(String subId, String adminId) async {
    try {
      await _firebaseService.approveSubscription(subId, adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription approved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
