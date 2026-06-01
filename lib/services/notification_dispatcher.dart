import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'push_notification_dispatcher.dart';
import 'email_service.dart';
import 'sms_services.dart';

class NotificationDispatcher {
  /// Dispatches multi-channel OCR success alerts to the parent.
  static Future<void> sendOcrSuccessAlert({
    required Map<String, dynamic> parentData,
    required String studentName,
    required String rollNo,
    required String monthYear, // e.g. "05-2026"
  }) async {
    try {
      final String adminId = parentData['adminId'];
      final String studentId = parentData['docId'];
      
      // Parse month string (e.g. "05-2026" to "May 2026")
      String monthNameYear = monthYear;
      try {
        final parts = monthYear.split('-');
        if (parts.length == 2) {
          final int month = int.tryParse(parts[0]) ?? 1;
          const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          monthNameYear = '${monthNames[month - 1]} ${parts[1]}';
        }
      } catch (e) {
        // Fallback to original string if parsing fails
      }

      final String messageTemplate = 
          "The fee voucher of $studentName ($rollNo) for the month of $monthNameYear has been verified and the fee status is set to Paid by the system.";
          
      // 1. In-App Alert (Firestore)
      try {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId)
            .collection('students')
            .doc(studentId)
            .collection('alerts')
            .add({
          'title': 'Payment Verified',
          'message': messageTemplate,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'payment_success',
          'isRead': false,
        });
        debugPrint('✅ In-App Alert written to Firestore');
      } catch (e) {
        debugPrint('❌ In-App Alert failed: $e');
      }

      // 2. Push Notification (FCM)
      try {
        if (parentData['fcmToken'] != null) {
          await PushNotificationDispatcher.sendIndividualNotification(
            token: parentData['fcmToken'],
            title: 'Payment Verified',
            body: messageTemplate,
            type: 'payment_success',
          );
        } else {
          String normalizedTopic = PushNotificationDispatcher.normalizeTopic('parent_$studentId');
          await PushNotificationDispatcher.sendNotificationToTopic(
            topic: normalizedTopic,
            title: 'Payment Verified',
            body: messageTemplate,
          );
        }
      } catch (e) {
        debugPrint('❌ Push Notification failed: $e');
      }

      // 3. Preference-Based External Alert (SMS/Email)
      try {
        final dynamic prefString = parentData['notifications_preference'];
        final dynamic prefMap = parentData['notificationPreferences'];
        
        String preference = 'none';
        if (prefString is String) {
          preference = prefString.toLowerCase();
        } else if (prefMap is Map) {
          if (prefMap['sms'] == true) {
            preference = 'sms';
          } else if (prefMap['email'] == true) preference = 'email';
        }

        if (preference.contains('sms')) {
          final String? phoneNumber = parentData['parentPhone'];
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            final url = 'https://api.textbee.dev/api/v1/gateway/devices/${SmsService.deviceId}/send-sms';
            final response = await http.post(
              Uri.parse(url),
              headers: {'x-api-key': SmsService.apiKey, 'Content-Type': 'application/json'},
              body: jsonEncode({
                'recipients': [phoneNumber],
                'message': messageTemplate,
              }),
            );
            if (response.statusCode == 200 || response.statusCode == 201) {
              debugPrint('✅ SMS Success Alert Sent');
            } else {
              debugPrint('❌ SMS Success Alert Failed: ${response.body}');
            }
          }
        } else if (preference.contains('email')) {
          final String? email = parentData['parentEmail'];
          if (email != null && email.isNotEmpty) {
            final EmailService emailService = EmailService();
            await emailService.sendOcrSuccessEmail(email, messageTemplate);
          }
        }
      } catch (e) {
        debugPrint('❌ External Alert failed: $e');
      }
    } catch (e) {
      debugPrint('🚨 NotificationDispatcher Fatal Error: $e');
    }
  }
}
