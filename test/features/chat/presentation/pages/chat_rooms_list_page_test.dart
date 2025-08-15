import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../../lib/features/chat/domain/entities/chat_room.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_bloc.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_event.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_state.dart';
import '../../../../../lib/features/chat/presentation/pages/chat_rooms_list_page.dart';
import '../../../../../lib/features/chat/presentation/widgets/chat_room_card.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

void main() {
  group('ChatRoomsListPage', () {
    late MockChatBloc mockChatBloc;

    setUp(() {
      mockChatBloc = MockChatBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: const ChatRoomsListPage(),
        ),
      );
    }

    testWidgets('should display app bar with title and create button',
        (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(2)); // AppBar + FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading',
        (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable(
            [const ChatLoading(operation: 'Loading chat rooms')]),
        initialState: const ChatLoading(operation: 'Loading chat rooms'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no chat rooms',
        (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
          )
        ]),
        initialState: const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('No chat rooms available'), findsOneWidget);
      expect(find.text('Create your first chat room to get started'),
          findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('should display chat rooms when available', (tester) async {
      // Arrange
      final chatRooms = [
        ChatRoom(
          id: '1',
          name: 'General',
          description: 'General discussion',
          createdBy: 'user1',
          createdAt: DateTime.now(),
          participants: ['user1', 'user2'],
        ),
        ChatRoom(
          id: '2',
          name: 'Tech Talk',
          description: 'Technology discussions',
          createdBy: 'user2',
          createdAt: DateTime.now(),
          participants: ['user1', 'user2', 'user3'],
        ),
      ];

      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          ChatCombinedState(
            chatRooms: chatRooms,
            currentMessages: const [],
          )
        ]),
        initialState: ChatCombinedState(
          chatRooms: chatRooms,
          currentMessages: const [],
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(ChatRoomCard), findsNWidgets(2));
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Tech Talk'), findsOneWidget);
    });

    testWidgets('should display error state when error occurs', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatError(
            message: 'Failed to load chat rooms',
            operation: 'load_chat_rooms',
          )
        ]),
        initialState: const ChatError(
          message: 'Failed to load chat rooms',
          operation: 'load_chat_rooms',
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Failed to load chat rooms'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should navigate to create room page when FAB is pressed',
        (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatCombinedState(
            chatRooms: [],
            currentMessages: [],
          )
        ]),
        initialState: const ChatCombinedState(
          chatRooms: [],
          currentMessages: [],
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Create Chat Room'), findsOneWidget);
    });

    testWidgets('should show success snackbar when room is created',
        (tester) async {
      // Arrange
      final chatRoom = ChatRoom(
        id: '1',
        name: 'New Room',
        description: 'A new room',
        createdBy: 'user1',
        createdAt: DateTime.now(),
        participants: ['user1'],
      );

      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatInitial(),
          ChatRoomCreated(chatRoom: chatRoom),
        ]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text('Chat room created successfully!'), findsOneWidget);
    });

    testWidgets('should show error snackbar when error occurs', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatInitial(),
          const ChatError(
            message: 'Failed to create room',
            operation: 'create_chat_room',
          ),
        ]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text('Failed to create room'), findsOneWidget);
    });
  });
}
