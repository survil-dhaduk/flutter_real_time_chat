import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';
import '../../../../core/constants/firebase_constants.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.content,
    required super.type,
    required super.timestamp,
    required super.status,
    required super.readBy,
  });

  /// Creates MessageModel from Message entity
  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      content: message.content,
      type: message.type,
      timestamp: message.timestamp,
      status: message.status,
      readBy: message.readBy,
    );
  }

  /// Creates MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      roomId: data[FirebaseConstants.messageRoomIdField] as String,
      senderId: data[FirebaseConstants.messageSenderIdField] as String,
      content: data[FirebaseConstants.messageContentField] as String,
      type: _messageTypeFromString(
          data[FirebaseConstants.messageTypeField] as String),
      timestamp:
          (data[FirebaseConstants.messageTimestampField] as Timestamp).toDate(),
      status: _messageStatusFromString(
          data[FirebaseConstants.messageStatusField] as String),
      readBy: _parseReadByMap(
          data[FirebaseConstants.messageReadByField] as Map<String, dynamic>?),
    );
  }

  /// Creates MessageModel from JSON map
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json[FirebaseConstants.messageIdField] as String,
      roomId: json[FirebaseConstants.messageRoomIdField] as String,
      senderId: json[FirebaseConstants.messageSenderIdField] as String,
      content: json[FirebaseConstants.messageContentField] as String,
      type: _messageTypeFromString(
          json[FirebaseConstants.messageTypeField] as String),
      timestamp: DateTime.parse(
          json[FirebaseConstants.messageTimestampField] as String),
      status: _messageStatusFromString(
          json[FirebaseConstants.messageStatusField] as String),
      readBy: _parseReadByMapFromJson(
          json[FirebaseConstants.messageReadByField] as Map<String, dynamic>?),
    );
  }

  /// Converts MessageModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      FirebaseConstants.messageIdField: id,
      FirebaseConstants.messageRoomIdField: roomId,
      FirebaseConstants.messageSenderIdField: senderId,
      FirebaseConstants.messageContentField: content,
      FirebaseConstants.messageTypeField: _messageTypeToString(type),
      FirebaseConstants.messageTimestampField: timestamp.toIso8601String(),
      FirebaseConstants.messageStatusField: _messageStatusToString(status),
      FirebaseConstants.messageReadByField: _readByMapToJson(readBy),
    };
  }

  /// Converts MessageModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      FirebaseConstants.messageRoomIdField: roomId,
      FirebaseConstants.messageSenderIdField: senderId,
      FirebaseConstants.messageContentField: content,
      FirebaseConstants.messageTypeField: _messageTypeToString(type),
      FirebaseConstants.messageTimestampField: Timestamp.fromDate(timestamp),
      FirebaseConstants.messageStatusField: _messageStatusToString(status),
      FirebaseConstants.messageReadByField: _readByMapToFirestore(readBy),
    };
  }

  /// Creates a copy with updated fields
  @override
  MessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, DateTime>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
    );
  }

  /// Creates a copy with updated read status
  @override
  MessageModel markAsReadBy(String userId, DateTime readTime) {
    final updatedReadBy = Map<String, DateTime>.from(readBy);
    updatedReadBy[userId] = readTime;

    return MessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: timestamp,
      status: MessageStatus.read,
      readBy: updatedReadBy,
    );
  }

  // Helper methods for type conversion

  /// Converts MessageType enum to string
  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return FirebaseConstants.messageTypeText;
      case MessageType.image:
        return FirebaseConstants.messageTypeImage;
      case MessageType.file:
        return FirebaseConstants.messageTypeFile;
    }
  }

  /// Converts string to MessageType enum
  static MessageType _messageTypeFromString(String type) {
    switch (type) {
      case FirebaseConstants.messageTypeText:
        return MessageType.text;
      case FirebaseConstants.messageTypeImage:
        return MessageType.image;
      case FirebaseConstants.messageTypeFile:
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  /// Converts MessageStatus enum to string
  static String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return FirebaseConstants.messageStatusSent;
      case MessageStatus.delivered:
        return FirebaseConstants.messageStatusDelivered;
      case MessageStatus.read:
        return FirebaseConstants.messageStatusRead;
    }
  }

  /// Converts string to MessageStatus enum
  static MessageStatus _messageStatusFromString(String status) {
    switch (status) {
      case FirebaseConstants.messageStatusSent:
        return MessageStatus.sent;
      case FirebaseConstants.messageStatusDelivered:
        return MessageStatus.delivered;
      case FirebaseConstants.messageStatusRead:
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  /// Parses readBy map from Firestore
  static Map<String, DateTime> _parseReadByMap(
      Map<String, dynamic>? readByData) {
    if (readByData == null) return {};

    final Map<String, DateTime> readBy = {};
    readByData.forEach((userId, timestamp) {
      if (timestamp is Timestamp) {
        readBy[userId] = timestamp.toDate();
      }
    });
    return readBy;
  }

  /// Parses readBy map from JSON
  static Map<String, DateTime> _parseReadByMapFromJson(
      Map<String, dynamic>? readByData) {
    if (readByData == null) return {};

    final Map<String, DateTime> readBy = {};
    readByData.forEach((userId, timestamp) {
      if (timestamp is String) {
        readBy[userId] = DateTime.parse(timestamp);
      }
    });
    return readBy;
  }

  /// Converts readBy map to Firestore format
  static Map<String, Timestamp> _readByMapToFirestore(
      Map<String, DateTime> readBy) {
    final Map<String, Timestamp> firestoreReadBy = {};
    readBy.forEach((userId, dateTime) {
      firestoreReadBy[userId] = Timestamp.fromDate(dateTime);
    });
    return firestoreReadBy;
  }

  /// Converts readBy map to JSON format
  static Map<String, String> _readByMapToJson(Map<String, DateTime> readBy) {
    final Map<String, String> jsonReadBy = {};
    readBy.forEach((userId, dateTime) {
      jsonReadBy[userId] = dateTime.toIso8601String();
    });
    return jsonReadBy;
  }
}
