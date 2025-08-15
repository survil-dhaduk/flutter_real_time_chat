import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/get_chat_rooms.dart';

import 'get_chat_rooms_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late GetChatRoomsUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = GetChatRoomsUseCase(mockChatRepository);
  });

  final tChatRooms = [
    ChatRoom(
      id: '1',
      name: 'General',
      description: 'General discussion',
      createdBy: 'user1',
      createdAt: DateTime(2024, 1, 1),
      participants: ['user1', 'user2'],
    ),
    ChatRoom(
      id: '2',
      name: 'Tech Talk',
      description: 'Technology discussions',
      createdBy: 'user2',
      createdAt: DateTime(2024, 1, 2),
      participants: ['user2', 'user3'],
    ),
  ];

  group('GetChatRoomsUseCase', () {
    test('should return list of chat rooms when repository call is successful',
        () async {
      // arrange
      when(mockChatRepository.getChatRooms())
          .thenAnswer((_) async => Right(tChatRooms));

      // act
      final result = await useCase();

      // assert
      expect(result, Right(tChatRooms));
      verify(mockChatRepository.getChatRooms());
      verifyNoMoreInteractions(mockChatRepository);
    });

    test('should return empty list when no chat rooms exist', () async {
      // arrange
      when(mockChatRepository.getChatRooms())
          .thenAnswer((_) async => const Right(<ChatRoom>[]));

      // act
      final result = await useCase();

      // assert
      expect(result, const Right(<ChatRoom>[]));
      verify(mockChatRepository.getChatRooms());
    });

    test('should return ServerFailure when repository call fails', () async {
      // arrange
      const tFailure = ServerFailure('Failed to retrieve chat rooms');
      when(mockChatRepository.getChatRooms())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.getChatRooms());
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockChatRepository.getChatRooms())
          .thenThrow(Exception('Network error'));

      // act
      final result = await useCase();

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (success) => fail('Should return failure'),
      );
      verify(mockChatRepository.getChatRooms());
    });

    test('should return stream of chat rooms', () async {
      // arrange
      final tStream = Stream.value(tChatRooms);
      when(mockChatRepository.chatRoomsStream).thenAnswer((_) => tStream);

      // act
      final result = useCase.getChatRoomsStream();

      // assert
      expect(result, tStream);
      verify(mockChatRepository.chatRoomsStream);
    });
  });
}
