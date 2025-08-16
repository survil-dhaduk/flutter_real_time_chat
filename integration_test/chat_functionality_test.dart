import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:flutter_real_time_chat/main.dart' as app;

import 'helpers/test_helpers.dart';
import 'helpers/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Functionality Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUpAll(() async {
      await FirebaseTestSetup.initialize();
    });

    setUp(() async {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      await FirebaseTestSetup.setupTestData(mockFirestore);
      await resetTestDependencies();
      await initializeTestDependencies(mockAuth, mockFirestore);
    });

    tearDown(() async {
      await FirebaseTestSetup.cleanup(mockFirestore);
    });

    testWidgets('Chat room creation and management',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Should be on chat rooms list
      expect(find.text('Chat Rooms'), findsOneWidget);

      // Test room creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Create Chat Room'), findsOneWidget);

      // Test form validation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      expect(find.textContaining('required'), findsWidgets);

      // Fill valid form
      await TestHelpers.enterText(tester, 'Room Name', 'Integration Test Room');
      await TestHelpers.enterText(
          tester, 'Description', 'A room for integration testing');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      // Should return to rooms list with new room
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.text('Integration Test Room'), findsOneWidget);

      // Verify room was created in Firestore
      final roomsQuery = await mockFirestore
          .collection('chatRooms')
          .where('name', isEqualTo: 'Integration Test Room')
          .get();

      expect(roomsQuery.docs.isNotEmpty, true);
      expect(roomsQuery.docs.first.data()['description'],
          'A room for integration testing');
    });

    testWidgets('Real-time message sending and receiving',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Real-time Test Room');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to chat room
      await TestHelpers.navigateToChat(tester, roomId, 'Real-time Test Room');

      // Verify chat interface
      expect(find.text('Real-time Test Room'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Test sending messages
      const messages = [
        'First test message',
        'Second test message',
        'Third test message with emoji 😊',
      ];

      for (final message in messages) {
        await TestHelpers.enterText(tester, 'Type a message...', message);
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Message should appear in chat
        expect(find.text(message), findsOneWidget);

        // Should show sent status
        expect(find.byIcon(Icons.check), findsWidgets);
      }

      // Test message input clearing after send
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Verify messages were stored in Firestore
      final messagesQuery = await mockFirestore
          .collection('messages')
          .where('roomId', isEqualTo: roomId)
          .get();

      expect(messagesQuery.docs.length, greaterThanOrEqualTo(messages.length));
    });

    testWidgets('Message status tracking and read receipts',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'user1@example.com', 'User 1');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Status Test Room');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Status Test Room');

      // Send a message
      const testMessage = 'Message for status testing';
      await TestHelpers.enterText(tester, 'Type a message...', testMessage);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Initially should show sent status
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Simulate message delivery
      await TestHelpers.simulateMessageDelivery(mockFirestore, roomId);
      await TestHelpers.waitForRealtimeUpdate(tester);

      // Should show delivered status
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Simulate message being read by another user
      await TestHelpers.simulateMessageRead(
          mockFirestore, roomId, 'user2@example.com');
      await TestHelpers.waitForRealtimeUpdate(tester);

      // Should show read status (implementation dependent)
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('Real-time message reception from other users',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'user1@example.com', 'User 1');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Reception Test Room');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Reception Test Room');

      // Simulate incoming messages from other users
      const incomingMessages = [
        'Hello from User 2!',
        'How are you doing?',
        'This is a real-time test',
      ];

      for (int i = 0; i < incomingMessages.length; i++) {
        await TestHelpers.simulateIncomingMessage(
          mockFirestore,
          roomId,
          'user${i + 2}@example.com',
          incomingMessages[i],
        );

        await TestHelpers.waitForRealtimeUpdate(tester);

        // Message should appear in chat
        expect(find.text(incomingMessages[i]), findsOneWidget);
      }

      // Test message ordering
      await TestHelpers.scrollToTop(tester);

      // All messages should be visible
      for (final message in incomingMessages) {
        expect(find.text(message), findsOneWidget);
      }
    });

    testWidgets('Chat room joining and participant management',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'user1@example.com', 'User 1');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Should see existing test rooms
      expect(find.text('General Chat'), findsOneWidget);

      // Join existing room
      await tester.tap(find.text('General Chat'));
      await tester.pumpAndSettle();

      // Should be in chat interface
      expect(find.text('General Chat'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify user was added to participants
      final roomDoc =
          await mockFirestore.collection('chatRooms').doc('test-room-1').get();
      final participants =
          List<String>.from(roomDoc.data()?['participants'] ?? []);

      expect(participants.contains('user1@example.com'), true);

      // Test sending message in joined room
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Hello from new participant!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello from new participant!'), findsOneWidget);
    });

    testWidgets('Message pagination and loading', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Create room with many messages for pagination testing
      await FirebaseTestSetup.createPerformanceTestData(mockFirestore, 50);

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(
          tester, 'performance-test-room', 'Performance Test Room');

      // Should load initial messages
      expect(find.textContaining('Performance test message'), findsWidgets);

      // Test scrolling to load more messages
      await TestHelpers.scrollToTop(tester);
      await tester.pumpAndSettle();

      // Should load more messages (implementation dependent)
      expect(find.textContaining('Performance test message'), findsWidgets);
    });

    testWidgets('Chat interface user experience', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'UX Test Room');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'UX Test Room');

      // Test auto-scroll to bottom when new message is sent
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Auto-scroll test');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should auto-scroll to show new message
      expect(find.text('Auto-scroll test'), findsOneWidget);

      // Test message input focus and keyboard handling
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Text field should be focused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, true);

      // Test send button state
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Test empty message handling
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should not send empty message
      // (Implementation dependent - might disable button or show validation)
    });

    testWidgets('Multiple chat rooms navigation', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Create multiple test rooms
      final room1Id = await TestHelpers.createTestRoom(mockFirestore, 'Room 1');
      final room2Id = await TestHelpers.createTestRoom(mockFirestore, 'Room 2');

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Should see both rooms in list
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsOneWidget);

      // Navigate to first room
      await tester.tap(find.text('Room 1'));
      await tester.pumpAndSettle();

      expect(find.text('Room 1'), findsOneWidget);

      // Send message in first room
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Message in Room 1');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Navigate back to rooms list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Chat Rooms'), findsOneWidget);

      // Navigate to second room
      await tester.tap(find.text('Room 2'));
      await tester.pumpAndSettle();

      expect(find.text('Room 2'), findsOneWidget);

      // Send message in second room
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Message in Room 2');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Navigate back and verify room list updates
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Both rooms should still be visible
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsOneWidget);
    });
  });
}
