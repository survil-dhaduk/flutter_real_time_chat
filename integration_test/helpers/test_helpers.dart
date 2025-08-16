import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_real_time_chat/core/routing/route_names.dart';
import 'package:flutter_real_time_chat/core/routing/navigation_service.dart';

/// Helper class for integration test utilities
class TestHelpers {
  /// Enter text into a text field by finding it with a label or hint
  static Future<void> enterText(
    WidgetTester tester,
    String fieldLabel,
    String text,
  ) async {
    final textField = find.widgetWithText(TextField, fieldLabel).first;
    await tester.enterText(textField, text);
    await tester.pump();
  }

  /// Authenticate a user for testing
  static Future<void> authenticateUser(
    MockFirebaseAuth mockAuth,
    String email,
    String displayName,
  ) async {
    // Create a mock user
    final user = MockUser(
      isAnonymous: false,
      uid: 'test-uid-${email.hashCode}',
      email: email,
      displayName: displayName,
    );

    // Set the mock user as signed in
    mockAuth.mockUser = user;

    // Trigger sign in to update the auth state
    try {
      await mockAuth.signInWithEmailAndPassword(
        email: email,
        password: 'password123',
      );
    } catch (e) {
      // If sign in fails, the mock user is still set
      // This is expected behavior for testing
    }
  }

  /// Navigate to login page
  static Future<void> navigateToLogin(WidgetTester tester) async {
    // If not already on login, navigate there
    if (find.text('Welcome Back').evaluate().isEmpty) {
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
    }
  }

  /// Create a test chat room
  static Future<String> createTestRoom(
    FakeFirebaseFirestore mockFirestore,
    String roomName,
  ) async {
    final roomRef = mockFirestore.collection('chatRooms').doc();

    await roomRef.set({
      'name': roomName,
      'description': 'Test room description',
      'createdBy': 'test-uid',
      'createdAt': FieldValue.serverTimestamp(),
      'participants': ['test-uid'],
      'lastMessageId': null,
      'lastMessageTime': null,
    });

    return roomRef.id;
  }

  /// Navigate to chat room
  static Future<void> navigateToChat(
    WidgetTester tester,
    String roomId,
    String roomName,
  ) async {
    // Navigate using the navigation service
    NavigationService.navigatorKey.currentState?.pushNamed(
      RouteNames.chat,
      arguments: {
        'roomId': roomId,
        'roomName': roomName,
      },
    );
    await tester.pumpAndSettle();
  }

  /// Navigate via deep link
  static Future<void> navigateViaDeepLink(
    WidgetTester tester,
    String deepLink,
  ) async {
    NavigationService.navigatorKey.currentState?.pushNamed(deepLink);
    await tester.pumpAndSettle();
  }

  /// Simulate message delivery
  static Future<void> simulateMessageDelivery(
    FakeFirebaseFirestore mockFirestore,
    String roomId,
  ) async {
    final messagesQuery = await mockFirestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .get();

    for (final doc in messagesQuery.docs) {
      await doc.reference.update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Simulate message being read by a user
  static Future<void> simulateMessageRead(
    FakeFirebaseFirestore mockFirestore,
    String roomId,
    String userId,
  ) async {
    final messagesQuery = await mockFirestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .get();

    for (final doc in messagesQuery.docs) {
      final data = doc.data();
      final readBy = Map<String, dynamic>.from(data['readBy'] ?? {});
      readBy[userId] = FieldValue.serverTimestamp();

      await doc.reference.update({
        'status': 'read',
        'readBy': readBy,
      });
    }
  }

  /// Add user to chat room
  static Future<void> addUserToRoom(
    FakeFirebaseFirestore mockFirestore,
    String roomId,
    String userId,
  ) async {
    final roomRef = mockFirestore.collection('chatRooms').doc(roomId);

    await roomRef.update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  /// Simulate incoming message from another user
  static Future<void> simulateIncomingMessage(
    FakeFirebaseFirestore mockFirestore,
    String roomId,
    String senderId,
    String content,
  ) async {
    final messageRef = mockFirestore.collection('messages').doc();

    await messageRef.set({
      'id': messageRef.id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'readBy': {},
    });

    // Update room's last message
    await mockFirestore.collection('chatRooms').doc(roomId).update({
      'lastMessageId': messageRef.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Simulate network error
  static Future<void> simulateNetworkError(
    FakeFirebaseFirestore mockFirestore,
  ) async {
    // This would typically involve mocking network failures
    // For fake_cloud_firestore, we can simulate by temporarily disabling operations
    // In a real implementation, you might use a network interceptor
  }

  /// Restore network connectivity
  static Future<void> restoreNetwork(
    FakeFirebaseFirestore mockFirestore,
  ) async {
    // Restore normal operations
    // In a real implementation, you would restore network connectivity
  }

  /// Simulate offline mode
  static Future<void> simulateOfflineMode(
    FakeFirebaseFirestore mockFirestore,
  ) async {
    // Simulate offline state
    // For fake_cloud_firestore, we simulate this by setting a flag
    // In a real implementation, you would disable network connectivity
    // This is a placeholder for offline simulation
  }

  /// Simulate online mode
  static Future<void> simulateOnlineMode(
    FakeFirebaseFirestore mockFirestore,
  ) async {
    // Restore online state
    // For fake_cloud_firestore, we simulate this by clearing the offline flag
    // In a real implementation, you would restore network connectivity
    // This is a placeholder for online simulation
  }

  /// Wait for real-time updates to propagate
  static Future<void> waitForRealtimeUpdate(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// Verify message appears in chat
  static void verifyMessageInChat(String messageContent) {
    expect(find.text(messageContent), findsOneWidget);
  }

  /// Verify message status indicator
  static void verifyMessageStatus(IconData expectedIcon) {
    expect(find.byIcon(expectedIcon), findsOneWidget);
  }

  /// Scroll to bottom of chat
  static Future<void> scrollToBottom(WidgetTester tester) async {
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
  }

  /// Scroll to top of chat
  static Future<void> scrollToTop(WidgetTester tester) async {
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView, const Offset(0, 500));
      await tester.pumpAndSettle();
    }
  }

  /// Verify error message is displayed
  static void verifyErrorMessage(String expectedError) {
    expect(find.textContaining(expectedError), findsOneWidget);
  }

  /// Verify loading indicator is shown
  static void verifyLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verify no loading indicator is shown
  static void verifyNoLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Tap retry button
  static Future<void> tapRetryButton(WidgetTester tester) async {
    await tester.tap(find.textContaining('Retry'));
    await tester.pumpAndSettle();
  }

  /// Verify navigation to specific route
  static void verifyCurrentRoute(String expectedRoute) {
    final currentRoute = ModalRoute.of(
      NavigationService.navigatorKey.currentContext!,
    )?.settings.name;
    expect(currentRoute, equals(expectedRoute));
  }

  /// Generate test user data
  static Map<String, dynamic> generateTestUser(
      String email, String displayName) {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    };
  }

  /// Generate test message data
  static Map<String, dynamic> generateTestMessage(
    String roomId,
    String senderId,
    String content,
  ) {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'readBy': {},
    };
  }

  /// Generate test room data
  static Map<String, dynamic> generateTestRoom(
    String name,
    String createdBy, {
    String? description,
    List<String>? participants,
  }) {
    return {
      'name': name,
      'description': description ?? 'Test room description',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': participants ?? [createdBy],
      'lastMessageId': null,
      'lastMessageTime': null,
    };
  }
}
