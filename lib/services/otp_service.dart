import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'email_service.dart';
import 'firebase_service.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService();
  final FirebaseService _firebaseService = FirebaseService();
  final String _collection = 'otp_verifications';

  /// Generates a 6-digit OTP, saves it to Firestore, and sends it via email.
  Future<bool> generateAndSendOTP(String email) async {
    try {
      // 1. Generate 6-digit random code
      final String otpCode = (Random().nextInt(900000) + 100000).toString();

      // 2. Save to Firestore (Doc ID is email to overwrite older ones)
      await _firestore.collection(_collection).doc(email).set({
        'otp': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Send via EmailService
      return await _emailService.sendVerificationOTP(userEmail: email, otpCode: otpCode);
    } catch (e) {
      debugPrint('❌ OTPService Error (Generate): $e');
      return false;
    }
  }

  /// Verifies the OTP, checks for 10-minute expiry, and deletes on success.
  Future<bool> verifyOTP(String email, String enteredOTP) async {
    try {
      final doc = await _firestore.collection(_collection).doc(email).get();

      if (!doc.exists) {
        debugPrint('❌ OTPService: No OTP record found for $email');
        return false;
      }

      final data = doc.data()!;
      final String storedOTP = data['otp'];
      final Timestamp createdAt = data['createdAt'];

      // 1. Check if OTP matches
      if (storedOTP != enteredOTP) {
        debugPrint('❌ OTPService: OTP mismatch');
        return false;
      }

      // 2. Check for 10-minute expiry
      final DateTime creationTime = createdAt.toDate();
      final DateTime now = _firebaseService.secureTime;
      final difference = now.difference(creationTime).inMinutes;

      if (difference > 10) {
        debugPrint('❌ OTPService: OTP expired ($difference minutes old)');
        // Optional: Clean up expired OTP
        await _firestore.collection(_collection).doc(email).delete();
        return false;
      }

      // 3. Success: Delete OTP doc to prevent reuse
      await _firestore.collection(_collection).doc(email).delete();
      debugPrint('✅ OTPService: Verification successful for $email');
      return true;
    } catch (e) {
      debugPrint('❌ OTPService Error (Verify): $e');
      return false;
    }
  }
}
