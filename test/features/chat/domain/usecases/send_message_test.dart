import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/message.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/send_message.dart';

import 'send_message_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late SendMessageUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = SendMessageUseCase(mockChatRepository);
  });

  const tRoomId = 'room123';
  const tContent = 'Hello, world!';
  final tMessage = Message(
    id: 'msg123',
    roomId: tRoomId,
    senderId: 'user1',
    content: tContent,
    type: MessageType.text,
    timestamp: DateTime(2024, 1, 1),
    status: MessageStatus.sent,
    readBy: {},
  );

  group('SendMessageUseCase', () {
    test('should return Message when sending is successful', () async {
      // arrange
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tContent,
        type: MessageType.text,
      ));

      // assert
      expect(result, Right(tMessage));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tContent,
        type: MessageType.text,
      ));
      verifyNoMoreInteractions(mockChatRepository);
    });

    test('should trim whitespace from content', () async {
      // arrange
      const tContentWithSpaces = '  Hello, world!  ';
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tContentWithSpaces,
        type: MessageType.text,
      ));

      // assert
      expect(result, Right(tMessage));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tContent,
        type: MessageType.text,
      ));
    });

    test('should use default MessageType.text when type is not specified',
        () async {
      // arrange
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tContent,
      ));

      // assert
      expect(result, Right(tMessage));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tContent,
        type: MessageType.text,
      ));
    });

    test('should return ValidationFailure when room ID is empty', () async {
      // act
      final result = await useCase(const SendMessageParams(
        roomId: '',
        content: tContent,
      ));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when room ID is only whitespace',
        () async {
      // act
      final result = await useCase(const SendMessageParams(
        roomId: '   ',
        content: tContent,
      ));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Room ID')));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when text content is empty',
        () async {
      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: '',
        type: MessageType.text,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidMessageContent()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should return ValidationFailure when text content is only whitespace',
        () async {
      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: '   ',
        type: MessageType.text,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidMessageContent()));
      verifyZeroInteractions(mockChatRepository);
    });

    test(
        'should return ValidationFailure when text content exceeds 1000 characters',
        () async {
      // arrange
      final tLongContent = 'A' * 1001; // 1001 characters

      // act
      final result = await useCase(SendMessageParams(
        roomId: tRoomId,
        content: tLongContent,
        type: MessageType.text,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidMessageContent()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should accept valid image content', () async {
      // arrange
      const tImageUrl = 'https://example.com/image.jpg';
      final tImageMessage = tMessage.copyWith(
        content: tImageUrl,
        type: MessageType.image,
      );
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Right(tImageMessage));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tImageUrl,
        type: MessageType.image,
      ));

      // assert
      expect(result, Right(tImageMessage));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tImageUrl,
        type: MessageType.image,
      ));
    });

    test('should return ValidationFailure when image content is empty',
        () async {
      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: '',
        type: MessageType.image,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidMessageContent()));
      verifyZeroInteractions(mockChatRepository);
    });

    test('should accept valid file content', () async {
      // arrange
      const tFileUrl = 'https://example.com/document.pdf';
      final tFileMessage = tMessage.copyWith(
        content: tFileUrl,
        type: MessageType.file,
      );
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Right(tFileMessage));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tFileUrl,
        type: MessageType.file,
      ));

      // assert
      expect(result, Right(tFileMessage));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tFileUrl,
        type: MessageType.file,
      ));
    });

    test('should return ServerFailure when repository call fails', () async {
      // arrange
      const tFailure = ServerFailure('Failed to send message');
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tContent,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(mockChatRepository.sendMessage(
        roomId: tRoomId,
        content: tContent,
        type: MessageType.text,
      ));
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockChatRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
        type: anyNamed('type'),
      )).thenThrow(Exception('Network error'));

      // act
      final result = await useCase(const SendMessageParams(
        roomId: tRoomId,
        content: tContent,
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
