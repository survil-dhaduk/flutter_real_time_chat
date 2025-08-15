import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/create_chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/get_chat_rooms.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/get_messages.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/join_chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/mark_message_as_read.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/send_message.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_event.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_state.dart';

import 'chat_bloc_test.mocks.dart';

@GenerateMocks([
  GetChatRoomsUseCase,
  CreateChatRoomUseCase,
  JoinChatRoomUseCase,
  SendMessageUseCase,
  GetMessagesUseCase,
  MarkMessageAsReadUseCase,
  ChatBloc,
])
void main() {
  late ChatBloc chatBloc;
  late MockGetChatRoomsUseCase mockGetChatRoomsUseCase;
  late MockCreateChatRoomUseCase mockCreateChatRoomUseCase;
  late MockJoinChatRoomUseCase mockJoinChatRoomUseCase;
  late MockSendMessageUseCase mockSendMessageUseCase;
  late MockGetMessagesUseCase mockGetMessagesUseCase;
  late MockMarkMessageAsReadUseCase mockMarkMessageAsReadUseCase;

  // Test data
  final testChatRoom = ChatRoom(
    id: 'room1',
    name: 'Test Room',
    description: 'A test chat room',
    createdBy: 'user1',
    createdAt: DateTime.now(),
    participants: ['user1', 'user2'],
    lastMessageId: 'msg1',
    lastMessageTime: DateTime.now(),
  );

  final testMessage = Message(
    id: 'msg1',
    roomId: 'room1',
    senderId: 'user1',
    content: 'Hello World',
    type: MessageType.text,
    timestamp: DateTime.now(),
    status: MessageStatus.sent,
    readBy: {},
  );

  final testChatRooms = [testChatRoom];
  final testMessages = [testMessage];

  setUp(() {
    mockGetChatRoomsUseCase = MockGetChatRoomsUseCase();
    mockCreateChatRoomUseCase = MockCreateChatRoomUseCase();
    mockJoinChatRoomUseCase = MockJoinChatRoomUseCase();
    mockSendMessageUseCase = MockSendMessageUseCase();
    mockGetMessagesUseCase = MockGetMessagesUseCase();
    mockMarkMessageAsReadUseCase = MockMarkMessageAsReadUseCase();

    // Set up default stubs for stream methods
    when(mockGetMessagesUseCase.getMessagesStream(any))
        .thenAnswer((_) => const Stream.empty());
    when(mockGetChatRoomsUseCase.getChatRoomsStream())
        .thenAnswer((_) => const Stream.empty());

    chatBloc = ChatBloc(
      getChatRoomsUseCase: mockGetChatRoomsUseCase,
      createChatRoomUseCase: mockCreateChatRoomUseCase,
      joinChatRoomUseCase: mockJoinChatRoomUseCase,
      sendMessageUseCase: mockSendMessageUseCase,
      getMessagesUseCase: mockGetMessagesUseCase,
      markMessageAsReadUseCase: mockMarkMessageAsReadUseCase,
    );
  });

  tearDown(() {
    chatBloc.close();
  });

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(chatBloc.state, equals(const ChatInitial()));
    });

    group('LoadChatRooms', () {
      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatCombinedState] when LoadChatRooms succeeds',
        build: () {
          when(mockGetChatRoomsUseCase.call())
              .thenAnswer((_) async => Right(testChatRooms));
          return chatBloc;
        },
        act: (bloc) => bloc.add(const LoadChatRooms()),
        expect: () => [
          const ChatLoading(operation: 'Loading chat rooms'),
          ChatCombinedState(
            chatRooms: testChatRooms,
            currentMessages: const [],
          ),
        ],
        verify: (_) {
          verify(mockGetChatRoomsUseCase.call()).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatError] when LoadChatRooms fails',
        build: () {
          when(mockGetChatRoomsUseCase.call()).thenAnswer(
              (_) async => const Left(ServerFailure('Server error')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(const LoadChatRooms()),
        expect: () => [
          const ChatLoading(operation: 'Loading chat rooms'),
          const ChatError(
            message: 'Server error',
            operation: 'load_chat_rooms',
            previousState: ChatLoading(operation: 'Loading chat rooms'),
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'updates existing ChatCombinedState when LoadChatRooms succeeds',
        build: () {
          when(mockGetChatRoomsUseCase.call())
              .thenAnswer((_) async => Right(testChatRooms));
          return chatBloc;
        },
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) => bloc.add(const LoadChatRooms()),
        expect: () => [
          const ChatLoading(operation: 'Loading chat rooms'),
          ChatCombinedState(
            chatRooms: testChatRooms,
            currentMessages: const [],
          ),
        ],
      );
    });

    group('CreateChatRoom', () {
      const createChatRoomEvent = CreateChatRoom(
        name: 'New Room',
        description: 'A new chat room',
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatRoomCreated] when CreateChatRoom succeeds',
        build: () {
          when(mockCreateChatRoomUseCase.call(any))
              .thenAnswer((_) async => Right(testChatRoom));
          when(mockGetChatRoomsUseCase.call())
              .thenAnswer((_) async => Right(testChatRooms));
          return chatBloc;
        },
        act: (bloc) => bloc.add(createChatRoomEvent),
        expect: () => [
          const ChatLoading(operation: 'Creating chat room'),
          ChatRoomCreated(chatRoom: testChatRoom),
          const ChatLoading(operation: 'Loading chat rooms'),
          ChatCombinedState(
            chatRooms: testChatRooms,
            currentMessages: const [],
          ),
        ],
        verify: (_) {
          verify(mockCreateChatRoomUseCase.call(any)).called(1);
          verify(mockGetChatRoomsUseCase.call()).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatError] when CreateChatRoom fails',
        build: () {
          when(mockCreateChatRoomUseCase.call(any)).thenAnswer(
              (_) async => const Left(ValidationFailure('Invalid name')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(createChatRoomEvent),
        expect: () => [
          const ChatLoading(operation: 'Creating chat room'),
          const ChatError(
            message: 'Invalid name',
            operation: 'create_chat_room',
            previousState: ChatLoading(operation: 'Creating chat room'),
          ),
        ],
      );
    });

    group('JoinChatRoom', () {
      const joinChatRoomEvent = JoinChatRoom(roomId: 'room1');

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatCombinedState] when JoinChatRoom succeeds',
        build: () {
          when(mockJoinChatRoomUseCase.call(any))
              .thenAnswer((_) async => Right(testChatRoom));
          when(mockGetMessagesUseCase.call(any))
              .thenAnswer((_) async => Right(testMessages));
          return chatBloc;
        },
        act: (bloc) => bloc.add(joinChatRoomEvent),
        expect: () => [
          const ChatLoading(operation: 'Joining chat room'),
          ChatCombinedState(
            chatRooms: const [],
            currentRoom: testChatRoom,
            currentMessages: testMessages,
          ),
        ],
        verify: (_) {
          verify(mockJoinChatRoomUseCase.call(any)).called(1);
          verify(mockGetMessagesUseCase.call(any)).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatError] when JoinChatRoom fails',
        build: () {
          when(mockJoinChatRoomUseCase.call(any)).thenAnswer(
              (_) async => const Left(ServerFailure('Room not found')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(joinChatRoomEvent),
        expect: () => [
          const ChatLoading(operation: 'Joining chat room'),
          const ChatError(
            message: 'Room not found',
            operation: 'join_chat_room',
            previousState: ChatLoading(operation: 'Joining chat room'),
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatError] when GetMessages fails after successful join',
        build: () {
          when(mockJoinChatRoomUseCase.call(any))
              .thenAnswer((_) async => Right(testChatRoom));
          when(mockGetMessagesUseCase.call(any)).thenAnswer((_) async =>
              const Left(ServerFailure('Failed to load messages')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(joinChatRoomEvent),
        expect: () => [
          const ChatLoading(operation: 'Joining chat room'),
          const ChatError(
            message: 'Failed to load messages',
            operation: 'load_initial_messages',
            previousState: ChatLoading(operation: 'Joining chat room'),
          ),
        ],
      );
    });

    group('LoadMessages', () {
      const loadMessagesEvent = LoadMessages(roomId: 'room1', limit: 50);

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, MessagesLoaded] when LoadMessages succeeds',
        build: () {
          when(mockGetMessagesUseCase.call(any))
              .thenAnswer((_) async => Right(testMessages));
          return chatBloc;
        },
        act: (bloc) => bloc.add(loadMessagesEvent),
        expect: () => [
          const ChatLoading(operation: 'Loading messages'),
          MessagesLoaded(
            roomId: 'room1',
            messages: testMessages,
            hasMoreMessages: false,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'updates existing ChatCombinedState when LoadMessages succeeds',
        build: () {
          when(mockGetMessagesUseCase.call(any))
              .thenAnswer((_) async => Right(testMessages));
          return chatBloc;
        },
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) => bloc.add(loadMessagesEvent),
        expect: () => [
          const ChatLoading(operation: 'Loading messages'),
          ChatCombinedState(
            chatRooms: const [],
            currentMessages: testMessages,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatLoading, ChatError] when LoadMessages fails',
        build: () {
          when(mockGetMessagesUseCase.call(any)).thenAnswer(
              (_) async => const Left(ServerFailure('Failed to load')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(loadMessagesEvent),
        expect: () => [
          const ChatLoading(operation: 'Loading messages'),
          const ChatError(
            message: 'Failed to load',
            operation: 'load_messages',
            previousState: ChatInitial(),
          ),
        ],
      );
    });

    group('SendMessage', () {
      const sendMessageEvent = SendMessage(
        roomId: 'room1',
        content: 'Hello World',
        type: MessageType.text,
      );

      blocTest<ChatBloc, ChatState>(
        'emits [MessageSent] when SendMessage succeeds',
        build: () {
          when(mockSendMessageUseCase.call(any))
              .thenAnswer((_) async => Right(testMessage));
          return chatBloc;
        },
        act: (bloc) => bloc.add(sendMessageEvent),
        expect: () => [
          MessageSent(message: testMessage),
        ],
        verify: (_) {
          verify(mockSendMessageUseCase.call(any)).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatError] when SendMessage fails',
        build: () {
          when(mockSendMessageUseCase.call(any)).thenAnswer(
              (_) async => const Left(ValidationFailure('Message too long')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(sendMessageEvent),
        expect: () => [
          const ChatError(
            message: 'Message too long',
            operation: 'send_message',
            previousState: ChatInitial(),
          ),
        ],
      );
    });

    group('MessageReceived', () {
      final messageReceivedEvent = MessageReceived(message: testMessage);

      blocTest<ChatBloc, ChatState>(
        'updates ChatCombinedState when MessageReceived and message belongs to current room',
        build: () => chatBloc,
        seed: () => ChatCombinedState(
          chatRooms: const [],
          currentRoom: testChatRoom,
          currentMessages: const [],
        ),
        act: (bloc) => bloc.add(messageReceivedEvent),
        expect: () => [
          ChatCombinedState(
            chatRooms: const [],
            currentRoom: testChatRoom,
            currentMessages: [testMessage],
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'updates MessagesLoaded when MessageReceived and message belongs to current room',
        build: () => chatBloc,
        seed: () => const MessagesLoaded(
          roomId: 'room1',
          messages: [],
        ),
        act: (bloc) => bloc.add(messageReceivedEvent),
        expect: () => [
          MessagesLoaded(
            roomId: 'room1',
            messages: [testMessage],
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'does not update MessagesLoaded when MessageReceived for different room',
        build: () => chatBloc,
        seed: () => const MessagesLoaded(
          roomId: 'room2',
          messages: [],
        ),
        act: (bloc) => bloc.add(messageReceivedEvent),
        expect: () => [],
      );
    });

    group('MarkMessageAsRead', () {
      const markMessageEvent = MarkMessageAsRead(
        messageId: 'msg1',
        roomId: 'room1',
      );

      blocTest<ChatBloc, ChatState>(
        'emits [MessagesMarkedAsRead] when MarkMessageAsRead succeeds',
        build: () {
          when(mockMarkMessageAsReadUseCase.call(any))
              .thenAnswer((_) async => const Right(null));
          return chatBloc;
        },
        act: (bloc) => bloc.add(markMessageEvent),
        expect: () => [
          const MessagesMarkedAsRead(
            roomId: 'room1',
            messageIds: ['msg1'],
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatError] when MarkMessageAsRead fails',
        build: () {
          when(mockMarkMessageAsReadUseCase.call(any)).thenAnswer(
              (_) async => const Left(ServerFailure('Failed to mark as read')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(markMessageEvent),
        expect: () => [
          const ChatError(
            message: 'Failed to mark as read',
            operation: 'mark_message_as_read',
            previousState: ChatInitial(),
          ),
        ],
      );
    });

    group('MarkAllMessagesAsRead', () {
      const markAllMessagesEvent = MarkAllMessagesAsRead(roomId: 'room1');

      blocTest<ChatBloc, ChatState>(
        'emits [MessagesMarkedAsRead] when MarkAllMessagesAsRead succeeds with ChatCombinedState',
        build: () {
          when(mockMarkMessageAsReadUseCase.markAllMessagesAsRead(any))
              .thenAnswer((_) async => const Right(null));
          return chatBloc;
        },
        seed: () => ChatCombinedState(
          chatRooms: const [],
          currentMessages: testMessages,
        ),
        act: (bloc) => bloc.add(markAllMessagesEvent),
        expect: () => [
          MessagesMarkedAsRead(
            roomId: 'room1',
            messageIds: testMessages.map((m) => m.id).toList(),
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [MessagesMarkedAsRead] when MarkAllMessagesAsRead succeeds with MessagesLoaded',
        build: () {
          when(mockMarkMessageAsReadUseCase.markAllMessagesAsRead(any))
              .thenAnswer((_) async => const Right(null));
          return chatBloc;
        },
        seed: () => MessagesLoaded(
          roomId: 'room1',
          messages: testMessages,
        ),
        act: (bloc) => bloc.add(markAllMessagesEvent),
        expect: () => [
          MessagesMarkedAsRead(
            roomId: 'room1',
            messageIds: testMessages.map((m) => m.id).toList(),
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatError] when MarkAllMessagesAsRead fails',
        build: () {
          when(mockMarkMessageAsReadUseCase.markAllMessagesAsRead(any))
              .thenAnswer((_) async =>
                  const Left(ServerFailure('Failed to mark all as read')));
          return chatBloc;
        },
        act: (bloc) => bloc.add(markAllMessagesEvent),
        expect: () => [
          const ChatError(
            message: 'Failed to mark all as read',
            operation: 'mark_all_messages_as_read',
            previousState: ChatInitial(),
          ),
        ],
      );
    });

    group('Real-time message listening', () {
      late StreamController<List<Message>> messagesStreamController;

      setUp(() {
        messagesStreamController = StreamController<List<Message>>();
      });

      tearDown(() {
        messagesStreamController.close();
      });

      blocTest<ChatBloc, ChatState>(
        'starts listening to messages and updates state when StartListeningToMessages is added',
        build: () {
          when(mockGetMessagesUseCase.getMessagesStream(any))
              .thenAnswer((_) => messagesStreamController.stream);
          return chatBloc;
        },
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) {
          bloc.add(const StartListeningToMessages(roomId: 'room1'));
        },
        expect: () => [
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
            isListeningToMessages: true,
          ),
        ],
        verify: (_) {
          verify(mockGetMessagesUseCase.getMessagesStream('room1')).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'stops listening to messages when StopListeningToMessages is added',
        build: () {
          when(mockGetMessagesUseCase.getMessagesStream(any))
              .thenAnswer((_) => messagesStreamController.stream);
          return chatBloc;
        },
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) {
          bloc.add(const StartListeningToMessages(roomId: 'room1'));
          bloc.add(const StopListeningToMessages(roomId: 'room1'));
        },
        expect: () => [
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
            isListeningToMessages: true,
          ),
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
            isListeningToMessages: false,
          ),
        ],
      );
    });

    group('Real-time chat rooms listening', () {
      late StreamController<List<ChatRoom>> chatRoomsStreamController;

      setUp(() {
        chatRoomsStreamController = StreamController<List<ChatRoom>>();
      });

      tearDown(() {
        chatRoomsStreamController.close();
      });

      blocTest<ChatBloc, ChatState>(
        'starts listening to chat rooms and updates state when StartListeningToChatRooms is added',
        build: () {
          when(mockGetChatRoomsUseCase.getChatRoomsStream())
              .thenAnswer((_) => chatRoomsStreamController.stream);
          return chatBloc;
        },
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) {
          bloc.add(const StartListeningToChatRooms());
        },
        expect: () => [
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
            isListeningToChatRooms: true,
          ),
        ],
        verify: (_) {
          verify(mockGetChatRoomsUseCase.getChatRoomsStream()).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'stops listening to chat rooms when StopListeningToChatRooms is added',
        build: () => chatBloc,
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
          isListeningToChatRooms: true,
        ),
        act: (bloc) {
          bloc.add(const StopListeningToChatRooms());
        },
        expect: () => [
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
            isListeningToChatRooms: false,
          ),
        ],
      );
    });

    group('ChatRoomsUpdated', () {
      final chatRoomsUpdatedEvent = ChatRoomsUpdated(chatRooms: testChatRooms);

      blocTest<ChatBloc, ChatState>(
        'updates ChatCombinedState when ChatRoomsUpdated is added',
        build: () => chatBloc,
        seed: () => const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
        act: (bloc) => bloc.add(chatRoomsUpdatedEvent),
        expect: () => [
          ChatCombinedState(
            chatRooms: testChatRooms,
            currentMessages: const [],
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'creates ChatCombinedState when ChatRoomsUpdated is added and state is not ChatCombinedState',
        build: () => chatBloc,
        act: (bloc) => bloc.add(chatRoomsUpdatedEvent),
        expect: () => [
          ChatCombinedState(
            chatRooms: testChatRooms,
            currentMessages: const [],
          ),
        ],
      );
    });
  });
}
