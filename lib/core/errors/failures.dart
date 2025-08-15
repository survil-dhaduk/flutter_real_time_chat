import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure that occurs when there's a server-side error
class ServerFailure extends Failure {
  const ServerFailure(super.message);

  /// Creates a ServerFailure with a default message
  const ServerFailure.general()
      : super('Server error occurred. Please try again later.');

  /// Creates a ServerFailure for Firebase-specific errors
  const ServerFailure.firebase(String firebaseError)
      : super('Firebase error: $firebaseError');
}

/// Failure that occurs when there's a network connectivity issue
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  /// Creates a NetworkFailure with a default message
  const NetworkFailure.general()
      : super(
            'Network connection failed. Please check your internet connection.');

  /// Creates a NetworkFailure for timeout scenarios
  const NetworkFailure.timeout()
      : super('Request timed out. Please try again.');
}

/// Failure that occurs during authentication processes
class AuthFailure extends Failure {
  const AuthFailure(super.message);

  /// Creates an AuthFailure for invalid credentials
  const AuthFailure.invalidCredentials() : super('Invalid email or password.');

  /// Creates an AuthFailure for user not found
  const AuthFailure.userNotFound() : super('No user found with this email.');

  /// Creates an AuthFailure for email already in use
  const AuthFailure.emailAlreadyInUse()
      : super('An account already exists with this email.');

  /// Creates an AuthFailure for weak password
  const AuthFailure.weakPassword()
      : super('Password is too weak. Please choose a stronger password.');

  /// Creates an AuthFailure for user not authenticated
  const AuthFailure.notAuthenticated()
      : super('User is not authenticated. Please sign in.');

  /// Creates an AuthFailure for account disabled
  const AuthFailure.accountDisabled()
      : super('This account has been disabled.');

  /// Creates an AuthFailure for too many requests
  const AuthFailure.tooManyRequests()
      : super('Too many failed attempts. Please try again later.');
}

/// Failure that occurs when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  /// Creates a ValidationFailure for invalid email format
  const ValidationFailure.invalidEmail()
      : super('Please enter a valid email address.');

  /// Creates a ValidationFailure for invalid password
  const ValidationFailure.invalidPassword()
      : super(
            'Password must be at least 6 characters long and contain both letters and numbers.');

  /// Creates a ValidationFailure for invalid display name
  const ValidationFailure.invalidDisplayName()
      : super(
            'Display name must be between 2-50 characters and cannot contain special characters.');

  /// Creates a ValidationFailure for invalid room name
  const ValidationFailure.invalidRoomName()
      : super(
            'Room name must be between 2-100 characters and cannot contain special characters.');

  /// Creates a ValidationFailure for invalid message content
  const ValidationFailure.invalidMessageContent()
      : super('Message cannot be empty and must be less than 1000 characters.');

  /// Creates a ValidationFailure for empty field
  const ValidationFailure.emptyField(String fieldName)
      : super('$fieldName cannot be empty.');

  /// Creates a ValidationFailure for field too long
  const ValidationFailure.fieldTooLong(String fieldName, int maxLength)
      : super('$fieldName cannot exceed $maxLength characters.');
}
