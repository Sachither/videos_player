import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign In Anonymously (Ideal for Rooms - instant and stress-free)
  Future<UserCredential?> signInAnonymously() async {
    try {
      print('🔐 Signing in anonymously...');
      final userCredential = await _auth.signInAnonymously();
      print('✅ Anonymous sign-in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('❌ Anonymous sign-in error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }
}
