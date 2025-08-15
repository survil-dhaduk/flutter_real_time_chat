import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
  });

  /// Validates email format
  static bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates display name
  static bool isValidDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty || trimmed.length < 2 || trimmed.length > 50) {
      return false;
    }
    // Check for invalid characters
    return !trimmed.contains('<') &&
        !trimmed.contains('>') &&
        !trimmed.contains('"') &&
        !trimmed.contains("'");
  }

  /// Validates password strength
  static bool isValidPassword(String password) {
    return password.length >= 6 &&
        password.length <= 128 &&
        password.contains(RegExp(r'[a-zA-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Validates photo URL format
  static bool isValidPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return true;
    final urlRegex = RegExp(r'^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$',
        caseSensitive: false);
    return urlRegex.hasMatch(photoUrl);
  }

  /// Checks if user is currently online
  bool get isCurrentlyOnline => isOnline;

  /// Checks if user was recently active (within last 5 minutes)
  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes <= 5;
  }

  /// Creates a copy with updated online status
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// Updates last seen timestamp and online status
  User updateLastSeen({bool? isOnline}) {
    return copyWith(
      lastSeen: DateTime.now(),
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        lastSeen,
        isOnline,
      ];
}
