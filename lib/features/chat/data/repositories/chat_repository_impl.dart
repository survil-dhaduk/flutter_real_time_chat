import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/user_context_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/pagination_service.dart';
import '../../../../core/services/memory_management_service.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_room_model.dart';

/// Implementation of [ChatRepository] that handles chat operations
/// with proper error mapping, real-time data handling, caching, and offline support
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final UserContextService _userContextService;
  final CacheService _cacheService;
  final PaginationService _paginationService;
  final MemoryManagementService _memoryManagementService;
  final Logger _logger;

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Message>>> _messageStreamControllers =
      {};

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required UserContextService userContextService,
    required CacheService cacheService,
    required PaginationService paginationService,
    required MemoryManagementService memoryManagementService,
    Logger? logger,
  })  : _remoteDataSource = remoteDataSource,
        _userContextService = userContextService,
        _cacheService = cacheService,
        _paginationService = paginationService,
        _memoryManagementService = memoryManagementService,
        _logger = logger ?? const Logger();

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    try {
      _logger.info('ChatRepository: Getting chat rooms');

      // Try to get from remote first
      try {
        final chatRooms = await _remoteDataSource.getChatRooms();

        // Cache chat rooms for offline support
        await _cacheService.cacheChatRooms(chatRooms);
        _logger.info(
            'ChatRepository: Successfully retrieved and cached ${chatRooms.length} chat rooms');

        return Right(chatRooms);
      } on SocketException catch (e) {
        _logger.warning(
            'ChatRepository: Network error, trying cache: ${e.message}');

        // Try to get from cache
        final cachedRooms = await _cacheService.getCachedChatRooms();
        if (cachedRooms != null) {
          _logger.info(
              'ChatRepository: Returning ${cachedRooms.length} cached chat rooms');
          return Right(cachedRooms);
        }

        return const Left(NetworkFailure.general());
      }
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting chat rooms: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger.error(
          'ChatRepository: Server error getting chat rooms: ${e.message}');

      // Try to get from cache
      final cachedRooms = await _cacheService.getCachedChatRooms();
      if (cachedRooms != null) {
        _logger.info(
            'ChatRepository: Returning cached chat rooms due to server error');
        return Right(cachedRooms);
      }

      return Left(e);
    } catch (e) {
      _logger.error('ChatRepository: Unexpected error getting chat rooms: $e');
      return Left(ServerFailure('Failed to get chat rooms: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ChatRoom>> get chatRoomsStream {
    try {
      _logger.info('ChatRepository: Creating chat rooms stream');

      const listenerId = 'chat_rooms_stream';

      final stream = _remoteDataSource.getChatRoomsStream().map((chatRooms) {
        // Cache chat rooms for offline support
        _cacheService.cacheChatRooms(chatRooms);
        _logger.info(
            'ChatRepository: Chat rooms stream updated with ${chatRooms.length} rooms');
        return chatRooms.cast<ChatRoom>();
      }).handleError((error) {
        _logger.error('ChatRepository: Error in chat rooms stream: $error');
        // Re-throw the error to let the caller handle it
        throw error;
      });

      // Register the stream subscription for memory management
      final subscription = stream.listen((_) {});
      _memoryManagementService.registerListener(
        listenerId,
        subscription,
        description: 'Chat rooms real-time stream',
      );

      return stream;
    } catch (e) {
      _logger.error('ChatRepository: Error creating chat rooms stream: $e');

      // Return a stream that emits cached data if available
      return _getCachedChatRoomsStream();
    }
  }

  /// Get cached chat rooms as a stream
  Stream<List<ChatRoom>> _getCachedChatRoomsStream() async* {
    final cachedRooms = await _cacheService.getCachedChatRooms();
    if (cachedRooms != null) {
      yield cachedRooms.cast<ChatRoom>();
    } else {
      yield <ChatRoom>[];
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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      final chatRoom = await _remoteDataSource.createChatRoom(
        name: name,
        description: description,
        createdBy: currentUserId,
      );

      // Update cache with new room
      final cachedRooms =
          await _cacheService.getCachedChatRooms() ?? <ChatRoomModel>[];
      cachedRooms.insert(0, chatRoom);
      await _cacheService.cacheChatRooms(cachedRooms);

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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      await _remoteDataSource.joinChatRoom(
        roomId: roomId,
        userId: currentUserId,
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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      await _remoteDataSource.leaveChatRoom(
        roomId: roomId,
        userId: currentUserId,
      );

      // Remove from cached chat rooms if present
      final cachedRooms = await _cacheService.getCachedChatRooms();
      if (cachedRooms != null) {
        cachedRooms.removeWhere((room) => room.id == roomId);
        await _cacheService.cacheChatRooms(cachedRooms);
      }

      // Clear cached messages for this room
      await _cacheService.removeCachedMessages(roomId);

      // Remove pagination state
      _paginationService.removePagination(roomId);

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
      _logger.info(
          'ChatRepository: Getting messages for room: $roomId with pagination');

      // Validate input
      if (roomId.trim().isEmpty) {
        return const Left(ValidationFailure.emptyField('Room ID'));
      }

      // Initialize pagination if not already done
      if (_paginationService.getPaginationState(roomId) == null) {
        _paginationService.initializePagination(roomId, pageSize: limit ?? 20);
      }

      // Try to get from remote with pagination
      try {
        final messages = await _remoteDataSource.getMessagesPaginated(
          roomId: roomId,
          limit: limit,
          lastMessageId: lastMessageId,
        );

        // Update pagination state
        _paginationService.updatePaginationState(roomId, messages);

        // Cache messages for offline support
        await _cacheService.cacheMessages(roomId, messages);

        _logger.info(
            'ChatRepository: Successfully retrieved ${messages.length} messages with pagination');

        return Right(messages);
      } on SocketException catch (e) {
        _logger.warning(
            'ChatRepository: Network error, trying cache: ${e.message}');

        // Try to get from cache
        final cachedMessages = await _cacheService.getCachedMessages(roomId);
        if (cachedMessages != null) {
          _logger.info(
              'ChatRepository: Returning ${cachedMessages.length} cached messages');
          return Right(cachedMessages);
        }

        return const Left(NetworkFailure.general());
      }
    } on ValidationFailure catch (e) {
      _logger.error(
          'ChatRepository: Validation error getting messages: ${e.message}');
      return Left(e);
    } on ServerFailure catch (e) {
      _logger
          .error('ChatRepository: Server error getting messages: ${e.message}');

      // Return cached messages if available during server errors
      final cachedMessages = await _cacheService.getCachedMessages(roomId);
      if (cachedMessages != null) {
        _logger.info(
            'ChatRepository: Returning cached messages due to server error');
        return Right(cachedMessages);
      }

      return Left(e);
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

      final listenerId = 'messages_stream_$roomId';

      final stream = _remoteDataSource.getMessages(roomId).map((messages) {
        // Cache messages for offline support
        _cacheService.cacheMessages(roomId, messages);

        // Optimize message list to prevent memory issues
        final optimizedMessages =
            _paginationService.optimizeMessageList(messages);

        _logger.info(
            'ChatRepository: Messages stream updated with ${optimizedMessages.length} messages');
        return optimizedMessages.cast<Message>();
      }).handleError((error) {
        _logger.error('ChatRepository: Error in messages stream: $error');
        // Re-throw the error to let the caller handle it
        throw error;
      });

      // Register the stream subscription for memory management
      final subscription = stream.listen((_) {});
      _memoryManagementService.registerListener(
        listenerId,
        subscription,
        description: 'Messages real-time stream for room $roomId',
      );

      return stream;
    } catch (e) {
      _logger.error('ChatRepository: Error creating messages stream: $e');

      // Return a stream that emits cached messages if available
      return _getCachedMessagesStream(roomId);
    }
  }

  /// Get cached messages as a stream
  Stream<List<Message>> _getCachedMessagesStream(String roomId) async* {
    final cachedMessages = await _cacheService.getCachedMessages(roomId);
    if (cachedMessages != null) {
      yield cachedMessages.cast<Message>();
    } else {
      yield <Message>[];
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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      final message = await _remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: currentUserId,
        content: content,
        messageType: _messageTypeToString(type),
      );

      // Cache the new message
      await _cacheService.cacheMessage(roomId, message);

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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      await _remoteDataSource.markMessageAsRead(
        messageId: messageId,
        userId: currentUserId,
      );

      // Update cached message status
      final cachedMessages = await _cacheService.getCachedMessages(roomId);
      if (cachedMessages != null) {
        final messageIndex =
            cachedMessages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = cachedMessages[messageIndex]
              .markAsReadBy(currentUserId, DateTime.now());
          cachedMessages[messageIndex] = updatedMessage;
          await _cacheService.cacheMessages(roomId, cachedMessages);
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

      // Get current user ID
      final currentUserId = _userContextService.currentUserId;
      if (currentUserId == null) {
        return const Left(AuthFailure.notAuthenticated());
      }

      // Mark each message as read
      for (final message in messages) {
        await _remoteDataSource.markMessageAsRead(
          messageId: message.id,
          userId: currentUserId,
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
      final cachedRooms = await _cacheService.getCachedChatRooms();
      if (cachedRooms != null) {
        try {
          final cachedRoom =
              cachedRooms.firstWhere((room) => room.id == roomId);
          _logger.info('ChatRepository: Found room in cache: $roomId');
          return Right(cachedRoom);
        } catch (e) {
          // Room not found in cache, continue to remote fetch
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
    // Close stream controllers
    for (final controller in _messageStreamControllers.values) {
      controller.close();
    }
    _messageStreamControllers.clear();

    // Clean up memory management
    _memoryManagementService.dispose();

    // Clear pagination states
    _paginationService.clearAll();

    _logger.info('ChatRepository: Disposed successfully');
  }
}
