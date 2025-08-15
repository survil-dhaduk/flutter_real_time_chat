import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Implementation of [AuthRemoteDataSource] using Firebase Auth and Firestore
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Logger _logger;

  AuthRemoteDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? const Logger();

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting to sign in user with email: $email');

      // Sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
            'Sign in failed: No user returned from Firebase Auth');
      }

      // Get user profile from Firestore
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw const AuthException('User profile not found in database');
      }

      // Update online status
      await _updateUserOnlineStatus(firebaseUser.uid, true);

      final userModel = UserModel.fromFirestore(userDoc);
      _logger.info('Successfully signed in user: ${userModel.id}');

      return userModel.copyWith(isOnline: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error during sign in: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on FirebaseException catch (e) {
      _logger.error('Firestore error during sign in: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error during sign in: $e');
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _logger.info('Attempting to sign up user with email: $email');

      // Create user with Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
            'Sign up failed: No user returned from Firebase Auth');
      }

      // Update Firebase Auth profile
      await firebaseUser.updateDisplayName(displayName);

      // Create user profile in Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        id: firebaseUser.uid,
        email: email,
        displayName: displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: now,
        lastSeen: now,
        isOnline: true,
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      _logger.info('Successfully signed up user: ${userModel.id}');
      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error during sign up: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on FirebaseException catch (e) {
      _logger.error('Firestore error during sign up: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error during sign up: $e');
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        _logger.info('Signing out user: ${currentUser.uid}');

        // Update online status to false before signing out
        await _updateUserOnlineStatus(currentUser.uid, false);
      }

      await _firebaseAuth.signOut();
      _logger.info('Successfully signed out user');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error during sign out: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on FirebaseException catch (e) {
      _logger
          .error('Firestore error during sign out: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error during sign out: $e');
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No authenticated user found');
      }

      _logger.info('Getting current user: ${firebaseUser.uid}');

      // Get user profile from Firestore
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw const AuthException('User profile not found in database');
      }

      final userModel = UserModel.fromFirestore(userDoc);
      _logger.info('Successfully retrieved current user: ${userModel.id}');

      return userModel;
    } on FirebaseException catch (e) {
      _logger.error(
          'Firestore error getting current user: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error getting current user: $e');
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _logger.info('Auth state changed: User signed out');
        return null;
      }

      try {
        _logger
            .info('Auth state changed: User signed in - ${firebaseUser.uid}');

        // Get user profile from Firestore
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          _logger.warning(
              'User profile not found in Firestore for authenticated user: ${firebaseUser.uid}');
          return null;
        }

        // Update online status when user becomes authenticated
        await _updateUserOnlineStatus(firebaseUser.uid, true);

        final userModel = UserModel.fromFirestore(userDoc);
        return userModel.copyWith(isOnline: true);
      } catch (e) {
        _logger.error('Error in auth state changes stream: $e');
        return null;
      }
    });
  }

  @override
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No authenticated user found');
      }

      _logger.info('Updating user profile: ${firebaseUser.uid}');

      // Update Firebase Auth profile
      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.updatePhotoURL(photoUrl);

      // Prepare update data for Firestore
      final updateData = <String, dynamic>{};
      if (displayName != null) {
        updateData[FirebaseConstants.userDisplayNameField] = displayName;
      }
      if (photoUrl != null) {
        updateData[FirebaseConstants.userPhotoUrlField] = photoUrl;
      }
      updateData[FirebaseConstants.userLastSeenField] = Timestamp.now();

      // Update user profile in Firestore
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .update(updateData);

      // Get updated user profile
      final updatedUser = await getCurrentUser();
      _logger.info('Successfully updated user profile: ${updatedUser.id}');

      return updatedUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error updating profile: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on FirebaseException catch (e) {
      _logger
          .error('Firestore error updating profile: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error updating profile: $e');
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _updateUserOnlineStatus(userId, isOnline);
    } catch (e) {
      _logger.error('Error updating online status: $e');
      throw AuthException('Failed to update online status: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      _logger.info('Sending password reset email to: $email');

      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.info('Successfully sent password reset email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error sending password reset: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      _logger.error('Unexpected error sending password reset: $e');
      throw AuthException(
          'Failed to send password reset email: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No authenticated user found');
      }

      _logger.info('Deleting user account: ${firebaseUser.uid}');

      // Delete user profile from Firestore
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .delete();

      // Delete user from Firebase Auth
      await firebaseUser.delete();

      _logger.info('Successfully deleted user account');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error(
          'Firebase Auth error deleting account: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on FirebaseException catch (e) {
      _logger
          .error('Firestore error deleting account: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected error deleting account: $e');
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  /// Updates user's online status and last seen timestamp in Firestore
  Future<void> _updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.userIsOnlineField: isOnline,
        FirebaseConstants.userLastSeenField: Timestamp.now(),
      });

      _logger.info('Updated online status for user $userId: $isOnline');
    } on FirebaseException catch (e) {
      _logger.error('Error updating online status: ${e.code} - ${e.message}');
      throw AuthException('Failed to update online status: ${e.message}',
          code: e.code);
    }
  }

  /// Maps Firebase Auth errors to user-friendly messages
  String _mapFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
