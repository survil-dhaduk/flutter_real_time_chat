import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/message.dart';
import 'chat_remote_data_source.dart';

/// Implementation of ChatRemoteDataSource using Firebase Firestore
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .orderBy(FirebaseConstants.roomCreatedAtField, descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to get chat rooms: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error getting chat rooms: $e');
    }
  }

  @override
  Stream<List<ChatRoomModel>> getChatRoomsStream() {
    try {
      return _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .orderBy(FirebaseConstants.roomCreatedAtField, descending: true)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList();
      }).handleError((error) {
        if (error is FirebaseException) {
          throw ServerFailure('Failed to stream chat rooms: ${error.message}');
        }
        throw ServerFailure('Unexpected error streaming chat rooms: $error');
      });
    } catch (e) {
      throw ServerFailure('Failed to create chat rooms stream: $e');
    }
  }

  @override
  Future<ChatRoomModel> createChatRoom({
    required String name,
    required String description,
    required String createdBy,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw ValidationFailure('Room name cannot be empty');
      }
      if (createdBy.isEmpty) {
        throw ValidationFailure('Creator ID cannot be empty');
      }

      final now = DateTime.now();
      final roomData = <String, dynamic>{
        FirebaseConstants.roomNameField: name.trim(),
        FirebaseConstants.roomDescriptionField: description.trim(),
        FirebaseConstants.roomCreatedByField: createdBy,
        FirebaseConstants.roomCreatedAtField: Timestamp.fromDate(now),
        FirebaseConstants.roomParticipantsField: [createdBy],
        FirebaseConstants.roomLastMessageIdField: null,
        FirebaseConstants.roomLastMessageTimeField: null,
      };

      final docRef = await _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .add(roomData);

      // Return the created room with the generated ID
      return ChatRoomModel(
        id: docRef.id,
        name: name.trim(),
        description: description.trim(),
        createdBy: createdBy,
        createdAt: now,
        participants: [createdBy],
        lastMessageId: null,
        lastMessageTime: null,
      );
    } on ValidationFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to create chat room: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error creating chat room: $e');
    }
  }

  @override
  Future<void> joinChatRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      if (roomId.isEmpty || userId.isEmpty) {
        throw ValidationFailure('Room ID and User ID cannot be empty');
      }

      final roomRef = _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .doc(roomId);

      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw ServerFailure('Chat room not found');
        }

        final roomData = roomDoc.data()!;
        final participants = List<String>.from(
            roomData[FirebaseConstants.roomParticipantsField] as List);

        // Check if user is already a participant
        if (participants.contains(userId)) {
          return; // User already joined, no action needed
        }

        // Add user to participants
        participants.add(userId);

        transaction.update(roomRef, {
          FirebaseConstants.roomParticipantsField: participants,
        });
      });
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to join chat room: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error joining chat room: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    required String messageType,
  }) async {
    try {
      // Validate input
      if (roomId.isEmpty || senderId.isEmpty || content.trim().isEmpty) {
        throw ValidationFailure(
            'Room ID, sender ID, and content cannot be empty');
      }

      final now = DateTime.now();
      final messageData = <String, dynamic>{
        FirebaseConstants.messageRoomIdField: roomId,
        FirebaseConstants.messageSenderIdField: senderId,
        FirebaseConstants.messageContentField: content.trim(),
        FirebaseConstants.messageTypeField: messageType,
        FirebaseConstants.messageTimestampField: Timestamp.fromDate(now),
        FirebaseConstants.messageStatusField:
            FirebaseConstants.messageStatusSent,
        FirebaseConstants.messageReadByField: const <String, Timestamp>{},
      };

      // Send message and update room's last message info in a transaction
      late DocumentReference messageRef;
      await _firestore.runTransaction((transaction) async {
        // Add message to messages collection
        messageRef =
            _firestore.collection(FirebaseConstants.messagesCollection).doc();

        transaction.set(messageRef, messageData);

        // Update room's last message information
        final roomRef = _firestore
            .collection(FirebaseConstants.chatRoomsCollection)
            .doc(roomId);

        transaction.update(roomRef, {
          FirebaseConstants.roomLastMessageIdField: messageRef.id,
          FirebaseConstants.roomLastMessageTimeField: Timestamp.fromDate(now),
        });
      });

      // Update message status to delivered after successful storage
      await updateMessageStatus(
        messageId: messageRef.id,
        status: FirebaseConstants.messageStatusDelivered,
      );

      // Return the created message
      return MessageModel(
        id: messageRef.id,
        roomId: roomId,
        senderId: senderId,
        content: content.trim(),
        type: _parseMessageType(messageType),
        timestamp: now,
        status: MessageStatus.delivered,
        readBy: {},
      );
    } on ValidationFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to send message: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error sending message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessages(String roomId) {
    try {
      if (roomId.isEmpty) {
        throw const ValidationFailure('Room ID cannot be empty');
      }

      return _firestore
          .collection(FirebaseConstants.messagesCollection)
          .where(FirebaseConstants.messageRoomIdField, isEqualTo: roomId)
          .orderBy(FirebaseConstants.messageTimestampField, descending: false)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
      }).handleError((error) {
        if (error is FirebaseException) {
          throw ServerFailure('Failed to stream messages: ${error.message}');
        }
        throw ServerFailure('Unexpected error streaming messages: $error');
      });
    } catch (e) {
      throw ServerFailure('Failed to create messages stream: $e');
    }
  }

  /// Get messages with pagination support
  @override
  Future<List<MessageModel>> getMessagesPaginated({
    required String roomId,
    int? limit,
    String? lastMessageId,
  }) async {
    try {
      if (roomId.isEmpty) {
        throw const ValidationFailure('Room ID cannot be empty');
      }

      Query query = _firestore
          .collection(FirebaseConstants.messagesCollection)
          .where(FirebaseConstants.messageRoomIdField, isEqualTo: roomId)
          .orderBy(FirebaseConstants.messageTimestampField, descending: true);

      // Apply pagination
      if (lastMessageId != null) {
        final lastMessageDoc = await _firestore
            .collection(FirebaseConstants.messagesCollection)
            .doc(lastMessageId)
            .get();

        if (lastMessageDoc.exists) {
          query = query.startAfterDocument(lastMessageDoc);
        }
      }

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      final messages = querySnapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();

      // Reverse to get chronological order (oldest first)
      return messages.reversed.toList();
    } on ValidationFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to get paginated messages: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error getting paginated messages: $e');
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      if (messageId.isEmpty || userId.isEmpty) {
        throw ValidationFailure('Message ID and User ID cannot be empty');
      }

      final messageRef = _firestore
          .collection(FirebaseConstants.messagesCollection)
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);

        if (!messageDoc.exists) {
          throw ServerFailure('Message not found');
        }

        final messageData = messageDoc.data()!;
        final readByData = Map<String, dynamic>.from(
            messageData[FirebaseConstants.messageReadByField] as Map? ?? {});

        // Add user's read timestamp
        readByData[userId] = Timestamp.fromDate(DateTime.now());

        // Update message with read status
        transaction.update(messageRef, {
          FirebaseConstants.messageReadByField: readByData,
          FirebaseConstants.messageStatusField:
              FirebaseConstants.messageStatusRead,
        });
      });
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to mark message as read: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error marking message as read: $e');
    }
  }

  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    try {
      if (messageId.isEmpty || status.isEmpty) {
        throw ValidationFailure('Message ID and status cannot be empty');
      }

      await _firestore
          .collection(FirebaseConstants.messagesCollection)
          .doc(messageId)
          .update({
        FirebaseConstants.messageStatusField: status,
      });
    } on ValidationFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to update message status: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error updating message status: $e');
    }
  }

  @override
  Future<List<String>> getRoomParticipants(String roomId) async {
    try {
      if (roomId.isEmpty) {
        throw ValidationFailure('Room ID cannot be empty');
      }

      final roomDoc = await _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .doc(roomId)
          .get();

      if (!roomDoc.exists) {
        throw ServerFailure('Chat room not found');
      }

      final roomData = roomDoc.data()!;
      return List<String>.from(
          roomData[FirebaseConstants.roomParticipantsField] as List);
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to get room participants: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error getting room participants: $e');
    }
  }

  @override
  Future<void> leaveChatRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      if (roomId.isEmpty || userId.isEmpty) {
        throw ValidationFailure('Room ID and User ID cannot be empty');
      }

      final roomRef = _firestore
          .collection(FirebaseConstants.chatRoomsCollection)
          .doc(roomId);

      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw ServerFailure('Chat room not found');
        }

        final roomData = roomDoc.data()!;
        final participants = List<String>.from(
            roomData[FirebaseConstants.roomParticipantsField] as List);

        // Check if user is a participant
        if (!participants.contains(userId)) {
          throw ServerFailure('User is not a participant in this room');
        }

        // Remove user from participants
        participants.remove(userId);

        transaction.update(roomRef, {
          FirebaseConstants.roomParticipantsField: participants,
        });
      });
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure('Failed to leave chat room: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error leaving chat room: $e');
    }
  }

  /// Helper method to parse message type string to enum
  MessageType _parseMessageType(String typeString) {
    switch (typeString) {
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
}
