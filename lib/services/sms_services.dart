import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmsService {
  // API Configuration Constants
  static const String apiKey = '8fdc39fc-62df-4fc8-9f6d-3b0ce68a846f';
  static const String deviceId = '6a0598ea9b9db0a6fe81dab8';

  /// Sends an SMS alert when a new fee voucher is created.
  ///
  /// Logic:
  /// - Only proceeds if [parentData]['notifications_preference'] is 'SMS Alerts'.
  /// - Uses TextBee API to deliver the message.
  static Future<void> sendFeeCreatedAlert({
    required Map<String, dynamic> parentData,
    required String studentName,
    required String rollNo,
    required String totalFee,
    required String month,
    required String dueDate,
    required bool isInstallmentAvailable,
  }) async {
    try {
      // 1. Check notification preference (Supports both legacy string and new map format)
      final dynamic prefString = parentData['notifications_preference'];
      final dynamic prefMap = parentData['notificationPreferences'];
      
      bool isSmsEnabled = false;
      if (prefString == 'SMS Alerts') {
        isSmsEnabled = true;
      } else if (prefMap is Map && prefMap['sms'] == true) {
        isSmsEnabled = true;
      }

      if (!isSmsEnabled) {
        debugPrint('ℹ️ SMS alert skipped: SMS not enabled for this parent.');
        return;
      }

      // 2. Resolve recipient phone number
      final String? phoneNumber = parentData['parentPhone'];
      if (phoneNumber == null || phoneNumber.isEmpty) {
        debugPrint(
          'SmsService: Operation failed - No phone number found for $studentName',
        );
        return;
      }

      // 3. Construct message body from template
      String messageText =
          "Fee Alert: The fee of PKR $totalFee for the month of $month of $studentName ($rollNo) has been created by admin. Please pay it before $dueDate to avoid late fee penalty.";

      if (isInstallmentAvailable) {
        messageText +=
            " The Installments are available and can be created through FeePal App or manually by visiting school.";
      }

      // 4. API endpoint configuration
      final String url =
          'https://api.textbee.dev/api/v1/gateway/devices/$deviceId/send-sms';

      // 5. Execute HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipients': [phoneNumber],
          'message': messageText,
        }),
      );

      // 6. Log the outcome
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ SMS Sent Successfully to $phoneNumber');
      } else {
        debugPrint('❌ SMS Failed: (${response.statusCode}) ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ SMS Failed: Critical error during dispatch - $e');
    }
  }

  /// Sends an SMS alert when a fee voucher becomes overdue.
  static Future<void> sendOverdueAlert({
    required Map<String, dynamic> parentData,
    required String studentName,
    required String rollNo,
    required String month,
  }) async {
    try {
      final dynamic prefMap = parentData['notificationPreferences'];
      bool isSmsEnabled = prefMap is Map && prefMap['sms'] == true;

      if (!isSmsEnabled) return;

      final String? phoneNumber = parentData['parentPhone'];
      if (phoneNumber == null || phoneNumber.isEmpty) return;

      String messageText =
          "URGENT: Fee for $studentName ($rollNo) for $month is now OVERDUE. A late fee penalty has been applied. Please clear the outstanding dues immediately to avoid further inconvenience.";

      final String url = 'https://api.textbee.dev/api/v1/gateway/devices/$deviceId/send-sms';

      final response = await http.post(
        Uri.parse(url),
        headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipients': [phoneNumber],
          'message': messageText,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Overdue SMS Sent to $phoneNumber');
      } else {
        debugPrint('❌ Overdue SMS Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Overdue SMS Critical Error: $e');
    }
  }

  /// Sends a manual or automated payment reminder SMS.
  static Future<void> sendReminderSms({
    required Map<String, dynamic> parentData,
    required String studentName,
    required String rollNo,
    required String type,
  }) async {
    try {
      final dynamic prefMap = parentData['notificationPreferences'];
      bool isSmsEnabled = prefMap is Map && prefMap['sms'] == true;

      if (!isSmsEnabled) return;

      final String? phoneNumber = parentData['parentPhone'];
      if (phoneNumber == null || phoneNumber.isEmpty) return;

      String messageText =
          "Fee Reminder: This is a friendly reminder to clear the outstanding dues for $studentName ($rollNo). Please pay before the due date to avoid any further penalties. Thank you - FeePal";

      final String url = 'https://api.textbee.dev/api/v1/gateway/devices/$deviceId/send-sms';

      final response = await http.post(
        Uri.parse(url),
        headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipients': [phoneNumber],
          'message': messageText,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Reminder SMS Sent to $phoneNumber');
      } else {
        debugPrint('❌ Reminder SMS Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Reminder SMS Critical Error: $e');
    }
  }
}
