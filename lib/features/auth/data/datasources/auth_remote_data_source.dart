import '../models/user_model.dart';

export 'auth_remote_data_source_impl.dart';

/// Abstract interface for authentication remote data source
abstract class AuthRemoteDataSource {
  /// Signs in a user with email and password using Firebase Auth
  ///
  /// Returns [UserModel] on successful authentication
  /// Throws [AuthException] on authentication failure
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Signs up a new user with email, password, and display name
  ///
  /// Creates user in Firebase Auth and stores profile in Firestore
  /// Returns [UserModel] on successful registration
  /// Throws [AuthException] on registration failure
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs out the current user from Firebase Auth
  ///
  /// Updates user's online status to false in Firestore
  /// Throws [AuthException] on sign out failure
  Future<void> signOut();

  /// Gets the current authenticated user from Firebase Auth
  ///
  /// Returns [UserModel] if user is authenticated
  /// Throws [AuthException] if user is not authenticated
  Future<UserModel> getCurrentUser();

  /// Stream of authentication state changes from Firebase Auth
  ///
  /// Emits [UserModel] when user is authenticated
  /// Emits [null] when user is not authenticated
  Stream<UserModel?> get authStateChanges;

  /// Updates the current user's profile information in Firebase Auth and Firestore
  ///
  /// Returns [UserModel] with updated information
  /// Throws [AuthException] on update failure
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Updates the user's online status in Firestore
  ///
  /// Throws [AuthException] on update failure
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  });

  /// Sends a password reset email to the specified email address
  ///
  /// Throws [AuthException] on failure to send email
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Deletes the current user's account from Firebase Auth and Firestore
  ///
  /// Throws [AuthException] on deletion failure
  Future<void> deleteAccount();
}

/// Custom exception for authentication data source errors
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}
