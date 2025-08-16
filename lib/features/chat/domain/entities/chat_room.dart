import 'package:equatable/equatable.dart';

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> participants;
  final String? lastMessageId;
  final DateTime? lastMessageTime;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.participants,
    this.lastMessageId,
    this.lastMessageTime,
  });

  /// Validates chat room name
  static bool isValidName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty &&
        trimmed.length >= 2 &&
        trimmed.length <= 100 &&
        !trimmed.contains(RegExp(r'[<>"' "']"));
  }

  /// Validates chat room description
  static bool isValidDescription(String description) {
    final trimmed = description.trim();
    return trimmed.length <= 500;
  }

  /// Checks if a user is a participant in this room
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Gets the number of participants
  int get participantCount => participants.length;

  /// Checks if the room has recent activity (within last 24 hours)
  bool get hasRecentActivity {
    if (lastMessageTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    return difference.inHours <= 24;
  }

  /// Checks if user is the creator of the room
  bool isCreatedBy(String userId) {
    return createdBy == userId;
  }

  /// Adds a participant to the room
  ChatRoom addParticipant(String userId) {
    if (hasParticipant(userId)) return this;

    final updatedParticipants = List<String>.from(participants)..add(userId);
    return copyWith(participants: updatedParticipants);
  }

  /// Removes a participant from the room
  ChatRoom removeParticipant(String userId) {
    if (!hasParticipant(userId)) return this;

    final updatedParticipants = List<String>.from(participants)..remove(userId);
    return copyWith(participants: updatedParticipants);
  }

  /// Updates the last message information
  ChatRoom updateLastMessage(String messageId, DateTime messageTime) {
    return copyWith(
      lastMessageId: messageId,
      lastMessageTime: messageTime,
    );
  }

  /// Creates a copy with updated fields
  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? participants,
    String? lastMessageId,
    DateTime? lastMessageTime,
    bool clearLastMessageTime = false,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageTime: clearLastMessageTime
          ? null
          : (lastMessageTime ?? this.lastMessageTime),
    );
  }

  /// Validates the entire chat room entity
  bool isValid() {
    return id.isNotEmpty &&
        isValidName(name) &&
        isValidDescription(description) &&
        createdBy.isNotEmpty &&
        participants.isNotEmpty &&
        participants.contains(createdBy);
  }

  factory ChatRoom.empty() => ChatRoom(
        id: '',
        name: '',
        description: '',
        createdBy: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0), // default to epoch
        participants: const [],
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdBy,
        createdAt,
        participants,
        lastMessageId,
        lastMessageTime,
      ];
}
