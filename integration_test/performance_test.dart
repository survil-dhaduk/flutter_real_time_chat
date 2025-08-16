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

  group('Performance Integration Tests', () {
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

    testWidgets('Rapid message sending performance',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Performance Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Performance Room');

      // Measure time to send multiple messages rapidly
      final stopwatch = Stopwatch()..start();
      const messageCount = 25;

      for (int i = 1; i <= messageCount; i++) {
        await TestHelpers.enterText(
            tester, 'Type a message...', 'Performance message $i');
        await tester.tap(find.byIcon(Icons.send));

        // Minimal pump to simulate rapid sending
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify all messages were sent
      for (int i = 1; i <= messageCount; i++) {
        expect(find.text('Performance message $i'), findsOneWidget);
      }

      // Performance benchmark: should complete within reasonable time
      final elapsedMs = stopwatch.elapsedMilliseconds;
      print(
          'Rapid message sending took: ${elapsedMs}ms for $messageCount messages');

      // Should complete within 15 seconds for 25 messages
      expect(elapsedMs, lessThan(15000));

      // Average time per message should be reasonable
      final avgTimePerMessage = elapsedMs / messageCount;
      expect(avgTimePerMessage, lessThan(600)); // Less than 600ms per message
    });

    testWidgets('Real-time listener performance with high message volume',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'High Volume Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'High Volume Room');

      // Measure time to receive multiple incoming messages
      final stopwatch = Stopwatch()..start();
      const incomingMessageCount = 30;

      // Simulate rapid incoming messages from multiple users
      for (int i = 1; i <= incomingMessageCount; i++) {
        final senderId =
            'user${(i % 5) + 1}@example.com'; // 5 different senders
        await TestHelpers.simulateIncomingMessage(
          mockFirestore,
          roomId,
          senderId,
          'Incoming performance message $i',
        );

        // Small delay to simulate real-time arrival
        await tester.pump(const Duration(milliseconds: 30));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify all incoming messages are displayed
      for (int i = 1; i <= incomingMessageCount; i++) {
        expect(find.text('Incoming performance message $i'), findsOneWidget);
      }

      final elapsedMs = stopwatch.elapsedMilliseconds;
      print(
          'Real-time message reception took: ${elapsedMs}ms for $incomingMessageCount messages');

      // Should handle real-time updates efficiently
      expect(elapsedMs, lessThan(10000)); // Less than 10 seconds

      final avgTimePerMessage = elapsedMs / incomingMessageCount;
      expect(avgTimePerMessage, lessThan(333)); // Less than 333ms per message
    });

    testWidgets('Chat room list loading performance',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Create multiple chat rooms for performance testing
      final stopwatchSetup = Stopwatch()..start();
      const roomCount = 50;

      for (int i = 1; i <= roomCount; i++) {
        await TestHelpers.createTestRoom(mockFirestore, 'Performance Room $i');
      }
      stopwatchSetup.stop();

      print(
          'Created $roomCount rooms in ${stopwatchSetup.elapsedMilliseconds}ms');

      // Measure time to load and display room list
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verify rooms are loaded
      expect(find.text('Chat Rooms'), findsOneWidget);

      // Should find at least some of the created rooms
      expect(find.textContaining('Performance Room'), findsWidgets);

      final elapsedMs = stopwatch.elapsedMilliseconds;
      print('Room list loading took: ${elapsedMs}ms for $roomCount rooms');

      // Should load room list efficiently
      expect(elapsedMs, lessThan(5000)); // Less than 5 seconds
    });

    testWidgets('Message history loading performance',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Create room with extensive message history
      await FirebaseTestSetup.createPerformanceTestData(mockFirestore, 100);

      // Measure time to load chat with message history
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(
          tester, 'performance-test-room', 'Performance Test Room');

      stopwatch.stop();

      // Verify messages are loaded
      expect(find.textContaining('Performance test message'), findsWidgets);

      final elapsedMs = stopwatch.elapsedMilliseconds;
      print('Message history loading took: ${elapsedMs}ms for 100 messages');

      // Should load message history efficiently
      expect(elapsedMs, lessThan(8000)); // Less than 8 seconds
    });

    testWidgets('Memory usage during extended chat session',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Memory Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Memory Test Room');

      // Simulate extended chat session with many operations
      const operationCount = 100;

      for (int i = 1; i <= operationCount; i++) {
        // Send message
        await TestHelpers.enterText(
            tester, 'Type a message...', 'Memory test $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(const Duration(milliseconds: 20));

        // Simulate incoming message every 5th iteration
        if (i % 5 == 0) {
          await TestHelpers.simulateIncomingMessage(
            mockFirestore,
            roomId,
            'other@example.com',
            'Incoming memory test $i',
          );
          await tester.pump(const Duration(milliseconds: 20));
        }

        // Scroll occasionally to test list performance
        if (i % 10 == 0) {
          await TestHelpers.scrollToTop(tester);
          await tester.pump(const Duration(milliseconds: 10));
          await TestHelpers.scrollToBottom(tester);
          await tester.pump(const Duration(milliseconds: 10));
        }
      }

      await tester.pumpAndSettle();

      // Verify the chat is still responsive
      expect(find.text('Memory test $operationCount'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Test that we can still send messages after extended session
      await TestHelpers.enterText(
          tester, 'Type a message...', 'Final memory test');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Final memory test'), findsOneWidget);
    });

    testWidgets('Network latency simulation performance',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Latency Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Latency Test Room');

      // Test performance with simulated network latency
      const messageCount = 10;
      final stopwatch = Stopwatch()..start();

      for (int i = 1; i <= messageCount; i++) {
        // Simulate network latency
        await FirebaseTestSetup.simulateNetworkLatency(100); // 100ms latency

        await TestHelpers.enterText(
            tester, 'Type a message...', 'Latency test $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify all messages were sent despite latency
      for (int i = 1; i <= messageCount; i++) {
        expect(find.text('Latency test $i'), findsOneWidget);
      }

      final elapsedMs = stopwatch.elapsedMilliseconds;
      print(
          'Messages with latency took: ${elapsedMs}ms for $messageCount messages');

      // Should handle latency gracefully (accounting for simulated 100ms per message)
      expect(
          elapsedMs,
          lessThan(messageCount * 200 +
              2000)); // Allow for latency + processing time
    });

    testWidgets('Concurrent user simulation performance',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId = await TestHelpers.createTestRoom(
          mockFirestore, 'Concurrent Test Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Concurrent Test Room');

      // Simulate concurrent activity from multiple users
      const concurrentUsers = 5;
      const messagesPerUser = 8;

      final stopwatch = Stopwatch()..start();

      // Simulate messages from multiple users arriving concurrently
      for (int round = 1; round <= messagesPerUser; round++) {
        for (int user = 1; user <= concurrentUsers; user++) {
          await TestHelpers.simulateIncomingMessage(
            mockFirestore,
            roomId,
            'concurrent_user_$user@example.com',
            'Concurrent message $round from user $user',
          );

          // Very small delay to simulate near-concurrent arrival
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Send our own message in the mix
        await TestHelpers.enterText(
            tester, 'Type a message...', 'My message in round $round');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(const Duration(milliseconds: 20));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify messages from all users are displayed
      for (int round = 1; round <= messagesPerUser; round++) {
        for (int user = 1; user <= concurrentUsers; user++) {
          expect(
            find.text('Concurrent message $round from user $user'),
            findsOneWidget,
          );
        }
        expect(find.text('My message in round $round'), findsOneWidget);
      }

      final totalMessages = concurrentUsers * messagesPerUser + messagesPerUser;
      final elapsedMs = stopwatch.elapsedMilliseconds;
      print(
          'Concurrent simulation took: ${elapsedMs}ms for $totalMessages messages');

      // Should handle concurrent activity efficiently
      expect(elapsedMs, lessThan(15000)); // Less than 15 seconds

      final avgTimePerMessage = elapsedMs / totalMessages;
      expect(avgTimePerMessage, lessThan(300)); // Less than 300ms per message
    });

    testWidgets('UI responsiveness during heavy load',
        (WidgetTester tester) async {
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Heavy Load Room');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      await TestHelpers.navigateToChat(tester, roomId, 'Heavy Load Room');

      // Create heavy load scenario
      const heavyLoadMessages = 20;

      // Start heavy message flow
      for (int i = 1; i <= heavyLoadMessages; i++) {
        await TestHelpers.simulateIncomingMessage(
          mockFirestore,
          roomId,
          'heavy_user@example.com',
          'Heavy load message $i',
        );

        // Don't wait for full settle to simulate heavy load
        await tester.pump(const Duration(milliseconds: 25));
      }

      // Test UI responsiveness during heavy load
      final responsivenessTester = Stopwatch()..start();

      // Try to interact with UI during heavy load
      await TestHelpers.enterText(
          tester, 'Type a message...', 'UI responsiveness test');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      responsivenessTester.stop();

      // UI should remain responsive
      expect(find.text('UI responsiveness test'), findsOneWidget);

      final responsivenessMs = responsivenessTester.elapsedMilliseconds;
      print('UI responsiveness during heavy load: ${responsivenessMs}ms');

      // UI should respond within reasonable time even under load
      expect(responsivenessMs, lessThan(3000)); // Less than 3 seconds
    });
  });
}
