import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:flutter_real_time_chat/main.dart' as app;
import 'package:flutter_real_time_chat/injection/injection.dart';
import 'package:flutter_real_time_chat/core/routing/route_names.dart';

import 'helpers/test_helpers.dart';
import 'helpers/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real-Time Chat App Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUpAll(() async {
      // Initialize Firebase for testing
      await FirebaseTestSetup.initialize();
    });

    setUp(() async {
      // Reset Firebase mocks for each test
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();

      // Setup test data
      await FirebaseTestSetup.setupTestData(mockFirestore);

      // Reset dependency injection
      await resetTestDependencies();
      await initializeTestDependencies(mockAuth, mockFirestore);
    });

    tearDown(() async {
      // Clean up after each test
      await FirebaseTestSetup.cleanup(mockFirestore);
    });

    testWidgets('Complete user authentication flow',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should start at splash screen
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to login page for unauthenticated user
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Test registration flow
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Should be on register page
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Join the conversation'), findsOneWidget);

      // Fill registration form
      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Display Name', 'Test User');
      await TestHelpers.enterText(tester, 'Password', 'password123');
      await TestHelpers.enterText(tester, 'Confirm Password', 'password123');

      // Submit registration
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Should navigate to chat rooms list after successful registration
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Test logout
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Should return to login page
      expect(find.text('Welcome Back'), findsOneWidget);

      // Test login flow
      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should be back at chat rooms list
      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('Chat room creation and joining workflow',
        (WidgetTester tester) async {
      // Setup authenticated user
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should start at chat rooms list for authenticated user
      expect(find.text('Chat Rooms'), findsOneWidget);

      // Test room creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should be on create room page
      expect(find.text('Create Chat Room'), findsOneWidget);

      // Fill room creation form
      await TestHelpers.enterText(tester, 'Room Name', 'Test Room');
      await TestHelpers.enterText(tester, 'Description', 'A test chat room');

      // Create room
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      // Should return to rooms list with new room
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.text('Test Room'), findsOneWidget);

      // Test joining room
      await tester.tap(find.text('Test Room'));
      await tester.pumpAndSettle();

      // Should be in chat interface
      expect(find.text('Test Room'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Message input
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Real-time message sending and receiving',
        (WidgetTester tester) async {
      // Setup authenticated user and room
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to chat room
      await TestHelpers.navigateToChat(tester, roomId, 'Test Room');

      // Test sending message
      const testMessage = 'Hello, this is a test message!';
      await TestHelpers.enterText(tester, 'Type a message...', testMessage);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should appear in chat
      expect(find.text(testMessage), findsOneWidget);

      // Test message status indicators
      expect(find.byIcon(Icons.check), findsOneWidget); // Sent status

      // Simulate message delivery
      await TestHelpers.simulateMessageDelivery(mockFirestore, roomId);
      await tester.pumpAndSettle();

      // Should show delivered status
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Test sending multiple messages
      for (int i = 1; i <= 3; i++) {
        await TestHelpers.enterText(tester, 'Type a message...', 'Message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Message $i'), findsOneWidget);
      }

      // Test message ordering (newest at bottom)
      final messages = tester.widgetList<Text>(find.byType(Text));
      final messageTexts = messages
          .map((widget) => widget.data)
          .where((text) => text?.startsWith('Message') == true)
          .toList();

      expect(messageTexts, ['Message 1', 'Message 2', 'Message 3']);
    });

    testWidgets('Message status updates and read receipts',
        (WidgetTester tester) async {
      // Setup two users
      await TestHelpers.authenticateUser(
          mockAuth, 'user1@example.com', 'User 1');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to chat room
      await TestHelpers.navigateToChat(tester, roomId, 'Test Room');

      // Send a message
      const testMessage = 'Test message for read receipts';
      await TestHelpers.enterText(tester, 'Type a message...', testMessage);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Initially should show sent status
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Simulate message being delivered
      await TestHelpers.simulateMessageDelivery(mockFirestore, roomId);
      await tester.pumpAndSettle();

      // Should show delivered status
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Simulate another user reading the message
      await TestHelpers.simulateMessageRead(
          mockFirestore, roomId, 'user2@example.com');
      await tester.pumpAndSettle();

      // Should show read status (blue checkmarks or different icon)
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Test read receipt tracking for multiple recipients
      await TestHelpers.addUserToRoom(
          mockFirestore, roomId, 'user3@example.com');
      await TestHelpers.simulateMessageRead(
          mockFirestore, roomId, 'user3@example.com');
      await tester.pumpAndSettle();

      // Message should still show as read
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('Error scenarios and recovery mechanisms',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Test invalid login credentials
      await TestHelpers.navigateToLogin(tester);

      await TestHelpers.enterText(tester, 'Email', 'invalid@example.com');
      await TestHelpers.enterText(tester, 'Password', 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Invalid'), findsOneWidget);

      // Test network error recovery
      await TestHelpers.simulateNetworkError(mockFirestore);

      // Try to create a room during network error
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await TestHelpers.enterText(tester, 'Room Name', 'Network Test Room');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      // Should show network error
      expect(find.textContaining('network'), findsOneWidget);

      // Test retry mechanism
      await TestHelpers.restoreNetwork(mockFirestore);
      await tester.tap(find.textContaining('Retry'));
      await tester.pumpAndSettle();

      // Should succeed after network restoration
      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('Performance test for real-time data handling',
        (WidgetTester tester) async {
      // Setup authenticated user and room
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Performance Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to chat room
      await TestHelpers.navigateToChat(tester, roomId, 'Performance Test Room');

      // Measure performance of sending multiple messages rapidly
      final stopwatch = Stopwatch()..start();

      for (int i = 1; i <= 20; i++) {
        await TestHelpers.enterText(
            tester, 'Type a message...', 'Performance test message $i');
        await tester.tap(find.byIcon(Icons.send));

        // Don't wait for full settle to simulate rapid sending
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify all messages were sent
      for (int i = 1; i <= 20; i++) {
        expect(find.text('Performance test message $i'), findsOneWidget);
      }

      // Performance should be reasonable (less than 10 seconds for 20 messages)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));

      // Test real-time listener performance with simulated incoming messages
      final incomingStopwatch = Stopwatch()..start();

      // Simulate rapid incoming messages from another user
      for (int i = 1; i <= 10; i++) {
        await TestHelpers.simulateIncomingMessage(
            mockFirestore, roomId, 'other@example.com', 'Incoming message $i');
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      incomingStopwatch.stop();

      // Verify incoming messages appear
      for (int i = 1; i <= 10; i++) {
        expect(find.text('Incoming message $i'), findsOneWidget);
      }

      // Real-time updates should be fast (less than 5 seconds for 10 messages)
      expect(incomingStopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('Deep linking and navigation flow',
        (WidgetTester tester) async {
      // Setup authenticated user and room
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Deep Link Room');

      // Test deep link navigation
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Simulate deep link to chat room
      await TestHelpers.navigateViaDeepLink(tester, '/chat/$roomId');
      await tester.pumpAndSettle();

      // Should be in the correct chat room
      expect(find.text('Deep Link Room'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Message input

      // Test navigation back to rooms list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('Offline and online state handling',
        (WidgetTester tester) async {
      // Setup authenticated user and room
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Offline Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to chat room
      await TestHelpers.navigateToChat(tester, roomId, 'Offline Test Room');

      // Send message while online
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Online message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Online message'), findsOneWidget);

      // Simulate going offline
      await TestHelpers.simulateOfflineMode(mockFirestore);
      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.textContaining('offline'), findsOneWidget);

      // Try to send message while offline
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Offline message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should be queued or show pending state
      expect(find.text('Offline message'), findsOneWidget);

      // Simulate coming back online
      await TestHelpers.simulateOnlineMode(mockFirestore);
      await tester.pumpAndSettle();

      // Offline indicator should disappear
      expect(find.textContaining('offline'), findsNothing);

      // Queued message should be sent
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.check), findsWidgets); // Message sent indicators
    });
  });
}
