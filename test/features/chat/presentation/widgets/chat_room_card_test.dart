import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/core/constants/app_colors.dart';
import '../../../../../lib/features/chat/domain/entities/chat_room.dart';
import '../../../../../lib/features/chat/presentation/widgets/chat_room_card.dart';

void main() {
  group('ChatRoomCard', () {
    late ChatRoom testChatRoom;
    late VoidCallback mockOnTap;
    bool onTapCalled = false;

    setUp(() {
      onTapCalled = false;
      mockOnTap = () {
        onTapCalled = true;
      };

      testChatRoom = ChatRoom(
        id: '1',
        name: 'Test Room',
        description: 'This is a test room',
        createdBy: 'user1',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        participants: ['user1', 'user2', 'user3'],
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );
    });

    Widget createWidgetUnderTest(ChatRoom chatRoom) {
      return MaterialApp(
        home: Scaffold(
          body: ChatRoomCard(
            chatRoom: chatRoom,
            onTap: mockOnTap,
          ),
        ),
      );
    }

    testWidgets('should display chat room name', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.text('Test Room'), findsOneWidget);
    });

    testWidgets('should display chat room description when provided',
        (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.text('This is a test room'), findsOneWidget);
    });

    testWidgets('should not display description when empty', (tester) async {
      // Arrange
      final roomWithoutDescription = testChatRoom.copyWith(description: '');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithoutDescription));

      // Assert
      expect(find.text('This is a test room'), findsNothing);
    });

    testWidgets('should display participant count', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.text('3 participants'), findsOneWidget);
    });

    testWidgets('should display singular participant when count is 1',
        (tester) async {
      // Arrange
      final roomWithOneParticipant =
          testChatRoom.copyWith(participants: ['user1']);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithOneParticipant));

      // Assert
      expect(find.text('1 participant'), findsOneWidget);
    });

    testWidgets('should display created time', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('should display last message time when available',
        (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.text('30m ago'), findsOneWidget);
    });

    testWidgets('should not display last message time when not available',
        (tester) async {
      // Arrange
      final roomWithoutLastMessage =
          testChatRoom.copyWith(clearLastMessageTime: true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithoutLastMessage));

      // Assert
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('should display activity indicator for recent activity',
        (tester) async {
      // Arrange
      final roomWithRecentActivity = testChatRoom.copyWith(
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithRecentActivity));

      // Assert
      expect(find.byType(Container), findsWidgets);

      // Find the activity indicator container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final activityIndicator = containers.firstWhere(
        (container) =>
            container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).color == AppColors.success,
        orElse: () => Container(),
      );

      expect(activityIndicator.decoration, isA<BoxDecoration>());
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));
      await tester.tap(find.byType(ChatRoomCard));

      // Assert
      expect(onTapCalled, isTrue);
    });

    testWidgets('should display chat bubble icon', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    });

    testWidgets('should display people icon for participants', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('should display arrow forward icon', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testChatRoom));

      // Assert
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('should format time correctly for different durations',
        (tester) async {
      // Test different time formats
      final testCases = [
        {
          'duration': const Duration(minutes: 5),
          'expected': '5m ago',
        },
        {
          'duration': const Duration(hours: 2),
          'expected': '2h ago',
        },
        {
          'duration': const Duration(days: 3),
          'expected': '3d ago',
        },
      ];

      for (final testCase in testCases) {
        final room = testChatRoom.copyWith(
          createdAt: DateTime.now().subtract(testCase['duration'] as Duration),
        );

        await tester.pumpWidget(createWidgetUnderTest(room));
        expect(find.text(testCase['expected'] as String), findsOneWidget);
      }
    });

    testWidgets('should handle very recent creation time', (tester) async {
      // Arrange
      final veryRecentRoom = testChatRoom.copyWith(
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(veryRecentRoom));

      // Assert
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('should truncate long room names', (tester) async {
      // Arrange
      final roomWithLongName = testChatRoom.copyWith(
        name: 'This is a very long room name that should be truncated',
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithLongName));

      // Assert
      final textWidget = tester.widget<Text>(
          find.text('This is a very long room name that should be truncated'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('should truncate long descriptions', (tester) async {
      // Arrange
      final roomWithLongDescription = testChatRoom.copyWith(
        description:
            'This is a very long description that should be truncated to prevent the card from becoming too tall and maintain a consistent layout',
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(roomWithLongDescription));

      // Assert
      final textWidget = tester.widget<Text>(find.text(
          'This is a very long description that should be truncated to prevent the card from becoming too tall and maintain a consistent layout'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 2);
    });
  });
}
