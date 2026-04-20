import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class FirebaseService {
  // Singleton pattern for speed and persistence
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs up an Admin with email and password, and saves details to Firestore.
  Future<String?> signUpAdmin({
    required String schoolName,
    required String adminName,
    required String email,
    required String phoneNumber,
    required String password,
    String? schoolCode,
  }) async {
    try {
      debugPrint("🚀 [FirebaseService] Starting signup for: $email");

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      debugPrint("✅ [FirebaseService] Auth user created: ${user?.uid}");

      if (user != null) {
        await _firestore.collection('admins').doc(user.uid).set({
          'uid': user.uid,
          'schoolName': schoolName.trim(),
          'adminName': adminName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'schoolCode': schoolCode?.trim() ?? '',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint("✅ Admin data saved!");
        return null;
      } else {
        return "User is null after signup.";
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Auth Error: ${e.code}");

      switch (e.code) {
        case 'weak-password':
          return 'Weak password';
        case 'email-already-in-use':
          return 'Email already exists';
        case 'invalid-email':
          return 'Invalid email';
        default:
          return e.message;
      }
    } catch (e) {
      debugPrint("❌ Unexpected: $e");
      return e.toString();
    }
  }

  /// Fetch admin profile
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
  Future<void> addOrUpdateStudent(Map<String, dynamic> studentData) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    String rollNo = studentData['rollNumber'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate password if it's a new student
    String password = studentData['parentPassword'] ?? _generatePassword();

    await _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .doc(rollNo)
        .set({
          ...studentData,
          'parentPassword': password,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': studentData.containsKey('createdAt') ? studentData['createdAt'] : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Batch Import
  Future<void> batchImportStudents(List<Map<String, dynamic>> students) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    WriteBatch batch = _firestore.batch();
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');

    for (var student in students) {
      String rollNo = student['rollNumber'] ?? '';
      if (rollNo.isEmpty) continue;

      batch.set(studentsRef.doc(rollNo), {
        ...student,
        'parentPassword': student['parentPassword'] ?? _generatePassword(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Save Class Fee & Automatically Apply to Unpaid Students
  Future<void> saveClassFee(Map<String, dynamic> feeData) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    String feeId = feeData['className'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    var feeRef = _firestore.collection('admins').doc(user.uid).collection('fees').doc(feeId);

    // 1. Save the fee structure
    await feeRef.set({
      ...feeData,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Automate: Find unpaid students in this class and add the new fee
    double newAmount = double.tryParse(feeData['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    var studentsRef = _firestore.collection('admins').doc(user.uid).collection('students');
    var unpaidStudents = await studentsRef
        .where('class', isEqualTo: feeData['className'])
        .where('feeStatus', isEqualTo: 'Unpaid')
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unpaidStudents.docs) {
      var data = doc.data();
      double currentFee = double.tryParse(data['lastFeeAmount']?.toString() ?? '0') ?? 0.0;
      
      batch.update(doc.reference, {
        'lastFeeAmount': (currentFee + newAmount).toStringAsFixed(0),
      });
    }

    await batch.commit();
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

  /// Get Unpaid Students Count Stream for Dashboard
  Stream<int> getUnpaidStudentsCountStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .where('feeStatus', isEqualTo: 'Unpaid')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
  Future<void> deleteStudent(String rollNo) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('students')
        .doc(rollNo)
        .delete();
  }

  /// Delete Fee
  Future<void> deleteFee(String feeId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('admins')
        .doc(user.uid)
        .collection('fees')
        .doc(feeId)
        .delete();
  }
}
