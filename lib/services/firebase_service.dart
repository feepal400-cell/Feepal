import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_notification_dispatcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_service.dart';
import 'sms_services.dart';

class FirebaseService {
  // Singleton pattern for speed and persistence
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    // Enable offline persistence and unlimited cache for network resilience
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory session for multiple children
  List<Map<String, dynamic>>? currentParentSession;
  int activeStudentIndex = 0;
  
  // High-performance time synchronization
  Duration _serverTimeOffset = Duration.zero;
  bool _isTimeSynced = false;

  /// Fetch and calculate server time offset to eliminate local clock dependencies
  Future<void> initializeTimeSync() async {
    try {
      debugPrint("🕒 [TimeSync] Starting global server time synchronization...");
      DateTime serverTime = await getServerTime();
      _serverTimeOffset = serverTime.difference(DateTime.now());
      _isTimeSynced = true;
      debugPrint("🕒 [TimeSync] Offset calculated: ${_serverTimeOffset.inSeconds}s (Synced: $_isTimeSynced)");
    } catch (e) {
      debugPrint("🚨 [TimeSync] Synchronization failed: $e. Falling back to zero offset.");
    }
  }

  /// Get the current secure time (Server time + offset)
  DateTime get secureTime => DateTime.now().add(_serverTimeOffset);

  Map<String, dynamic>? get selectedStudent {
    if (currentParentSession != null && currentParentSession!.isNotEmpty) {
      return currentParentSession![activeStudentIndex];
    }
    return null;
  }

  static String? _cachedAdminId;
  static void setCachedAdminId(String id) => _cachedAdminId = id;
  String _getAdminId(User? user) => _cachedAdminId ?? user?.uid ?? '';
  String? get currentAdminId => _getAdminId(_auth.currentUser);
  
  /// Get current parent session children
  List<Map<String, dynamic>>? getParentSession() => currentParentSession;

  /// Parent Login
  Future<String?> loginParent({required String email, required String password}) async {
    try {
      debugPrint("🚀 [FirebaseService] Searching for parent: $email");
      
      var emailOrPhone = email.trim();
      var emailOrPhoneLower = emailOrPhone.toLowerCase();

      // 1. Step 1: Authenticate parent (Lookup by Email first, then Phone)
      // Note: This requires the Firestore security rules to allow read access 
      // on collectionGroup('students') for unauthenticated users if anonymous sign-in is disabled.
      // Alternatively, we verify via a server-side logic or a restricted auth user.
      var authSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentEmail', isEqualTo: emailOrPhone)
          .where('parentPassword', isEqualTo: password)
          .limit(1)
          .get();

      if (authSnapshot.docs.isEmpty && emailOrPhone != emailOrPhoneLower) {
        authSnapshot = await _firestore
            .collectionGroup('students')
            .where('parentEmail', isEqualTo: emailOrPhoneLower)
            .where('parentPassword', isEqualTo: password)
            .limit(1)
            .get();
      }

      if (authSnapshot.docs.isEmpty) {
        authSnapshot = await _firestore
            .collectionGroup('students')
            .where('parentPhone', isEqualTo: emailOrPhone)
            .where('parentPassword', isEqualTo: password)
            .limit(1)
            .get();
      }

      if (authSnapshot.docs.isNotEmpty) {
        var authData = authSnapshot.docs.first.data();
        String? pEmail = authData['parentEmail'];
        String? pPhone = authData['parentPhone'];

        List<Filter> filters = [];
        if (pEmail != null && pEmail.trim().isNotEmpty) {
          filters.add(Filter('parentEmail', isEqualTo: pEmail.trim()));
        }
        if (pPhone != null && pPhone.trim().isNotEmpty) {
          filters.add(Filter('parentPhone', isEqualTo: pPhone.trim()));
        }

        if (filters.isEmpty) return 'Invalid parent data';

        // Step 2: Fetch ALL children that share this parent's email or phone
        var emailSiblings = await _firestore
            .collectionGroup('students')
            .where('parentEmail', isEqualTo: pEmail ?? "___NONE___")
            .get();

        var phoneSiblings = await _firestore
            .collectionGroup('students')
            .where('parentPhone', isEqualTo: pPhone ?? "___NONE___")
            .get();
        
        // Merge results locally
        final Map<String, QueryDocumentSnapshot> rawDocs = {};
        for (var doc in emailSiblings.docs) { rawDocs[doc.id] = doc; }
        for (var doc in phoneSiblings.docs) { rawDocs[doc.id] = doc; }

        List<Map<String, dynamic>> allChildren = [];
        
        // Step 3: Environment-Aware Validation (Async N+1 filtering)
        for (var doc in rawDocs.values) {
          var data = doc.data() as Map<String, dynamic>?;
          String? adminId = doc.reference.parent.parent?.id;
          
          if (adminId != null && data != null) {
            // Check student status
            if (data['status'] == 'deleted' || data['status'] == 'inactive') continue;

            // Check Admin/School status
            var adminDoc = await _firestore.collection('admins').doc(adminId).get();
            if (!adminDoc.exists) continue;
            
            var adminData = adminDoc.data() ?? {};
            String schoolStatus = adminData['status'] ?? adminData['accountStatus'] ?? 'active';
            if (schoolStatus == 'disabled' || schoolStatus == 'suspended') continue;

            Map<String, dynamic> mutableData = Map<String, dynamic>.from(data);
            mutableData['adminId'] = adminId;
            mutableData['docId'] = doc.id;
            allChildren.add(mutableData);
          }
        }
        
        if (allChildren.isNotEmpty) {
          debugPrint("✅ Found ${allChildren.length} verified children for this parent.");
          currentParentSession = allChildren;
          activeStudentIndex = 0;
          
          _subscribeToClassTopics(allChildren);
          updateParentFcmToken(emailOrPhone);
          return null;
        }
      }
      
      return 'Invalid email or password';
    } catch (e) {
      debugPrint("❌ Parent Login Error: $e");
      if (e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint("🚨 [Firestore Index Missing] Build it here: https://console.firebase.google.com/project/${FirebaseFirestore.instance.app.options.projectId}/firestore/indexes");
      }
      return e.toString();
    }
  }

