// FILE: lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userFromFirebase(User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(uid: user.uid);
  }

  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  // Sign Up with Email & Password
  Future<String?> signUpWithEmailAndPassword(
      String email, String password, String fullName, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Create a new document for the user in Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'email': email,
        'fullName': fullName,
        'role': role, // 'patient', 'doctor', or 'admin'
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  // Sign In with Email & Password
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Get current user's role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}