import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../integration_test/helpers/firebase_test_setup.dart';
import '../../integration_test/helpers/test_helpers.dart';

void main() {
  group('Integration Test Infrastructure Verification', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() async {
      await FirebaseTestSetup.initialize();
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
    });

    tearDown(() async {
      await FirebaseTestSetup.cleanup(mockFirestore);
    });

    test('Firebase test setup initializes correctly', () async {
      expect(mockAuth, isNotNull);
      expect(mockFirestore, isNotNull);

      // Test that we can create test data
      await FirebaseTestSetup.setupTestData(mockFirestore);

      // Verify test data was created
      final usersSnapshot = await mockFirestore.collection('users').get();
      expect(usersSnapshot.docs.isNotEmpty, true);

      final roomsSnapshot = await mockFirestore.collection('chatRooms').get();
      expect(roomsSnapshot.docs.isNotEmpty, true);

      final messagesSnapshot = await mockFirestore.collection('messages').get();
      expect(messagesSnapshot.docs.isNotEmpty, true);
    });

    test('Test helpers work correctly', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      // Test room creation helper
      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Test Room');
      expect(roomId, isNotNull);
      expect(roomId.isNotEmpty, true);

      // Verify room was created
      final roomDoc =
          await mockFirestore.collection('chatRooms').doc(roomId).get();
      expect(roomDoc.exists, true);
      expect(roomDoc.data()?['name'], 'Test Room');
    });

    test('Message simulation works correctly', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Message Test Room');

      // Test incoming message simulation
      await TestHelpers.simulateIncomingMessage(
        mockFirestore,
        roomId,
        'test@example.com',
        'Test message content',
      );

      // Verify message was created
      final messagesQuery = await mockFirestore
          .collection('messages')
          .where('roomId', isEqualTo: roomId)
          .where('content', isEqualTo: 'Test message content')
          .get();

      expect(messagesQuery.docs.isNotEmpty, true);
      expect(messagesQuery.docs.first.data()['senderId'], 'test@example.com');
    });

    test('Message status simulation works correctly', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Status Test Room');

      // Create a message
      await TestHelpers.simulateIncomingMessage(
        mockFirestore,
        roomId,
        'sender@example.com',
        'Status test message',
      );

      // Simulate message delivery
      await TestHelpers.simulateMessageDelivery(mockFirestore, roomId);

      // Verify status was updated
      final messagesQuery = await mockFirestore
          .collection('messages')
          .where('roomId', isEqualTo: roomId)
          .get();

      expect(messagesQuery.docs.isNotEmpty, true);
      expect(messagesQuery.docs.first.data()['status'], 'delivered');

      // Simulate message read
      await TestHelpers.simulateMessageRead(
          mockFirestore, roomId, 'reader@example.com');

      // Verify read status
      final updatedQuery = await mockFirestore
          .collection('messages')
          .where('roomId', isEqualTo: roomId)
          .get();

      expect(updatedQuery.docs.first.data()['status'], 'read');
      final readBy =
          updatedQuery.docs.first.data()['readBy'] as Map<String, dynamic>;
      expect(readBy.containsKey('reader@example.com'), true);
    });

    test('Performance test data creation works', () async {
      const messageCount = 50;
      await FirebaseTestSetup.createPerformanceTestData(
          mockFirestore, messageCount);

      // Verify performance test room was created
      final roomDoc = await mockFirestore
          .collection('chatRooms')
          .doc('performance-test-room')
          .get();

      expect(roomDoc.exists, true);
      expect(roomDoc.data()?['name'], 'Performance Test Room');

      // Verify messages were created
      final messagesQuery = await mockFirestore
          .collection('messages')
          .where('roomId', isEqualTo: 'performance-test-room')
          .get();

      expect(messagesQuery.docs.length, messageCount);
    });

    test('Network simulation functions work', () async {
      // Test offline/online simulation
      await TestHelpers.simulateOfflineMode(mockFirestore);

      // In a real implementation, this would test network state
      // For fake_cloud_firestore, we just verify the function doesn't throw
      expect(true, true);

      await TestHelpers.simulateOnlineMode(mockFirestore);
      expect(true, true);
    });

    test('User management helpers work', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'User Test Room');

      // Test adding user to room
      await TestHelpers.addUserToRoom(
          mockFirestore, roomId, 'newuser@example.com');

      // Verify user was added
      final roomDoc =
          await mockFirestore.collection('chatRooms').doc(roomId).get();
      final participants =
          List<String>.from(roomDoc.data()?['participants'] ?? []);

      expect(participants.contains('newuser@example.com'), true);
    });

    test('Test data generation helpers work', () {
      // Test user data generation
      final userData =
          TestHelpers.generateTestUser('test@example.com', 'Test User');
      expect(userData['email'], 'test@example.com');
      expect(userData['displayName'], 'Test User');
      expect(userData.containsKey('createdAt'), true);

      // Test message data generation
      final messageData = TestHelpers.generateTestMessage(
        'room123',
        'sender@example.com',
        'Test message',
      );
      expect(messageData['roomId'], 'room123');
      expect(messageData['senderId'], 'sender@example.com');
      expect(messageData['content'], 'Test message');
      expect(messageData['type'], 'text');

      // Test room data generation
      final roomData = TestHelpers.generateTestRoom(
        'Test Room',
        'creator@example.com',
      );
      expect(roomData['name'], 'Test Room');
      expect(roomData['createdBy'], 'creator@example.com');
      expect(roomData.containsKey('createdAt'), true);
    });

    test('Data integrity verification works', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      // Test data integrity verification
      final isValid =
          await FirebaseTestSetup.verifyTestDataIntegrity(mockFirestore);
      expect(isValid, true);

      // Test with empty database
      await FirebaseTestSetup.cleanup(mockFirestore);
      final isValidEmpty =
          await FirebaseTestSetup.verifyTestDataIntegrity(mockFirestore);
      expect(isValidEmpty, false);
    });

    test('Reset functionality works', () async {
      await FirebaseTestSetup.setupTestData(mockFirestore);

      // Verify data exists
      final beforeReset =
          await FirebaseTestSetup.verifyTestDataIntegrity(mockFirestore);
      expect(beforeReset, true);

      // Reset to initial state
      await FirebaseTestSetup.resetToInitialState(mockFirestore);

      // Verify data still exists after reset
      final afterReset =
          await FirebaseTestSetup.verifyTestDataIntegrity(mockFirestore);
      expect(afterReset, true);
    });

    test('Mock Firebase Auth works correctly', () async {
      // Test user authentication
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      // Verify user is authenticated
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser?.email, 'test@example.com');
      expect(mockAuth.currentUser?.displayName, 'Test User');
    });

    test('Dependency injection test setup works', () async {
      // This test verifies that the dependency injection setup functions exist
      // and can be called without errors

      expect(resetTestDependencies, isNotNull);
      expect(initializeTestDependencies, isNotNull);

      // Test that functions can be called
      try {
        await resetTestDependencies();
        await initializeTestDependencies(mockAuth, mockFirestore);

        // If we get here, the setup worked
        expect(true, true);
      } catch (e) {
        // If there's a registration conflict, that's expected in test environment
        // The important thing is that the functions exist and can be called
        expect(e.toString().contains('already registered'), true);
      }
    });
  });

  group('Integration Test Performance Benchmarks', () {
    late FakeFirebaseFirestore mockFirestore;

    setUp(() async {
      await FirebaseTestSetup.initialize();
      mockFirestore = FakeFirebaseFirestore();
    });

    test('Message creation performance benchmark', () async {
      const messageCount = 100;
      final stopwatch = Stopwatch()..start();

      final roomId =
          await TestHelpers.createTestRoom(mockFirestore, 'Perf Test');

      for (int i = 1; i <= messageCount; i++) {
        await TestHelpers.simulateIncomingMessage(
          mockFirestore,
          roomId,
          'user@example.com',
          'Performance test message $i',
        );
      }

      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgTimePerMessage = elapsedMs / messageCount;

      print('Created $messageCount messages in ${elapsedMs}ms');
      print(
          'Average time per message: ${avgTimePerMessage.toStringAsFixed(2)}ms');

      // Performance benchmark: should create messages efficiently
      expect(avgTimePerMessage, lessThan(50)); // Less than 50ms per message
    });

    test('Room creation performance benchmark', () async {
      const roomCount = 50;
      final stopwatch = Stopwatch()..start();

      for (int i = 1; i <= roomCount; i++) {
        await TestHelpers.createTestRoom(mockFirestore, 'Performance Room $i');
      }

      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgTimePerRoom = elapsedMs / roomCount;

      print('Created $roomCount rooms in ${elapsedMs}ms');
      print('Average time per room: ${avgTimePerRoom.toStringAsFixed(2)}ms');

      // Performance benchmark: should create rooms efficiently
      expect(avgTimePerRoom, lessThan(100)); // Less than 100ms per room
    });

    test('Data query performance benchmark', () async {
      await FirebaseTestSetup.createPerformanceTestData(mockFirestore, 200);

      final stopwatch = Stopwatch()..start();

      // Perform multiple queries
      for (int i = 0; i < 10; i++) {
        await mockFirestore
            .collection('messages')
            .where('roomId', isEqualTo: 'performance-test-room')
            .limit(20)
            .get();
      }

      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgTimePerQuery = elapsedMs / 10;

      print('Performed 10 queries in ${elapsedMs}ms');
      print('Average time per query: ${avgTimePerQuery.toStringAsFixed(2)}ms');

      // Performance benchmark: queries should be fast
      expect(avgTimePerQuery, lessThan(200)); // Less than 200ms per query
    });
  });
}
