import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_real_time_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';

void main() {
  group('MessageBubble', () {
    late Message testMessage;
    late User testSender;

    setUp(() {
      testMessage = Message(
        id: 'msg1',
        roomId: 'room1',
        senderId: 'user1',
        content: 'Hello, world!',
        type: MessageType.text,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.delivered,
        readBy: const {},
      );

      testSender = User(
        id: 'user1',
        email: 'sender@example.com',
        displayName: 'Test Sender',
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest({
      required Message message,
      User? sender,
      required bool isCurrentUser,
      bool showTimestamp = true,
      bool showSenderName = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            sender: sender,
            isCurrentUser: isCurrentUser,
            showTimestamp: showTimestamp,
            showSenderName: showSenderName,
          ),
        ),
      );
    }

    testWidgets('should display message content', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        isCurrentUser: false,
      ));

      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('should show sender name when not current user',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        sender: testSender,
        isCurrentUser: false,
        showSenderName: true,
      ));

      expect(find.text('Test Sender'), findsOneWidget);
    });

    testWidgets('should not show sender name when current user',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        sender: testSender,
        isCurrentUser: true,
        showSenderName: true,
      ));

      expect(find.text('Test Sender'), findsNothing);
    });

    testWidgets('should show timestamp when enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        isCurrentUser: false,
        showTimestamp: true,
      ));

      // Should show some form of timestamp (exact format may vary)
      expect(find.textContaining('12:00'), findsOneWidget);
    });

    testWidgets('should show message status icon for current user',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        isCurrentUser: true,
      ));

      // Should show delivered status icon
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('should not show message status icon for other users',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        message: testMessage,
        isCurrentUser: false,
      ));

      // Should not show status icons for received messages
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('should show different status icons based on message status',
        (WidgetTester tester) async {
      // Test sent status
      final sentMessage = testMessage.copyWith(status: MessageStatus.sent);
      await tester.pumpWidget(createWidgetUnderTest(
        message: sentMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Test read status
      final readMessage = testMessage.copyWith(status: MessageStatus.read);
      await tester.pumpWidget(createWidgetUnderTest(
        message: readMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('should handle image message type',
        (WidgetTester tester) async {
      final imageMessage = testMessage.copyWith(
        type: MessageType.image,
        content: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        message: imageMessage,
        isCurrentUser: false,
      ));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle file message type', (WidgetTester tester) async {
      final fileMessage = testMessage.copyWith(
        type: MessageType.file,
        content: '/path/to/document.pdf',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        message: fileMessage,
        isCurrentUser: false,
      ));

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('document.pdf'), findsOneWidget);
    });

    testWidgets('should call onTap when message is tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: testMessage,
            isCurrentUser: false,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Hello, world!'), warnIfMissed: false);
      expect(tapped, isTrue);
    });
  });
}
