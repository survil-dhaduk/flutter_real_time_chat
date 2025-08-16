import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_real_time_chat/injection/injection.dart' as injection;

/// Firebase test setup utilities
class FirebaseTestSetup {
  static bool _initialized = false;

  /// Initialize Firebase for testing
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
    } catch (e) {
      // Firebase already initialized
    }

    _initialized = true;
  }

  /// Setup test data in Firestore
  static Future<void> setupTestData(FakeFirebaseFirestore firestore) async {
    // Create test users
    await _createTestUsers(firestore);

    // Create test chat rooms
    await _createTestChatRooms(firestore);

    // Create test messages
    await _createTestMessages(firestore);
  }

  /// Create test users in Firestore
  static Future<void> _createTestUsers(FakeFirebaseFirestore firestore) async {
    final users = [
      {
        'id': 'test-user-1',
        'email': 'user1@example.com',
        'displayName': 'Test User 1',
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      },
      {
        'id': 'test-user-2',
        'email': 'user2@example.com',
        'displayName': 'Test User 2',
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': false,
      },
    ];

    for (final user in users) {
      await firestore.collection('users').doc(user['id'] as String).set(user);
    }
  }

  /// Create test chat rooms in Firestore
  static Future<void> _createTestChatRooms(
      FakeFirebaseFirestore firestore) async {
    final rooms = [
      {
        'id': 'test-room-1',
        'name': 'General Chat',
        'description': 'General discussion room',
        'createdBy': 'test-user-1',
        'createdAt': FieldValue.serverTimestamp(),
        'participants': ['test-user-1', 'test-user-2'],
        'lastMessageId': null,
        'lastMessageTime': null,
      },
      {
        'id': 'test-room-2',
        'name': 'Private Room',
        'description': 'Private discussion room',
        'createdBy': 'test-user-2',
        'createdAt': FieldValue.serverTimestamp(),
        'participants': ['test-user-2'],
        'lastMessageId': null,
        'lastMessageTime': null,
      },
    ];

    for (final room in rooms) {
      await firestore
          .collection('chatRooms')
          .doc(room['id'] as String)
          .set(room);
    }
  }

  /// Create test messages in Firestore
  static Future<void> _createTestMessages(
      FakeFirebaseFirestore firestore) async {
    final messages = [
      {
        'id': 'test-message-1',
        'roomId': 'test-room-1',
        'senderId': 'test-user-1',
        'content': 'Hello everyone!',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'delivered',
        'readBy': {
          'test-user-2': FieldValue.serverTimestamp(),
        },
      },
      {
        'id': 'test-message-2',
        'roomId': 'test-room-1',
        'senderId': 'test-user-2',
        'content': 'Hi there!',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'read',
        'readBy': {
          'test-user-1': FieldValue.serverTimestamp(),
        },
      },
    ];

    for (final message in messages) {
      await firestore
          .collection('messages')
          .doc(message['id'] as String)
          .set(message);
    }

    // Update room last message references
    await firestore.collection('chatRooms').doc('test-room-1').update({
      'lastMessageId': 'test-message-2',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Clean up test data
  static Future<void> cleanup(FakeFirebaseFirestore firestore) async {
    // Clear all collections
    await _clearCollection(firestore, 'users');
    await _clearCollection(firestore, 'chatRooms');
    await _clearCollection(firestore, 'messages');
  }

  /// Clear a Firestore collection
  static Future<void> _clearCollection(
    FakeFirebaseFirestore firestore,
    String collectionName,
  ) async {
    final collection = firestore.collection(collectionName);
    final snapshot = await collection.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Create mock Firebase Auth instance
  static MockFirebaseAuth createMockAuth() {
    return MockFirebaseAuth(
      mockUser: MockUser(
        isAnonymous: false,
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      ),
    );
  }

  /// Create fake Firestore instance
  static FakeFirebaseFirestore createFakeFirestore() {
    return FakeFirebaseFirestore();
  }

  /// Setup security rules for testing
  static Future<void> setupSecurityRules(
      FakeFirebaseFirestore firestore) async {
    // In a real implementation, you would set up Firestore security rules
    // For fake_cloud_firestore, we can simulate rule enforcement

    // Example: Users can only read/write their own data
    // This would be implemented in the actual Firestore rules
  }

  /// Simulate network latency
  static Future<void> simulateNetworkLatency([int milliseconds = 100]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Simulate Firestore offline mode
  static Future<void> simulateOfflineMode(
      FakeFirebaseFirestore firestore) async {
    await firestore.disableNetwork();
  }

  /// Simulate Firestore online mode
  static Future<void> simulateOnlineMode(
      FakeFirebaseFirestore firestore) async {
    await firestore.enableNetwork();
  }

  /// Create test data for performance testing
  static Future<void> createPerformanceTestData(
    FakeFirebaseFirestore firestore,
    int messageCount,
  ) async {
    final roomId = 'performance-test-room';

    // Create performance test room
    await firestore.collection('chatRooms').doc(roomId).set({
      'name': 'Performance Test Room',
      'description': 'Room for performance testing',
      'createdBy': 'test-user-1',
      'createdAt': FieldValue.serverTimestamp(),
      'participants': ['test-user-1', 'test-user-2'],
      'lastMessageId': null,
      'lastMessageTime': null,
    });

    // Create multiple messages for performance testing
    final batch = firestore.batch();

    for (int i = 1; i <= messageCount; i++) {
      final messageRef =
          firestore.collection('messages').doc('perf-message-$i');
      batch.set(messageRef, {
        'id': 'perf-message-$i',
        'roomId': roomId,
        'senderId': i % 2 == 0 ? 'test-user-1' : 'test-user-2',
        'content': 'Performance test message $i',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'delivered',
        'readBy': {},
      });
    }

    await batch.commit();
  }

  /// Verify test data integrity
  static Future<bool> verifyTestDataIntegrity(
      FakeFirebaseFirestore firestore) async {
    try {
      // Check if test users exist
      final usersSnapshot = await firestore.collection('users').get();
      if (usersSnapshot.docs.isEmpty) return false;

      // Check if test rooms exist
      final roomsSnapshot = await firestore.collection('chatRooms').get();
      if (roomsSnapshot.docs.isEmpty) return false;

      // Check if test messages exist
      final messagesSnapshot = await firestore.collection('messages').get();
      if (messagesSnapshot.docs.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset Firestore to initial state
  static Future<void> resetToInitialState(
      FakeFirebaseFirestore firestore) async {
    await cleanup(firestore);
    await setupTestData(firestore);
  }
}

/// Initialize test dependencies with mocked Firebase services
Future<void> initializeTestDependencies(
  MockFirebaseAuth mockAuth,
  FakeFirebaseFirestore mockFirestore,
) async {
  // Reset service locator
  await injection.sl.reset();

  // Register mocked Firebase services
  injection.sl.registerLazySingleton<FirebaseAuth>(() => mockAuth);
  injection.sl.registerLazySingleton<FirebaseFirestore>(() => mockFirestore);

  // Initialize the rest of the dependencies
  await injection.initializeDependencies();
}

/// Reset dependencies for testing
Future<void> resetTestDependencies() async {
  try {
    await injection.sl.reset();
  } catch (e) {
    // If reset fails, try to unregister specific services
    try {
      if (injection.sl.isRegistered<FirebaseAuth>()) {
        injection.sl.unregister<FirebaseAuth>();
      }
      if (injection.sl.isRegistered<FirebaseFirestore>()) {
        injection.sl.unregister<FirebaseFirestore>();
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}
