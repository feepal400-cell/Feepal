import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/foundation.dart';

class PushNotificationDispatcher {
  static const String _projectId = 'feepal-ebd7a';
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  static const List<String> _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  /// Normalizes a class name into a valid FCM topic string.
  /// FCM topics must match: [a-zA-Z0-9-_.~%]+
  static String normalizeTopic(String className) {
    // Replace spaces and special characters with underscores
    String normalized = className
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')
        .replaceAll(RegExp(r'_+'), '_'); // Remove double underscores
    
    return normalized;
  }

  /// Fetches an OAuth2 access token using the service account JSON.
  static Future<String?> _getAccessToken() async {
    try {
      final String response = await rootBundle.loadString('assets/service-account.json');
      final Map<String, dynamic> serviceAccount = json.decode(response);

      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ FCM Dispatcher: Error getting access token: $e');
      return null;
    }
  }

  /// Sends a push notification to a specific class topic.
  static Future<void> sendClassNotification({
    required String classId,
    required String title,
    required String body,
  }) async {
    try {
      final String normalizedClassId = normalizeTopic(classId);
      final String topic = 'class_$normalizedClassId';
      
      debugPrint('🚀 FCM Dispatcher: Sending notification to topic: $topic');

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ FCM Dispatcher: Failed to get access token.');
        return;
      }

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'title': title,
              'body': body,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'class_alert',
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'high_importance_channel',
                'sound': 'default',
              }
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM Dispatcher: Push notification sent successfully to $topic');
      } else {
        debugPrint('❌ FCM Dispatcher: Failed to send notification. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 FCM Dispatcher: Fatal error during dispatch: $e');
    }
  }

  /// Sends a push notification to a specific generic topic.
  static Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🚀 FCM Dispatcher: Sending notification to topic: $topic');

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ FCM Dispatcher: Failed to get access token.');
        return;
      }

      final Map<String, dynamic> dataPayload = {
        'title': title,
        'body': body,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      if (additionalData != null) {
        dataPayload.addAll(additionalData);
      }

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': dataPayload,
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'high_importance_channel',
                'sound': 'default',
              }
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM Dispatcher: Push notification sent successfully to $topic');
      } else {
        debugPrint('❌ FCM Dispatcher: Failed to send notification. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 FCM Dispatcher: Fatal error during topic dispatch: $e');
    }
  }

  /// Sends a push notification to a specific device token.
  /// Returns null on success, 'NotRegistered' if the token is dead, or an error message.
  static Future<String?> sendIndividualNotification({
    required String token,
    required String title,
    required String body,
    String? route,
    String? type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      debugPrint('🚀 FCM Dispatcher: Sending individual notification to token: ${token.substring(0, 10)}...');

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return 'Failed to get access token';
      }

      final Map<String, dynamic> dataPayload = {
        'title': title,
        'body': body,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'type': type ?? 'status_update',
        'route': route ?? 'alerts_screen',
      };

      if (extraData != null) {
        dataPayload.addAll(extraData);
      }

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': dataPayload,
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'high_importance_channel',
                'sound': 'default',
              }
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM Dispatcher: Individual push notification sent successfully');
        return null;
      } else {
        final responseBody = json.decode(response.body);
        final errorCode = responseBody['error']?['status'];
        debugPrint('❌ FCM Dispatcher: Failed. Status: ${response.statusCode}, Error: $errorCode');
        
        if (errorCode == 'UNREGISTERED' || response.statusCode == 404) {
          return 'NotRegistered';
        }
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('🚨 FCM Dispatcher: Fatal error during individual dispatch: $e');
      return e.toString();
    }
  }
}
