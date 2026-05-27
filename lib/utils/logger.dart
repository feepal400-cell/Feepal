import 'package:flutter/foundation.dart';

class FeePalLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final String time = DateTime.now().toString().split(' ').last;
      debugPrint('[$time]${tag != null ? ' [$tag]' : ''} $message');
    }
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) debugPrint('Details: $error');
      if (stackTrace != null) debugPrint('Stacktrace: $stackTrace');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}
