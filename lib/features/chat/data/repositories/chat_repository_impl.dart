import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

/// Implementation of [ChatRepository] that handles chat operations
/// with proper error mapping, real-time data handling, and offline support
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // Cache for offline support
  List<ChatRoomModel>? _cachedChatRooms;
  final Map<String, List<MessageModel>> _cachedMessages = {};
  final Map<String, StreamController<List<Message>>> _messageStreamControllers =
      {};

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    Logger? logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger ?? const Logger();

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    try {
      _logger.info('ChatRepository: Getting chat rooms');

      final chatRooms = await _remoteDataSource.getChatRooms();

      // Cache chat rooms for offline support
      _cachedChatRooms = chatRooms;
      _logger.info(
          'ChatRepository: Successfully retrieved ${chatRooms.length} chat rooms');

      return Right(chatRooms);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting chat rooms: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error getting chat rooms: ${e.message}');

      // Return cached data if available during server errors
      if (_cachedChatRooms != null) {
        _logger.info(
            'ChatRepository: Returning cached chat rooms due to server error');
        return Right(_cachedChatRooms!);
      }

      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error getting chat rooms: ${e.message}');

      // Return cached data if available during network issues
      if (_cachedChatRooms != null) {
        _logger.info(
            'ChatRepository: Returning cached chat rooms due to network error');
        return Right(_cachedChatRooms!);
      }

      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error getting chat rooms: $e');
      return Left(ServerFailure('Failed to get chat rooms: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ChatRoom>> get chatRoomsStream {
    try {
      _logger.info('ChatRepository: Creating chat rooms stream');

      return _remoteDataSource.getChatRoomsStream().map((chatRooms) {
        // Cache chat rooms for offline support
        _cachedChatRooms = chatRooms;
        _logger.info(
            'ChatRepository: Chat rooms stream updated with ${chatRooms.length} rooms');
        return chatRooms.cast<ChatRoom>();
      }).handleError((error) {
        _logger.error('ChatRepository: Error in chat rooms stream: $error');
        // Re-throw the error to let the caller handle it
        throw error;
      });
    } catch (e) {
      _logger.error('ChatRepository: Error creating chat rooms stream: $e');

      // Return a stream that emits cached data if available, otherwise empty list
      return Stream.value(_cachedChatRooms?.cast<ChatRoom>() ?? <ChatRoom>[]);
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String name,
    required String description,
  }) async {
    try {
      _logger.info('ChatRepository: Creating chat room: $name');

      // Validate input
      final validationResult = _validateChatRoomInput(name, description);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Get current user ID (this should be provided by the use case layer)
      // For now, we'll assume it's handled by the data source
      final chatRoom = await _remoteDataSource.createChatRoom(
        name: name,
        description: description,
        createdBy: '', // This should be provided by the calling layer
      );

      // Update cached chat rooms
      if (_cachedChatRooms != null) {
        _cachedChatRooms!.insert(0, chatRoom);
      }

      _logger.info(
          'ChatRepository: Successfully created chat room: ${chatRoom.id}');
      return Right(chatRoom);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error creating chat room: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error creating chat room: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error creating chat room: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error creating chat room: $e');
      return Left(ServerFailure('Failed to create chat room: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> joinChatRoom({
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Joining chat room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Get current user ID (this should be provided by the use case layer)
      await _remoteDataSource.joinChatRoom(
        roomId: roomId,
        userId: '', // This should be provided by the calling layer
      );

      // Get updated room information
      final roomResult = await getChatRoomById(roomId: roomId);
      if (roomResult.isLeft()) {
        return roomResult;
      }

      final chatRoom = roomResult.getOrElse(() => throw Exception('No room'));
      _logger.info(
          'ChatRepository: Successfully joined chat room: ${chatRoom.id}');

      return Right(chatRoom);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error joining chat room: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error joining chat room: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error joining chat room: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error joining chat room: $e');
      return Left(ServerFailure('Failed to join chat room: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveChatRoom({
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Leaving chat room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      await _remoteDataSource.leaveChatRoom(
        roomId: roomId,
        userId: '', // This should be provided by the calling layer
      );

      // Remove from cached chat rooms if present
      if (_cachedChatRooms != null) {
        _cachedChatRooms!.removeWhere((room) => room.id == roomId);
      }

      // Clear cached messages for this room
      _cachedMessages.remove(roomId);

      // Close message stream controller for this room
      _messageStreamControllers[roomId]?.close();
      _messageStreamControllers.remove(roomId);

      _logger.info('ChatRepository: Successfully left chat room: $roomId');
      return const Right(null);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error leaving chat room: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error leaving chat room: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error leaving chat room: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error leaving chat room: $e');
      return Left(ServerFailure('Failed to leave chat room: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String roomId,
    int? limit,
    String? lastMessageId,
  }) async {
    try {
      _logger.info('ChatRepository: Getting messages for room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // For now, we'll use the stream-based approach since the data source provides streams
      // In a real implementation, you might want to add pagination support to the data source
      final messages = await _remoteDataSource.getMessages(roomId).first;

      // Apply limit if specified
      List<MessageModel> limitedMessages = messages;
      if (limit != null && limit > 0) {
        limitedMessages = messages.take(limit).toList();
      }

      // Cache messages for offline support
      _cachedMessages[roomId] = limitedMessages;
      _logger.info(
          'ChatRepository: Successfully retrieved ${limitedMessages.length} messages');

      return Right(limitedMessages);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting messages: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger
          .error('ChatRepository: Server error getting messages: ${e.message}');

      // Return cached messages if available during server errors
      if (_cachedMessages.containsKey(roomId)) {
        _logger.info(
            'ChatRepository: Returning cached messages due to server error');
        return Right(_cachedMessages[roomId]!);
      }

      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error getting messages: ${e.message}');

      // Return cached messages if available during network issues
      if (_cachedMessages.containsKey(roomId)) {
        _logger.info(
            'ChatRepository: Returning cached messages due to network error');
        return Right(_cachedMessages[roomId]!);
      }

      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error getting messages: $e');
      return Left(ServerFailure('Failed to get messages: ${e.toString()}'));
    }
  }

  @override
  Stream<List<Message>> getMessagesStream({
    required String roomId,
  }) {
    try {
      _logger
          .info('ChatRepository: Creating messages stream for room: $roomId');

      return _remoteDataSource.getMessages(roomId).map((messages) {
        // Cache messages for offline support
        _cachedMessages[roomId] = messages;
        _logger.info(
            'ChatRepository: Messages stream updated with ${messages.length} messages');
        return messages.cast<Message>();
      }).handleError((error) {
        _logger.error('ChatRepository: Error in messages stream: $error');
        // Re-throw the error to let the caller handle it
        throw error;
      });
    } catch (e) {
      _logger.error('ChatRepository: Error creating messages stream: $e');

      // Return a stream that emits cached messages if available, otherwise empty list
      return Stream.value(
          _cachedMessages[roomId]?.cast<Message>() ?? <Message>[]);
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String roomId,
    required String content,
    required MessageType type,
  }) async {
    try {
      _logger.info('ChatRepository: Sending message to room: $roomId');

      // Validate input
      final validationResult = _validateMessageInput(roomId, content);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final message = await _remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: '', // This should be provided by the calling layer
        content: content,
        messageType: _messageTypeToString(type),
      );

      // Add to cached messages
      if (_cachedMessages.containsKey(roomId)) {
        _cachedMessages[roomId]!.add(message);
      }

      _logger.info('ChatRepository: Successfully sent message: ${message.id}');
      return Right(message);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error sending message: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger
          .error('ChatRepository: Server error sending message: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger
          .error('ChatRepository: Network error sending message: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error sending message: $e');
      return Left(ServerFailure('Failed to send message: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead({
    required String messageId,
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Marking message as read: $messageId');

      // Validate input
      if (messageId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Message ID'));
      }
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      await _remoteDataSource.markMessageAsRead(
        messageId: messageId,
        userId: '', // This should be provided by the calling layer
      );

      // Update cached message status
      if (_cachedMessages.containsKey(roomId)) {
        final messageIndex =
            _cachedMessages[roomId]!.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = _cachedMessages[roomId]![messageIndex]
              .markAsReadBy('', DateTime.now());
          _cachedMessages[roomId]![messageIndex] = updatedMessage;
        }
      }

      _logger.info(
          'ChatRepository: Successfully marked message as read: $messageId');
      return const Right(null);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error marking message as read: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error marking message as read: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error marking message as read: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error(
          'ChatRepository: Unexpected error marking message as read: $e');
      return Left(
          ServerFailure('Failed to mark message as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllMessagesAsRead({
    required String roomId,
  }) async {
    try {
      _logger.info(
          'ChatRepository: Marking all messages as read in room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Get all messages in the room and mark them as read
      final messagesResult = await getMessages(roomId: roomId);
      if (messagesResult.isLeft()) {
        return Left(messagesResult.fold(
            (failure) => failure, (_) => const ServerFailure.general()));
      }

      final messages = messagesResult.getOrElse(() => <Message>[]);

      // Mark each message as read
      for (final message in messages) {
        await _remoteDataSource.markMessageAsRead(
          messageId: message.id,
          userId: '', // This should be provided by the calling layer
        );
      }

      _logger.info(
          'ChatRepository: Successfully marked all messages as read in room: $roomId');
      return const Right(null);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error marking all messages as read: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error marking all messages as read: ${e.message}');
      return Left(e);
    } on SocketException catch (e) {
      _logger.error(
          'ChatRepository: Network error marking all messages as read: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error(
          'ChatRepository: Unexpected error marking all messages as read: $e');
      return Left(ServerFailure(
          'Failed to mark all messages as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Message>> updateMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      _logger.info('ChatRepository: Updating message: $messageId');

      // Validate input
      if (messageId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Message ID'));
      }
      if (newContent.trim().isEmpty) {
        return const Left(ValidationFailure.invalidMessageContent());
      }

      // Note: This functionality is not implemented in the data source
      // In a real implementation, you would add this to the data source
      _logger.warning(
          'ChatRepository: Message update not implemented in data source');
      return const Left(ServerFailure('Message update not supported'));
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error updating message: $e');
      return Left(ServerFailure('Failed to update message: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Deleting message: $messageId');

      // Validate input
      if (messageId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Message ID'));
      }
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Note: This functionality is not implemented in the data source
      // In a real implementation, you would add this to the data source
      _logger.warning(
          'ChatRepository: Message deletion not implemented in data source');
      return const Left(ServerFailure('Message deletion not supported'));
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error deleting message: $e');
      return Left(ServerFailure('Failed to delete message: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadMessageCount({
    required String roomId,
  }) async {
    try {
      _logger.info(
          'ChatRepository: Getting unread message count for room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Get messages and count unread ones
      final messagesResult = await getMessages(roomId: roomId);
      if (messagesResult.isLeft()) {
        return Left(messagesResult.fold(
            (failure) => failure, (_) => const ServerFailure.general()));
      }

      final messages = messagesResult.getOrElse(() => <Message>[]);
      // For testing purposes, count messages that don't have status 'read'
      // In a real implementation, this would check if the current user has read the message
      final unreadCount = messages
          .where((message) => message.status != MessageStatus.read)
          .length;

      _logger.info(
          'ChatRepository: Found $unreadCount unread messages in room: $roomId');
      return Right(unreadCount);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting unread count: ${e.message}');
      return Left(e);
    } catch (e) {
      _logger
          .error('ChatRepository: Unexpected error getting unread count: $e');
      return Left(
          ServerFailure('Failed to get unread message count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalUnreadMessageCount() async {
    try {
      _logger.info('ChatRepository: Getting total unread message count');

      // Get all chat rooms
      final roomsResult = await getChatRooms();
      if (roomsResult.isLeft()) {
        return Left(roomsResult.fold(
            (failure) => failure, (_) => const ServerFailure.general()));
      }

      final rooms = roomsResult.getOrElse(() => <ChatRoom>[]);
      int totalUnreadCount = 0;

      // Count unread messages in each room
      for (final room in rooms) {
        final unreadCountResult = await getUnreadMessageCount(roomId: room.id);
        if (unreadCountResult.isRight()) {
          totalUnreadCount += unreadCountResult.getOrElse(() => 0);
        }
      }

      _logger.info(
          'ChatRepository: Total unread message count: $totalUnreadCount');
      return Right(totalUnreadCount);
    } catch (e) {
      _logger.error(
          'ChatRepository: Unexpected error getting total unread count: $e');
      return Left(ServerFailure(
          'Failed to get total unread message count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> searchMessages({
    required String roomId,
    required String query,
    int? limit,
  }) async {
    try {
      _logger.info(
          'ChatRepository: Searching messages in room: $roomId with query: $query');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }
      if (query.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Search query'));
      }

      // Get all messages and filter locally
      // In a real implementation, you might want to add server-side search
      final messagesResult = await getMessages(roomId: roomId);
      if (messagesResult.isLeft()) {
        return messagesResult;
      }

      final messages = messagesResult.getOrElse(() => <Message>[]);
      final searchResults = messages
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Apply limit if specified
      if (limit != null && limit > 0) {
        return Right(searchResults.take(limit).toList());
      }

      _logger.info(
          'ChatRepository: Found ${searchResults.length} messages matching query');
      return Right(searchResults);
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error searching messages: ${e.message}');
      return Left(e);
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error searching messages: $e');
      return Left(ServerFailure('Failed to search messages: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> getChatRoomById({
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Getting chat room by ID: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // First check cached rooms
      if (_cachedChatRooms != null) {
        final cachedRoom = _cachedChatRooms!.firstWhere(
          (room) => room.id == roomId,
          orElse: () => throw StateError('Room not found'),
        );
        if (cachedRoom.id == roomId) {
          _logger.info('ChatRepository: Found room in cache: $roomId');
          return Right(cachedRoom);
        }
      }

      // If not in cache, get all rooms and find the one we need
      final roomsResult = await getChatRooms();
      if (roomsResult.isLeft()) {
        return Left(roomsResult.fold(
            (failure) => failure, (_) => const ServerFailure.general()));
      }

      final rooms = roomsResult.getOrElse(() => <ChatRoom>[]);
      final room = rooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => throw StateError('Room not found'),
      );

      _logger.info('ChatRepository: Successfully retrieved chat room: $roomId');
      return Right(room);
    } on StateError {
      _logger.error('ChatRepository: Chat room not found: $roomId');
      return const Left(ServerFailure('Chat room not found'));
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting chat room: ${e.message}');
      return Left(e);
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error getting chat room: $e');
      return Left(ServerFailure('Failed to get chat room: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
  }) async {
    try {
      _logger.info('ChatRepository: Updating chat room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Note: This functionality is not implemented in the data source
      // In a real implementation, you would add this to the data source
      _logger.warning(
          'ChatRepository: Chat room update not implemented in data source');
      return const Left(ServerFailure('Chat room update not supported'));
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error updating chat room: $e');
      return Left(ServerFailure('Failed to update chat room: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChatRoom({
    required String roomId,
  }) async {
    try {
      _logger.info('ChatRepository: Deleting chat room: $roomId');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Note: This functionality is not implemented in the data source
      // In a real implementation, you would add this to the data source
      _logger.warning(
          'ChatRepository: Chat room deletion not implemented in data source');
      return const Left(ServerFailure('Chat room deletion not supported'));
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error deleting chat room: $e');
      return Left(ServerFailure('Failed to delete chat room: ${e.toString()}'));
    }
  }

  /// Validates chat room input parameters
  ValidationFailure? _validateChatRoomInput(String name, String description) {
    if (name.trim().isEmpty) {
      return const ValidationFailure.emptyField('Room name');
    }

    if (name.trim().length < 2) {
      return const ValidationFailure.invalidRoomName();
    }

    if (name.trim().length > 100) {
      return const ValidationFailure.fieldTooLong('Room name', 100);
    }

    if (description.length > 500) {
      return const ValidationFailure.fieldTooLong('Room description', 500);
    }

    return null;
  }

  /// Validates message input parameters
  ValidationFailure? _validateMessageInput(String roomId, String content) {
    if (roomId.trim().isEmpty) {
      return const ValidationFailure.emptyField('Room ID');
    }

    if (content.trim().isEmpty) {
      return const ValidationFailure.invalidMessageContent();
    }

    if (content.trim().length > 1000) {
      return const ValidationFailure.fieldTooLong('Message content', 1000);
    }

    return null;
  }

  /// Converts MessageType enum to string
  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }

  /// Disposes resources and closes stream controllers
  void dispose() {
    for (final controller in _messageStreamControllers.values) {
      controller.close();
    }
    _messageStreamControllers.clear();
    _cachedChatRooms = null;
    _cachedMessages.clear();
  }
}
