import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'language_config.dart';
import 'subscription_screen.dart';

class AdminSubscriptionDetailsScreen extends StatefulWidget {
  const AdminSubscriptionDetailsScreen({super.key});

  @override
  State<AdminSubscriptionDetailsScreen> createState() => _AdminSubscriptionDetailsScreenState();
}

class _AdminSubscriptionDetailsScreenState extends State<AdminSubscriptionDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isUrdu = languageNotifier.value;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Translations.get('Subscription Details', isUrdu),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.getAdminDataStream(_firebaseService.currentAdminId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2168F8)));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return Center(child: Text(Translations.get('No subscription data found.', isUrdu)));
              }
              
              final adminData = snapshot.data!.data() as Map<String, dynamic>;
              return _buildDetails(isUrdu, adminData);
            }
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(bool isUrdu, Map<String, dynamic> adminData) {
    String planType = adminData['planType'] ?? 'Unknown';
    String status = adminData['subscriptionStatus'] ?? 'Unknown';
    
    // Capitalize planType and status
    planType = planType.isNotEmpty ? planType[0].toUpperCase() + planType.substring(1) : planType;
    status = status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : status;

    bool isExpired = _firebaseService.isSubscriptionExpired(adminData);
    int daysRemaining = _firebaseService.getSubscriptionDaysRemaining(adminData);

    Color statusColor = isExpired ? Colors.red : Colors.green;
    if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'pending_subscription') {
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_membership,
                  size: 60,
                  color: Color(0xFF2168F8),
                ),
                const SizedBox(height: 20),
                Text(
                  Translations.get('Current Plan', isUrdu),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  planType,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('Status', isUrdu),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isExpired ? Translations.get('Expired', isUrdu) : status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('Time Remaining', isUrdu),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isExpired 
                          ? Translations.get('0 Days', isUrdu) 
                          : '$daysRemaining ${Translations.get('Days', isUrdu)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isExpired)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Translations.get('Your subscription has expired. Please log out and log back in to renew your plan.', isUrdu),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Translations.get(
                      'Do NOT resubscribe until and unless you are ready to wait for your subscription to be approved, to keep your workflow safe re-subscribe after you are done with your work.',
                      isUrdu),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionScreen(
                      adminData: adminData,
                      isLockedMode: false,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2168F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                Translations.get('Pre-subscribe / Renew Subscription', isUrdu),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