  /// Restore Parent Session (For Auto-Login)
  Future<String?> restoreParentSession(String identifier) async {
    try {
      var snapshot = await _firestore
          .collectionGroup('students')
          .where(Filter.or(
            Filter('parentEmail', isEqualTo: identifier),
            Filter('parentPhone', isEqualTo: identifier)
          ))
          .get();

      List<Map<String, dynamic>> allChildren = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String? adminId = doc.reference.parent.parent?.id;
        
        if (adminId != null) {
          // Check student status
          if (data['status'] == 'deleted' || data['status'] == 'inactive') continue;

          // Check Admin status
          var adminDoc = await _firestore.collection('admins').doc(adminId).get();
          if (!adminDoc.exists) continue;
          
          var adminData = adminDoc.data() ?? {};
          String status = adminData['status'] ?? adminData['accountStatus'] ?? 'active';
          if (status == 'disabled' || status == 'suspended') continue;

          data['adminId'] = adminId;
          data['docId'] = doc.id;
          allChildren.add(data);
        }
      }

      if (allChildren.isNotEmpty) {
        currentParentSession = allChildren;
        activeStudentIndex = 0;
        _subscribeToClassTopics(allChildren);
        return null;
      }
      return "No student data found.";
    } catch (e) {
      debugPrint("❌ Restore Parent Session Error: $e");
      if (e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint("🚨 [Firestore Index Missing] Build it here: https://console.firebase.google.com/project/${FirebaseFirestore.instance.app.options.projectId}/firestore/indexes");
      }
      return e.toString();
    }
  }


  /// Helper to subscribe a parent to FCM topics for their children's classes
  Future<void> _subscribeToClassTopics(List<Map<String, dynamic>> children) async {
    try {
      for (var student in children) {
        String? className = student['class'];
        if (className != null && className.isNotEmpty) {
          String normalized = PushNotificationDispatcher.normalizeTopic(className);
          String topic = 'class_$normalized';
          await FirebaseMessaging.instance.subscribeToTopic(topic);
          debugPrint("🔔 [FCM] Subscribed to Topic: $topic");
        }
        
        String? studentDocId = student['docId'];
        if (studentDocId != null) {
          String normalizedParentTopic = PushNotificationDispatcher.normalizeTopic('parent_$studentDocId');
          await FirebaseMessaging.instance.subscribeToTopic(normalizedParentTopic);
          debugPrint("🔔 [FCM] Subscribed to Topic: $normalizedParentTopic");
        }
      }
    } catch (e) {
      debugPrint("❌ [FCM] Subscription Error: $e");
    }
  }

  /// Logout (Both Admin and Parent)
  Future<void> logout() async {
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("❌ Error deleting FCM token (timeout or fail): $e");
    }
    await _auth.signOut();
    currentParentSession = null;
    activeStudentIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("✅ Logged out from Firebase and cleared session.");
  }

  /// Parent Logout
  Future<void> logoutParent() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint("❌ Error deleting FCM token: $e");
    }
    await _auth.signOut();
    currentParentSession = null;
    activeStudentIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("✅ Parent logged out and session reset.");
  }

  /// Signs up an Admin with email and password, and saves details to Firestore.
  /// Signs up an Admin with email and password, logo, and address.
  Future<String?> signUpAdmin({
    required String schoolName,
    required String adminName,
    required String email,
    required String phoneNumber,
    required String password,
    required String schoolAddress,
    Uint8List? logoBytes,
    String? externalLogoUrl,
  }) async {
    User? user;
    try {
      debugPrint("🚀 [FirebaseService] Starting atomic signup for: $email");

      // 1. Pre-signup Constraint Check (Unique Address & Email)
      final emailQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) return 'Email already exists';

      final phoneQuery = await _firestore
          .collection('admins')
          .where('phoneNumber', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        return 'Phone number already registered with another school.';
      }

      final addressQuery = await _firestore
          .collection('admins')
          .where('schoolAddress', isEqualTo: schoolAddress.trim())
          .limit(1)
          .get();
      if (addressQuery.docs.isNotEmpty) {
        return 'A school is already registered with this address.';
      }

      // 2. Create Auth User
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;
      debugPrint("✅ [FirebaseService] Auth user created: ${user?.uid}");

      if (user != null) {
        // 2. Resolve Logo URL
        String logoUrl = externalLogoUrl ?? "";
        
        if (logoUrl.isEmpty && logoBytes != null) {
          try {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('school_logos')
                .child('${user.uid}.jpg');

            await storageRef.putData(logoBytes);
            logoUrl = await storageRef.getDownloadURL();
            debugPrint("✅ [FirebaseService] Logo uploaded to Firebase: $logoUrl");
          } catch (e) {
            debugPrint("❌ [FirebaseService] Firebase Logo upload failed: $e");
            throw Exception("Logo upload failed: $e");
          }
        }

        // 3. Save Firestore document
        await _firestore.collection('admins').doc(_getAdminId(user)).set({
          'uid': user.uid,
          'schoolName': schoolName.trim(),
          'adminName': adminName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'schoolAddress': schoolAddress.trim(),
          'schoolLogoUrl': logoUrl,
          'role': 'admin',
          'password': password, // Workaround: Store password for client-side auth deletion
          'subscriptionStatus': 'none',
          'hasSeenWelcome': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Phase 5: Store Admin Token
        await updateAdminFcmToken(user.uid);

        // Add Welcome Activity
        await createAdminActivity(
          'Welcome to FeePal',
          'Thank you for signing up with FeePal! 😊',
          iconType: 'welcome',
        );

        debugPrint("✅ Admin data saved!");
        return null;
      } else {
        return "User is null after signup.";
      }
    } catch (e) {
      debugPrint("🚨 [FirebaseService] Signup process failed: $e");

      // Rollback: Delete the Auth user if it was created but subsequent steps failed
      if (user != null) {
        try {
          debugPrint("🔄 [FirebaseService] Rolling back: Deleting auth user...");
          await user.delete();
          debugPrint("✅ [FirebaseService] Rollback successful.");
        } catch (rollbackError) {
          debugPrint("⚠️ [FirebaseService] Rollback failed: $rollbackError");
        }
      }

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            return 'Weak password';
          case 'email-already-in-use':
            return 'Email already exists';
          case 'invalid-email':
            return 'Invalid email';
          default:
            return e.message ?? 'Authentication error';
        }
      }
      return e.toString().contains('Exception:') ? e.toString().split('Exception:')[1].trim() : e.toString();
    }
  }

  /// Deletes the currently authenticated unverified admin account.
  /// Used when a user wants to go back from OTP screen to edit details.
  Future<void> deleteCurrentAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String uid = user.uid;
        debugPrint("🔄 [FirebaseService] Deleting unverified account: $uid");
        // 1. Delete Firestore Record
        await _firestore.collection('admins').doc(uid).delete();
        // 2. Delete Auth User
        await user.delete();
        debugPrint("✅ [FirebaseService] Unverified account deleted successfully.");
      }
    } catch (e) {
      debugPrint("❌ [FirebaseService] Error deleting unverified account: $e");
    }
  }

  /// Deletes the admin account completely from subscriptions, admins collection, and Firebase Auth.
  Future<void> deleteAdminAccountComplete({required String adminId, String? password}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated.");

      String targetAdminId = (adminId.isEmpty) ? user.uid : adminId;

      // CRITICAL: Block Super Admin Deletion
      if (user.email == 'superadmin@feepal.com') {
        throw Exception("CRITICAL: The Super Admin account cannot be deleted.");
      }

      debugPrint("🔄 [FirebaseService] Starting complete account deletion for: $targetAdminId");

      // 1. Delete Subscription Records
      var subQuery = await _firestore
          .collection('subscriptions')
          .where('adminId', isEqualTo: targetAdminId)
          .get();
      
      for (var doc in subQuery.docs) {
        await doc.reference.delete();
      }
      debugPrint("✅ [FirebaseService] Subscription records deleted.");

      // 2. Delete Admin Document
      // We might need the password from Firestore if not provided
      String? storedPassword = (password != null && password.isNotEmpty) ? password : null;
      if (storedPassword == null) {
        var adminDoc = await _firestore.collection('admins').doc(targetAdminId).get();
        if (adminDoc.exists) {
          storedPassword = adminDoc.data()?['password'];
        }
      }

      await _firestore.collection('admins').doc(targetAdminId).delete();
      debugPrint("✅ [FirebaseService] Admin document deleted.");

      // 3. Delete Auth User (Handle re-authentication if required)
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login' && storedPassword != null && storedPassword.isNotEmpty && user.email != null) {
          debugPrint("🔄 [FirebaseService] Re-authenticating user for deletion...");
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: storedPassword,
          );
          await user.reauthenticateWithCredential(credential);
          await user.delete();
        } else {
          rethrow;
        }
      }
      
      debugPrint("✅ [FirebaseService] Auth user deleted successfully.");
    } catch (e) {
      debugPrint("❌ [FirebaseService] Complete account deletion error: $e");
      rethrow;
    }
  }

  /// OTP Verification System (Generic)
  Future<bool> sendOTP({
    required String email, 
    required String uid, 
    bool isParent = false,
    String? adminId, // Required if isParent is true
    String? reason, // Optional context for the email
  }) async {
    try {
      // 1. Generate 6-digit OTP
      String otp = (100000 + Random().nextInt(900000)).toString();
      
      // 2. Resolve Path
      DocumentReference otpRef;
      if (isParent && adminId != null) {
        otpRef = _firestore
            .collection('admins')
            .doc(adminId)
            .collection('students')
            .doc(uid)
            .collection('verification')
            .doc('otp_data');
      } else {
        otpRef = _firestore
            .collection('admins')
            .doc(uid)
            .collection('verification')
            .doc('otp_data');
      }

      // 3. Save to Firestore (With 10s Timeout)
      await otpRef.set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': secureTime.add(const Duration(minutes: 10)),
      }).timeout(const Duration(seconds: 10));

      // 4. Send via Email
      final emailService = EmailService();
      return await emailService.sendVerificationOTP(
        userEmail: email, 
        otpCode: otp, 
        reason: reason,
      );
    } catch (e) {
      debugPrint("❌ OTP Send Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String uid, 
    required String code, 
    bool isParent = false,
    String? adminId, 
    bool markAsVerified = false, // Only for signup flow
  }) async {
    try {
      DocumentReference otpRef;
      if (isParent && adminId != null) {
        otpRef = _firestore
            .collection('admins')
            .doc(adminId)
            .collection('students')
            .doc(uid)
            .collection('verification')
            .doc('otp_data');
      } else {
        otpRef = _firestore
            .collection('admins')
            .doc(uid)
            .collection('verification')
            .doc('otp_data');
      }

      var doc = await otpRef.get();
      if (!doc.exists) return {'success': false, 'message': 'OTP not found. Please resend.'};

      var data = doc.data() as Map<String, dynamic>;
      String savedOtp = data['otp'];
      DateTime expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (secureTime.isAfter(expiresAt)) {
        return {'success': false, 'message': 'OTP expired.'};
      }

      if (savedOtp == code) {
        // Mark as verified if requested (Signup flow)
        if (markAsVerified && !isParent) {
          await _firestore.collection('admins').doc(uid).update({
            'isEmailVerified': true,
          });
        }
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Incorrect OTP.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  /// Find existing parent by email (for sibling auto-fill)
  Future<Map<String, dynamic>?> findParentByEmail(String email) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    var emailOrPhone = email.trim();
    var snapshot = await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .where(Filter.or(
          Filter('parentEmail', isEqualTo: emailOrPhone),
          Filter('parentPhone', isEqualTo: emailOrPhone)
        ))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  /// Get Admin Profile
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        var doc = await _firestore.collection('admins').doc(_getAdminId(user)).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching admin: $e");
      return null;
    }
  }

  /// Login
  Future<String?> login({
    required String email, // This can now be email OR phone number
    required String password,
  }) async {
    try {
      String loginEmail = email.trim().toLowerCase();

      // 1. If it's a phone number (doesn't contain '@'), find the associated email
      if (!loginEmail.contains('@')) {
        debugPrint("📱 [Service] Login with Phone detected: $loginEmail");
        var snapshot = await _firestore
            .collection('admins')
            .where('phoneNumber', isEqualTo: email.trim())
            .limit(1)
            .get();
        
        if (snapshot.docs.isEmpty) {
          return 'No admin account found with this phone number.';
        }
        loginEmail = snapshot.docs.first.data()['email'] ?? '';
        if (loginEmail.isEmpty) return 'Account has no email associated.';
      }

      // 2. Standard Firebase Auth sign-in
      await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      debugPrint("✅ Login success");
      
      // Phase 5: Update Admin Token on Login
      User? user = _auth.currentUser;
      if (user != null) {
        var doc = await _firestore.collection('admins').doc(_getAdminId(user)).get();
        
        // 1. Check if the school document exists (Fixes hang for deleted schools)
        if (!doc.exists) {
          await _auth.signOut();
          return 'Account record not found. Please contact support.';
        }

        var data = doc.data() ?? {};
        
        // 2. Role Enforcement: Ensure user is an admin or super_admin
        String role = data['role'] ?? 'admin';
        if (role != 'admin' && role != 'super_admin') {
          await _auth.signOut();
          return 'Wrong credentials for this login type.';
        }

        // 3. Status Check: Allow disabled accounts to proceed to SubscriptionScreen
        if (data['status'] == 'disabled') {
          debugPrint("⚠️ Account is disabled. Allowing auth to route to Resubscription Screen.");
        }
        
        // Everything passed, update the token
        updateAdminFcmToken(user.uid);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' && email.trim().toLowerCase() == 'feepal@gmail.com') {
        debugPrint("🛠️ [Service] Auto-Recovering Super Admin Auth Account...");
        await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
        return null; // Force Success
      }

      switch (e.code) {
        case 'user-not-found':
          return 'User not found';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong credentials';
        default:
          return e.message;
      }
    }
  }

  /// Fetch a stream of students
  Stream<QuerySnapshot> getStudentsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Add / Update Student
  Future<void> addOrUpdateStudent(Map<String, dynamic> studentData, {String? oldDocId}) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    String studentName = studentData['studentName'] ?? 'No Name';
    String rollNo = studentData['rollNumber'] ?? secureTime.millisecondsSinceEpoch.toString();
    String newDocId = "$studentName ($rollNo)";

    // 1. Roll Number Uniqueness Check
    // We check if any OTHER student already has this roll number
    final rollQuery = await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .where('rollNumber', isEqualTo: rollNo)
        .get();

    for (var doc in rollQuery.docs) {
      if (doc.id != oldDocId && doc.id != newDocId) {
        throw Exception("Roll No cannot be same as other student, duplication not allowed");
      }
    }
    
    // 2. Normalize Class Name: Ensure format "Class: X"
    String className = studentData['class']?.toString() ?? 'Unknown';
    String digitsOnly = className.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isNotEmpty) {
      className = 'Class: $digitsOnly';
    } else if (!className.startsWith('Class:')) {
      className = 'Class: $className';
    }

    // 1. Handle Migration if ID changed
    if (oldDocId != null && oldDocId != newDocId) {
      debugPrint("🔄 Migrating student from $oldDocId to $newDocId");
      await _migrateStudentData(user.uid, oldDocId, newDocId);
    }
    
    // Generate password if it's a new student
    String password = studentData['parentPassword'] ?? _generatePassword();

    // Clean up legacy fields from studentData to prevent them from being saved
    studentData.remove('lastFeeAmount');
    studentData.remove('arrearsBalance');
    studentData.remove('feeStatus');
    studentData.remove('oldDues');
    studentData.remove('overrideFee'); // Purged as requested

    await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .doc(newDocId)
        .set({
          'parentStatus': studentData['parentStatus'] ?? 'Standard',
          ...studentData,
          'class': className, // Enforce normalized class name
          'parentPassword': password,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': studentData.containsKey('createdAt') ? studentData['createdAt'] : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Real-time Sibling Syncing
    String? parentEmail = studentData['parentEmail'];
    String? parentPhone = studentData['parentPhone'];
    
    List<Filter> filters = [];
    if (parentEmail != null && parentEmail.trim().isNotEmpty) {
      filters.add(Filter('parentEmail', isEqualTo: parentEmail.trim()));
    }
    if (parentPhone != null && parentPhone.trim().isNotEmpty) {
      filters.add(Filter('parentPhone', isEqualTo: parentPhone.trim()));
    }

    if (filters.isNotEmpty) {
      var siblingsQuery = await _firestore
          .collection('admins')
          .doc(_getAdminId(user))
          .collection('students')
          .where(filters.length > 1 ? Filter.or(filters[0], filters[1]) : filters[0])
          .get();
      
      for (var doc in siblingsQuery.docs) {
        if (doc.id != newDocId) {
          await doc.reference.update({
            'siblingDiscountPercentage': num.tryParse(studentData['siblingDiscountPercentage']?.toString() ?? '0') ?? 0,
            'parentName': studentData['parentName'],
            'parentPhone': studentData['parentPhone'],
            'parentStatus': studentData['parentStatus'],
            'parentPassword': password,
            'notificationPreferences': studentData['notificationPreferences'],
            'notifications_preference': studentData['notifications_preference'],
          });
        }
      }
    }

    // Log activity
    await createAdminActivity(
      studentData.containsKey('createdAt') ? 'Student Updated' : 'New Student Added',
      '${studentData['studentName'] ?? 'A student'} was ${studentData.containsKey('createdAt') ? 'updated' : 'added'} to ${studentData['class']}',
      iconType: 'student',
    );

    // Late Enrollment Auto-Sync (Task 2)
    String currentMonth = DateFormat('MM-yyyy').format(secureTime);
    String nextMonth = DateFormat('MM-yyyy').format(DateTime(secureTime.year, secureTime.month + 1, 1));
    
    try {
      await generateVoucherForStudent(user.uid, newDocId, currentMonth);
    } catch (_) {}
    try {
      await generateVoucherForStudent(user.uid, nextMonth, nextMonth);
    } catch (_) {}
  }

  /// Batch Import (Optimized for Large Sheets)
  Future<void> batchImportStudents(List<Map<String, dynamic>> students) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    var studentsRef = _firestore.collection('admins').doc(_getAdminId(user)).collection('students');
    
    // Split into chunks of 500 (Firestore WriteBatch limit)
    for (var i = 0; i < students.length; i += 500) {
      WriteBatch batch = _firestore.batch();
      var end = (i + 500 < students.length) ? i + 500 : students.length;
      var chunk = students.sublist(i, end);

      for (var student in chunk) {
        String studentName = student['studentName'] ?? 'No Name';
        String rollNo = student['rollNumber'] ?? '';
        if (rollNo.isEmpty) continue;
        String docId = "$studentName ($rollNo)";

        // Normalize Class Name: Ensure format "Class: X"
        String className = student['class']?.toString() ?? 'Unknown';
        String digitsOnly = className.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          className = 'Class: $digitsOnly';
        } else if (!className.startsWith('Class:')) {
          className = 'Class: $className';
        }

        batch.set(studentsRef.doc(docId), {
          ...student,
          'class': className, // Overwrite with normalized class
          'parentPassword': student['parentPassword'] ?? _generatePassword(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint("✅ Batch ${i ~/ 500 + 1} committed successfully.");
    }

    // Log Activity
    await createAdminActivity(
      'Batch Import',
      'Successfully imported ${students.length} students via batch.',
      iconType: 'student',
    );
  }

  /// Get specific student stream
  Stream<DocumentSnapshot> getStudentStream(String adminId, String studentId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .snapshots();
  }

  /// Get class fees stream (Templates)
  Stream<QuerySnapshot> getClassFeesTemplatesStream(String monthYear) {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('monthly_fees')
        .where('monthYear', isEqualTo: monthYear)
        .snapshots();
  }

  /// Get Student Vouchers Stream (Sub-collection)
  Stream<QuerySnapshot> getStudentVouchersStream(String adminId, String studentId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get Notifications Stream
  Stream<QuerySnapshot> getNotificationsStream(String adminId, String studentId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Create Notification
  Future<void> createNotification(String adminId, String studentId, Map<String, dynamic> notificationData) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('notifications')
        .add({
      ...notificationData,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String adminId, String studentId) async {
    var notifications = await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (notifications.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Check and send welcome notification
  Future<void> checkAndSendWelcomeNotification(String adminId, String studentId) async {
    try {
      var snapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(studentId)
          .collection('notifications')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        await createNotification(adminId, studentId, {
          'title': 'Welcome to FeePal',
          'description': 'Welcome to the FeePal family! We are happy to have you here. 😊',
          'isReminder': false,
          'iconType': 'welcome',
        });
      }
    } catch (e) {
      debugPrint("❌ Error checking welcome notification: $e");
    }
  }

  /// Check if fee exists for a class (Simplified)
  Future<bool> checkFeeExists(String className) async {
    return true; // Restriction removed as requested
  }

  /// Get Fees Stream
  Stream<QuerySnapshot> getFeesStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('fees')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Save Monthly Fee Template
  Future<void> saveMonthlyFeeTemplate(Map<String, dynamic> data) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      String templateClass = data['className'];
      String monthYear = data['monthYear'];
      
      String docId = "${templateClass}_$monthYear";
      
      await _firestore
          .collection('admins')
          .doc(_getAdminId(user))
          .collection('monthly_fees')
          .doc(docId)
          .set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Trigger Class-Wide Voucher Generation
      await syncClassVouchers(user.uid, templateClass, monthYear);

      await createAdminActivity(
        'Fee Template Created',
        'Template for $templateClass ($monthYear) was issued and vouchers synced.',
        iconType: 'fee',
      );

      // Task 2: Log to Super Admin
      var adminDoc = await _firestore.collection('admins').doc(_getAdminId(user)).get();
      if (adminDoc.exists) {
        String schoolName = adminDoc.data()?['schoolName'] ?? 'Unknown School';
        await createSuperAdminLog(
          description: 'Created new fee template for $templateClass ($monthYear)',
          actionType: 'CREATE',
          targetSchool: schoolName,
          details: 'Admin ID: ${user.uid}',
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving fee template: $e");
      rethrow;
    }
  }

  /// Sync Class Vouchers (Class-Wide generation)
  Future<void> syncClassVouchers(String adminId, String templateClass, String monthYear) async {
    try {
      // 1. Fetch the template
      String templateId = "${templateClass}_$monthYear";
      var templateDoc = await _firestore.collection('admins').doc(adminId).collection('monthly_fees').doc(templateId).get();
      if (!templateDoc.exists) return;
      var template = templateDoc.data()!;

      // 2. Fetch all students in this class
      // Support variants like "1", "Class 1", "Class: 1"
      String digits = templateClass.replaceAll(RegExp(r'\D'), '');
      List<String> classVariants = [templateClass];
      if (digits.isNotEmpty) {
        classVariants.add(digits);
        classVariants.add("Class $digits");
        classVariants.add("Class: $digits");
      }
      // Remove duplicates
      classVariants = classVariants.toSet().toList();

      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .where('class', whereIn: classVariants)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        debugPrint("ℹ️ No students found in class $templateClass for voucher sync.");
        return;
      }

      WriteBatch batch = _firestore.batch();
      int operationCount = 0;

      // 3. Clear existing vouchers and Generate fresh ones in batches
      for (var studentDoc in studentsSnapshot.docs) {
        var existingVouchers = await studentDoc.reference.collection('vouchers').where('monthYear', isEqualTo: monthYear).get();
        for (var vDoc in existingVouchers.docs) {
          batch.delete(vDoc.reference);
          operationCount++;
          if (operationCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }

        // Add generation operation to batch
        await _generateVoucherFromTemplate(adminId, studentDoc.id, studentDoc.data(), template, monthYear, batch: batch);
        
        // 🔥 Update student feeStatus to Unpaid ONLY if it's not a future voucher
        try {
          DateTime now = secureTime; 
          DateTime voucherDate = DateFormat('MM-yyyy').parse(monthYear);
          DateTime currentMonthStart = DateTime(now.year, now.month, 1);
          
          if (!voucherDate.isAfter(currentMonthStart)) {
            batch.update(studentDoc.reference, {'feeStatus': 'Unpaid'});
          }
        } catch (e) {
          batch.update(studentDoc.reference, {'feeStatus': 'Unpaid'});
        }
        
        operationCount++;
        
        if (operationCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      // 4. Send Notifications (Push & In-App)
      DateTime now = secureTime; 
      DateTime voucherDateForNotif = DateFormat('MM-yyyy').parse(monthYear);
      DateTime currentMonthStartForNotif = DateTime(now.year, now.month, 1);
      bool isFutureVoucher = voucherDateForNotif.isAfter(currentMonthStartForNotif);

      if (!isFutureVoucher) {
        String dueDate = template['dueDate'] ?? 'N/A';
        String notificationTitle = "New Fee Voucher Issued: $monthYear";
        String notificationBody = "A new fee voucher has been issued for $templateClass. Please review and clear the dues by $dueDate to avoid any late fee penalties.";
        
        // Push Notification to Topic
        await PushNotificationDispatcher.sendClassNotification(
          classId: templateClass,
          title: notificationTitle,
          body: notificationBody,
        );

        // In-App Alerts for each student
        for (var studentDoc in studentsSnapshot.docs) {
          var sData = studentDoc.data();
          await createNotification(adminId, studentDoc.id, {
            'title': notificationTitle,
            'description': notificationBody,
            'isReminder': false,
            'iconType': 'fee',
          });

          // 🔥 New: Send Email Alert to Parent
          String? pEmail = sData['parentEmail'];
          var nPrefs = sData['notificationPreferences'] as Map<String, dynamic>?;
          bool emailAlertEnabled = nPrefs != null ? (nPrefs['email'] ?? true) : true;

          if (pEmail != null && pEmail.isNotEmpty && emailAlertEnabled) {
            final emailService = EmailService();
            await emailService.sendFeeAlert(
              parentEmail: pEmail,
              studentName: sData['studentName'] ?? 'Student',
              rollNo: sData['rollNumber']?.toString() ?? '-',
              studentClass: template['className'],
              baseFee: double.tryParse(template['baseFee']?.toString() ?? '0'),
              additionalCharges: double.tryParse(template['additionalCharges']?.toString() ?? '0'),
              latePenaltyFee: double.tryParse(template['latePenalty']?.toString() ?? '0'),
              dueDate: template['dueDate'],
              isInstallmentAvailable: template['isInstallmentAllowed'],
            );
          }
        }
        debugPrint("✅ Vouchers synced and notifications sent for $templateClass ($monthYear)");
      } else {
        debugPrint("✅ Vouchers synced for $templateClass ($monthYear) [Future: Notifications skipped]");
      }
    } catch (e) {
      debugPrint("❌ syncClassVouchers Error: $e");
    }
  }

  /// Delete Monthly Fee Template & Associated Vouchers
  Future<void> deleteMonthlyFeeTemplate(String templateClass, String monthYear) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      String templateId = "${templateClass}_$monthYear";
      
      // 1. Delete the template itself
      await _firestore
          .collection('admins')
          .doc(_getAdminId(user))
          .collection('monthly_fees')
          .doc(templateId)
          .delete();

      // 2. Clear vouchers for all students in this class for this month using batches
      String digits = templateClass.replaceAll(RegExp(r'\D'), '');
      List<String> classVariants = [templateClass];
      if (digits.isNotEmpty) {
        classVariants.add(digits);
        classVariants.add("Class $digits");
        classVariants.add("Class: $digits");
      }
      classVariants = classVariants.toSet().toList();

      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(_getAdminId(user))
          .collection('students')
          .where('class', whereIn: classVariants)
          .get();

      WriteBatch batch = _firestore.batch();
      int operationCount = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        var existingVouchers = await studentDoc.reference.collection('vouchers').where('monthYear', isEqualTo: monthYear).get();
        for (var vDoc in existingVouchers.docs) {
          batch.delete(vDoc.reference);
          operationCount++;
          
          // Firestore batch limit is 500
          if (operationCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      await createAdminActivity(
        'Fee Template Deleted',
        'Template for $templateClass ($monthYear) and associated vouchers were removed.',
        iconType: 'fee',
      );
    } catch (e) {
      debugPrint("❌ Error deleting fee template: $e");
      rethrow;
    }
  }

  /// Internal helper to generate voucher from template data
  Future<void> _generateVoucherFromTemplate(String adminId, String studentDocId, Map<String, dynamic> studentData, Map<String, dynamic> template, String monthYear, {WriteBatch? batch}) async {
    String studentRollNo = studentData['rollNumber']?.toString() ?? '';
    String className = studentData['class'] ?? '';
    
    // Ensure className is in "Class: X" format
    if (className.isNotEmpty) {
      String digits = className.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        className = 'Class: $digits';
      }
    }
    
    double baseFee = double.tryParse(template['baseFee']?.toString() ?? '0') ?? 0.0;
    double additionalCharge = double.tryParse(template['additionalCharges']?.toString() ?? '0') ?? 0.0;
    double latePenalty = double.tryParse(template['latePenalty']?.toString() ?? '0') ?? 0.0;
    bool isInstallmentAllowed = template['isInstallmentAllowed'] ?? false;
    dynamic dueDate = template['dueDate'];
    dynamic dueDateRaw = template['dueDateRaw'];

    String newVoucherId = "${studentRollNo}_$monthYear";

    var docRef = _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentDocId)
        .collection('vouchers')
        .doc(newVoucherId);

    var voucherData = {
      'id': newVoucherId,
      'adminId': adminId,
      'studentRollNo': studentRollNo,
      'studentName': studentData['studentName'] ?? 'Unknown',
      'className': className,
      'monthYear': monthYear,
      'baseFee': baseFee,
      'additionalCharge': additionalCharge,
      'latePenalty': latePenalty,
      'dueDate': dueDate,
      'dueDateRaw': dueDateRaw,
      'status': 'unpaid',
      'isInstallmentAllowed': isInstallmentAllowed,
      'isInstallment': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (batch != null) {
      batch.set(docRef, voucherData, SetOptions(merge: true));
    } else {
      await docRef.set(voucherData, SetOptions(merge: true));
    }

    // 🚀 [SMS Integration] Trigger SMS alert in the background
    try {
      DateTime now = secureTime;
      DateTime vDate = DateFormat('MM-yyyy').parse(monthYear);
      DateTime currentMonthStart = DateTime(now.year, now.month, 1);
      bool isFutureVoucher = vDate.isAfter(currentMonthStart);

      if (!isFutureVoucher) {
        double totalAmount = baseFee + additionalCharge;
        SmsService.sendFeeCreatedAlert(
          parentData: studentData,
          studentName: studentData['studentName'] ?? 'Student',
          rollNo: studentRollNo,
          totalFee: totalAmount.toStringAsFixed(0),
          month: monthYear,
          dueDate: dueDate ?? 'N/A',
          isInstallmentAvailable: isInstallmentAllowed,
        );
      }
    } catch (e) {
      debugPrint("⚠️ SMS trigger failed for $studentDocId: $e");
    }
  }

  /// Generate Voucher for a Specific Student based on Class Template
  Future<void> generateVoucherForStudent(String adminId, String studentId, String monthYear) async {
    // 1. Fetch student data
    var studentDoc = await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).get();
    if (!studentDoc.exists) throw Exception("Student not found.");
    var studentData = studentDoc.data()!;
    String className = studentData['class']?.toString() ?? '';
    // Normalize className to "Class X" format for template lookup
    if (RegExp(r'^\d+$').hasMatch(className.trim())) {
      className = 'Class ${className.trim()}';
    }

    // 2. Fetch Class Template for this month
    String templateId = "${className}_$monthYear";
    var templateDoc = await _firestore.collection('admins').doc(adminId).collection('monthly_fees').doc(templateId).get();
    
    if (!templateDoc.exists) {
      throw Exception("No fee template found for $className in $monthYear. Please create one in Fees tab first.");
    }
    
    await _generateVoucherFromTemplate(adminId, studentId, studentData, templateDoc.data()!, monthYear);
    
    // 🔥 Update student feeStatus to Unpaid ONLY if it's not a future voucher
    try {
      DateTime now = await getServerTime();
      DateTime voucherDate = DateFormat('MM-yyyy').parse(monthYear);
      DateTime currentMonthStart = DateTime(now.year, now.month, 1);
      
      if (!voucherDate.isAfter(currentMonthStart)) {
        await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).update({
          'feeStatus': 'Unpaid',
        });
      }
    } catch (e) {
      // Fallback to updating anyway if time check fails
      await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).update({
        'feeStatus': 'Unpaid',
      });
    }

    await createAdminActivity(
      'Voucher Issued',
      'Voucher issued for ${studentData['studentName']} ($monthYear) based on $className template.',
      iconType: 'fee',
    );
  }

  /// Update Individual Voucher with Audit Logging
  Future<void> updateVoucher(String adminId, String studentId, String voucherId, Map<String, dynamic> updates, String studentName, String rollNo, String month) async {
    var voucherRef = _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .doc(voucherId);

    await voucherRef.update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔥 Sync student feeStatus and lastFeeAmount if voucher is marked as paid
    if (updates['status'] == 'paid') {
      var unpaidVouchers = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(studentId)
          .collection('vouchers')
          .where('status', isEqualTo: 'unpaid')
          .get();
      
      if (unpaidVouchers.docs.isEmpty) {
        await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('students')
            .doc(studentId)
            .update({
          'feeStatus': 'Paid',
          'lastFeeAmount': 0,
        });
      }
    }

    // Audit Logging
    await createAdminActivity(
      'Fee Adjusted',
      'Admin adjusted $month fee for $studentName (Roll No: $rollNo).',
      iconType: 'fee',
    );
  }

  /// Get Unpaid Students Count Stream for Dashboard (Strictly Current Month & Active Templates)
  Stream<int> getUnpaidStudentsCountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);
  
    return _firestore.collectionGroup('vouchers')
        .snapshots()
        .asyncMap((snapshot) async {
          final studentIds = <String>{};
          final String currentMonth = DateFormat('MM-yyyy').format(secureTime);

          // 1. Fetch active students to filter out ghost vouchers from deleted students
          var studentsSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('students').get();
          var validStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toSet();

          // 2. Fetch active templates to ensure we only count valid fees
          var templatesSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('monthly_fees').get();
          var activeClasses = templatesSnapshot.docs
              .where((doc) => doc.id.endsWith("_$currentMonth"))
              .map((doc) => doc.data()['className']?.toString() ?? doc.data()['class']?.toString() ?? '')
              .toSet();

          if (activeClasses.isEmpty || validStudentIds.isEmpty) return 0;
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String? vMonth = data['monthYear'];
            final String? vClass = data['className'];
            final String? vAdminId = data['adminId'];
            
            List<String> pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 4) {
              String studentId = pathParts[3];
              
              if (data['status'] == 'unpaid' && 
                  vMonth == currentMonth && 
                  activeClasses.contains(vClass) && 
                  vAdminId == user.uid &&
                  validStudentIds.contains(studentId)) {
                studentIds.add(studentId);
              }
            }
          }
          debugPrint("📊 [Dashboard] Pending Students Count: ${studentIds.length} | Valid Students in DB: ${validStudentIds.length}");
          if (studentIds.length > validStudentIds.length) {
             debugPrint("⚠️ Warning: Pending count exceeds total students! Investigating...");
          }
          return studentIds.length;
        });
  }

  /// Get Total Pending Amount Stream for Dashboard (Strictly Current Month & Active Templates)
  Stream<double> getTotalPendingAmountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);

    return _firestore.collectionGroup('vouchers')
        .snapshots()
        .asyncMap((snapshot) async {
          double total = 0;
          final String currentMonth = DateFormat('MM-yyyy').format(secureTime);
          final now = secureTime;
          final today = DateTime(now.year, now.month, now.day);

          var studentsSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('students').get();
          var validStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toSet();

          var templatesSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('monthly_fees').get();
          var activeClasses = templatesSnapshot.docs
              .where((doc) => doc.id.endsWith("_$currentMonth"))
              .map((doc) => doc.data()['className']?.toString() ?? doc.data()['class']?.toString() ?? '')
              .toSet();

          if (activeClasses.isEmpty || validStudentIds.isEmpty) return 0.0;

          // Use a map to ensure we only count one voucher per student to prevent "ghost" duplicates
          final studentVoucherMap = <String, double>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String? vMonth = data['monthYear'];
            final String? vClass = data['className'];
            final String? vAdminId = data['adminId'];
            
            List<String> pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 4) {
              String studentId = pathParts[3];

              if (data['status'] == 'unpaid' && 
                  vMonth == currentMonth && 
                  activeClasses.contains(vClass) && 
                  vAdminId == user.uid &&
                  validStudentIds.contains(studentId)) {
                
                double base = (data['baseFee'] ?? 0).toDouble();
                double add = (data['additionalCharge'] ?? 0).toDouble();
                
                bool isOverdue = false;
                if (data['dueDateRaw'] is Timestamp) {
                  DateTime due = (data['dueDateRaw'] as Timestamp).toDate();
                  DateTime dueDay = DateTime(due.year, due.month, due.day);
                  // Penalty applies only AFTER the due date has passed
                  isOverdue = today.isAfter(dueDay);
                }
                
                double pen = isOverdue ? (data['latePenalty'] ?? 0).toDouble() : 0.0;
                double voucherTotal = base + add + pen;
                
                // If student has multiple vouchers (ghosts), take the one with the higher amount or just the first one found
                // Usually there should only be one.
                if (!studentVoucherMap.containsKey(studentId) || voucherTotal > studentVoucherMap[studentId]!) {
                  studentVoucherMap[studentId] = voucherTotal;
                }
              }
            }
          }
          
          total = studentVoucherMap.values.fold(0, (sum, val) => sum + val);
          return total;
        });
  }

  /// Get Fees Collected Sum for the Current Month & Active Templates
  Stream<double> getFeesCollectedStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);

    return _firestore.collectionGroup('vouchers')
        .snapshots()
        .asyncMap((snapshot) async {
          double total = 0;
          final String currentMonth = DateFormat('MM-yyyy').format(secureTime);

          // 1. Fetch active students
          var studentsSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('students').get();
          var validStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toSet();

          // 2. Fetch active templates
          var templatesSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('monthly_fees').get();
          var activeClasses = templatesSnapshot.docs
              .where((doc) => doc.id.endsWith("_$currentMonth"))
              .map((doc) => doc.data()['className']?.toString() ?? doc.data()['class']?.toString() ?? '')
              .toSet();

          if (activeClasses.isEmpty || validStudentIds.isEmpty) return 0.0;

          final studentVoucherMap = <String, double>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String? vMonth = data['monthYear'];
            final String? vClass = data['className'];
            final String? vAdminId = data['adminId'];

            List<String> pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 4) {
              String studentId = pathParts[3];

              if (data['status'] == 'paid' && 
                  vMonth == currentMonth && 
                  activeClasses.contains(vClass) && 
                  vAdminId == user.uid &&
                  validStudentIds.contains(studentId)) {
                
                double base = (data['baseFee'] ?? 0).toDouble();
                double add = (data['additionalCharge'] ?? 0).toDouble();
                double pen = (data['latePenaltyApplied'] ?? data['latePenalty'] ?? 0).toDouble();
                double voucherTotal = base + add + pen;

                if (!studentVoucherMap.containsKey(studentId) || voucherTotal > studentVoucherMap[studentId]!) {
                  studentVoucherMap[studentId] = voucherTotal;
                }
              }
            }
          }
          total = studentVoucherMap.values.fold(0, (sum, val) => sum + val);
          return total;
        });
  }

  /// Get Total Expected Fees Sum (Paid + Unpaid) for the Current Month & Active Templates
  Stream<double> getTotalExpectedFeesStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);

    return _firestore.collectionGroup('vouchers')
        .snapshots()
        .asyncMap((snapshot) async {
          double total = 0;
          final String currentMonth = DateFormat('MM-yyyy').format(secureTime);
          final now = secureTime;
          final today = DateTime(now.year, now.month, now.day);

          // 1. Fetch active students
          var studentsSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('students').get();
          var validStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toSet();

          // 2. Fetch active templates
          var templatesSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('monthly_fees').get();
          var activeClasses = templatesSnapshot.docs
              .where((doc) => doc.id.endsWith("_$currentMonth"))
              .map((doc) => doc.data()['className']?.toString() ?? doc.data()['class']?.toString() ?? '')
              .toSet();

          if (activeClasses.isEmpty || validStudentIds.isEmpty) return 0.0;

          final studentVoucherMap = <String, double>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String? vMonth = data['monthYear'];
            final String? vClass = data['className'];
            final String? vAdminId = data['adminId'];

            List<String> pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 4) {
              String studentId = pathParts[3];

              if (vMonth == currentMonth && 
                  activeClasses.contains(vClass) && 
                  vAdminId == user.uid &&
                  validStudentIds.contains(studentId)) {
                
                double base = (data['baseFee'] ?? 0).toDouble();
                double add = (data['additionalCharge'] ?? 0).toDouble();
                double pen = 0.0;

                if (data['status'] == 'paid') {
                  pen = (data['latePenaltyApplied'] ?? 0).toDouble();
                } else {
                  bool isOverdue = false;
                  if (data['dueDateRaw'] is Timestamp) {
                    DateTime due = (data['dueDateRaw'] as Timestamp).toDate();
                    DateTime dueDay = DateTime(due.year, due.month, due.day);
                    isOverdue = today.isAfter(dueDay);
                  }
                  pen = isOverdue ? (data['latePenalty'] ?? 0).toDouble() : 0.0;
                }
                double voucherTotal = base + add + pen;

                if (!studentVoucherMap.containsKey(studentId) || voucherTotal > studentVoucherMap[studentId]!) {
                  studentVoucherMap[studentId] = voucherTotal;
                }
              }
            }
          }
          total = studentVoucherMap.values.fold(0, (sum, val) => sum + val);
          return total;
        });
  }

  /// Get Overdue Students Count Stream for Dashboard (Strictly Current Month & Active Templates)
  Stream<int> getOverdueStudentsCountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    
    return _firestore.collectionGroup('vouchers')
        .snapshots()
        .asyncMap((snapshot) async {
          final now = secureTime;
          final String currentMonth = DateFormat('MM-yyyy').format(now);
          final today = DateTime(now.year, now.month, now.day);
          final overdueStudentIds = <String>{};

          // 1. Fetch active students
          var studentsSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('students').get();
          var validStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toSet();

          // 2. Fetch active templates
          var templatesSnapshot = await _firestore.collection('admins').doc(_getAdminId(user)).collection('monthly_fees').get();
          var activeClasses = templatesSnapshot.docs
              .where((doc) => doc.id.endsWith("_$currentMonth"))
              .map((doc) => doc.data()['className']?.toString() ?? doc.data()['class']?.toString() ?? '')
              .toSet();

          if (activeClasses.isEmpty || validStudentIds.isEmpty) return 0;
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String? vMonth = data['monthYear'];
            final String? vClass = data['className'];
            final String? vAdminId = data['adminId'];
            
            List<String> pathParts = doc.reference.path.split('/');
            if (pathParts.length >= 4) {
              String studentId = pathParts[3];

              if (data['status'] == 'unpaid' && 
                  vMonth == currentMonth && 
                  activeClasses.contains(vClass) && 
                  vAdminId == user.uid &&
                  validStudentIds.contains(studentId)) {
                
                var dueDateRaw = data['dueDateRaw'];
                if (dueDateRaw is Timestamp) {
                  var due = dueDateRaw.toDate();
                  var dueDay = DateTime(due.year, due.month, due.day);
                  if (today.isAfter(dueDay)) {
                    overdueStudentIds.add(studentId);
                  }
                }
              }
            }
          }
          debugPrint("📊 [Dashboard] Overdue Students Count: ${overdueStudentIds.length} | Filtered from ${snapshot.docs.length} vouchers");
          return overdueStudentIds.length;
        });
  }

  /// Public wrapper for the UI
  String generatePassword() => _generatePassword();

  /// Robust 10-character password generator
  String _generatePassword() {
    const String letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const String lowerLetters = 'abcdefghjklmnpqrstuvwxyz';
    const String numbers = '23456789';
    const String special = '!@#\$%^&*';
    
    final Random random = Random.secure();
    final String allChars = letters + lowerLetters + numbers + special;
    
    // Ensure we have at least one character from each set for complexity
    List<String> password = [
      letters[random.nextInt(letters.length)],
      lowerLetters[random.nextInt(lowerLetters.length)],
      numbers[random.nextInt(numbers.length)],
      special[random.nextInt(special.length)],
    ];

    // Build to 10 characters total
    password += List.generate(6, (index) {
      return allChars[random.nextInt(allChars.length)];
    });

    // Shuffle for true randomness
    password.shuffle(random);
    return password.join();
  }

  /// Delete Student (Recursive Wipe)
  Future<void> deleteStudent(String studentDocId, String studentName, String rollNumber) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // 1. Delete associated vouchers (Sub-collection)
    var vouchers = await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .doc(studentDocId)
        .collection('vouchers')
        .get();
    
    for (var doc in vouchers.docs) {
      await doc.reference.delete();
    }

    // 2. Delete student document
    await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .doc(studentDocId)
        .delete();

    // 3. Log Activity
    await createAdminActivity(
      'Student Removed',
      'Student $studentName (Roll No: $rollNumber) was removed from the system.',
      iconType: 'student',
    );
  }

  /// Bulk Delete Students (Efficient Batching)
  Future<void> bulkDeleteStudents(List<String> studentIds) async {
    User? user = _auth.currentUser;
    if (user == null || studentIds.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int operationCount = 0;

    try {
      for (String studentId in studentIds) {
        // 1. Get vouchers for this student (we need to clear sub-collections)
        var vouchers = await _firestore
            .collection('admins')
            .doc(_getAdminId(user))
            .collection('students')
            .doc(studentId)
            .collection('vouchers')
            .get();

        for (var doc in vouchers.docs) {
          batch.delete(doc.reference);
          operationCount++;
          
          if (operationCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }

        // 2. Queue student document deletion
        batch.delete(_firestore
            .collection('admins')
            .doc(_getAdminId(user))
            .collection('students')
            .doc(studentId));
        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      // 3. Log Activity
      await createAdminActivity(
        'Bulk Students Removed',
        '${studentIds.length} students were removed from the system in a bulk action.',
        iconType: 'student',
      );
    } catch (e) {
      debugPrint("❌ Bulk Deletion error: $e");
      rethrow;
    }
  }



  /// Update Student Installments
  Future<void> updateStudentInstallments(String adminId, String studentId, List<Map<String, dynamic>> installments) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(studentId)
          .update({
        'installments': installments,
        'hasInstallments': installments.isNotEmpty,
      });
    } catch (e) {
      debugPrint("❌ Error updating installments: $e");
      rethrow;
    }
  }


  /// Update Admin Password (Firebase Auth) with optional re-authentication
  Future<void> updateAdminPassword(String newPassword, {String? currentPassword}) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (currentPassword != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, 
          password: currentPassword
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint("✅ Re-authentication successful");
      } catch (e) {
        debugPrint("❌ Re-authentication failed: $e");
        throw Exception("Current password verification failed. Please try again.");
      }
    }

    await user.updatePassword(newPassword);
  }

  /// Update Admin Profile (School Name, Address)
  Future<void> updateAdminProfile({String? schoolName, String? schoolAddress, String? schoolLogoUrl}) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    Map<String, dynamic> updates = {};
    if (schoolName != null) updates['schoolName'] = schoolName;
    if (schoolAddress != null) updates['schoolAddress'] = schoolAddress;
    if (schoolLogoUrl != null) updates['schoolLogoUrl'] = schoolLogoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('admins').doc(uid).update(updates);
    }
  }

  // --- MESSAGING SYSTEM (Admin <-> Super Admin) ---

  /// Simplified Send Message with explicit role handling and push notifications
  Future<void> sendMessage(String roomId, String text) async {
    print("--------------------------------------------------");
    print("💬 [CHAT DEBUG] sendMessage triggered!");

    try {
      final prefs = await SharedPreferences.getInstance();
      String role = prefs.getString('userRole') ?? 'admin';
      String? senderId = _auth.currentUser?.uid ?? prefs.getString('adminId');

      print("💬 [CHAT DEBUG] Role: $role, Sender: $senderId, Room: $roomId");

      if (senderId == null || roomId.isEmpty) {
        print("❌ [CHAT DEBUG] ABORT: Missing senderId or roomId.");
        return;
      }

      bool isSuperAdmin = role == 'super_admin';
      String finalMessage = isSuperAdmin ? "FeePal: $text" : text;

      // 1. Save message to Firestore
      await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .add({
        'text': finalMessage,
        'senderId': senderId,
        'senderRole': role,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ [CHAT DEBUG] Message Saved.");

      // 2. Update room metadata
      Map<String, dynamic> roomUpdate = {
        'lastMessage': finalMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
      };

      if (isSuperAdmin) {
        roomUpdate['unreadCount'] = 0;
        roomUpdate['hasUnread'] = false;
        
        // NEW: Also track unread for the Admin side
        roomUpdate['hasUnreadForAdmin'] = true;
        roomUpdate['unreadCountForAdmin'] = FieldValue.increment(1);
        
        _notifyAdminOfReply(roomId, text);
      } else {
        final profile = await getAdminProfile();
        roomUpdate['hasUnread'] = true;
        roomUpdate['unreadCount'] = FieldValue.increment(1);
        
        // Admin is sending, so clear their own unread flag
        roomUpdate['hasUnreadForAdmin'] = false;
        roomUpdate['unreadCountForAdmin'] = 0;

        roomUpdate['schoolName'] = profile?['schoolName'] ?? 'School';
        roomUpdate['schoolLogo'] = profile?['schoolLogoUrl'] ?? '';
        _notifySuperAdminNewMessage(profile?['schoolName'] ?? 'A school');
      }

      await _firestore.collection('chats').doc(roomId).set(
            roomUpdate,
            SetOptions(merge: true),
          );
      print("✅ [CHAT DEBUG] Metadata Updated.");
      print("--------------------------------------------------");
    } catch (e) {
      print("🛑 [CHAT DEBUG] ERROR: $e");
    }
  }

  /// Send push notification to Admin when Super Admin replies
  Future<void> _notifyAdminOfReply(String adminId, String messageText) async {
    try {
      var adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (adminDoc.exists) {
        String? token = adminDoc.data()?['fcmToken'];
        String schoolName = adminDoc.data()?['schoolName'] ?? 'Admin';
        
        if (token != null && token.isNotEmpty) {
          PushNotificationDispatcher.sendIndividualNotification(
            token: token,
            title: 'Support Reply',
            body: messageText.length > 50 ? '${messageText.substring(0, 47)}...' : messageText,
          ).then((result) {
            if (result == 'NotRegistered') {
              _firestore.collection('admins').doc(adminId).update({'fcmToken': FieldValue.delete()});
            }
          });
          debugPrint("✅ [Chat] Push notification sent to Admin $adminId");
        }
      }
    } catch (e) {
      debugPrint("❌ [Chat] Failed to notify Admin: $e");
    }
  }

  /// Send push notification to Super Admin when an Admin messages
  Future<void> _notifySuperAdminNewMessage(String schoolName) async {
    try {
      // Find Super Admin(s) by role
      var saQuery = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'super_admin')
          .limit(1)
          .get();

      if (saQuery.docs.isNotEmpty) {
        String? saToken = saQuery.docs.first.data()['fcmToken'];
        if (saToken != null && saToken.isNotEmpty) {
          PushNotificationDispatcher.sendIndividualNotification(
            token: saToken,
            title: 'Support Request',
            body: '$schoolName requires help',
          ).then((result) {
            if (result == 'NotRegistered') {
              _firestore.collection('admins').doc(saQuery.docs.first.id).update({'fcmToken': FieldValue.delete()});
            }
          });
          debugPrint("✅ [Chat] Push notification sent to Super Admin for $schoolName");
        }
      }
    } catch (e) {
      debugPrint("❌ [Chat] Failed to notify Super Admin: $e");
    }
  }

  /// Send Auto Welcome Message (for Admin side)
  Future<void> sendAutoWelcomeMessage(String roomId, String adminName) async {
    String welcomeMsg = "FeePal: Hello $adminName, how can we help you? Please send your queries here; we will get back to you as soon as possible.";
    
    // Fixed sender ID for system messages
    String supportId = 'system';

    // Add message
    await _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .add({
      'text': welcomeMsg,
      'senderId': supportId,
      'senderRole': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fetch school data to initialize room properly for Super Admin list
    final profile = await getAdminData(roomId);

    // Initialize room metadata
    await _firestore.collection('chats').doc(roomId).set({
      'lastMessage': welcomeMsg,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'schoolId': roomId,
      'schoolName': profile?['schoolName'] ?? 'School',
      'schoolLogo': profile?['schoolLogoUrl'] ?? '',
      'hasUnread': false,
      'unreadCount': 0,
    }, SetOptions(merge: true));
  }

  /// Get Messages Stream
  Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get Chat Rooms Stream (for Super Admin)
  Stream<QuerySnapshot> getChatRoomsStream() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Mark a chat room as read (for Super Admin)
  /// Mark Chat as read (Role-aware)
  Future<void> markChatAsRead(String roomId, bool isSuperAdmin) async {
    try {
      if (roomId.isEmpty) return;
      
      Map<String, dynamic> updates = {};
      if (isSuperAdmin) {
        updates['hasUnread'] = false;
        updates['unreadCount'] = 0;
      } else {
        updates['hasUnreadForAdmin'] = false;
        updates['unreadCountForAdmin'] = 0;
      }

      await _firestore.collection('chats').doc(roomId).update(updates);
    } catch (e) {
      debugPrint("❌ [FirebaseService] markChatAsRead Error: $e");
    }
  }

  /// Check if there are ANY unread messages for the Super Admin
  Stream<bool> hasAnyUnreadForSuperAdmin() {
    return _firestore
        .collection('chats')
        .where('hasUnread', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Check if there is an unread message for a specific Admin
  Stream<bool> hasUnreadForAdminStream(String adminId) {
    if (adminId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('chats')
        .doc(adminId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          return data?['hasUnreadForAdmin'] == true;
        });
  }

  /// Check user type for password reset
  Future<Map<String, dynamic>?> checkUserType(String emailOrPhone) async {
    try {
      final input = emailOrPhone.trim();
      final inputLower = input.toLowerCase();

      // 1. Check if Admin (Email lookup)
      var adminSnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: inputLower)
          .limit(1)
          .get();
      
      if (adminSnapshot.docs.isNotEmpty) {
        return {
          'role': 'admin',
          'id': adminSnapshot.docs.first.id,
          'name': adminSnapshot.docs.first.data()['adminName'] ?? 'Admin',
        };
      }

      // 2. Check if Parent (Lookup by Email or Phone)
      // First try Email
      var parentSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentEmail', isEqualTo: input) // Search literal first
          .limit(1)
          .get();

      if (parentSnapshot.docs.isEmpty && input != inputLower) {
        parentSnapshot = await _firestore
            .collectionGroup('students')
            .where('parentEmail', isEqualTo: inputLower)
            .limit(1)
            .get();
      }

      // If still empty, try Phone
      if (parentSnapshot.docs.isEmpty) {
        parentSnapshot = await _firestore
            .collectionGroup('students')
            .where('parentPhone', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (parentSnapshot.docs.isNotEmpty) {
        var data = parentSnapshot.docs.first.data();
        return {
          'role': 'parent',
          'id': data['parentEmail'] ?? data['parentPhone'] ?? input,
          'name': data['parentName'] ?? 'Parent',
        };
      }

      return null;
    } catch (e) {
      debugPrint("❌ checkUserType Error: $e");
      return null;
    }
  }

  /// Manual Password Reset (Firestore-based)
  Future<bool> resetPasswordManual(String identifier, String newPassword, String role) async {
    try {
      if (role == 'admin') {
        // Find Admin document by email
        var snapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: identifier.trim().toLowerCase())
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.update({
            'password': newPassword, // Store manual password for reference/login
            'lastPasswordReset': FieldValue.serverTimestamp(),
          });
          return true;
        }
      } else if (role == 'parent') {
        // Update ALL students associated with this parent identifier (email/phone)
        var snapshot = await _firestore
            .collectionGroup('students')
            .where(Filter.or(
              Filter('parentEmail', isEqualTo: identifier),
              Filter('parentPhone', isEqualTo: identifier)
            ))
            .get();

        if (snapshot.docs.isNotEmpty) {
          WriteBatch batch = _firestore.batch();
          
          // Create masked version for "Privacy Matters"
          // Example: MySecret123 -> MySe******
          String masked = newPassword.length > 4 
              ? "${newPassword.substring(0, 4)}****" 
              : "****";

          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {
              'parentPassword': newPassword,
              'parentPasswordMasked': masked, // For privacy-compliant display
            });
          }
          await batch.commit();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ resetPasswordManual Error: $e");
      return false;
    }
  }

  /// Single update (legacy/internal use)
  Future<void> updateParentPassword(String adminId, String studentId, String newPassword) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .update({'parentPassword': newPassword});
  }

  /// Verifies current password for logged in user (Admin or Parent)
  Future<bool> verifyCurrentPassword(String password, String role) async {
    try {
      if (role == 'admin') {
        User? user = _auth.currentUser;
        if (user == null) return false;
        
        var doc = await _firestore.collection('admins').doc(_getAdminId(user)).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          return doc.data()?['password'] == password;
        }
      } else if (role == 'parent') {
        if (currentParentSession != null && currentParentSession!.isNotEmpty) {
          // Check against the first child's record (they all share the same password)
          return currentParentSession![0]['parentPassword'] == password;
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ verifyCurrentPassword Error: $e");
      return false;
    }
  }

  /// Completes the password change flow
  Future<bool> completePasswordChange(String newPassword, String role, [String? currentPassword]) async {
    try {
      if (role == 'admin') {
        User? user = _auth.currentUser;
        if (user == null || currentPassword == null) return false;
        
        // 1. Re-authenticate to prevent requires-recent-login error
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // 2. Update Firebase Auth (Critical for Admin)
        await user.updatePassword(newPassword);
        
        // 3. Update Firestore
        await _firestore.collection('admins').doc(_getAdminId(user)).update({
          'password': newPassword,
          'lastPasswordReset': FieldValue.serverTimestamp(),
        });
        
        // 3. Sign Out
        await logout();
        return true;
      } else if (role == 'parent') {
        if (currentParentSession != null && currentParentSession!.isNotEmpty) {
          String? pEmail = currentParentSession![0]['parentEmail'];
          String? pPhone = currentParentSession![0]['parentPhone'];
          String identifier = (pEmail != null && pEmail.isNotEmpty) ? pEmail : (pPhone ?? "");
          
          if (identifier.isEmpty) return false;

          // Update ALL associated students via resetPasswordManual (handles masking)
          bool success = await resetPasswordManual(identifier, newPassword, 'parent');
          
          if (success) {
            // Sign Out
            await logoutParent();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ completePasswordChange Error: $e");
      rethrow; // Propagate error for UI handling
    }
  }

  /// Create Admin Activity
  Future<void> createAdminActivity(String title, String subtitle, {String iconType = 'info'}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('activities')
        .add({
      'title': title,
      'subtitle': subtitle,
      'timestamp': FieldValue.serverTimestamp(),
      'iconType': iconType,
    });
  }

  /// Get Admin Activity Stream (Limited for Dashboard)
  Stream<QuerySnapshot> getAdminActivityStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  /// Get Paginated Admin Activity
  Future<QuerySnapshot> getAdminActivityPage({DocumentSnapshot? lastDoc, int limit = 20}) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    Query query = _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }



  /// Get reliable server time to prevent phone clock tampering
  Future<DateTime> getServerTime() async {
    try {
      // Fetching from a reliable UTC time API
      final response = await http.get(Uri.parse('https://timeapi.io/api/time/current/zone?timeZone=Etc/UTC'))
          .timeout(const Duration(seconds: 3));
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DateTime utcTime = DateTime.parse(data['dateTime']);
        DateTime localServerTime = utcTime.toLocal(); // Convert to device's local timezone
        _serverTimeOffset = localServerTime.difference(DateTime.now());
        return localServerTime;
      } else {
        throw Exception("Failed to fetch server time: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🚨 Strict Server Time Fetch Failed: $e. Attempting Firestore fallback.");
      
      try {
        // Fallback: Firestore server timestamp ping
        var docRef = _firestore.collection('metadata').doc('time_sync');
        await docRef.set({'timestamp': FieldValue.serverTimestamp()});
        var doc = await docRef.get(const GetOptions(source: Source.server));
        Timestamp? ts = doc.data()?['timestamp'] as Timestamp?;
        if (ts != null) {
           DateTime serverTime = ts.toDate();
           _serverTimeOffset = serverTime.difference(DateTime.now());
           return serverTime;
        }
      } catch (e2) {
         debugPrint("🚨 Firestore time sync also failed: $e2");
      }
      
      // Ultimate silent fallback using cached offset
      return DateTime.now().add(_serverTimeOffset);
    }
  }

  /// Update Voucher Installments
  Future<void> updateVoucherInstallments(String adminId, String studentId, String voucherId, List<Map<String, dynamic>> installments) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .doc(voucherId)
        .update({
      'installments': installments,
    });
  }

  /// Split Voucher Into Installments (Parent Choice)
  Future<void> splitVoucherIntoInstallments(String adminId, String studentId, String voucherId) async {
    var voucherDoc = await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .doc(voucherId)
        .get();
        
    if (!voucherDoc.exists) return;
    var data = voucherDoc.data()!;
    
    double base = (data['baseFee'] ?? 0).toDouble();
    double add = (data['additionalCharge'] ?? 0).toDouble();
    
    // Check if overdue to apply penalty
    bool isOverdue = false;
    if (data['dueDateRaw'] is Timestamp) {
      DateTime due = (data['dueDateRaw'] as Timestamp).toDate();
      DateTime endOfDueDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
      isOverdue = secureTime.isAfter(endOfDueDay);
    }
    
    double pen = isOverdue ? (data['latePenalty'] ?? 0).toDouble() : 0.0;
    
    double halfBase = base / 2;
    double halfAdd = add / 2;
    
    // Installment Split Logic: Half Base + Half Add + (Penalty if overdue)
    double inst1Amount = halfBase + halfAdd + pen;
    double inst2Amount = halfBase + halfAdd;

    // Calculate Second Due Date: 1st Due Date + 8 Days
    String secondDueStr = 'Next Month';
    if (data['dueDateRaw'] is Timestamp) {
      DateTime firstDue = (data['dueDateRaw'] as Timestamp).toDate();
      DateTime secondDue = firstDue.add(const Duration(days: 8));
      secondDueStr = DateFormat('dd/MM/yyyy').format(secondDue);
    } else if (data['dueDate'] != null) {
      try {
        // Try parsing with slashes first
        DateTime firstDue = DateFormat('dd/MM/yyyy').parse(data['dueDate']);
        DateTime secondDue = firstDue.add(const Duration(days: 8));
        secondDueStr = DateFormat('dd/MM/yyyy').format(secondDue);
      } catch (_) {
        try {
          // Fallback to hyphens if already stored that way
          DateTime firstDue = DateFormat('dd-MM-yyyy').parse(data['dueDate']);
          DateTime secondDue = firstDue.add(const Duration(days: 8));
          secondDueStr = DateFormat('dd/MM/yyyy').format(secondDue);
        } catch (_) {}
      }
    }

    List<Map<String, dynamic>> installments = [
      {
        'label': 'Installment 1',
        'amount': inst1Amount.toInt(),
        'status': 'unpaid',
        'dueDate': data['dueDate'],
      },
      {
        'label': 'Installment 2',
        'amount': inst2Amount.toInt(),
        'status': 'unpaid',
        'dueDate': secondDueStr, 
      }
    ];
    
    await updateVoucherInstallments(adminId, studentId, voucherId, installments);
  }

  /// Send Reminder (Manual or Auto)
  Future<void> sendReminder({
    String? adminId,
    required Map<String, dynamic> studentData,
    required String type,
    String? studentId,
  }) async {
    String? finalAdminId = adminId ?? _auth.currentUser?.uid;
    if (finalAdminId == null || finalAdminId.isEmpty) {
      debugPrint("❌ Cannot send reminder: No Admin ID found.");
      return;
    }
    
    String finalTitle = 'Payment Reminder: Outstanding Fees';
    String rollNo = studentData['rollNumber'].toString();
    String studentName = studentData['studentName'] ?? 'Student';
    String parentName = studentData['parentName'] ?? 'Parent';
    String dueDate = studentData['feeDueDate'] ?? 'the due date';

    // 1. Add notification for parent
    String notificationMsg = type == 'Overdue' 
        ? 'URGENT: Dues for $studentName ($rollNo) are now OVERDUE. A late fee penalty has been applied. Please clear immediately.'
        : 'The dues for $studentName ($rollNo) are currently pending. Please ensure payment is cleared by $dueDate to avoid any late fee penalties.';

    String? pEmail = studentData['parentEmail'];
    // Default to true if not set, matching user preference for mandatory email
    var nPrefs = studentData['notificationPreferences'] as Map<String, dynamic>?;
    bool emailAlertEnabled = nPrefs != null ? (nPrefs['email'] ?? true) : true;
    bool smsAlertEnabled = nPrefs != null ? (nPrefs['sms'] ?? false) : false;

    // Use explicit ID if provided, then check data map, fallback to reconstruction
    String finalStudentId = studentId ?? studentData['docId']?.toString() ?? "$studentName ($rollNo)";

    await _firestore
        .collection('admins')
        .doc(finalAdminId)
        .collection('students')
        .doc(finalStudentId)
        .collection('notifications')
        .add({
      'title': type == 'Overdue' ? 'Urgent: Fee Overdue' : finalTitle,
      'description': notificationMsg,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isReminder': true,
      'iconType': type == 'Overdue' ? 'error' : 'alert',
    });

    // 2. Log in reminder_logs for history
    await _firestore
        .collection('admins')
        .doc(finalAdminId)
        .collection('reminder_logs')
        .add({
      'studentName': studentName,
      'parentName': parentName,
      'rollNo': rollNo,
      'type': type,
      'title': type == 'Overdue' ? 'Overdue Alert' : finalTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Update last alert timestamp using the same robust ID logic
    await _firestore
        .collection('admins')
        .doc(finalAdminId)
        .collection('students')
        .doc(finalStudentId)
        .update({
      'lastManualAlertAt': FieldValue.serverTimestamp(),
      if (type == 'Auto-System') 'lastPriorityAlertAt': FieldValue.serverTimestamp(),
      if (type == 'Overdue') 'lastOverdueAlertAt': FieldValue.serverTimestamp(),
    });

    // 4. Log to Admin Activity (Recent Activity)
    await createAdminActivity(
      type == 'Overdue' ? 'Overdue Alert Sent' : (type == 'Manual' ? 'Reminder Sent' : 'Auto-Reminder Sent'),
      'Sent ${type == 'Overdue' ? 'Overdue Notice' : finalTitle} to $parentName for $studentName',
      iconType: type == 'Overdue' ? 'alert' : 'notification',
    );

    // 5. Send real-time FCM notification if token exists
    String? token = studentData['parentFcmToken'];
    if (token != null && token.isNotEmpty) {
      PushNotificationDispatcher.sendIndividualNotification(
        token: token,
        title: type == 'Overdue' ? 'Urgent: Fee Overdue' : finalTitle,
        body: notificationMsg,
      ).then((result) {
        if (result == 'NotRegistered') {
          debugPrint("🧹 Removing dead FCM token for student: $finalStudentId");
          _firestore
              .collection('admins')
              .doc(finalAdminId)
              .collection('students')
              .doc(finalStudentId)
              .update({'parentFcmToken': FieldValue.delete()});
        }
      });
    }

    // 6. Send Email Alert if enabled
    if (pEmail != null && pEmail.isNotEmpty && emailAlertEnabled) {
      try {
        final emailService = EmailService();
        String? studentClass = studentData['class'];
        double? baseFee = double.tryParse(studentData['baseFee']?.toString() ?? '0');
        double? additionalCharges = double.tryParse(studentData['additionalCharges']?.toString() ?? '0');
        double? latePenalty = double.tryParse(studentData['latePenalty']?.toString() ?? '0');

        // Fallback: If fee data is missing (common for manual alerts from students collection),
        // try to fetch from the latest unpaid voucher.
        if ((baseFee == null || baseFee == 0) && (additionalCharges == null || additionalCharges == 0)) {
           var vSnapshot = await _firestore
              .collection('admins')
              .doc(finalAdminId)
              .collection('students')
              .doc(finalStudentId)
              .collection('vouchers')
              .where('status', isEqualTo: 'unpaid')
              .limit(1)
              .get();
           
           if (vSnapshot.docs.isNotEmpty) {
             var vData = vSnapshot.docs.first.data();
             baseFee = double.tryParse(vData['baseFee']?.toString() ?? '0');
             additionalCharges = double.tryParse(vData['additionalCharge']?.toString() ?? '0');
             latePenalty = double.tryParse(vData['latePenalty']?.toString() ?? '0');
             studentClass ??= vData['className'];
           }
        }

        if (type == 'Overdue') {
          await emailService.sendAutomatedReminder(
            parentEmail: pEmail,
            studentName: studentName,
            rollNo: rollNo,
            isOverdue: true,
            studentClass: studentClass,
            baseFee: baseFee,
            additionalCharges: additionalCharges,
            latePenaltyFee: latePenalty,
            dueDate: studentData['feeDueDate'],
            isInstallmentAvailable: studentData['isInstallmentAvailable'],
          );
        } else if (type == 'Auto-System') {
          await emailService.sendAutomatedReminder(
            parentEmail: pEmail,
            studentName: studentName,
            rollNo: rollNo,
            isOverdue: finalTitle.contains('Priority'),
            studentClass: studentClass,
            baseFee: baseFee,
            additionalCharges: additionalCharges,
            latePenaltyFee: latePenalty,
            dueDate: studentData['feeDueDate'],
            isInstallmentAvailable: studentData['isInstallmentAvailable'],
          );
        } else {
          await emailService.sendAutomatedReminder(
            parentEmail: pEmail,
            studentName: studentName,
            rollNo: rollNo,
            isOverdue: false,
            studentClass: studentClass,
            baseFee: baseFee,
            additionalCharges: additionalCharges,
            latePenaltyFee: latePenalty,
            dueDate: studentData['feeDueDate'],
            isInstallmentAvailable: studentData['isInstallmentAvailable'],
          );
        }
      } catch (e) {
        debugPrint("❌ [Email] Reminder email failed: $e");
      }
    }

    // 7. Send SMS Alert if enabled
    if (smsAlertEnabled) {
      try {
        if (type == 'Overdue') {
          await SmsService.sendOverdueAlert(
            parentData: studentData,
            studentName: studentName,
            rollNo: rollNo,
            month: studentData['feeMonth'] ?? 'Current Month',
          );
        } else {
          // Send regular reminder SMS for 'Manual' or 'Auto-System'
          await SmsService.sendReminderSms(
            parentData: studentData,
            studentName: studentName,
            rollNo: rollNo,
            type: type,
          );
        }
      } catch (e) {
        debugPrint("❌ [SMS] Reminder alert failed: $e");
      }
    }
  }

  /// Streams for Alerts Screen
  Stream<QuerySnapshot> getReminderLogsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('reminder_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPriorityUnpaidStudentsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .where('parentStatus', isEqualTo: 'Priority')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots();
  }

  Stream<QuerySnapshot> getStandardUnpaidStudentsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('students')
        .where('parentStatus', isEqualTo: 'Standard')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots();
  }

  /// Check if a fee template already exists for a class and month
  Future<bool> checkIfFeeTemplateExists(String className, String monthYear) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    
    var snapshot = await _firestore
        .collection('admins')
        .doc(_getAdminId(user))
        .collection('monthly_fees')
        .where('className', isEqualTo: className)
        .where('monthYear', isEqualTo: monthYear)
        .get();
        
    return snapshot.docs.isNotEmpty;
  }

  /// Submit Payment Proof for a specific voucher
  Future<void> submitPaymentProof({
    required String adminId,
    required String studentId,
    required String voucherId,
    int? installmentIndex,
    required String proofUrl,
  }) async {
    var voucherRef = _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .doc(voucherId);

    var voucher = await voucherRef.get();
    if (!voucher.exists) throw Exception("Voucher not found.");
    var vData = voucher.data()!;

    List installments = vData['installments'] as List? ?? [];
    bool isStandard = installments.isEmpty;

    if (isStandard) {
      await voucherRef.update({
        'paymentProofUrl': proofUrl,
        'paymentProofSubmittedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Installment Logic
      int targetIndex = installmentIndex ?? installments.indexWhere((inst) => inst['status'] == 'unpaid');
      if (targetIndex != -1 && targetIndex < installments.length) {
        installments[targetIndex]['paymentProofUrl'] = proofUrl;
        installments[targetIndex]['paymentProofSubmittedAt'] = Timestamp.fromDate(secureTime);
        
        await voucherRef.update({
          'installments': installments,
        });
      }
    }
    
    String studentName = vData['studentName'] ?? 'Unknown Student';
    String monthYear = vData['monthYear'] ?? '';

    // Log activity for the admin to see
    await createAdminActivity(
      'Payment Proof Uploaded',
      'Student: $studentName uploaded payment proof for ${isStandard ? 'full' : 'an installment of'} $monthYear voucher.',
      iconType: 'fee',
    );
  }

  /// Admin Manual Voucher Status Override
  Future<void> adminUpdateVoucherStatus({
    required String adminId,
    required String studentId,
    required String voucherId,
    required String newStatus, // 'paid' or 'unpaid'
    int? installmentIndex,
  }) async {
    var voucherRef = _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .collection('vouchers')
        .doc(voucherId);

    var voucher = await voucherRef.get();
    if (!voucher.exists) throw Exception("Voucher not found.");
    var vData = voucher.data()!;

    List installments = List.from(vData['installments'] as List? ?? []);
    bool isStandard = installments.isEmpty;
    String studentName = vData['studentName'] ?? 'Student';
    String monthYear = vData['monthYear'] ?? 'N/A';
    
    // Format Month for notification (e.g., 05-2026 -> May 2026)
    String monthDisplay = monthYear;
    try {
      DateTime dt = DateFormat('MM-yyyy').parse(monthYear);
      monthDisplay = DateFormat('MMMM yyyy').format(dt);
    } catch (_) {}

    if (isStandard) {
      // Standard Voucher Logic
      await voucherRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'manualOverrideBy': adminId,
      });

      // Update overall student status
      await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).update({
        'feeStatus': newStatus == 'paid' ? 'Paid' : 'Unpaid',
        'lastFeeAmount': newStatus == 'paid' ? 0 : (double.tryParse(vData['baseFee']?.toString() ?? '0') ?? 0.0) + (double.tryParse(vData['additionalCharge']?.toString() ?? '0') ?? 0.0),
      });
    } else if (installmentIndex != null) {
      // Complex Installment Logic
      installments[installmentIndex]['status'] = newStatus;
      if (newStatus == 'paid') {
        installments[installmentIndex]['paidAt'] = Timestamp.fromDate(secureTime);
      } else {
        installments[installmentIndex].remove('paidAt');
      }

      bool allPaid = installments.every((inst) => inst['status'] == 'paid');
      
      double remainingAmount = installments
          .where((inst) => inst['status'] == 'unpaid')
          .fold(0.0, (s, inst) => s + (double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0));

      await voucherRef.update({
        'installments': installments,
        'status': allPaid ? 'paid' : 'unpaid',
        'updatedAt': FieldValue.serverTimestamp(),
        'manualOverrideBy': adminId,
      });

      // Update student status and remaining fee balance
      await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).update({
        'feeStatus': allPaid ? 'Paid' : 'Unpaid',
        'lastFeeAmount': remainingAmount,
      });
    }

    String statusText = newStatus == 'paid' ? 'Paid' : 'Unpaid';
    String notificationBody = "$studentName fee for the month of $monthDisplay has been set to $statusText by the admin.";

    // 1. Create In-App Alert for Parent
    await createNotification(adminId, studentId, {
      'title': 'Fee Status Updated',
      'description': notificationBody,
      'isRead': false,
      'isReminder': false,
      'iconType': 'fee',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Create Alert Record for Admin (History)
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('reminder_logs')
        .add({
      'studentName': studentName,
      'rollNo': vData['studentRollNo'] ?? '-',
      'type': 'Status Override',
      'title': 'Fee Status Updated',
      'description': notificationBody,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Trigger Push Notification to Parent
    var studentDoc = await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).get();
    String? parentToken = studentDoc.data()?['parentFcmToken'];
    
    if (parentToken != null && parentToken.isNotEmpty) {
      PushNotificationDispatcher.sendIndividualNotification(
        token: parentToken,
        title: 'Fee Status Updated',
        body: notificationBody,
        route: 'alerts_screen',
      ).then((result) {
        if (result == 'NotRegistered') {
          debugPrint("🧹 Removing dead FCM token for student: $studentId");
          _firestore
              .collection('admins')
              .doc(adminId)
              .collection('students')
              .doc(studentId)
              .update({'parentFcmToken': FieldValue.delete()});
        }
      });
    }

    // Log Activity
    await createAdminActivity(
      'Fee Status Override',
      'Manually set $monthYear fee for $studentName to ${newStatus.toUpperCase()}.',
      iconType: 'fee',
    );
  }

  /// Helper to migrate student data if ID (Name or Roll No) changes
  Future<void> migrateStudentData(String adminId, String oldDocId, String newDocId) async {
    try {
      var oldDocRef = _firestore.collection('admins').doc(adminId).collection('students').doc(oldDocId);
      var newDocRef = _firestore.collection('admins').doc(adminId).collection('students').doc(newDocId);

      var snapshot = await oldDocRef.get();
      if (snapshot.exists) {
        // 1. Copy main document
        await newDocRef.set(snapshot.data()!);

        // 2. Move sub-collections (notifications)
        var notifications = await oldDocRef.collection('notifications').get();
        WriteBatch batch = _firestore.batch();
        for (var doc in notifications.docs) {
          batch.set(newDocRef.collection('notifications').doc(doc.id), doc.data());
          batch.delete(doc.reference);
        }
        await batch.commit();

        // 3. Delete old document
        await oldDocRef.delete();
        debugPrint("✅ Migration from $oldDocId to $newDocId completed.");
      }
    } catch (e) {
      debugPrint("❌ Migration Error: $e");
    }
  }


  /// Update Bank Details in Firestore
  Future<void> updateBankDetails(String bankName, String accountTitle, String accountNumber) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('admins').doc(_getAdminId(user)).update({
        'bankName': bankName,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Error updating bank details: $e");
      rethrow;
    }
  }

  /// Update Notification Settings & Sync with FCM Topic
  Future<void> updateNotificationSettings(bool enabled) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    try {
      // 1. Update Firestore
      await _firestore.collection('admins').doc(_getAdminId(user)).update({
        'isNotificationsEnabled': enabled,
      });

      // 2. Sync with FCM Topic
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic('admin_alerts');
        await FirebaseMessaging.instance.subscribeToTopic('admin_${user.uid}');
        debugPrint("🔔 FCM: Subscribed to Admin Topics");
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('admin_alerts');
        await FirebaseMessaging.instance.unsubscribeFromTopic('admin_${user.uid}');
        debugPrint("🔕 FCM: Unsubscribed from Admin Topics");
      }
    } catch (e) {
      debugPrint("❌ Error updating notification settings: $e");
    }
  }

  /// Get Admin Data
  Future<Map<String, dynamic>?> getAdminData(String uid) async {
    try {
      // Force fresh server-side fetch to prevent stale cache loops
      var doc = await _firestore.collection('admins').doc(uid).get(
        const GetOptions(source: Source.server),
      );
      if (doc.exists && doc.data() != null) {
        var data = doc.data()!;
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get Admin Data Stream
  Stream<DocumentSnapshot> getAdminDataStream(String uid) {
    return _firestore.collection('admins').doc(uid).snapshots();
  }

  /// Submit Subscription Proof
  Future<void> submitSubscriptionProof({
    required String adminId,
    required String plan,
    File? imageFile,
    String? externalProofUrl,
    required String schoolName,
    required String adminName,
    required String adminEmail,
  }) async {
    try {
      // 1. Resolve Proof URL
      String downloadUrl = externalProofUrl ?? "";
      
      if (downloadUrl.isEmpty && imageFile != null) {
        String fileName = 'proofs/$adminId/${secureTime.millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }
      // 2. Create Subscription Document
      await _firestore.collection('subscriptions').add({
        'adminId': adminId,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'schoolName': schoolName,
        'selectedPlan': plan,
        'paymentProofUrl': downloadUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Admin Status
      await _firestore.collection('admins').doc(adminId).update({
        'subscriptionStatus': 'pending_subscription',
      });

      // 4. Notify Super Admin
      var superAdminQuery = await _firestore.collection('admins').where('role', isEqualTo: 'super_admin').limit(1).get();
      if (superAdminQuery.docs.isNotEmpty) {
        String? saToken = superAdminQuery.docs.first.data()['fcmToken'];
        if (saToken != null && saToken.isNotEmpty) {
          PushNotificationDispatcher.sendIndividualNotification(
            token: saToken,
            title: 'Resubscription Request',
            body: '$schoolName is pending resubscription',
            type: 'resubscription_request',
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Subscription submission error: $e");
      rethrow;
    }
  }

  /// Update Welcome Flag
  Future<void> updateWelcomeFlag(String adminId) async {
    await _firestore.collection('admins').doc(adminId).update({
      'hasSeenWelcome': true,
    });
  }

  /// Get Pending Subscriptions (Super Admin)
  Stream<QuerySnapshot> getPendingSubscriptionsStream() {
    return _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
  Future<void> approveSubscription(String subscriptionId, String adminId) async {
    // 0. Fetch subscription and admin data
    var subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
    var adminDoc = await _firestore.collection('admins').doc(adminId).get();
    
    var subData = subDoc.data() ?? {};
    var adminData = adminDoc.data() ?? {};

    String schoolName = adminData['schoolName'] ?? subData['schoolName'] ?? 'Unknown School';
    String adminEmail = adminData['email'] ?? subData['adminEmail'] ?? 'No Email';

    WriteBatch batch = _firestore.batch();

    // 1. Update subscription status
    batch.update(_firestore.collection('subscriptions').doc(subscriptionId), {
      'status': 'approved',
    });

    // 2. Calculate New Expiration Baseline & Extended Days
    DateTime now = secureTime;
    Timestamp? start = adminData['subscriptionStartDate'] as Timestamp?;
    String oldPlan = adminData['planType'] ?? 'monthly';
    int oldExtended = adminData['extendedDays'] ?? 0;
    int oldBase = (oldPlan.toLowerCase() == 'yearly' ? 365 : 30);
    DateTime currentExpiration = start != null ? start.toDate().add(Duration(days: oldBase + oldExtended)) : now;
    
    DateTime baseline = currentExpiration.isAfter(now) ? currentExpiration : now;
    String newPlanStr = subData['selectedPlan']?.toString() ?? 'monthly';
    int addedDays = (newPlanStr.toLowerCase() == 'yearly') ? 365 : 30;
    DateTime targetExpiration = baseline.add(Duration(days: addedDays));
    
    Timestamp newStart = start ?? Timestamp.fromDate(now);
    int newBase = (newPlanStr.toLowerCase() == 'yearly') ? 365 : 30;
    int newExtendedDays = targetExpiration.difference(newStart.toDate()).inDays - newBase;

    // 3. Update admin document
    batch.update(_firestore.collection('admins').doc(adminId), {
      'subscriptionStatus': 'active',
      'status': 'active',
      'accountStatus': 'active',
      'planType': newPlanStr,
      'subscriptionStartDate': newStart,
      'extendedDays': newExtendedDays,
      'hasSeenWelcome': false,
    });

    await batch.commit();

    // 4. Log Activity
    await createSuperAdminLog(
      actionType: 'SUBSCRIPTION_APPROVED',
      description: 'Super Admin approved subscription for $schoolName.',
      targetSchool: schoolName,
      details: 'Admin ID: $adminId\nEmail: $adminEmail',
    );

    // 5. Notify Admin (FCM/In-app)
    String alertMsg = 'Your $newPlanStr has been approved for $addedDays days more by FeePal.';
    notifyAdminStatus(adminId, 'Subscription Approved', alertMsg);
    await createAdminActivity('Subscription Approved', alertMsg, iconType: 'info');
    
    // 6. Send Email Alert to Admin
    if (adminEmail != 'No Email') {
      final emailService = EmailService();
      await emailService.sendSubscriptionApproved(adminEmail, schoolName);
    }
  }

  Future<void> rejectSubscription(String subscriptionId, String adminId, {String? rejectionReason}) async {
    // 0. Fetch subscription and admin data
    var subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
    var adminDoc = await _firestore.collection('admins').doc(adminId).get();
    
    var subData = subDoc.data() ?? {};
    var adminData = adminDoc.data() ?? {};

    String schoolName = adminData['schoolName'] ?? subData['schoolName'] ?? 'Unknown School';
    String adminEmail = adminData['email'] ?? subData['adminEmail'] ?? 'No Email';

    WriteBatch batch = _firestore.batch();

    // 1. Update subscription status
    batch.update(_firestore.collection('subscriptions').doc(subscriptionId), {
      'status': 'rejected',
      'rejectionReason': rejectionReason,
    });

    // 2. Update admin document
    batch.update(_firestore.collection('admins').doc(adminId), {
      'subscriptionStatus': 'rejected',
      'rejectionReason': rejectionReason,
    });

    await batch.commit();

    // 3. Log Activity
    await createSuperAdminLog(
      actionType: 'SUBSCRIPTION_DENIED',
      description: 'Super Admin denied subscription for $schoolName.',
      targetSchool: schoolName,
      details: 'Reason: ${rejectionReason ?? "No reason specified"}',
    );

    // 4. Notify Admin (FCM/In-app)
    String planName = subData['selectedPlan'] ?? 'monthly';
    int addedDays = (planName.toLowerCase() == 'yearly') ? 365 : 30;
    String alertMsg = 'Your $planName has been rejected for $addedDays days more by FeePal. Reason: ${rejectionReason ?? "Please check email."}';
    
    notifyAdminStatus(adminId, 'Subscription Rejected', alertMsg);
    await createAdminActivity('Subscription Rejected', alertMsg, iconType: 'warning');

    // 5. Send Email Alert to Admin
    if (adminEmail != 'No Email') {
      final emailService = EmailService();
      await emailService.sendSubscriptionDenied(adminEmail, schoolName, rejectionReason: rejectionReason);
    }
  }

  /// Helper to notify admin about status changes
  Future<void> notifyAdminStatus(String adminId, String title, String body) async {
    try {
      var adminDoc = await _firestore.collection('admins').doc(adminId).get();
      String? token = adminDoc.data()?['fcmToken'];
      
      if (token != null && token.isNotEmpty) {
        PushNotificationDispatcher.sendIndividualNotification(
          token: token,
          title: title,
          body: body,
        ).then((result) {
          if (result == 'NotRegistered') {
            _firestore.collection('admins').doc(adminId).update({'fcmToken': FieldValue.delete()});
          }
        });
      } else {
        debugPrint("⚠️ [FCM] No token found for admin $adminId");
      }
    } catch (e) {
      debugPrint("❌ [FCM] Status Notification Error: $e");
    }
  }

  /// Update Admin FCM Token in Firestore
  Future<void> updateAdminFcmToken(String adminId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('admins').doc(adminId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ [FCM] Admin Token Updated for $adminId");
      }
    } catch (e) {
      debugPrint("❌ [FCM] Admin Token Update Error: $e");
    }
  }

  /// Update Parent FCM Token in Firestore for all their children
  Future<void> updateParentFcmToken(String identifier) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      var snapshot = await _firestore
          .collectionGroup('students')
          .where(Filter.or(
            Filter('parentEmail', isEqualTo: identifier),
            Filter('parentPhone', isEqualTo: identifier)
          ))
          .get();

      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {
            'parentFcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        debugPrint("✅ [FCM] Parent Token Updated for all children of $identifier");
      }
    } catch (e) {
      debugPrint("❌ [FCM] Parent Token Update Error: $e");
    }
  }

  // --- SUPER ADMIN CRUD & MANAGEMENT ---

  /// Recursive Delete School and all associated data
  Future<void> recursiveDeleteSchool(String adminId) async {
    try {
      WriteBatch batch = _firestore.batch();
      int opCount = 0;

      // 1. Get all students and their sub-collections
      var students = await _firestore.collection('admins').doc(adminId).collection('students').get();
      for (var student in students.docs) {
        // Delete notifications sub-collection
        var notifications = await student.reference.collection('notifications').get();
        for (var note in notifications.docs) {
          batch.delete(note.reference);
          opCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }
        
        // Delete vouchers sub-collection
        var vouchers = await student.reference.collection('vouchers').get();
        for (var v in vouchers.docs) {
          batch.delete(v.reference);
          opCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }

        // Delete student document
        batch.delete(student.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 2. Delete fees
      var fees = await _firestore.collection('admins').doc(adminId).collection('fees').get();
      for (var fee in fees.docs) {
        batch.delete(fee.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 3. Delete monthlyFees
      var monthlyFees = await _firestore.collection('admins').doc(adminId).collection('monthlyFees').get();
      for (var mFee in monthlyFees.docs) {
        batch.delete(mFee.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 4. Delete activities
      var activities = await _firestore.collection('admins').doc(adminId).collection('activities').get();
      for (var act in activities.docs) {
        batch.delete(act.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 5. Delete reminder logs
      var reminderLogs = await _firestore.collection('admins').doc(adminId).collection('reminder_logs').get();
      for (var log in reminderLogs.docs) {
        batch.delete(log.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 6. Delete subscriptions if any
      var subscriptions = await _firestore.collection('subscriptions').where('adminId', isEqualTo: adminId).get();
      for (var sub in subscriptions.docs) {
        batch.delete(sub.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 7. Delete student_vouchers (Flat Collection)
      var vSnapshot = await _firestore.collection('student_vouchers').where('adminId', isEqualTo: adminId).get();
      for (var voucher in vSnapshot.docs) {
        batch.delete(voucher.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 8. Delete school document
      batch.delete(_firestore.collection('admins').doc(adminId));
      opCount++;
      
      // Final commit
      if (opCount > 0) {
        await batch.commit();
      }

      debugPrint("🗑️ [SuperAdmin] Full recursive chunked wipe completed for $adminId");

      // Log the deletion
      await createSuperAdminLog(
        actionType: 'DELETE',
        description: 'Super Admin deleted school and all associated data.',
        targetSchool: adminId, // We use ID because the doc is gone
      );
    } catch (e) {
      debugPrint("❌ [SuperAdmin] Recursive Delete Error: $e");
      rethrow;
    }
  }

  /// Update Admin Details
  Future<void> updateAdminDetails(String adminId, Map<String, dynamic> updates) async {
    // Fetch old data for logging
    var oldDoc = await _firestore.collection('admins').doc(adminId).get();
    var oldData = oldDoc.data() ?? {};
    String schoolName = oldData['schoolName'] ?? 'Unknown School';

    await _firestore.collection('admins').doc(adminId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log the changes
    List<String> changeDetails = [];
    if (updates.containsKey('email') && updates['email'] != oldData['email']) {
      changeDetails.add('Email updated: ${oldData['email']} -> ${updates['email']}');
    }
    if (updates.containsKey('phoneNumber') && updates['phoneNumber'] != oldData['phoneNumber']) {
      changeDetails.add('Phone updated: ${oldData['phoneNumber']} -> ${updates['phoneNumber']}');
    }
    if (updates.containsKey('schoolName') && updates['schoolName'] != oldData['schoolName']) {
      changeDetails.add('School Name updated: ${oldData['schoolName']} -> ${updates['schoolName']}');
    }
    if (updates.containsKey('adminName') && updates['adminName'] != oldData['adminName']) {
      changeDetails.add('Admin Name updated: ${oldData['adminName']} -> ${updates['adminName']}');
    }

    if (changeDetails.isNotEmpty) {
      await createSuperAdminLog(
        actionType: 'UPDATE',
        description: 'Super Admin updated $schoolName details.',
        targetSchool: schoolName,
        details: changeDetails.join("\n"),
      );
    }
  }

  /// Update Admin Password in Firestore (to sync with Auth)
  Future<void> updateAdminPasswordInFirestore(String uid, String newPassword) async {
    await _firestore.collection('admins').doc(uid).update({
      'password': newPassword,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle School Status (Active/Disabled)
  Future<void> updateSchoolStatus(String adminId, String newStatus) async {
    var adminDoc = await _firestore.collection('admins').doc(adminId).get();
    String schoolName = adminDoc.data()?['schoolName'] ?? 'Unknown School';

    await _firestore.collection('admins').doc(adminId).update({
      'status': newStatus,
      'accountStatus': newStatus, // Sync both for legacy and new listeners
      'subscriptionStatus': newStatus == 'disabled' ? 'suspended' : 'approved',
    });

    if (newStatus == 'disabled') {
      notifyAdminStatus(adminId, 'Account Disabled', 'Your school account has been disabled by FeePal. Please contact support.');
    } else {
      notifyAdminStatus(adminId, 'Account Activated', 'Your school account has been reactivated. Welcome back!');
    }

    // Log the status change
    await createSuperAdminLog(
      actionType: 'STATUS_CHANGE',
      description: 'Super Admin changed $schoolName status to $newStatus.',
      targetSchool: schoolName,
      details: 'New Status: $newStatus',
    );
  }

  /// Fetch all students for a specific school (Super Admin view)
  Stream<QuerySnapshot> getSchoolStudents(String adminId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .orderBy('studentName')
        .snapshots();
  }

  /// Remove All Fees and Vouchers for a School (Super Admin Tool)
  Future<void> removeAllFeesForSchool(String schoolId) async {
    try {
      WriteBatch batch = _firestore.batch();
      int opCount = 0;

      // 1. Delete all monthly fees
      var monthlyFees = await _firestore
          .collection('admins')
          .doc(schoolId)
          .collection('monthly_fees')
          .get();
      
      for (var doc in monthlyFees.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 3. Delete all flat student_vouchers
      var flatVouchers = await _firestore
          .collection('student_vouchers')
          .where('adminId', isEqualTo: schoolId)
          .get();

      for (var doc in flatVouchers.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 4. Delete all sub-collection vouchers for all students
      var students = await _firestore
          .collection('admins')
          .doc(schoolId)
          .collection('students')
          .get();

      for (var student in students.docs) {
        var vouchers = await student.reference.collection('vouchers').get();
        for (var vDoc in vouchers.docs) {
          batch.delete(vDoc.reference);
          opCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }
        // Reset student feeStatus
        batch.update(student.reference, {'feeStatus': 'Paid'});
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      if (opCount > 0) {
        await batch.commit();
      }
      debugPrint("✅ [SuperAdmin] Fee scrubbing completed for $schoolId");
    } catch (e) {
      debugPrint("❌ removeAllFeesForSchool Error: $e");
      rethrow;
    }
  }

  /// Remove All Students for a School (Super Admin Tool)
  Future<void> removeAllStudentsForSchool(String schoolId) async {
    try {
      WriteBatch batch = _firestore.batch();
      int opCount = 0;

      // 1. Delete all student documents and their sub-collections
      var students = await _firestore
          .collection('admins')
          .doc(schoolId)
          .collection('students')
          .get();

      for (var student in students.docs) {
        // Delete notifications sub-collection
        var notifications = await student.reference.collection('notifications').get();
        for (var note in notifications.docs) {
          batch.delete(note.reference);
          opCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }
        
        // Delete vouchers sub-collection
        var vouchers = await student.reference.collection('vouchers').get();
        for (var v in vouchers.docs) {
          batch.delete(v.reference);
          opCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }

        // Delete student document
        batch.delete(student.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      // 2. Delete all flat student_vouchers
      var flatVouchers = await _firestore
          .collection('student_vouchers')
          .where('adminId', isEqualTo: schoolId)
          .get();

      for (var doc in flatVouchers.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
      }

      if (opCount > 0) {
        await batch.commit();
      }
      debugPrint("✅ [SuperAdmin] Student scrubbing completed for $schoolId");
    } catch (e) {
      debugPrint("❌ removeAllStudentsForSchool Error: $e");
      rethrow;
    }
  }

  /// Update Parent Password Directly
  Future<void> updateParentPasswordDirect(String adminId, String studentId, String newPassword) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .update({'parentPassword': newPassword});
  }

  /// Delete Student Record (Super Admin)
  Future<void> deleteStudentRecord(String adminId, String studentId) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  /// Update Student Details (Super Admin)
  Future<void> updateStudentDetails(String adminId, String studentId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .update(updates);
  }

  /// Real-time Status Listener for Admins
  StreamSubscription<DocumentSnapshot>? listenToAdminStatus(String adminId, Function(Map<String, dynamic> data) onDataChange) {
    return _firestore.collection('admins').doc(adminId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() ?? {};
        data['docId'] = snapshot.id; // Ensure docId is present
        onDataChange(data);
      }
    });
  }

  /// Get All Schools (Super Admin)
  Stream<QuerySnapshot> getAllSchoolsStream() {
    // Show everyone except super admins. Since most legacy admins have null role, 
    // we fetch all and filter in the UI or use a simpler query.
    return _firestore.collection('admins').snapshots();
  }

  /// Ensure a specific user is marked as Super Admin (Self-Healing logic)
  Future<void> ensureSuperAdminDocument(String uid, String email) async {
    if (email.trim().toLowerCase() == 'feepal@gmail.com') {
      var doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists || doc.data()?['role'] != 'super_admin') {
        debugPrint("⚡ [FirebaseService] Auto-initializing Super Admin document for: $email");
        await _firestore.collection('admins').doc(uid).set({
          'uid': uid,
          'email': email,
          'role': 'super_admin',
          'adminName': 'FeePal Super Admin',
          'schoolName': 'FeePal Management',
          'subscriptionStatus': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  /// Get School Stats for Super Admin
  Future<Map<String, dynamic>> getSchoolStats(String adminId) async {
    try {
      // 1. Total Students & Unique Parents
      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .get();
      
      int totalStudents = studentsSnapshot.docs.length;
      Set<String> uniqueParents = {};
      for (var doc in studentsSnapshot.docs) {
        String? parentEmail = doc.data()['parentEmail'];
        if (parentEmail != null) uniqueParents.add(parentEmail);
      }

      // 2. Total Fees
      var feesSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('fees')
          .get();
      
      return {
        'totalStudents': totalStudents,
        'totalParents': uniqueParents.length,
        'totalFeesCount': feesSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint("❌ Error fetching school stats: $e");
      return {'totalStudents': 0, 'totalParents': 0, 'totalFeesCount': 0};
    }
  }

  /// Get School Activities Stream for Super Admin with optional date filtering
  Stream<QuerySnapshot> getSchoolActivitiesStream(String adminId, {DateTime? startDate, DateTime? endDate}) {
    Query query = _firestore
        .collection('admins')
        .doc(adminId)
        .collection('activities')
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots();
  }

  // --- SUPER ADMIN LOGGING ---

  /// Create a log for Super Admin actions
  Future<void> createSuperAdminLog({
    required String actionType,
    required String description,
    required String targetSchool,
    dynamic details,
  }) async {
    try {
      await _firestore.collection('super_admin_logs').add({
        'actionType': actionType,
        'description': description,
        'targetSchool': targetSchool,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ [SuperAdmin] Log Creation Error: $e");
    }
  }

  /// Get Super Admin Logs Stream
  Stream<QuerySnapshot> getSuperAdminLogsStream() {
    return _firestore
        .collection('super_admin_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Scenario 12: Automated Fee Reminder
  /// This should be triggered periodically (e.g., when Admin Dashboard loads)
  Future<void> processAutomatedReminders(String adminId) async {
    try {
      debugPrint("🤖 [FirebaseService] Running Automated Reminder Engine for $adminId...");
      final now = secureTime;
      
      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .get();

      for (var studentDoc in studentsSnapshot.docs) {
        var sData = studentDoc.data();
        String parentStatus = sData['parentStatus'] ?? 'Standard';
        
        // Check Cooldown: Automated reminders run every 5 days
        Timestamp? lastAutoAlertTs = sData['lastAutoAlertAt'] as Timestamp?;
        if (lastAutoAlertTs != null) {
          if (now.difference(lastAutoAlertTs.toDate()).inDays < 5) continue;
        }

        // Check if any vouchers are nearing due date
        var vouchersSnapshot = await studentDoc.reference
            .collection('vouchers')
            .where('status', isEqualTo: 'unpaid')
            .get();

        bool shouldRemind = false;
        bool isNewlyOverdue = false;
        String? nextDueDate;
        String? overdueMonth;
        bool? isInstallmentAvailable;
        double? baseFee;
        double? additionalCharges;
        double? latePenalty;

        for (var vDoc in vouchersSnapshot.docs) {
          var vData = vDoc.data();
          if (vData['dueDateRaw'] is Timestamp) {
            DateTime due = (vData['dueDateRaw'] as Timestamp).toDate();
            int daysDiff = due.difference(now).inDays;

            // 1. Check for Newly Overdue (Due date passed)
            if (daysDiff < 0) {
              Timestamp? lastOverdueTs = sData['lastOverdueAlertAt'] as Timestamp?;
              // Cooldown for overdue alerts: 7 days
              if (lastOverdueTs == null || now.difference(lastOverdueTs.toDate()).inDays >= 7) {
                isNewlyOverdue = true;
                overdueMonth = vData['monthYear'];
                isInstallmentAvailable = vData['isInstallmentAllowed'] ?? false;
                baseFee = double.tryParse(vData['baseFee']?.toString() ?? '0');
                additionalCharges = double.tryParse(vData['additionalCharge']?.toString() ?? '0');
                latePenalty = double.tryParse(vData['latePenalty']?.toString() ?? '0');
                break;
              }
            }

            // 2. Check for upcoming dues
            if (parentStatus == 'Priority') {
              // Priority: Dues within 7 days
              if (daysDiff >= 0 && daysDiff <= 7) {
                shouldRemind = true;
                nextDueDate = vData['dueDate'];
                isInstallmentAvailable = vData['isInstallmentAllowed'] ?? false;
                baseFee = double.tryParse(vData['baseFee']?.toString() ?? '0');
                additionalCharges = double.tryParse(vData['additionalCharge']?.toString() ?? '0');
                latePenalty = double.tryParse(vData['latePenalty']?.toString() ?? '0');
                break;
              }
            } else {
              // Standard: Dues within 10 days
              if (daysDiff >= 0 && daysDiff <= 10) {
                shouldRemind = true;
                nextDueDate = vData['dueDate'];
                isInstallmentAvailable = vData['isInstallmentAllowed'] ?? false;
                baseFee = double.tryParse(vData['baseFee']?.toString() ?? '0');
                additionalCharges = double.tryParse(vData['additionalCharge']?.toString() ?? '0');
                latePenalty = double.tryParse(vData['latePenalty']?.toString() ?? '0');
                break;
              }
            }
          }
        }

        if (isNewlyOverdue) {
          var studentMutable = Map<String, dynamic>.from(sData);
          studentMutable['docId'] = studentDoc.id;
          studentMutable['feeMonth'] = overdueMonth;
          studentMutable['isInstallmentAvailable'] = isInstallmentAvailable;
          studentMutable['baseFee'] = baseFee;
          studentMutable['additionalCharges'] = additionalCharges;
          studentMutable['latePenalty'] = latePenalty;

          await sendReminder(
            adminId: adminId,
            studentData: studentMutable,
            type: 'Overdue',
            studentId: studentDoc.id,
          );
        } else if (shouldRemind) {
          // Send via the unified sendReminder method to ensure logging and multi-channel
          var studentMutable = Map<String, dynamic>.from(sData);
          studentMutable['docId'] = studentDoc.id;
          if (nextDueDate != null) studentMutable['feeDueDate'] = nextDueDate;
          if (isInstallmentAvailable != null) studentMutable['isInstallmentAvailable'] = isInstallmentAvailable;
          studentMutable['baseFee'] = baseFee;
          studentMutable['additionalCharges'] = additionalCharges;
          studentMutable['latePenalty'] = latePenalty;

          await sendReminder(
            adminId: adminId,
            studentData: studentMutable,
            type: 'Auto-System',
            studentId: studentDoc.id,
          );

          // Update last auto alert timestamp
          await studentDoc.reference.update({
            'lastAutoAlertAt': FieldValue.serverTimestamp(),
          });
        }
      }
      debugPrint("✅ [FirebaseService] Automated Reminder Engine completed.");
    } catch (e) {
      debugPrint("❌ Automated Reminder Error: $e");
    }
  }
  /// Sync all students feeStatus from their vouchers (Repair Logic)
  Future<void> syncAllStudentsFeeStatus(String adminId) async {
    try {
      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .get();

      WriteBatch batch = _firestore.batch();
      int operationCount = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        var unpaidVouchers = await studentDoc.reference
            .collection('vouchers')
            .where('status', isEqualTo: 'unpaid')
            .limit(1)
            .get();

        String newStatus = unpaidVouchers.docs.isNotEmpty ? 'Unpaid' : 'Paid';
        
        batch.update(studentDoc.reference, {'feeStatus': newStatus});
        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }
      
      debugPrint("✅ feeStatus Sync Complete for all students");
    } catch (e) {
      debugPrint("❌ syncAllStudentsFeeStatus Error: $e");
      rethrow;
    }
  }
  /// Helper to migrate student data if ID (Name or Roll No) changes
  Future<void> _migrateStudentData(String adminId, String oldDocId, String newDocId) async {
    try {
      var oldDocRef = _firestore.collection('admins').doc(adminId).collection('students').doc(oldDocId);
      var newDocRef = _firestore.collection('admins').doc(adminId).collection('students').doc(newDocId);

      var snapshot = await oldDocRef.get();
      if (snapshot.exists) {
        // 1. Copy main document
        await newDocRef.set(snapshot.data()!);

        // 2. Move sub-collections (notifications)
        var notifications = await oldDocRef.collection('notifications').get();
        WriteBatch batch = _firestore.batch();
        for (var doc in notifications.docs) {
          batch.set(newDocRef.collection('notifications').doc(doc.id), doc.data());
          batch.delete(doc.reference);
        }
        await batch.commit();

        // 3. Delete old document
        await oldDocRef.delete();
        debugPrint("✅ Migration from $oldDocId to $newDocId completed.");
      }
    } catch (e) {
      debugPrint("❌ Migration Error: $e");
    }
  }

  /// [PHASE 3] Utility to scrub orphaned or inactive parent-student links (Ghost Data Cleanup)
  Future<void> runParentDataScrubbing() async {
    try {
      debugPrint("🧹 [Scrub] Starting parent data scrubbing process...");
      var snapshot = await _firestore.collectionGroup('students').get();
      
      WriteBatch batch = _firestore.batch();
      int opCount = 0;
      int deletedCount = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String? adminId = doc.reference.parent.parent?.id;
        
        bool shouldDelete = false;
        if (adminId == null) {
          shouldDelete = true; // Orphaned document
        } else {
          // Check if admin exists
          var adminDoc = await _firestore.collection('admins').doc(adminId).get();
          if (!adminDoc.exists) {
            shouldDelete = true; // School no longer exists
          } else {
            // Check student status
            String status = data['status']?.toString().toLowerCase() ?? 'active';
            if (status == 'deleted') shouldDelete = true;
          }
        }

        if (shouldDelete) {
          debugPrint("🗑️ [Scrub] Marking student for deletion: ${doc.id}");
          
          // 1. Delete notifications
          var notes = await doc.reference.collection('notifications').get();
          for (var n in notes.docs) {
            batch.delete(n.reference);
            opCount++;
            if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
          }

          // 2. Delete vouchers
          var vouchers = await doc.reference.collection('vouchers').get();
          for (var v in vouchers.docs) {
            batch.delete(v.reference);
            opCount++;
            if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
          }

          // 3. Delete student doc
          batch.delete(doc.reference);
          opCount++;
          deletedCount++;
          if (opCount >= 450) { await batch.commit(); batch = _firestore.batch(); opCount = 0; }
        }
      }

      if (opCount > 0) await batch.commit();
      debugPrint("✅ [Scrub] Completed. Deleted $deletedCount ghost students.");
    } catch (e) {
      debugPrint("❌ [Scrub] Data Scrubbing Error: $e");
    }
  }

  /// Verifies Super Admin password for high-risk operations
  Future<bool> verifySuperAdminPassword(String password) async {
    User? user = _auth.currentUser;
    if (user == null || user.email != 'superadmin@feepal.com') return false;

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint("❌ Super Admin Auth Verification Failed: $e");
      return false;
    }
  }

  /// [SUPER ADMIN ONLY] Utility to wipe all students from a specific school
  /// This deletes all student records, vouchers, and notifications in bulk.
  Future<void> wipeAllStudentsForSchool(String adminId) async {
    try {
      debugPrint("🧹 [SuperAdmin] Wiping all students for school: $adminId");
      
      var studentsSnapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .get();
      
      if (studentsSnapshot.docs.isEmpty) {
        debugPrint("ℹ️ [SuperAdmin] No students found to wipe.");
        return;
      }

      WriteBatch batch = _firestore.batch();
      int opCount = 0;
      int deletedCount = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        // 1. Delete Vouchers sub-collection
        var vouchers = await studentDoc.reference.collection('vouchers').get();
        for (var vDoc in vouchers.docs) {
          batch.delete(vDoc.reference);
          opCount++;
          if (opCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
        }

        // 2. Delete Notifications sub-collection
        var notifications = await studentDoc.reference.collection('notifications').get();
        for (var nDoc in notifications.docs) {
          batch.delete(nDoc.reference);
          opCount++;
          if (opCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
        }

        // 3. Delete Verification sub-collection
        var verifs = await studentDoc.reference.collection('verification').get();
        for (var vDoc in verifs.docs) {
          batch.delete(vDoc.reference);
          opCount++;
          if (opCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
        }

        // 4. Delete Student Document itself
        batch.delete(studentDoc.reference);
        opCount++;
        deletedCount++;

        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      // Final commit
      if (opCount > 0) {
        await batch.commit();
      }

      debugPrint("✅ [SuperAdmin] Wiped $deletedCount students and all associated data.");
    } catch (e) {
      debugPrint("❌ [SuperAdmin] Wipe Students Error: $e");
      rethrow;
    }
  }
  /// Client-Side Automated Monthly Rollover Logic
  Future<void> checkAndRunMonthlyRollover(String adminId) async {
    try {
      var adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (!adminDoc.exists) return;

      Map<String, dynamic> data = adminDoc.data()!;
      String? lastRolloverMonth = data['lastRolloverMonth'];
      
      DateTime serverTime = secureTime;
      String currentMonth = DateFormat('MM-yyyy').format(serverTime);

      if (lastRolloverMonth == null) {
        // First time running, just set it to current month so we don't retroactively rollover.
        await adminDoc.reference.update({'lastRolloverMonth': currentMonth});
        return;
      }

      // Check if current month is strictly greater than lastRolloverMonth
      DateTime lastRolloverDate = DateFormat('MM-yyyy').parse(lastRolloverMonth);
      DateTime currentMonthStart = DateTime(serverTime.year, serverTime.month, 1);

      if (currentMonthStart.isAfter(lastRolloverDate)) {
        debugPrint("🔄 [Rollover] New month detected. Rolling over from $lastRolloverMonth to $currentMonth.");

        // 1. Fetch all templates from lastRolloverMonth
        var oldTemplatesSnapshot = await adminDoc.reference
            .collection('monthly_fees')
            .where('monthYear', isEqualTo: lastRolloverMonth)
            .get();

        WriteBatch batch = _firestore.batch();
        List<Map<String, dynamic>> classesToSync = [];

        for (var oldDoc in oldTemplatesSnapshot.docs) {
          var oldData = oldDoc.data();
          String className = oldData['className'];
          String newTemplateId = "${className}_$currentMonth";

          // Check if admin already created a template for the new month (via "Next Month" tab)
          var newTemplateRef = adminDoc.reference.collection('monthly_fees').doc(newTemplateId);
          var newTemplateSnapshot = await newTemplateRef.get();

          if (!newTemplateSnapshot.exists) {
            // Carry over old template
            Map<String, dynamic> newData = Map<String, dynamic>.from(oldData);
            newData['monthYear'] = currentMonth;
            
            // Carry over exact due date day
            if (oldData['dueDateRaw'] != null) {
              DateTime oldDueDate = (oldData['dueDateRaw'] as Timestamp).toDate();
              // Create new due date with same day, but current month/year
              int newDay = oldDueDate.day;
              // Handle edge cases like Jan 31 -> Feb 28
              int daysInNewMonth = DateTime(serverTime.year, serverTime.month + 1, 0).day;
              if (newDay > daysInNewMonth) newDay = daysInNewMonth;

              DateTime newDueDate = DateTime(serverTime.year, serverTime.month, newDay);
              newData['dueDateRaw'] = Timestamp.fromDate(newDueDate);
              newData['dueDate'] = DateFormat('dd-MM-yyyy').format(newDueDate);
            }

            batch.set(newTemplateRef, newData);
          }
          classesToSync.add({'class': className, 'month': currentMonth});
        }

        // Fetch templates already created for the new month (e.g., via Next Month tab)
        var newTemplatesSnapshot = await adminDoc.reference
            .collection('monthly_fees')
            .where('monthYear', isEqualTo: currentMonth)
            .get();
            
        for (var newDoc in newTemplatesSnapshot.docs) {
          String className = newDoc.data()['className'];
          bool alreadyAdded = classesToSync.any((c) => c['class'] == className);
          if (!alreadyAdded) {
            classesToSync.add({'class': className, 'month': currentMonth});
          }
        }

        // Commit all new templates
        await batch.commit();

        // 2. Generate vouchers using the active template (either newly carried over or existing "Next Month" ones)
        for (var c in classesToSync) {
          await syncClassVouchers(adminId, c['class'], c['month']);
        }

        // 3. Update lastRolloverMonth
        await adminDoc.reference.update({'lastRolloverMonth': currentMonth});
        
        // 4. Ultimate Fail-safe: Sync all fee statuses to ensure UI is 100% accurate
        await syncAllStudentsFeeStatus(adminId);
        
        debugPrint("✅ [Rollover] Monthly rollover complete.");
      }
    } catch (e) { 
      debugPrint("🚨 [Rollover] Error during monthly rollover: $e"); 
    } 
  }

  Future<void> sendParentAdminMessage({
    required String parentId,
    required String adminId,
    required String text,
    required String senderRole,
    String parentName = 'Parent',
  }) async {
    try {
      // 1. Save message to Firestore
      await _firestore
          .collection('parent_chats')
          .doc('${adminId}_$parentId')
          .collection('messages')
          .add({
        'senderId': senderRole == 'admin' ? adminId : parentId,
        'senderRole': senderRole,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update parent chat room metadata
      await _firestore.collection('parent_chats').doc('${adminId}_$parentId').set({
        'adminId': adminId,
        'parentId': parentId,
        'parentName': parentName,
        'lastMessage': text,
        'lastMessageText': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnreadForAdmin': senderRole == 'parent',
        'hasUnreadForParent': senderRole == 'admin',
      }, SetOptions(merge: true));

      // 3. Send Push Notifications
      if (senderRole == 'admin') {
        await _notifyParentNewAdminMessage(adminId, parentId, text);
      } else {
        await _notifyAdminNewParentMessage(adminId, parentName, text, parentId);
      }
    } catch (e) {
      debugPrint("❌ [FirebaseService] sendParentAdminMessage Error: $e");
    }
  }

  Future<void> _notifyParentNewAdminMessage(String adminId, String parentId, String text) async {
    try {
      // parentId here is actually the student's docId because we used it as the chat ID
      var studentDoc = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(parentId)
          .get();
          
      if (studentDoc.exists) {
        String? token = studentDoc.data()?['parentFcmToken'];
        String schoolName = "School Admin";
        
        // Optionally fetch school name
        var adminDoc = await _firestore.collection('admins').doc(adminId).get();
        if (adminDoc.exists) {
            schoolName = adminDoc.data()?['schoolName'] ?? 'School Admin';
        }

        if (token != null && token.isNotEmpty) {
          await PushNotificationDispatcher.sendIndividualNotification(
            token: token,
            title: 'New Message from $schoolName',
            body: text,
            route: 'parent_chat', // Use same route
            type: 'parent_chat',
            extraData: {
              'parentId': parentId,
              'adminId': adminId,
            },
          );
        }
      }
    } catch (e) {
      debugPrint("❌ [FirebaseService] Failed to notify Parent: $e");
    }
  }

  Future<void> _notifyAdminNewParentMessage(String adminId, String parentName, String text, String parentId) async {
    try {
      var adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (adminDoc.exists) {
        String? token = adminDoc.data()?['fcmToken'];
        if (token != null && token.isNotEmpty) {
          await PushNotificationDispatcher.sendIndividualNotification(
            token: token,
            title: 'New Message from $parentName',
            body: text,
            route: 'parent_chat',
            type: 'parent_chat',
            extraData: {
              'parentId': parentId,
              'parentName': parentName,
            },
          );
        }
      }
    } catch (e) {
      debugPrint("❌ [FirebaseService] Failed to notify Admin: $e");
    }
  }

  /// Get Messages Stream for a Parent-Admin Chat
  Stream<QuerySnapshot> getParentAdminMessagesStream(String parentId, String adminId) {
    return _firestore
        .collection('parent_chats')
        .doc('${adminId}_$parentId')
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get Chat Rooms Stream for Admin
  Stream<QuerySnapshot> getAdminParentChatRoomsStream(String adminId) {
    return _firestore
        .collection('parent_chats')
        .where('adminId', isEqualTo: adminId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Mark Chat as Read
  Future<void> markParentAdminChatAsRead(String parentId, String adminId, String role) async {
    try {
      Map<String, dynamic> updates = {};
      if (role == 'admin') {
        updates['hasUnreadForAdmin'] = false;
      } else if (role == 'parent') {
        updates['hasUnreadForParent'] = false;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('parent_chats').doc('${adminId}_$parentId').update(updates);
      }
    } catch (e) {
      debugPrint("❌ [FirebaseService] markParentAdminChatAsRead Error: $e");
    }
  }

  // --- DELETE CHAT UTILITIES ---

  Future<void> deleteParentChat(String parentId, String adminId) async {
    try {
      // Get all messages in the subcollection
      final messagesSnapshot = await _firestore
          .collection('parent_chats')
          .doc('${adminId}_$parentId')
          .collection('messages')
          .get();

      // Create a batch to delete messages
      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the main chat document
      batch.delete(_firestore.collection('parent_chats').doc('${adminId}_$parentId'));

      // Commit the batch
      await batch.commit();
      debugPrint("🗑️ [FirebaseService] Deleted parent chat room: $parentId");
    } catch (e) {
      debugPrint("❌ [FirebaseService] deleteParentChat Error: $e");
    }
  }

  Future<void> wipeOrphanChats() async {
    try {
      final query = await _firestore.collection('parent_chats').get();
      for (var doc in query.docs) {
        if (!doc.id.contains('_')) { // Old format doesn't contain an underscore
          final messages = await _firestore.collection('parent_chats').doc(doc.id).collection('messages').get();
          WriteBatch batch = _firestore.batch();
          for (var msg in messages.docs) {
            batch.delete(msg.reference);
          }
          batch.delete(doc.reference);
          await batch.commit();
          debugPrint("🧹 [Scrub] Wiped orphan chat: ${doc.id}");
        }
      }
    } catch (e) {
      debugPrint("❌ [Scrub] Error wiping orphan chats: $e");
    }
  }

  Future<void> deleteSuperAdminChat(String roomId) async {
    try {
      // Get all messages in the subcollection
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .get();

      // Create a batch to delete messages
      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the main chat document
      batch.delete(_firestore.collection('chats').doc(roomId));

      // Commit the batch
      await batch.commit();
      debugPrint("🗑️ [FirebaseService] Deleted super admin chat room: $roomId");
    } catch (e) {
      debugPrint("❌ [FirebaseService] deleteSuperAdminChat Error: $e");
    }
  }

  // --- PARENT-ADMIN UNREAD STREAMS ---

  Stream<bool> hasUnreadParentMessagesStream(String adminId) {
    if (adminId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('parent_chats')
        .where('adminId', isEqualTo: adminId)
        .where('hasUnreadForAdmin', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Stream<bool> hasUnreadAdminMessagesStream(String studentId) {
    if (studentId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('parent_chats')
        .doc(studentId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          return data?['hasUnreadForParent'] == true;
        });
  }

  // --- SUBSCRIPTION UTILITIES ---

  bool isSubscriptionExpired(Map<String, dynamic> adminData) {
    String status = adminData['subscriptionStatus'] ?? '';
    // If status is active or approved, we evaluate dates. Otherwise, it's expired.
    if (status != 'active' && status != 'approved') return true;
    
    Timestamp? start = adminData['subscriptionStartDate'] as Timestamp?;
    // If start is null but status is active/approved, it might be a fresh approval (e.g., pending server timestamp sync).
    // Do not lock them out in this case.
    if (start == null) return false; 
    
    String plan = adminData['planType'] ?? 'monthly';
    int extendedDays = adminData['extendedDays'] ?? 0;
    int allowedDays = (plan.toLowerCase() == 'yearly' ? 365 : 30) + extendedDays;
    DateTime expiration = start.toDate().add(Duration(days: allowedDays));
    
    // Check if the current time is past expiration
    if (secureTime.isAfter(expiration)) {
      return true;
    }
    
    return false;
  }

  int getSubscriptionDaysRemaining(Map<String, dynamic> adminData) {
    Timestamp? start = adminData['subscriptionStartDate'] as Timestamp?;
    if (start == null) return 0;
    
    String plan = adminData['planType'] ?? 'monthly';
    int extendedDays = adminData['extendedDays'] ?? 0;
    int allowedDays = (plan.toLowerCase() == 'yearly' ? 365 : 30) + extendedDays;
    DateTime expiration = start.toDate().add(Duration(days: allowedDays));
    int diff = expiration.difference(secureTime).inDays;
    
    return diff < 0 ? 0 : diff;
  }

  Future<void> extendSubscription(String adminId, int extraDays) async {
    final docRef = _firestore.collection('admins').doc(adminId);
    
    return _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) {
        throw Exception("Admin not found!");
      }
      
      final data = docSnapshot.data() ?? {};
      int currentExtended = data['extendedDays'] ?? 0;
      int newExtended = currentExtended + extraDays;
      
      // If the subscription was previously expired, we should also re-activate it
      // provided that the new extension gives them positive days remaining.
      bool isExpiredNow = isSubscriptionExpired(data);
      
      Map<String, dynamic> updates = {
        'extendedDays': newExtended,
      };
      
      // If adding these days brings them back from expiration, reset their status
      data['extendedDays'] = newExtended;
      bool isExpiredAfter = isSubscriptionExpired(data);
      
      if (isExpiredNow && !isExpiredAfter) {
        updates['status'] = 'active';
        updates['accountStatus'] = 'active';
        updates['subscriptionStatus'] = 'active';
      }
      
      transaction.update(docRef, updates);
    });
  }
}
