import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/join_chat_room.dart';

import 'join_chat_room_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late JoinChatRoomUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = JoinChatRoomUseCase(mockChatRepository);
  });

  const tRoomId = 'room123';
  final tChatRoom = ChatRoom(
    id: tRoomId,
    name: 'General Discussion',
    description: 'A place for general conversations',
    createdBy: 'user1',
    createdAt: DateTime(2024, 1, 1),
    participants: ['user1', 'user2'],
  );

  group('JoinChatRoomUseCase', () {
    test('should return ChatRoom when joining is successful', () async {
      // arrange
      when(mockChatRepository.getChatRoomById(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => Right(tChatRoom));
      when(mockChatRepository.joinChatRoom(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => Right(tChatRoom));

      // act
      final result = await useCase(const JoinChatRoomParams(roomId: tRoomId));

      // assert
      expect(result, Right(tChatRoom));
      verify(mockChatRepository.getChatRoomById(roomId: tRoomId));
      verify(mockChatRepository.joinChatRoom(roomId: tRoomId));
      verifyNoMoreInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room ID is empty', () async {
      // act
      final result = await useCase(const JoinChatRoomParams(roomId: ''));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room ID is only whitespace',
        () async {
      // act
      final result = await useCase(const JoinChatRoomParams(roomId: '   '));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return failure when room does not exist', () async {
      // arrange
      const tFailure = ServerFailure('Room not found');
      when(mockChatRepository.getChatRoomById(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const JoinChatRoomParams(roomId: tRoomId));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.getChatRoomById(roomId: tRoomId));
      verifyNever(mockChatRepository.joinChatRoom(roomId: anyNamed('roomId')));
    });

    test('should return failure when joining room fails', () async {
      // arrange
      const tFailure = ServerFailure('Failed to join room');
      when(mockChatRepository.getChatRoomById(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => Right(tChatRoom));
      when(mockChatRepository.joinChatRoom(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const JoinChatRoomParams(roomId: tRoomId));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.getChatRoomById(roomId: tRoomId));
      verify(mockChatRepository.joinChatRoom(roomId: tRoomId));
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockChatRepository.getChatRoomById(roomId: anyNamed('roomId')))
          .thenThrow(Exception('Network error'));

      // act
      final result = await useCase(const JoinChatRoomParams(roomId: tRoomId));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (success) => fail('Should return failure'),
      );
      verify(mockChatRepository.getChatRoomById(roomId: tRoomId));
    });

    test('should handle network failure gracefully', () async {
      // arrange
      const tFailure = NetworkFailure('No internet connection');
      when(mockChatRepository.getChatRoomById(roomId: anyNamed('roomId')))
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const JoinChatRoomParams(roomId: tRoomId));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.getChatRoomById(roomId: tRoomId));
    });
  });
}
