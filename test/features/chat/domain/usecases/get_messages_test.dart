import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/get_messages.dart';

import 'get_messages_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late GetMessagesUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = GetMessagesUseCase(mockChatRepository);
  });

  const tRoomId = 'room123';
  final tMessages = [
    Message(
      id: 'msg1',
      roomId: tRoomId,
      senderId: 'user1',
      content: 'Hello!',
      type: MessageType.text,
      timestamp: DateTime(2024, 1, 1, 10, 0),
      status: MessageStatus.read,
      readBy: {'user2': DateTime(2024, 1, 1, 10, 1)},
    ),
    Message(
      id: 'msg2',
      roomId: tRoomId,
      senderId: 'user2',
      content: 'Hi there!',
      type: MessageType.text,
      timestamp: DateTime(2024, 1, 1, 10, 2),
      status: MessageStatus.delivered,
      readBy: {},
    ),
  ];

  group('GetMessagesUseCase', () {
    test('should return list of messages when repository call is successful',
        () async {
      // arrange
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await useCase(const GetMessagesParams(roomId: tRoomId));

      // assert
      expect(result, Right(tMessages));
      verify(mockChatRepository.getMessages(
        roomId: tRoomId,
        limit: null,
        lastMessageId: null,
      ));
      verifyNoMoreInteractions(mockChatRepository);
    });

    test('should return messages with pagination parameters', () async {
      // arrange
      const tLimit = 20;
      const tLastMessageId = 'msg123';
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await useCase(const GetMessagesParams(
        roomId: tRoomId,
        limit: tLimit,
        lastMessageId: tLastMessageId,
      ));

      // assert
      expect(result, Right(tMessages));
      verify(mockChatRepository.getMessages(
        roomId: tRoomId,
        limit: tLimit,
        lastMessageId: tLastMessageId,
      ));
    });

    test('should return empty list when no messages exist', () async {
      // arrange
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => const Right(<Message>[]));

      // act
      final result = await useCase(const GetMessagesParams(roomId: tRoomId));

      // assert
      expect(result, const Right(<Message>[]));
      verify(mockChatRepository.getMessages(
        roomId: tRoomId,
        limit: null,
        lastMessageId: null,
      ));
    });

    test('should return ValidationFailure when room ID is empty', () async {
      // act
      final result = await useCase(const GetMessagesParams(roomId: ''));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room ID is only whitespace',
        () async {
      // act
      final result = await useCase(const GetMessagesParams(roomId: '   '));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when limit is zero', () async {
      // act
      final result = await useCase(const GetMessagesParams(
        roomId: tRoomId,
        limit: 0,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('greater than 0')),
        (success) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when limit is negative', () async {
      // act
      final result = await useCase(const GetMessagesParams(
        roomId: tRoomId,
        limit: -5,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('greater than 0')),
        (success) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockChatRepository);
    });

    test('should accept positive limit values', () async {
      // arrange
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await useCase(const GetMessagesParams(
        roomId: tRoomId,
        limit: 10,
      ));

      // assert
      expect(result, Right(tMessages));
      verify(mockChatRepository.getMessages(
        roomId: tRoomId,
        limit: 10,
        lastMessageId: null,
      ));
    });

    test('should return ServerFailure when repository call fails', () async {
      // arrange
      const tFailure = ServerFailure('Failed to retrieve messages');
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const GetMessagesParams(roomId: tRoomId));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.getMessages(
        roomId: tRoomId,
        limit: null,
        lastMessageId: null,
      ));
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenThrow(Exception('Network error'));

      // act
      final result = await useCase(const GetMessagesParams(roomId: tRoomId));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (success) => fail('Should return failure'),
      );
    });

    test('should return stream of messages', () async {
      // arrange
      final tStream = Stream.value(tMessages);
      when(mockChatRepository.getMessagesStream(roomId: anyNamed('roomId')))
          .thenAnswer((_) => tStream);

      // act
      final result = useCase.getMessagesStream(tRoomId);

      // assert
      expect(result, tStream);
      verify(mockChatRepository.getMessagesStream(roomId: tRoomId));
    });

    test('should handle network failure gracefully', () async {
      // arrange
      const tFailure = NetworkFailure('No internet connection');
      when(mockChatRepository.getMessages(
        roomId: anyNamed('roomId'),
        limit: anyNamed('limit'),
        lastMessageId: anyNamed('lastMessageId'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const GetMessagesParams(roomId: tRoomId));

      // assert
      expect(result, const Left(tFailure));
    });
  });
}
