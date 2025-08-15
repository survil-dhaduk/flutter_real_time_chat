import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  file,
}

enum MessageStatus {
  sent,
  delivered,
  read,
}

class Message extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, DateTime> readBy;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.readBy,
  });

  /// Validates message content based on type
  bool isValid() {
    if (id.isEmpty || roomId.isEmpty || senderId.isEmpty) {
      return false;
    }

    switch (type) {
      case MessageType.text:
        return content.trim().isNotEmpty && content.length <= 1000;
      case MessageType.image:
      case MessageType.file:
        return content.isNotEmpty; // Should be a URL or file path
    }
  }

  /// Checks if message has been read by a specific user
  bool isReadBy(String userId) {
    return readBy.containsKey(userId);
  }

  /// Gets the read timestamp for a specific user
  DateTime? getReadTimestamp(String userId) {
    return readBy[userId];
  }

  /// Creates a copy with updated read status
  Message markAsReadBy(String userId, DateTime readTime) {
    final updatedReadBy = Map<String, DateTime>.from(readBy);
    updatedReadBy[userId] = readTime;

    return Message(
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

  /// Creates a copy with updated status
  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, DateTime>? readBy,
  }) {
    return Message(
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

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderId,
        content,
        type,
        timestamp,
        status,
        readBy,
      ];
}
