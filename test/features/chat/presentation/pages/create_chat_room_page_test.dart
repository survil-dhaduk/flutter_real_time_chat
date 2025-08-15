import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../../lib/features/chat/domain/entities/chat_room.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_bloc.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_event.dart';
import '../../../../../lib/features/chat/presentation/bloc/chat_state.dart';
import '../../../../../lib/features/chat/presentation/pages/create_chat_room_page.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

void main() {
  group('CreateChatRoomPage', () {
    late MockChatBloc mockChatBloc;

    setUp(() {
      mockChatBloc = MockChatBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: const CreateChatRoomPage(),
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
      expect(find.text('Create Chat Room'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('should display form fields', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Room Name *'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Room Guidelines'), findsOneWidget);
    });

    testWidgets('should validate required room name', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      // Assert
      expect(find.text('Room name is required'), findsOneWidget);
    });

    testWidgets('should validate minimum room name length', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextFormField).first, 'A');
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      // Assert
      expect(
          find.text('Room name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('should validate maximum room name length', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      final longName = 'A' * 101;

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextFormField).first, longName);
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      // Assert
      expect(
          find.text('Room name cannot exceed 100 characters'), findsOneWidget);
    });

    testWidgets('should validate invalid characters in room name',
        (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextFormField).first, 'Room<Name>');
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      // Assert
      expect(
          find.text('Room name contains invalid characters'), findsOneWidget);
    });

    testWidgets('should validate maximum description length', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      final longDescription = 'A' * 501;

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(
          find.byType(TextFormField).first, 'Valid Room Name');
      await tester.enterText(find.byType(TextFormField).last, longDescription);
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      // Assert
      expect(find.text('Description cannot exceed 500 characters'),
          findsOneWidget);
    });

    testWidgets('should show loading state when creating room', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([
          const ChatInitial(),
          const ChatLoading(operation: 'Creating chat room'),
        ]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text('Creating...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success message when room created',
        (tester) async {
      // Arrange
      final chatRoom = ChatRoom(
        id: '1',
        name: 'Test Room',
        description: 'Test Description',
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

    testWidgets('should show error message when creation fails',
        (tester) async {
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

    testWidgets('should display guidelines section', (tester) async {
      // Arrange
      whenListen(
        mockChatBloc,
        Stream.fromIterable([const ChatInitial()]),
        initialState: const ChatInitial(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Room Guidelines'), findsOneWidget);
      expect(find.text('Room names must be 2-100 characters long'),
          findsOneWidget);
      expect(
          find.text(
              'Descriptions are optional but help others understand the room purpose'),
          findsOneWidget);
      expect(
          find.text(
              'You will automatically become the room creator and first participant'),
          findsOneWidget);
      expect(find.text('Other users can join your room once it\'s created'),
          findsOneWidget);
    });
  });
}
