import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_real_time_chat/features/chat/domain/usecases/mark_message_as_read.dart';

import 'mark_message_as_read_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late MarkMessageAsReadUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = MarkMessageAsReadUseCase(mockChatRepository);
  });

  const tMessageId = 'msg123';
  const tRoomId = 'room123';

  group('MarkMessageAsReadUseCase', () {
    group('markMessageAsRead', () {
      test('should complete successfully when repository call succeeds',
          () async {
        // arrange
        when(mockChatRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          roomId: anyNamed('roomId'),
        )).thenAnswer((_) async => const Right(null));

        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: tMessageId,
          roomId: tRoomId,
        ));

        // assert
        expect(result, const Right(null));
        verify(mockChatRepository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        ));
        verifyNoMoreInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when message ID is empty',
          () async {
        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: '',
          roomId: tRoomId,
        ));

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Message ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when message ID is only whitespace',
          () async {
        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: '   ',
          roomId: tRoomId,
        ));

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Message ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: tMessageId,
          roomId: '',
        ));

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Room ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when room ID is only whitespace',
          () async {
        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: tMessageId,
          roomId: '   ',
        ));

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Room ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ServerFailure when repository call fails', () async {
        // arrange
        const tFailure = ServerFailure('Failed to mark message as read');
        when(mockChatRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          roomId: anyNamed('roomId'),
        )).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: tMessageId,
          roomId: tRoomId,
        ));

        // assert
        expect(result, const Left(tFailure));
        verify(mockChatRepository.markMessageAsRead(
          messageId: tMessageId,
          roomId: tRoomId,
        ));
      });

      test('should return ServerFailure when repository throws exception',
          () async {
        // arrange
        when(mockChatRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          roomId: anyNamed('roomId'),
        )).thenThrow(Exception('Network error'));

        // act
        final result = await useCase(const MarkMessageAsReadParams(
          messageId: tMessageId,
          roomId: tRoomId,
        ));

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (success) => fail('Should return failure'),
        );
      });
    });

    group('markAllMessagesAsRead', () {
      test('should complete successfully when repository call succeeds',
          () async {
        // arrange
        when(mockChatRepository.markAllMessagesAsRead(
                roomId: anyNamed('roomId')))
            .thenAnswer((_) async => const Right(null));

        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: tRoomId),
        );

        // assert
        expect(result, const Right(null));
        verify(mockChatRepository.markAllMessagesAsRead(roomId: tRoomId));
        verifyNoMoreInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when room ID is empty', () async {
        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: ''),
        );

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Room ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ValidationFailure when room ID is only whitespace',
          () async {
        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: '   '),
        );

        // assert
        expect(result, const Left(ValidationFailure.emptyField('Room ID')));
        verifyZeroInteractions(mockChatRepository);
      });

      test('should return ServerFailure when repository call fails', () async {
        // arrange
        const tFailure = ServerFailure('Failed to mark all messages as read');
        when(mockChatRepository.markAllMessagesAsRead(
                roomId: anyNamed('roomId')))
            .thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: tRoomId),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(mockChatRepository.markAllMessagesAsRead(roomId: tRoomId));
      });

      test('should return ServerFailure when repository throws exception',
          () async {
        // arrange
        when(mockChatRepository.markAllMessagesAsRead(
                roomId: anyNamed('roomId')))
            .thenThrow(Exception('Network error'));

        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: tRoomId),
        );

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (success) => fail('Should return failure'),
        );
      });

      test('should handle network failure gracefully', () async {
        // arrange
        const tFailure = NetworkFailure('No internet connection');
        when(mockChatRepository.markAllMessagesAsRead(
                roomId: anyNamed('roomId')))
            .thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await useCase.markAllMessagesAsRead(
          const MarkAllMessagesAsReadParams(roomId: tRoomId),
        );

        // assert
        expect(result, const Left(tFailure));
      });
    });

    test('should handle auth failure when user is not authenticated', () async {
      // arrange
      const tFailure = AuthFailure.notAuthenticated();
      when(mockChatRepository.markMessageAsRead(
        messageId: anyNamed('messageId'),
        roomId: anyNamed('roomId'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const MarkMessageAsReadParams(
        messageId: tMessageId,
        roomId: tRoomId,
      ));

      // assert
      expect(result, const Left(tFailure));
    });
  });
}
