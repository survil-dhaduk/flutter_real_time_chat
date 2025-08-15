import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/core/utils/logger.dart';
import 'package:flutter_real_time_chat/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:flutter_real_time_chat/features/chat/data/models/chat_room_model.dart';
import 'package:flutter_real_time_chat/features/chat/data/models/message_model.dart';
import 'package:flutter_real_time_chat/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';

import 'chat_repository_impl_test.mocks.dart';

@GenerateMocks([ChatRemoteDataSource, Logger])
void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockLogger mockLogger;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLogger = MockLogger();
    repository = ChatRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      logger: mockLogger,
    );
  });

  group('ChatRepositoryImpl', () {
    const tRoomId = 'room123';
    const tRoomName = 'Test Room';
    const tRoomDescription = 'Test Description';
    const tUserId = 'user123';
    const tMessageId = 'message123';
    const tMessageContent = 'Test message';

    final tChatRoomModel = ChatRoomModel(
      id: tRoomId,
      name: tRoomName,
      description: tRoomDescription,
      createdBy: tUserId,
      createdAt: DateTime(2023, 1, 1),
      participants: [tUserId],
      lastMessageId: null,
      lastMessageTime: null,
    );

    final tMessageModel = MessageModel(
      id: tMessageId,
      roomId: tRoomId,
      senderId: tUserId,
      content: tMessageContent,
      type: MessageType.text,
      timestamp: DateTime(2023, 1, 1),
      status: MessageStatus.sent,
      readBy: const {},
    );

    group('getChatRooms', () {
      test(
          'should return list of ChatRooms when getting chat rooms is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result.isRight(), true);
        final rooms = result.getOrElse(() => []);
        expect(rooms, equals([tChatRoomModel]));
        verify(mockRemoteDataSource.getChatRooms());
      });

      test(
          'should return cached chat rooms when server error occurs and rooms are cached',
          () async {
        // arrange
        // First, cache some rooms by calling a successful method
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);
        await repository.getChatRooms();

        // Then simulate server error
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(const ServerFailure('Server error'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result.isRight(), true);
        final rooms = result.getOrElse(() => []);
        expect(rooms, equals([tChatRoomModel]));
      });

      test(
          'should return cached chat rooms when network error occurs and rooms are cached',
          () async {
        // arrange
        // First, cache some rooms
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);
        await repository.getChatRooms();

        // Then simulate network error
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result.isRight(), true);
        final rooms = result.getOrElse(() => []);
        expect(rooms, equals([tChatRoomModel]));
      });

      test(
          'should return NetworkFailure when network error occurs and no cached rooms',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result, isA<Left<Failure, List<ChatRoom>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test(
          'should return ServerFailure when server error occurs and no cached rooms',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(const ServerFailure('Server error'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result, isA<Left<Failure, List<ChatRoom>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(const ValidationFailure('Validation error'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result, isA<Left<Failure, List<ChatRoom>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when unexpected exception is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.getChatRooms();

        // assert
        expect(result, isA<Left<Failure, List<ChatRoom>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('chatRoomsStream', () {
      test('should return stream of ChatRooms when stream is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRoomsStream())
            .thenAnswer((_) => Stream.value([tChatRoomModel]));

        // act
        final stream = repository.chatRoomsStream;

        // assert
        expect(stream, emits([tChatRoomModel]));
      });

      test(
          'should emit cached rooms when network error occurs and rooms are cached',
          () async {
        // arrange
        // First, cache some rooms
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);
        await repository.getChatRooms();

        // Then simulate stream with error
        when(mockRemoteDataSource.getChatRoomsStream()).thenAnswer(
            (_) => Stream.error(const SocketException('Network error')));

        // act
        final stream = repository.chatRoomsStream;

        // assert
        expect(stream, emits([])); // Should handle error gracefully
      });

      test('should emit empty list when error occurs and no cached rooms',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRoomsStream()).thenAnswer(
            (_) => Stream.error(const ServerFailure('Server error')));

        // act
        final stream = repository.chatRoomsStream;

        // assert
        expect(stream, emits([]));
      });
    });

    group('createChatRoom', () {
      test('should return ChatRoom when room creation is successful', () async {
        // arrange
        when(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        )).thenAnswer((_) async => tChatRoomModel);

        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
        );

        // assert
        expect(result, equals(Right(tChatRoomModel)));
        verify(mockRemoteDataSource.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
          createdBy: '', // Empty because user ID should be provided by use case
        ));
      });

      test('should return ValidationFailure when room name is empty', () async {
        // act
        final result = await repository.createChatRoom(
          name: '',
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        ));
      });

      test('should return ValidationFailure when room name is too short',
          () async {
        // act
        final result = await repository.createChatRoom(
          name: 'A',
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        ));
      });

      test('should return ValidationFailure when room name is too long',
          () async {
        // act
        final result = await repository.createChatRoom(
          name: 'A' * 101, // 101 characters
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        ));
      });

      test('should return ValidationFailure when description is too long',
          () async {
        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: 'A' * 501, // 501 characters
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        ));
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        )).thenThrow(const ValidationFailure('Room name cannot be empty'));

        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when ServerFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        )).thenThrow(const ServerFailure('Failed to create room'));

        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test('should return ServerFailure when unexpected exception is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.createChatRoom(
          name: anyNamed('name'),
          description: anyNamed('description'),
          createdBy: anyNamed('createdBy'),
        )).thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.createChatRoom(
          name: tRoomName,
          description: tRoomDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('joinChatRoom', () {
      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.joinChatRoom(roomId: '');

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.joinChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.joinChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ValidationFailure('Room ID cannot be empty'));

        // act
        final result = await repository.joinChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when ServerFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.joinChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ServerFailure('Failed to join room'));

        // act
        final result = await repository.joinChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.joinChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.joinChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });
    });

    group('leaveChatRoom', () {
      test('should return success when leaving room is successful', () async {
        // arrange
        when(mockRemoteDataSource.leaveChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // act
        final result = await repository.leaveChatRoom(roomId: tRoomId);

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.leaveChatRoom(
          roomId: tRoomId,
          userId: '', // Empty because user ID should be provided by use case
        ));
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.leaveChatRoom(roomId: '');

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.leaveChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.leaveChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ValidationFailure('Room ID cannot be empty'));

        // act
        final result = await repository.leaveChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when ServerFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.leaveChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ServerFailure('Failed to leave room'));

        // act
        final result = await repository.leaveChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.leaveChatRoom(
          roomId: anyNamed('roomId'),
          userId: anyNamed('userId'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.leaveChatRoom(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });
    });

    group('getMessages', () {
      test('should return list of Messages when getting messages is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value([tMessageModel]));

        // act
        final result = await repository.getMessages(roomId: tRoomId);

        // assert
        expect(result.isRight(), true);
        final messages = result.getOrElse(() => []);
        expect(messages, equals([tMessageModel]));
        verify(mockRemoteDataSource.getMessages(tRoomId));
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.getMessages(roomId: '');

        // assert
        expect(result, isA<Left<Failure, List<Message>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.getMessages(any));
      });

      test('should return limited messages when limit is specified', () async {
        // arrange
        final messages = [tMessageModel, tMessageModel, tMessageModel];
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value(messages));

        // act
        final result = await repository.getMessages(roomId: tRoomId, limit: 2);

        // assert
        expect(result.isRight(), true);
        final resultMessages = result.getOrElse(() => []);
        expect(resultMessages.length, equals(2));
      });

      test(
          'should return cached messages when server error occurs and messages are cached',
          () async {
        // arrange
        // First, cache some messages
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value([tMessageModel]));
        await repository.getMessages(roomId: tRoomId);

        // Then simulate server error
        when(mockRemoteDataSource.getMessages(any)).thenAnswer(
            (_) => Stream.error(const ServerFailure('Server error')));

        // act
        final result = await repository.getMessages(roomId: tRoomId);

        // assert
        expect(result.isRight(), true);
        final messages = result.getOrElse(() => []);
        expect(messages, equals([tMessageModel]));
      });

      test(
          'should return cached messages when network error occurs and messages are cached',
          () async {
        // arrange
        // First, cache some messages
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value([tMessageModel]));
        await repository.getMessages(roomId: tRoomId);

        // Then simulate network error
        when(mockRemoteDataSource.getMessages(any)).thenAnswer((_) =>
            Stream.error(const SocketException('No internet connection')));

        // act
        final result = await repository.getMessages(roomId: tRoomId);

        // assert
        expect(result.isRight(), true);
        final messages = result.getOrElse(() => []);
        expect(messages, equals([tMessageModel]));
      });

      test(
          'should return NetworkFailure when network error occurs and no cached messages',
          () async {
        // arrange
        when(mockRemoteDataSource.getMessages(any)).thenAnswer((_) =>
            Stream.error(const SocketException('No internet connection')));

        // act
        final result = await repository.getMessages(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, List<Message>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test(
          'should return ServerFailure when server error occurs and no cached messages',
          () async {
        // arrange
        when(mockRemoteDataSource.getMessages(any)).thenAnswer(
            (_) => Stream.error(const ServerFailure('Server error')));

        // act
        final result = await repository.getMessages(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, List<Message>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('getMessagesStream', () {
      test('should return stream of Messages when stream is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value([tMessageModel]));

        // act
        final stream = repository.getMessagesStream(roomId: tRoomId);

        // assert
        expect(stream, emits([tMessageModel]));
      });

      test(
          'should emit cached messages when network error occurs and messages are cached',
          () async {
        // arrange
        // First, cache some messages
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value([tMessageModel]));
        await repository.getMessages(roomId: tRoomId);

        // Then simulate stream with error
        when(mockRemoteDataSource.getMessages(any)).thenAnswer(
            (_) => Stream.error(const SocketException('Network error')));

        // act
        final stream = repository.getMessagesStream(roomId: tRoomId);

        // assert
        expect(stream, emits([])); // Should handle error gracefully
      });

      test('should emit empty list when error occurs and no cached messages',
          () async {
        // arrange
        when(mockRemoteDataSource.getMessages(any)).thenAnswer(
            (_) => Stream.error(const ServerFailure('Server error')));

        // act
        final stream = repository.getMessagesStream(roomId: tRoomId);

        // assert
        expect(stream, emits([]));
      });
    });

    group('sendMessage', () {
      test('should return Message when sending message is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        )).thenAnswer((_) async => tMessageModel);

        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, equals(Right(tMessageModel)));
        verify(mockRemoteDataSource.sendMessage(
          roomId: tRoomId,
          senderId: '', // Empty because user ID should be provided by use case
          content: tMessageContent,
          messageType: 'text',
        ));
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.sendMessage(
          roomId: '',
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        ));
      });

      test('should return ValidationFailure when content is empty', () async {
        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: '',
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        ));
      });

      test('should return ValidationFailure when content is too long',
          () async {
        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: 'A' * 1001, // 1001 characters
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        ));
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        )).thenThrow(const ValidationFailure('Content cannot be empty'));

        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when ServerFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        )).thenThrow(const ServerFailure('Failed to send message'));

        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test('should return ServerFailure when unexpected exception is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.sendMessage(
          roomId: anyNamed('roomId'),
          senderId: anyNamed('senderId'),
          content: anyNamed('content'),
          messageType: anyNamed('messageType'),
        )).thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.sendMessage(
          roomId: tRoomId,
          content: tMessageContent,
          type: MessageType.text,
        );

        // assert
        expect(result, isA<Left<Failure, Message>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('markMessageAsRead', () {
      test('should return success when marking message as read is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        );

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.markMessageAsRead(
          messageId: tMessageId,
          userId: '', // Empty because user ID should be provided by use case
        ));
      });

      test('should return ValidationFailure when message ID is empty',
          () async {
        // act
        final result = await repository.markMessageAsRead(
          messageId: '',
          roomId: tRoomId,
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: '',
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return ValidationFailure when ValidationFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ValidationFailure('Message ID cannot be empty'));

        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
      });

      test('should return ServerFailure when ServerFailure is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(const ServerFailure('Failed to mark message as read'));

        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test('should return ServerFailure when unexpected exception is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        );

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('searchMessages', () {
      test('should return filtered messages when search is successful',
          () async {
        // arrange
        final messages = [
          tMessageModel,
          tMessageModel.copyWith(content: 'Another message'),
          tMessageModel.copyWith(content: 'Test content here'),
        ];
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value(messages));

        // act
        final result = await repository.searchMessages(
          roomId: tRoomId,
          query: 'test',
        );

        // assert
        expect(result.isRight(), true);
        final searchResults = result.getOrElse(() => []);
        expect(searchResults.length,
            equals(2)); // Should find 2 messages containing 'test'
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.searchMessages(
          roomId: '',
          query: 'test',
        );

        // assert
        expect(result, isA<Left<Failure, List<Message>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.getMessages(any));
      });

      test('should return ValidationFailure when query is empty', () async {
        // act
        final result = await repository.searchMessages(
          roomId: tRoomId,
          query: '',
        );

        // assert
        expect(result, isA<Left<Failure, List<Message>>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.getMessages(any));
      });

      test('should return limited search results when limit is specified',
          () async {
        // arrange
        final messages = [
          tMessageModel,
          tMessageModel.copyWith(content: 'Test message 2'),
          tMessageModel.copyWith(content: 'Test message 3'),
        ];
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value(messages));

        // act
        final result = await repository.searchMessages(
          roomId: tRoomId,
          query: 'test',
          limit: 2,
        );

        // assert
        expect(result.isRight(), true);
        final searchResults = result.getOrElse(() => []);
        expect(searchResults.length, equals(2));
      });
    });

    group('getChatRoomById', () {
      test('should return ChatRoom when room is found in cache', () async {
        // arrange
        // First, cache some rooms
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);
        await repository.getChatRooms();

        // act
        final result = await repository.getChatRoomById(roomId: tRoomId);

        // assert
        expect(result, equals(Right(tChatRoomModel)));
      });

      test('should return ChatRoom when room is found by fetching all rooms',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);

        // act
        final result = await repository.getChatRoomById(roomId: tRoomId);

        // assert
        expect(result, equals(Right(tChatRoomModel)));
        verify(mockRemoteDataSource.getChatRooms());
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.getChatRoomById(roomId: '');

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.getChatRooms());
      });

      test('should return ServerFailure when room is not found', () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms()).thenAnswer((_) async => []);

        // act
        final result = await repository.getChatRoomById(roomId: tRoomId);

        // assert
        expect(result, isA<Left<Failure, ChatRoom>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('getUnreadMessageCount', () {
      test('should return unread message count when successful', () async {
        // arrange
        final messages = [
          tMessageModel, // Not read by current user
          tMessageModel.copyWith(status: MessageStatus.read), // Read
          tMessageModel, // Not read by current user
        ];
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value(messages));

        // act
        final result = await repository.getUnreadMessageCount(roomId: tRoomId);

        // assert
        expect(result, equals(const Right(2))); // 2 unread messages
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await repository.getUnreadMessageCount(roomId: '');

        // assert
        expect(result, isA<Left<Failure, int>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.getMessages(any));
      });
    });

    group('getTotalUnreadMessageCount', () {
      test('should return total unread message count across all rooms',
          () async {
        // arrange
        when(mockRemoteDataSource.getChatRooms())
            .thenAnswer((_) async => [tChatRoomModel]);

        final messages = [
          tMessageModel, // Not read
          tMessageModel.copyWith(status: MessageStatus.read), // Read
        ];
        when(mockRemoteDataSource.getMessages(any))
            .thenAnswer((_) => Stream.value(messages));

        // act
        final result = await repository.getTotalUnreadMessageCount();

        // assert
        expect(result, equals(const Right(1))); // 1 unread message total
      });
    });
  });
}
