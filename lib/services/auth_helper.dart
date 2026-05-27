import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Updates the password for the currently logged-in user.
  /// If the session is too old, it requires re-authentication.
  static Future<String?> updatePassword(String newPassword, {String? currentPassword}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "No user logged in";

      // Try updating password
      await user.updatePassword(newPassword);
      debugPrint("✅ Password updated successfully in Auth");
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint("🚨 Re-authentication required");
        
        if (currentPassword == null) {
          return "requires-recent-login";
        }

        // Attempt re-authentication
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: _auth.currentUser!.email!,
            password: currentPassword,
          );
          
          await _auth.currentUser!.reauthenticateWithCredential(credential);
          
          // Try updating again after re-auth
          await _auth.currentUser!.updatePassword(newPassword);
          debugPrint("✅ Password updated after re-authentication");
          return null;
        } catch (reAuthError) {
          return "Re-authentication failed: ${reAuthError.toString()}";
        }
      }
      return e.message ?? "An error occurred";
    } catch (e) {
      return e.toString();
    }
  }
}
