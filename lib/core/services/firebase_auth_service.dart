import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For Android, scopes can be specified if needed
    scopes: ['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Update display name
      await userCredential.user?.updateDisplayName(name.trim());

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signInMethod': 'email',
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'weak-password':
          throw Exception(
            'Password is too weak. Please choose a stronger password',
          );
        case 'email-already-in-use':
          throw Exception('An account already exists with this email address');
        case 'invalid-email':
          throw Exception('The email address is not valid');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled');
        default:
          throw Exception('Sign up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'invalid-email':
          throw Exception('The email address is not valid');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'user-not-found':
          throw Exception('No user found with this email address');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-credential':
          throw Exception('The email or password is incorrect');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Check if Google Services are available
      if (!await _googleSignIn.isSignedIn()) {
        // First, try to sign out any previous session
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // Ignore sign out errors for fresh start
        }
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by the user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Validate Firebase user
      if (userCredential.user == null) {
        throw Exception('Firebase authentication failed - no user returned');
      }

      // Check if this is a new user and create Firestore document if needed
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user?.displayName ?? 'Google User',
          'email': userCredential.user?.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'signInMethod': 'google',
        });
      } else {
        // Update last sign-in time for existing users
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'updatedAt': FieldValue.serverTimestamp()});
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      // Provide more specific error messages for common issues
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('channel') ||
          errorMessage.contains('unable to establish')) {
        throw Exception(
          'Google Sign-In configuration error for Android. Please ensure:\n'
          '1. Google Sign-In is enabled in Firebase Console\n'
          '2. SHA-1 fingerprint is added to Firebase project\n'
          '3. google-services.json contains OAuth client configuration\n'
          '4. Google Sign-In provider is enabled in Authentication\n'
          'Original error: $e',
        );
      } else if (errorMessage.contains('auth') &&
          errorMessage.contains('token')) {
        throw Exception(
          'Authentication token error. This usually means:\n'
          '1. Google Sign-In is not enabled in Firebase Console\n'
          '2. SHA-1 fingerprint is missing or incorrect\n'
          '3. OAuth client is not configured for Android\n'
          'Please check Firebase Console > Authentication > Sign-in method > Google\n'
          'Original error: $e',
        );
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('timeout')) {
        throw Exception(
          'Network error. Please check your internet connection and try again.',
        );
      } else {
        throw Exception('Failed to sign in with Google: $e');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Check if user is currently signed in
      if (_auth.currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      // Sign out from Google if signed in
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (googleError) {
        // Log Google sign out error but continue with Firebase sign out
        print('Google sign out error (non-critical): $googleError');
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Verify sign out was successful
      if (_auth.currentUser != null) {
        throw Exception(
          'Sign out verification failed - user still authenticated',
        );
      }
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile(String name) async {
    try {
      await currentUser?.updateDisplayName(name);
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final uid = currentUser!.uid;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }
}
