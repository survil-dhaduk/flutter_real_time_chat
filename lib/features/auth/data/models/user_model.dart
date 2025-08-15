import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../../../core/constants/firebase_constants.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.createdAt,
    required super.lastSeen,
    super.isOnline,
  });

  /// Creates UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
      isOnline: user.isOnline,
    );
  }

  /// Creates UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data[FirebaseConstants.userEmailField] as String,
      displayName: data[FirebaseConstants.userDisplayNameField] as String,
      photoUrl: data[FirebaseConstants.userPhotoUrlField] as String?,
      createdAt:
          (data[FirebaseConstants.userCreatedAtField] as Timestamp).toDate(),
      lastSeen:
          (data[FirebaseConstants.userLastSeenField] as Timestamp).toDate(),
      isOnline: data[FirebaseConstants.userIsOnlineField] as bool? ?? false,
    );
  }

  /// Creates UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json[FirebaseConstants.userIdField] as String,
      email: json[FirebaseConstants.userEmailField] as String,
      displayName: json[FirebaseConstants.userDisplayNameField] as String,
      photoUrl: json[FirebaseConstants.userPhotoUrlField] as String?,
      createdAt:
          DateTime.parse(json[FirebaseConstants.userCreatedAtField] as String),
      lastSeen:
          DateTime.parse(json[FirebaseConstants.userLastSeenField] as String),
      isOnline: json[FirebaseConstants.userIsOnlineField] as bool? ?? false,
    );
  }

  /// Converts UserModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      FirebaseConstants.userIdField: id,
      FirebaseConstants.userEmailField: email,
      FirebaseConstants.userDisplayNameField: displayName,
      FirebaseConstants.userPhotoUrlField: photoUrl,
      FirebaseConstants.userCreatedAtField: createdAt.toIso8601String(),
      FirebaseConstants.userLastSeenField: lastSeen.toIso8601String(),
      FirebaseConstants.userIsOnlineField: isOnline,
    };
  }

  /// Converts UserModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      FirebaseConstants.userEmailField: email,
      FirebaseConstants.userDisplayNameField: displayName,
      FirebaseConstants.userPhotoUrlField: photoUrl,
      FirebaseConstants.userCreatedAtField: Timestamp.fromDate(createdAt),
      FirebaseConstants.userLastSeenField: Timestamp.fromDate(lastSeen),
      FirebaseConstants.userIsOnlineField: isOnline,
    };
  }

  /// Creates a copy with updated fields
  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
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
  @override
  UserModel updateLastSeen({bool? isOnline}) {
    return copyWith(
      lastSeen: DateTime.now(),
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
