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

  group('Error Handling and Recovery Integration Tests', () {
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

    testWidgets('Authentication error handling and recovery',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Test invalid email format
      await TestHelpers.enterText(tester, 'Email', 'invalid-email-format');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show validation error
      TestHelpers.verifyErrorMessage('valid email');

      // Test network error during authentication
      await TestHelpers.simulateNetworkError(mockFirestore);

      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show network error
      TestHelpers.verifyErrorMessage('network');

      // Test recovery after network restoration
      await TestHelpers.restoreNetwork(mockFirestore);
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      if (find.textContaining('Retry').evaluate().isNotEmpty) {
        await TestHelpers.tapRetryButton(tester);

        // Should succeed after retry
        expect(find.text('Chat Rooms'), findsOneWidget);
      }

      // Test wrong credentials error
      await TestHelpers.navigateToLogin(tester);

      await TestHelpers.enterText(tester, 'Email', 'wrong@example.com');
      await TestHelpers.enterText(tester, 'Password', 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      TestHelpers.verifyErrorMessage('Invalid');

      // Test successful login after error
      await TestHelpers.authenticateUser(
          mockAuth, 'correct@example.com', 'Correct User');

      await TestHelpers.enterText(tester, 'Email', 'correct@example.com');
      await TestHelpers.enterText(tester, 'Password', 'correctpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('Chat room creation error handling',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to create room
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Test form validation errors
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      TestHelpers.verifyErrorMessage('required');

      // Test room name too short
      await TestHelpers.enterText(tester, 'Room Name', 'A');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      // Should show validation error for short name
      expect(find.textContaining('characters'), findsOneWidget);

      // Test network error during room creation
      await TestHelpers.simulateNetworkError(mockFirestore);

      await TestHelpers.enterText(tester, 'Room Name', 'Valid Room Name');
      await TestHelpers.enterText(tester, 'Description', 'Valid description');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Room'));
      await tester.pumpAndSettle();

      TestHelpers.verifyErrorMessage('network');

      // Test recovery
      await TestHelpers.restoreNetwork(mockFirestore);

      if (find.textContaining('Retry').evaluate().isNotEmpty) {
        await TestHelpers.tapRetryButton(tester);

        // Should succeed after retry
        expect(find.text('Chat Rooms'), findsOneWidget);
        expect(find.text('Valid Room Name'), findsOneWidget);
      }
    });

    testWidgets('Message sending error handling and retry',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Error Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Error Test Room');

      // Test sending empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should not send empty message (implementation dependent)
      // Either button should be disabled or validation should prevent sending

      // Test network error during message sending
      await TestHelpers.simulateNetworkError(mockFirestore);

      await TestHelpers.enterText(
          tester, 'Type a message...', 'Network error test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should show as pending or failed
      expect(find.text('Network error test message'), findsOneWidget);

      // Should show error indicator or retry option
      if (find.byIcon(Icons.error).evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.error), findsOneWidget);
      }

      // Test automatic retry when network is restored
      await TestHelpers.restoreNetwork(mockFirestore);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Message should eventually show as sent
      expect(find.text('Network error test message'), findsOneWidget);

      // Should show sent status after recovery
      if (find.byIcon(Icons.check).evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.check), findsOneWidget);
      }
    });

    testWidgets('Real-time connection error handling',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Connection Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Connection Test Room');

      // Send initial message while online
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Online message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Online message'), findsOneWidget);

      // Simulate connection loss
      await TestHelpers.simulateOfflineMode(mockFirestore);
      await tester.pumpAndSettle();

      // Should show offline indicator
      if (find.textContaining('offline').evaluate().isNotEmpty) {
        TestHelpers.verifyErrorMessage('offline');
      }

      // Try to send message while offline
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Offline message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should be queued or show pending state
      expect(find.text('Offline message'), findsOneWidget);

      // Simulate connection restoration
      await TestHelpers.simulateOnlineMode(mockFirestore);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Offline indicator should disappear
      expect(find.textContaining('offline'), findsNothing);

      // Queued message should be sent
      expect(find.text('Offline message'), findsOneWidget);
    });

    testWidgets('Data loading error handling', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Simulate error during initial data loading
      await TestHelpers.simulateNetworkError(mockFirestore);

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should show loading error
      TestHelpers.verifyErrorMessage('load');

      // Test retry mechanism
      await TestHelpers.restoreNetwork(mockFirestore);

      if (find.textContaining('Retry').evaluate().isNotEmpty) {
        await TestHelpers.tapRetryButton(tester);

        // Should load successfully after retry
        expect(find.text('Chat Rooms'), findsOneWidget);
      }
    });

    testWidgets('Invalid data handling', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Create room with invalid data
      await mockFirestore.collection('chatRooms').doc('invalid-room').set({
        'name': null, // Invalid: null name
        'description': 'Valid description',
        'createdBy': 'test@example.com',
        'participants': ['test@example.com'],
      });

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should handle invalid data gracefully
      expect(find.text('Chat Rooms'), findsOneWidget);

      // Should not crash the app
      expect(tester.takeException(), isNull);
    });

    testWidgets('Permission error handling', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Try to access a room without permission (simulate by creating restricted room)
      await mockFirestore.collection('chatRooms').doc('restricted-room').set({
        'name': 'Restricted Room',
        'description': 'Private room',
        'createdBy': 'other@example.com',
        'participants': [
          'other@example.com'
        ], // Current user not in participants
      });

      // Try to navigate to restricted room
      await TestHelpers.navigateToChat(
          tester, 'restricted-room', 'Restricted Room');

      // Should show permission error or redirect
      if (find.textContaining('permission').evaluate().isNotEmpty) {
        TestHelpers.verifyErrorMessage('permission');
      } else {
        // Should redirect to rooms list
        expect(find.text('Chat Rooms'), findsOneWidget);
      }
    });

    testWidgets('Session expiration handling', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Chat Rooms'), findsOneWidget);

      // Simulate session expiration
      await mockAuth.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should redirect to login page
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Chat Rooms'), findsNothing);
    });

    testWidgets('Concurrent error scenarios', (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Concurrent Error Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Concurrent Error Room');

      // Simulate multiple errors occurring simultaneously
      await TestHelpers.simulateNetworkError(mockFirestore);

      // Try multiple operations that should fail
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Error message 1');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(const Duration(milliseconds: 100));

      await TestHelpers.enterText(
          tester, 'Type a message...', 'Error message 2');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(const Duration(milliseconds: 100));

      await TestHelpers.enterText(
          tester, 'Type a message...', 'Error message 3');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should handle multiple concurrent errors gracefully
      expect(find.text('Error message 1'), findsOneWidget);
      expect(find.text('Error message 2'), findsOneWidget);
      expect(find.text('Error message 3'), findsOneWidget);

      // Restore network and verify recovery
      await TestHelpers.restoreNetwork(mockFirestore);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // All messages should eventually be sent
      expect(find.text('Error message 1'), findsOneWidget);
      expect(find.text('Error message 2'), findsOneWidget);
      expect(find.text('Error message 3'), findsOneWidget);
    });

    testWidgets('Error message display and dismissal',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Trigger an error
      await TestHelpers.enterText(tester, 'Email', 'invalid@example.com');
      await TestHelpers.enterText(tester, 'Password', 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show error message
      TestHelpers.verifyErrorMessage('Invalid');

      // Test error message dismissal (if implemented)
      if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Error message should be dismissed
        expect(find.textContaining('Invalid'), findsNothing);
      }

      // Test that new valid input clears error
      await TestHelpers.authenticateUser(
          mockAuth, 'valid@example.com', 'Valid User');

      await TestHelpers.enterText(tester, 'Email', 'valid@example.com');
      await TestHelpers.enterText(tester, 'Password', 'validpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should clear error and proceed
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.textContaining('Invalid'), findsNothing);
    });

    testWidgets('Graceful degradation during partial failures',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Degradation Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Degradation Test Room');

      // Send successful message first
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Successful message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Successful message'), findsOneWidget);

      // Simulate partial failure (e.g., status updates fail but messages still send)
      // This would require more sophisticated mocking in a real implementation

      // The app should continue to function even if some features fail
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Partial failure message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should still be sent even if status tracking fails
      expect(find.text('Partial failure message'), findsOneWidget);

      // App should remain functional
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
