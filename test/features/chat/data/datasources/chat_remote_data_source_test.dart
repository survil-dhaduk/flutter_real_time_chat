import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:flutter_real_time_chat/features/chat/data/datasources/chat_remote_data_source_impl.dart';
import 'package:flutter_real_time_chat/features/chat/data/models/chat_room_model.dart';
import 'package:flutter_real_time_chat/features/chat/data/models/message_model.dart';
import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/core/constants/firebase_constants.dart';

@GenerateMocks([FirebaseFirestore])
import 'chat_remote_data_source_test.mocks.dart';

void main() {
  group('ChatRemoteDataSourceImpl', () {
    late ChatRemoteDataSourceImpl dataSource;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = ChatRemoteDataSourceImpl(firestore: fakeFirestore);
    });

    group('createChatRoom', () {
      test('should create chat room successfully', () async {
        // Arrange
        const name = 'Test Room';
        const description = 'Test Description';
        const createdBy = 'user123';

        // Act
        final result = await dataSource.createChatRoom(
          name: name,
          description: description,
          createdBy: createdBy,
        );

        // Assert
        expect(result.name, equals(name));
        expect(result.description, equals(description));
        expect(result.createdBy, equals(createdBy));
        expect(result.participants, contains(createdBy));
        expect(result.id, isNotEmpty);
      });

      test('should throw ValidationFailure when name is empty', () async {
        // Arrange
        const name = '';
        const description = 'Test Description';
        const createdBy = 'user123';

        // Act & Assert
        expect(
          () => dataSource.createChatRoom(
            name: name,
            description: description,
            createdBy: createdBy,
          ),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('sendMessage', () {
      test('should send message successfully', () async {
        // Arrange
        const senderId = 'user123';
        const content = 'Hello World';
        const messageType = 'text';

        // Create a room first
        final room = await dataSource.createChatRoom(
          name: 'Test Room',
          description: 'Test Description',
          createdBy: senderId,
        );

        // Act
        final result = await dataSource.sendMessage(
          roomId: room.id,
          senderId: senderId,
          content: content,
          messageType: messageType,
        );

        // Assert
        expect(result.roomId, equals(room.id));
        expect(result.senderId, equals(senderId));
        expect(result.content, equals(content));
        expect(result.id, isNotEmpty);
      });

      test('should throw ValidationFailure when content is empty', () async {
        // Arrange
        const senderId = 'user123';
        const content = '';
        const messageType = 'text';

        // Create a room first
        final room = await dataSource.createChatRoom(
          name: 'Test Room',
          description: 'Test Description',
          createdBy: senderId,
        );

        // Act & Assert
        expect(
          () => dataSource.sendMessage(
            roomId: room.id,
            senderId: senderId,
            content: content,
            messageType: messageType,
          ),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('joinChatRoom', () {
      test('should join chat room successfully', () async {
        // Arrange
        const roomId = 'room123';
        const userId = 'user456';
        const createdBy = 'user123';

        // Create a room first
        await dataSource.createChatRoom(
          name: 'Test Room',
          description: 'Test Description',
          createdBy: createdBy,
        );

        // Get the actual room ID from Firestore
        final rooms = await dataSource.getChatRooms();
        final actualRoomId = rooms.first.id;

        // Act
        await dataSource.joinChatRoom(roomId: actualRoomId, userId: userId);

        // Assert - verify user was added to participants
        final updatedRooms = await dataSource.getChatRooms();
        final updatedRoom = updatedRooms.first;
        expect(updatedRoom.participants, contains(userId));
      });

      test('should throw ValidationFailure when roomId is empty', () async {
        // Arrange
        const roomId = '';
        const userId = 'user456';

        // Act & Assert
        expect(
          () => dataSource.joinChatRoom(roomId: roomId, userId: userId),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('getChatRooms', () {
      test('should return empty list when no rooms exist', () async {
        // Act
        final result = await dataSource.getChatRooms();

        // Assert
        expect(result, isEmpty);
      });

      test('should return list of chat rooms', () async {
        // Arrange - create a room first
        await dataSource.createChatRoom(
          name: 'Test Room',
          description: 'Test Description',
          createdBy: 'user123',
        );

        // Act
        final result = await dataSource.getChatRooms();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Test Room'));
      });
    });

    group('markMessageAsRead', () {
      test('should throw ValidationFailure when messageId is empty', () async {
        // Arrange
        const messageId = '';
        const userId = 'user123';

        // Act & Assert
        expect(
          () => dataSource.markMessageAsRead(
            messageId: messageId,
            userId: userId,
          ),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });
  });
}
