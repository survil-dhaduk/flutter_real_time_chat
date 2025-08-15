import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/create_chat_room.dart';

import 'create_chat_room_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late CreateChatRoomUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = CreateChatRoomUseCase(mockChatRepository);
  });

  const tName = 'General Discussion';
  const tDescription = 'A place for general conversations';
  final tChatRoom = ChatRoom(
    id: '1',
    name: tName,
    description: tDescription,
    createdBy: 'user1',
    createdAt: DateTime(2024, 1, 1),
    participants: ['user1'],
  );

  group('CreateChatRoomUseCase', () {
    test('should return ChatRoom when creation is successful', () async {
      // arrange
      when(mockChatRepository.createChatRoom(
        name: anyNamed('name'),
        description: anyNamed('description'),
      )).thenAnswer((_) async => Right(tChatRoom));

      // act
      final result = await useCase(const CreateChatRoomParams(
        name: tName,
        description: tDescription,
      ));

      // assert
      expect(result, Right(tChatRoom));
      verify(mockChatRepository.createChatRoom(
        name: tName,
        description: tDescription,
      ));
      verifyNoMoreInteractions(mockChatRepository);
    });

    test('should trim whitespace from name and description', () async {
      // arrange
      const tNameWithSpaces = '  General Discussion  ';
      const tDescriptionWithSpaces = '  A place for general conversations  ';
      when(mockChatRepository.createChatRoom(
        name: anyNamed('name'),
        description: anyNamed('description'),
      )).thenAnswer((_) async => Right(tChatRoom));

      // act
      final result = await useCase(const CreateChatRoomParams(
        name: tNameWithSpaces,
        description: tDescriptionWithSpaces,
      ));

      // assert
      expect(result, Right(tChatRoom));
      verify(mockChatRepository.createChatRoom(
        name: tName,
        description: tDescription,
      ));
    });

    test('should return ValidationFailure when room name is empty', () async {
      // act
      final result = await useCase(const CreateChatRoomParams(
        name: '',
        description: tDescription,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidRoomName()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room name is too short',
        () async {
      // act
      final result = await useCase(const CreateChatRoomParams(
        name: 'A',
        description: tDescription,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidRoomName()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room name is too long',
        () async {
      // arrange
      final tLongName = 'A' * 101; // 101 characters

      // act
      final result = await useCase(CreateChatRoomParams(
        name: tLongName,
        description: tDescription,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidRoomName()));
      verifyZeroInteractions(mockChatRepository);
    });

    test(
        'should return ValidationFailure when room name contains invalid characters',
        () async {
      // act
      final result = await useCase(const CreateChatRoomParams(
        name: 'Invalid<Name>',
        description: tDescription,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidRoomName()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when description is too long',
        () async {
      // arrange
      final tLongDescription = 'A' * 501; // 501 characters

      // act
      final result = await useCase(CreateChatRoomParams(
        name: tName,
        description: tLongDescription,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('500 characters')),
        (success) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ServerFailure when repository call fails', () async {
      // arrange
      const tFailure = ServerFailure('Failed to create chat room');
      when(mockChatRepository.createChatRoom(
        name: anyNamed('name'),
        description: anyNamed('description'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const CreateChatRoomParams(
        name: tName,
        description: tDescription,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.createChatRoom(
        name: tName,
        description: tDescription,
      ));
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockChatRepository.createChatRoom(
        name: anyNamed('name'),
        description: anyNamed('description'),
      )).thenThrow(Exception('Network error'));

      // act
      final result = await useCase(const CreateChatRoomParams(
        name: tName,
        description: tDescription,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (success) => fail('Should return failure'),
      );
    });
  });
}
