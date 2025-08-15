import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';
import '../../../../core/constants/firebase_constants.dart';

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.name,
    required super.description,
    required super.createdBy,
    required super.createdAt,
    required super.participants,
    super.lastMessageId,
    super.lastMessageTime,
  });

  /// Creates ChatRoomModel from ChatRoom entity
  factory ChatRoomModel.fromEntity(ChatRoom chatRoom) {
    return ChatRoomModel(
      id: chatRoom.id,
      name: chatRoom.name,
      description: chatRoom.description,
      createdBy: chatRoom.createdBy,
      createdAt: chatRoom.createdAt,
      participants: chatRoom.participants,
      lastMessageId: chatRoom.lastMessageId,
      lastMessageTime: chatRoom.lastMessageTime,
    );
  }

  /// Creates ChatRoomModel from Firestore document
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoomModel(
      id: doc.id,
      name: data[FirebaseConstants.roomNameField] as String,
      description: data[FirebaseConstants.roomDescriptionField] as String,
      createdBy: data[FirebaseConstants.roomCreatedByField] as String,
      createdAt:
          (data[FirebaseConstants.roomCreatedAtField] as Timestamp).toDate(),
      participants: List<String>.from(
          data[FirebaseConstants.roomParticipantsField] as List),
      lastMessageId: data[FirebaseConstants.roomLastMessageIdField] as String?,
      lastMessageTime: data[FirebaseConstants.roomLastMessageTimeField] != null
          ? (data[FirebaseConstants.roomLastMessageTimeField] as Timestamp)
              .toDate()
          : null,
    );
  }

  /// Creates ChatRoomModel from JSON map
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json[FirebaseConstants.roomIdField] as String,
      name: json[FirebaseConstants.roomNameField] as String,
      description: json[FirebaseConstants.roomDescriptionField] as String,
      createdBy: json[FirebaseConstants.roomCreatedByField] as String,
      createdAt:
          DateTime.parse(json[FirebaseConstants.roomCreatedAtField] as String),
      participants: List<String>.from(
          json[FirebaseConstants.roomParticipantsField] as List),
      lastMessageId: json[FirebaseConstants.roomLastMessageIdField] as String?,
      lastMessageTime: json[FirebaseConstants.roomLastMessageTimeField] != null
          ? DateTime.parse(
              json[FirebaseConstants.roomLastMessageTimeField] as String)
          : null,
    );
  }

  /// Converts ChatRoomModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      FirebaseConstants.roomIdField: id,
      FirebaseConstants.roomNameField: name,
      FirebaseConstants.roomDescriptionField: description,
      FirebaseConstants.roomCreatedByField: createdBy,
      FirebaseConstants.roomCreatedAtField: createdAt.toIso8601String(),
      FirebaseConstants.roomParticipantsField: participants,
      FirebaseConstants.roomLastMessageIdField: lastMessageId,
      FirebaseConstants.roomLastMessageTimeField:
          lastMessageTime?.toIso8601String(),
    };
  }

  /// Converts ChatRoomModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      FirebaseConstants.roomNameField: name,
      FirebaseConstants.roomDescriptionField: description,
      FirebaseConstants.roomCreatedByField: createdBy,
      FirebaseConstants.roomCreatedAtField: Timestamp.fromDate(createdAt),
      FirebaseConstants.roomParticipantsField: participants,
      FirebaseConstants.roomLastMessageIdField: lastMessageId,
      FirebaseConstants.roomLastMessageTimeField:
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
    };
  }

  /// Creates a copy with updated fields
  @override
  ChatRoomModel copyWith({
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
    return ChatRoomModel(
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

  /// Adds a participant to the room
  @override
  ChatRoomModel addParticipant(String userId) {
    if (hasParticipant(userId)) return this;

    final updatedParticipants = List<String>.from(participants)..add(userId);
    return copyWith(participants: updatedParticipants);
  }

  /// Removes a participant from the room
  @override
  ChatRoomModel removeParticipant(String userId) {
    if (!hasParticipant(userId)) return this;

    final updatedParticipants = List<String>.from(participants)..remove(userId);
    return copyWith(participants: updatedParticipants);
  }

  /// Updates the last message information
  @override
  ChatRoomModel updateLastMessage(String messageId, DateTime messageTime) {
    return copyWith(
      lastMessageId: messageId,
      lastMessageTime: messageTime,
    );
  }
}
