import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  FirebaseAuth? _auth;
  String? _verificationId;
  Function(String verificationId)? onCodeSent;

  // Lazy getter for FirebaseAuth instance
  FirebaseAuth get auth {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth!;
    } catch (e) {
      throw Exception(
        'Firebase is not initialized. Please ensure Firebase.initializeApp() is called.',
      );
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP(
    String phoneNumber, {
    Function(String verificationId)? onCodeSentCallback,
  }) async {
    try {
      // Verify Firebase is initialized by accessing auth
      final firebaseAuth = auth;

      onCodeSent = onCodeSentCallback;

      // Validate phone number format
      if (phoneNumber.isEmpty || phoneNumber.length < 10) {
        throw Exception('Invalid phone number format');
      }

      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          try {
            await firebaseAuth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Auto-verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (onCodeSent != null) {
            onCodeSent!(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      rethrow;
    }
  }

  // Get stored verification ID
  String? get verificationId => _verificationId;

  // Verify OTP code
  Future<UserCredential> verifyOTP(
    String verificationId,
    String smsCode,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await auth.signInWithCredential(credential);
  }

  // Get current user
  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    try {
      return auth.authStateChanges();
    } catch (e) {
      return Stream.value(null);
    }
  }
}
