import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  // Singleton pattern for speed and persistence
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory session for multiple children
  List<Map<String, dynamic>>? currentParentSession;
  int activeStudentIndex = 0;

  Map<String, dynamic>? get selectedStudent {
    if (currentParentSession != null && currentParentSession!.isNotEmpty) {
      return currentParentSession![activeStudentIndex];
    }
    return null;
  }

  String? get currentAdminId => _auth.currentUser?.uid;
  
  /// Get current parent session children
  List<Map<String, dynamic>>? getParentSession() => currentParentSession;

  /// Parent Login
  Future<String?> loginParent({required String email, required String password}) async {
    try {
      debugPrint("🚀 [FirebaseService] Searching for parent: $email");
      
      var emailOrPhone = email.trim();
      // Step 1: Authenticate parent against at least one child
      var authSnapshot = await _firestore
          .collectionGroup('students')
          .where(Filter.or(
            Filter('parentEmail', isEqualTo: emailOrPhone),
            Filter('parentPhone', isEqualTo: emailOrPhone)
          ))
          .where('parentPassword', isEqualTo: password)
          .limit(1)
          .get();

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
        var allSiblingsSnapshot = await _firestore
            .collectionGroup('students')
            .where(filters.length > 1 ? Filter.or(filters[0], filters[1]) : filters[0])
            .get();

        List<Map<String, dynamic>> allChildren = [];
        
        for (var doc in allSiblingsSnapshot.docs) {
          var data = doc.data();
          String? adminId = doc.reference.parent.parent?.id;
          if (adminId != null) {
            data['adminId'] = adminId;
            data['docId'] = doc.id; // Inject Document ID
            allChildren.add(data);
          }
        }
        
        if (allChildren.isNotEmpty) {
          debugPrint("✅ Found ${allChildren.length} children for this parent.");
          currentParentSession = allChildren;
          activeStudentIndex = 0;
          return null;
        }
      }
      
      return 'Invalid email or password';
    } catch (e) {
      debugPrint("❌ Parent Login Error: $e");
      return e.toString();
    }
  }

  /// Logout (Both Admin and Parent)
  Future<void> logout() async {
    await _auth.signOut();
    currentParentSession = null;
    debugPrint("✅ Logged out from Firebase and cleared session.");
  }

  /// Parent Logout
  void logoutParent() {
    currentParentSession = null;
    debugPrint("✅ Parent logged out.");
  }

  /// Signs up an Admin with email and password, and saves details to Firestore.
  /// Signs up an Admin with email and password, logo, address, and branches.
  Future<String?> signUpAdmin({
    required String schoolName,
    required String adminName,
    required String email,
    required String phoneNumber,
    required String password,
    required String schoolAddress,
    required List<Map<String, dynamic>> branches,
    Uint8List? logoBytes,
    String? externalLogoUrl,
  }) async {
    User? user;
    try {
      debugPrint("🚀 [FirebaseService] Starting atomic signup for: $email");

      // 1. Create Auth User
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
        await _firestore.collection('admins').doc(user.uid).set({
          'uid': user.uid,
          'schoolName': schoolName.trim(),
          'adminName': adminName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'schoolAddress': schoolAddress.trim(),
          'schoolLogoUrl': logoUrl,
          'branches': branches,
          'role': 'admin',
          'subscriptionStatus': 'none',
          'hasSeenWelcome': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

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

  /// Find existing parent by email (for sibling auto-fill)
  Future<Map<String, dynamic>?> findParentByEmail(String email) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    var emailOrPhone = email.trim();
    var snapshot = await _firestore
        .collection('admins')
        .doc(user.uid)
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
        var doc = await _firestore.collection('admins').doc(user.uid).get();
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
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint("✅ Login success");
      return null;
    } on FirebaseAuthException catch (e) {
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
        .doc(user.uid)
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Add / Update Student
  Future<void> addOrUpdateStudent(Map<String, dynamic> studentData, {String? oldDocId}) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    String studentName = studentData['studentName'] ?? 'No Name';
    String rollNo = studentData['rollNumber'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    String newDocId = "$studentName ($rollNo)";
    
    // Handle Migration if ID changed
    if (oldDocId != null && oldDocId != newDocId) {
      debugPrint("🔄 Migrating student from $oldDocId to $newDocId");
      await _migrateStudentData(user.uid, oldDocId, newDocId);
    }
    
    // Generate password if it's a new student
    String password = studentData['parentPassword'] ?? _generatePassword();

    // Case 1: Arrears (Old Dues) Handling
    double oldDues = double.tryParse(studentData['oldDues']?.toString() ?? '0') ?? 0.0;
    Map<String, dynamic> arrearsData = {};
    if (oldDues > 0 && !studentData.containsKey('oldDuesDueDate')) {
      arrearsData['oldDues'] = oldDues;
      arrearsData['oldDuesStatus'] = 'Unpaid';
      arrearsData['oldDuesDueDate'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)));
    }

    // Consolidation: Use arrearsBalance (num)
    double arrearsBalance = double.tryParse(studentData['arrearsBalance']?.toString() ?? '0') ?? 
                           double.tryParse(studentData['oldDues']?.toString() ?? '0') ?? 0.0;

    // Case 3: Auto-assign Monthly Fee if it exists for this class
    Map<String, dynamic> autoFeeData = {};
    String className = studentData['class']?.toString() ?? 'Unknown';
    if (RegExp(r'^\d+$').hasMatch(className.trim())) {
      className = 'Class ${className.trim()}';
    }

    double currentLastFee = double.tryParse(studentData['lastFeeAmount']?.toString() ?? '0') ?? 0.0;
    if (currentLastFee == 0) {
      try {
        var feeDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .collection('fees')
            .doc(className)
            .get();
        
        if (feeDoc.exists) {
          var fee = feeDoc.data()!;
          autoFeeData['lastFeeAmount'] = fee['amount']?.toString() ?? '0';
          autoFeeData['feeStatus'] = 'Unpaid';
          autoFeeData['feeDueDate'] = fee['dueDateRaw'];
          autoFeeData['currentBaseFee'] = double.tryParse(fee['baseFee']?.toString() ?? '0') ?? 0.0;
          autoFeeData['currentAdditionalCharge'] = double.tryParse(fee['additionalCharge']?.toString() ?? '0') ?? 0.0;
          autoFeeData['currentPenaltyAmount'] = double.tryParse(fee['penaltyAmount']?.toString() ?? '0') ?? 0.0;
        }
      } catch (e) {
        debugPrint("⚠️ Could not auto-fetch fee for $className: $e");
      }
    }

    await _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .doc(newDocId)
        .set({
          'additionalCharge': 0,
          'penaltyAmount': 0,
          'arrearsBalance': arrearsBalance,
          'installments': [],
          'hasInstallments': false,
          'parentStatus': 'Standard',
          'penaltyApplied': false,
          'siblingDiscountPercentage': 0,
          ...studentData,
          'class': className, // Enforce normalized class name
          ...autoFeeData, // Apply auto-fetched fee if applicable
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
          .doc(user.uid)
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
  }

  /// Batch Import
  Future<void> batchImportStudents(List<Map<String, dynamic>> students) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    WriteBatch batch = _firestore.batch();
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');

    for (var student in students) {
      String studentName = student[ 'studentName'] ?? 'No Name';
      String rollNo = student['rollNumber'] ?? '';
      if (rollNo.isEmpty) continue;
      String docId = "$studentName ($rollNo)";

      batch.set(studentsRef.doc(docId), {
        ...student,
        'parentPassword': student['parentPassword'] ?? _generatePassword(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    // Log Activity
    await createAdminActivity(
      'Batch Import',
      'Successfully imported ${students.length} students via batch.',
      iconType: 'student',
    );
  }

  /// Save Class Fee & Automatically Apply to Unpaid Students
  Future<void> saveClassFee(Map<String, dynamic> feeData) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    String feeId = feeData['className'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    var feeRef = _firestore.collection('admins').doc(user.uid).collection('fees').doc(feeId);

    try {
      debugPrint("🚀 [FirebaseService] Saving class fee for: $feeId");
      
      // 1. Save the fee structure (Case 3: Base Fee, Additional, Penalty)
      await feeRef.set({
        ...feeData,
        'baseFee': double.tryParse(feeData['baseFee']?.toString() ?? '0') ?? 0.0,
        'additionalCharge': double.tryParse(feeData['additionalCharge']?.toString() ?? '0') ?? 0.0,
        'penaltyAmount': double.tryParse(feeData['penaltyAmount']?.toString() ?? '0') ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Automate: Find all students in this class and apply the new fee
      await _applyFeeToStudents(feeData, user);
      
      // Log activity
      await createAdminActivity(
        'New Fee Issued',
        'A fee of Rs. ${feeData['amount']} was issued for ${feeData['className']}',
        iconType: 'fee',
      );

      debugPrint("✅ Class fee saved and applied successfully.");
    } catch (e) {
      debugPrint("❌ Error in saveClassFee: $e");
      rethrow;
    }
  }

  Future<void> _applyFeeToStudents(Map<String, dynamic> feeData, User user) async {
    double newAmount = double.tryParse(feeData['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    String rawClass = feeData['className']?.toString().trim() ?? '';
    String numOnly = rawClass.replaceAll(RegExp(r'[^0-9]'), '');
    
    List<String> classVariations = [rawClass, rawClass.toLowerCase(), rawClass.toUpperCase()];
    if (numOnly.isNotEmpty) {
      classVariations.add(numOnly); // '1'
      classVariations.add('Class $numOnly'); // 'Class 1'
      classVariations.add('class $numOnly'); // 'class 1'
      classVariations.add('CLASS $numOnly'); // 'CLASS 1'
    }
    // Final cleanup to ensure no duplicates and only strings
    classVariations = classVariations.map((e) => e.toString().trim()).toSet().toList();
    
    // Safety check: if more than 10 variations (limit for whereIn), trim it
    if (classVariations.length > 10) classVariations = classVariations.sublist(0, 10);
    
    // Sibling Class Bug Fix: Filter by class variations to handle '3' vs 'Class 3'
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');
    var classStudents = await studentsRef
        .where('class', whereIn: classVariations)
        .get();

    if (classStudents.docs.isEmpty) {
      debugPrint("ℹ️ No students found for class: $rawClass");
      return;
    }

    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (var doc in classStudents.docs) {
      if (count >= 500) break; // Firestore batch limit safety
      var data = doc.data();
      String status = data['feeStatus']?.toString().trim().toLowerCase() ?? 'unpaid';
      String lastFeeStr = data['lastFeeAmount']?.toString() ?? '0';
      double currentFee = double.tryParse(lastFeeStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      
      double baseFee = double.tryParse(feeData['baseFee']?.toString() ?? '0') ?? 0.0;
      double additional = double.tryParse(feeData['additionalCharge']?.toString() ?? '0') ?? 0.0;
      double penalty = double.tryParse(feeData['penaltyAmount']?.toString() ?? '0') ?? 0.0;
      double newTotal = baseFee + additional;
      
      if (status == 'unpaid') {
        batch.update(doc.reference, {
          'lastFeeAmount': (currentFee + newTotal).toStringAsFixed(0),
          'currentBaseFee': baseFee,
          'currentAdditionalCharge': additional,
          'currentPenaltyAmount': penalty,
          'feeDueDate': feeData['dueDateRaw'],
        });
      } else {
        batch.update(doc.reference, {
          'lastFeeAmount': newTotal.toStringAsFixed(0),
          'currentBaseFee': baseFee,
          'currentAdditionalCharge': additional,
          'currentPenaltyAmount': penalty,
          'feeDueDate': feeData['dueDateRaw'],
          'feeStatus': 'Unpaid',
        });
      }

      // 3. Send notification to the parent
      // We do this via individual calls to keep batches under 500 limit if student list is large
      createNotification(user.uid, doc.id, {
        'title': 'New Fee Issued',
        'description': 'A new monthly fee of Rs. ${feeData['amount']} has been created. Due date: ${feeData['dueDate']}',
        'isImportant': true,
        'iconType': 'fee',
      }).catchError((e) => debugPrint("❌ Error sending fee notification: $e"));

      count++;
    }

    await batch.commit();
    debugPrint("✅ Batch update committed for $count students.");
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

  /// Get class fees stream (Alias for getFeeStream for UI consistency)
  Stream<QuerySnapshot> getClassFeesStream(String adminId, String className) {
    return getFeeStream(adminId, className);
  }

  /// Get fee stream with class name normalization
  Stream<QuerySnapshot> getFeeStream(String adminId, String className) {
    String rawClass = className.trim();
    String numOnly = rawClass.replaceAll(RegExp(r'[^0-9]'), '');
    
    List<String> classVariations = [rawClass];
    if (numOnly.isNotEmpty) {
      classVariations.add(numOnly); // '1'
      classVariations.add('Class $numOnly'); // 'Class 1'
      classVariations.add('class $numOnly'); // 'class 1'
    }
    classVariations = classVariations.toSet().toList();

    return _firestore
        .collection('admins')
        .doc(adminId)
        .collection('fees')
        .where('className', whereIn: classVariations)
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

  /// Check if fee exists
  Future<bool> checkFeeExists(String className) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    String feeId = className;
    var doc = await _firestore.collection('admins').doc(user.uid).collection('fees').doc(feeId).get();
    return doc.exists;
  }

  /// Renew expired fees
  Future<void> checkAndRenewExpiredFees() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    var feesRef = _firestore.collection('admins').doc(user.uid).collection('fees');
    var feesSnapshot = await feesRef.get();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (var doc in feesSnapshot.docs) {
      var data = doc.data();
      if (data['dueDateRaw'] != null) {
        DateTime dueDate = (data['dueDateRaw'] as Timestamp).toDate();
        DateTime dueDateMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);

        if (today.isAfter(dueDateMidnight)) {
          // Increment by 1 month
          DateTime newDueDate = DateTime(dueDateMidnight.year, dueDateMidnight.month + 1, dueDateMidnight.day);
          
          while(newDueDate.isBefore(today) || newDueDate.isAtSameMomentAs(today)) {
             newDueDate = DateTime(newDueDate.year, newDueDate.month + 1, newDueDate.day);
          }

          data['dueDateRaw'] = Timestamp.fromDate(newDueDate);
          data['dueDate'] = "${newDueDate.month}/${newDueDate.day}/${newDueDate.year}";

          // Re-apply fee to students since it renewed
          await _applyFeeToStudents(data, user);
          
          await feesRef.doc(doc.id).update({
            'dueDateRaw': data['dueDateRaw'],
            'dueDate': data['dueDate'],
          });
        }
      }
    }
  }

  /// Get Fees Stream
  Stream<QuerySnapshot> getFeesStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('fees')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get Unpaid Students Count Stream for Dashboard (Any pending balance)
  Stream<int> getUnpaidStudentsCountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);
  
    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            var data = doc.data();
            double fee = double.tryParse(data['lastFeeAmount']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0;
            double arrears = double.tryParse(data['arrearsBalance']?.toString() ?? '0') ?? 0.0;
            return (fee + arrears) > 0;
          }).length;
        });
  }

  /// Get Overdue Students Count Stream for Dashboard
  Stream<int> getOverdueStudentsCountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots()
        .map((snapshot) {
          DateTime now = DateTime.now();
          DateTime todayMidnight = DateTime(now.year, now.month, now.day);
          
          return snapshot.docs.where((doc) {
            var data = doc.data();
            if (data['feeDueDate'] == null) return false;
            
            DateTime dueDate = (data['feeDueDate'] as Timestamp).toDate();
            DateTime dueDateMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
            
            // Overdue if current date is strictly after the due date
            return todayMidnight.isAfter(dueDateMidnight);
          }).length;
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

  /// Delete Student
  Future<void> deleteStudent(String studentId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .delete();

    // Log Activity
    await createAdminActivity(
      'Student Removed',
      'Student record ($studentId) was removed from the system.',
      iconType: 'student',
    );
  }

  /// Delete Fee
  Future<void> deleteFee(String feeId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Get the fee data so we know how much to reverse
    var feeRef = _firestore.collection('admins').doc(user.uid).collection('fees').doc(feeId);
    var feeDoc = await feeRef.get();
    
    if (feeDoc.exists) {
      await _removeFeeFromStudents(feeDoc.data() as Map<String, dynamic>, user);
    }

    await feeRef.delete();

    // Log Activity
    await createAdminActivity(
      'Fee Deleted',
      'Class fee structure for $feeId was removed.',
      iconType: 'fee',
    );
  }

  Future<void> _removeFeeFromStudents(Map<String, dynamic> feeData, User user) async {
    double removeAmount = double.tryParse(feeData['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    String rawClass = feeData['className']?.toString().trim() ?? '';
    String numOnly = rawClass.replaceAll(RegExp(r'[^0-9]'), '');
    
    List<String> classVariations = [];
    if (numOnly.isNotEmpty) {
      classVariations.add(numOnly); // '1'
      classVariations.add('Class $numOnly'); // 'Class 1'
      classVariations.add('class $numOnly'); // 'class 1'
    }
    classVariations.add(rawClass);
    classVariations = classVariations.toSet().toList(); // Remove duplicates
    
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');
    var classStudents = await studentsRef
        .where('class', whereIn: classVariations)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in classStudents.docs) {
      var data = doc.data();
      String status = data['feeStatus']?.toString().trim().toLowerCase() ?? 'unpaid';
      String lastFeeStr = data['lastFeeAmount']?.toString() ?? '0';
      double currentFee = double.tryParse(lastFeeStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      
      // Always clear installments when the base fee is deleted
      Map<String, dynamic> updates = {
        'installments': [],
        'hasInstallments': false,
      };
      
      if (status == 'unpaid') {
        double newFee = currentFee - removeAmount;
        if (newFee < 0) newFee = 0.0;
        updates['lastFeeAmount'] = newFee.toStringAsFixed(0);
        
        // If the balance drops to zero, mark as paid
        if (newFee == 0) {
          updates['feeStatus'] = 'Paid';
        }
      }

      batch.update(doc.reference, updates);
    }

    await batch.commit();
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

  Future<void> updateStudentArrearsInstallments(String adminId, String studentId, List<Map<String, dynamic>> installments) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('students')
          .doc(studentId)
          .update({
        'arrearsInstallments': installments,
        'hasArrearsInstallments': installments.isNotEmpty,
      });
    } catch (e) {
      debugPrint("❌ Error updating arrears installments: $e");
      rethrow;
    }
  }

  /// Update Admin Password (Firebase Auth)
  Future<void> updateAdminPassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");
    await user.updatePassword(newPassword);
  }

  /// Update Parent Password (Firestore)
  Future<void> updateParentPassword(String adminId, String studentId, String newPassword) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .update({'parentPassword': newPassword});
  }

  /// Create Admin Activity
  Future<void> createAdminActivity(String title, String subtitle, {String iconType = 'info'}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('admins')
        .doc(user.uid)
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
        .doc(user.uid)
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
        .doc(user.uid)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }

  /// Get reliable server time (Case 3: Penalty Logic)
  Future<DateTime> getServerTime() async {
    try {
      // Using a fast public API for reliability
      final response = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DateTime.parse(data['utc_datetime']).toLocal();
      }
    } catch (e) {
      debugPrint("⚠️ Server time fetch failed, using local: $e");
    }
    return DateTime.now();
  }

  Future<bool> canGenerateCurrentVoucher(String adminId, String studentId) async {
    try {
      var doc = await _firestore.collection('admins').doc(adminId).collection('students').doc(studentId).get();
      if (!doc.exists) return false;
      var data = doc.data()!;
      
      // Strict Blocking: If arrearsBalance > 0, block current month voucher
      double arrears = double.tryParse(data['arrearsBalance']?.toString() ?? '0') ?? 0.0;
      if (arrears > 0) return false;

      return true;
    } catch (e) {
      debugPrint("❌ Validation Error: $e");
      return false;
    }
  }

  /// Updated Math Pipeline for Total Payable
  Future<double> calculateTotalPayable(Map<String, dynamic> studentData) async {
    double base = double.tryParse(studentData['currentBaseFee']?.toString() ?? '0') ?? 0.0;
    num discountPercent = studentData['siblingDiscountPercentage'] ?? 0;
    double arrears = double.tryParse(studentData['arrearsBalance']?.toString() ?? '0') ?? 0.0;
    double additional = double.tryParse(studentData['currentAdditionalCharge']?.toString() ?? '0') ?? 0.0;
    
    double totalBeforeDiscount = base + additional;
    double discountAmount = (totalBeforeDiscount * discountPercent) / 100;
    double currentMonthDues = totalBeforeDiscount - discountAmount;
    
    // If overdue, add penalty to current month dues
    if (studentData['feeDueDate'] != null) {
      DateTime dueDate = (studentData['feeDueDate'] as Timestamp).toDate();
      DateTime now = await getServerTime();
      DateTime dueDateMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (now.isAfter(dueDateMidnight.add(const Duration(days: 1))) && studentData['feeStatus']?.toString().toLowerCase() == 'unpaid') {
        double penalty = double.tryParse(studentData['currentPenaltyAmount']?.toString() ?? '0') ?? 0.0;
        currentMonthDues += penalty;
      }
    }

    return arrears + currentMonthDues;
  }

  /// Automation Engine: Client-side logic for penalties and priority alerts
  Future<void> runAutomatedChecks() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');
    
    try {
      var snapshot = await studentsRef.get();
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String rollNo = doc.id;
        
        // 1. Rollover Logic: Current month dues (plus penalty) roll into arrears after due date
        if (data['feeStatus']?.toString().toLowerCase() == 'unpaid' && data['feeDueDate'] != null) {
          DateTime dueDate = (data['feeDueDate'] as Timestamp).toDate();
          
          DateTime dueDateMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
          DateTime rolloverThreshold = dueDateMidnight.add(const Duration(days: 1));
          
          if (now.isAfter(rolloverThreshold)) {
            double arrears = double.tryParse(data['arrearsBalance']?.toString() ?? '0') ?? 0.0;
            double currentBase = double.tryParse(data['currentBaseFee']?.toString() ?? '0') ?? 0.0;
            double penalty = double.tryParse(data['currentPenaltyAmount']?.toString() ?? '0') ?? 0.0;
            double additional = double.tryParse(data['currentAdditionalCharge']?.toString() ?? '0') ?? 0.0;
            
            num discountPercent = data['siblingDiscountPercentage'] ?? 0;
            double totalBeforeDiscount = currentBase + additional;
            double discountAmount = (totalBeforeDiscount * discountPercent) / 100;
            double monthDues = (totalBeforeDiscount - discountAmount) + penalty;

            // Update arrears and reset current fee fields to avoid double charge
            await studentsRef.doc(rollNo).update({
              'arrearsBalance': arrears + monthDues,
              'feeStatus': 'Unpaid', // Keep unpaid but with rolled dues
              'lastFeeAmount': '0',
              'penaltyApplied': true,
              'rolledOverAt': FieldValue.serverTimestamp(),
            });
            debugPrint("🤖 [Automation] Rollover applied for student $rollNo");
          }
        }

        // 2. Priority Auto-Alerts (Case 2: Priority alerts every 3 days)
        String parentStatus = data['parentStatus'] ?? 'Standard';
        if (parentStatus == 'Priority' && data['feeStatus']?.toString().toLowerCase() == 'unpaid') {
          DateTime? lastAlert = data['lastPriorityAlertAt'] != null 
              ? (data['lastPriorityAlertAt'] as Timestamp).toDate() 
              : null;
              
          if (lastAlert == null || now.difference(lastAlert).inDays >= 3) {
            await sendReminder(
              adminId: user.uid,
              studentData: data,
              type: 'Auto-System',
              title: 'Priority Alert',
            );
            
            await studentsRef.doc(rollNo).update({
              'lastPriorityAlertAt': FieldValue.serverTimestamp(),
            });
            debugPrint("🤖 [Automation] Priority Alert sent for student $rollNo");
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Automation Engine Error: $e");
    }
  }

  /// Send Reminder (Manual or Auto)
  Future<void> sendReminder({
    String? adminId,
    required Map<String, dynamic> studentData,
    required String type,
    String title = 'Fee Reminder',
  }) async {
    String? finalAdminId = adminId ?? _auth.currentUser?.uid;
    if (finalAdminId == null || finalAdminId.isEmpty) {
      debugPrint("❌ Cannot send reminder: No Admin ID found.");
      return;
    }
    
    String rollNo = studentData['rollNumber'].toString();
    String studentName = studentData['studentName'] ?? 'Student';
    String parentName = studentData['parentName'] ?? 'Parent';

    // 1. Add notification for parent
    String dueDateStr = "Not Set";
    if (studentData['feeDueDate'] != null) {
      DateTime dueDate = (studentData['feeDueDate'] as Timestamp).toDate();
      dueDateStr = DateFormat('dd MMM yyyy').format(dueDate);
    }

    String notificationMsg = title == 'Priority Alert' 
        ? 'Please clear your dues within due date: $dueDateStr'
        : 'Fee payment is pending for $studentName. Please clear it soon.';

    String studentId = "$studentName ($rollNo)";

    await _firestore
        .collection('admins')
        .doc(finalAdminId)
        .collection('students')
        .doc(studentId)
        .collection('notifications')
        .add({
      'title': title,
      'description': notificationMsg,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isReminder': true,
      'iconType': title == 'Priority Alert' ? 'priority' : 'alert',
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
      'title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Update last manual alert if type is Manual
    if (type == 'Manual') {
      String studentId = "$studentName ($rollNo)";
      await _firestore
          .collection('admins')
          .doc(finalAdminId)
          .collection('students')
          .doc(studentId)
          .update({'lastManualAlertAt': FieldValue.serverTimestamp()});
    }

    // 4. Log to Admin Activity (Recent Activity)
    await createAdminActivity(
      type == 'Manual' ? 'Reminder Sent' : 'Auto-Reminder Sent',
      'Sent $title to $parentName for $studentName',
      iconType: 'notification',
    );
  }

  /// Streams for Alerts Screen
  Stream<QuerySnapshot> getReminderLogsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('reminder_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPriorityUnpaidStudentsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .where('parentStatus', isEqualTo: 'Priority')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots();
  }

  Stream<QuerySnapshot> getStandardNearingDueStudentsStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    // We fetch all unpaid students and filter client-side for "nearing due" (3 days) 
    // to keep it simple and handle Firestore indexing limitations for complex filters.
    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots();
  }

  /// Submit Payment Proof
  Future<void> submitPaymentProof(String adminId, String studentId) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .collection('students')
        .doc(studentId)
        .update({
      'feeStatus': 'Paid',
      'lastFeeAmount': '0',
      'arrearsBalance': 0,
      'paymentProofSubmittedAt': FieldValue.serverTimestamp(),
    });
    
    // Log activity for the admin to see
    await createAdminActivity(
      'Payment Proof Received',
      'Student: $studentId submitted a payment proof and was marked as Paid.',
      iconType: 'fee',
    );
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

  /// Get Admin Data
  Future<Map<String, dynamic>?> getAdminData(String uid) async {
    try {
      var doc = await _firestore.collection('admins').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("❌ Error fetching admin data: $e");
      return null;
    }
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
        String fileName = 'proofs/$adminId/${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  /// Approve Subscription (Super Admin)
  Future<void> approveSubscription(String subscriptionId, String adminId) async {
    WriteBatch batch = _firestore.batch();

    // 1. Update subscription status
    batch.update(_firestore.collection('subscriptions').doc(subscriptionId), {
      'status': 'approved',
    });

    // 2. Update admin document
    batch.update(_firestore.collection('admins').doc(adminId), {
      'subscriptionStatus': 'approved',
      'hasSeenWelcome': false, // Trigger welcome popup
    });

    await batch.commit();
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
}
