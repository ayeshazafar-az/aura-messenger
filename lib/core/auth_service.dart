import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user exists in db (in case Google sign-in was used before, or migrated)
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));

      // Account confirmation check
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception(
          'Email not verified. Please check your inbox to confirm your account.',
        );
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Account not found. Please create an account first.');
      } else if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message);
    }
  }

  Future<User?> signUp(
    String email,
    String password,
    String username,
    String name,
    String phone,
  ) async {
    try {
      // Uniqueness check for username
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw Exception(
          'Username "@$username" is already taken. Please choose a different one.',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'username': username,
        'name': name,
        'phone': phone,
      });

      // Send the confirmation link
      await credential.user!.sendEmailVerification();

      // Immediately sign out to force login after confirmation
      await _auth.signOut();

      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'An account with this email already exists. Please login.',
        );
      }
      throw Exception(e.message);
    }
  }

  bool _isGoogleInitialized = false;

  Future<User?> signInWithGoogle() async {
    try {
      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleInitialized = true;
      }
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Only set base username if they are entirely new
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          final baseUsername = user.email!.split('@')[0];
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'username': baseUsername,
          }, SetOptions(merge: true));
        }
      }

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
