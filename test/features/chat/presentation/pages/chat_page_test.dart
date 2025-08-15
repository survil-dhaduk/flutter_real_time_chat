import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/bloc/chat_event.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';
import 'package:flutter_real_time_chat/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';

class MockChatBloc extends Mock implements ChatBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('ChatPage', () {
    late MockChatBloc mockChatBloc;
    late MockAuthBloc mockAuthBloc;
    late ChatRoom testChatRoom;
    late User testUser;

    setUp(() {
      mockChatBloc = MockChatBloc();
      mockAuthBloc = MockAuthBloc();

      testChatRoom = ChatRoom(
        id: 'room1',
        name: 'Test Room',
        description: 'A test chat room',
        createdBy: 'user1',
        createdAt: DateTime.now(),
        participants: const ['user1', 'user2'],
        lastMessageId: null,
        lastMessageTime: null,
      );

      testUser = User(
        id: 'user1',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      // Setup default states
      when(mockChatBloc.state).thenReturn(const ChatInitial());
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: testUser));
      when(mockChatBloc.stream)
          .thenAnswer((_) => Stream.value(const ChatInitial()));
      when(mockAuthBloc.stream)
          .thenAnswer((_) => Stream.value(AuthAuthenticated(user: testUser)));
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ChatBloc>.value(value: mockChatBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: ChatPage(chatRoom: testChatRoom),
        ),
      );
    }

    testWidgets('should display chat room name in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Room'), findsOneWidget);
      expect(find.text('2 participants'), findsOneWidget);
    });

    testWidgets('should display empty state when no messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Start the conversation by sending a message'),
          findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('should display message input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('should display messages when available',
        (WidgetTester tester) async {
      final messages = [
        Message(
          id: 'msg1',
          roomId: 'room1',
          senderId: 'user2',
          content: 'Hello!',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
          readBy: const {},
        ),
      ];

      when(mockChatBloc.state).thenReturn(
        ChatCombinedState(
          chatRooms: const [],
          currentRoom: testChatRoom,
          currentMessages: messages,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('No messages yet'), findsNothing);
    });

    testWidgets('should show loading indicator when loading',
        (WidgetTester tester) async {
      when(mockChatBloc.state)
          .thenReturn(const ChatLoading(operation: 'Loading messages'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading messages...'), findsOneWidget);
    });

    testWidgets('should send message when send button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter text in the message field
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));

      // Verify that the send message event was added
      verify(mockChatBloc.add(argThat(isA<SendMessage>()))).called(1);
    });

    testWidgets('should show attachment options when attach button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pumpAndSettle();

      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
    });

    testWidgets('should show room options when more button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Room Info'), findsOneWidget);
      expect(find.text('Participants'), findsOneWidget);
      expect(find.text('Leave Room'), findsOneWidget);
    });
  });
}
