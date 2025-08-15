import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

/// Parameters for marking a message as read
class MarkMessageAsReadParams extends Equatable {
  final String messageId;
  final String roomId;

  const MarkMessageAsReadParams({
    required this.messageId,
    required this.roomId,
  });

  @override
  List<Object> get props => [messageId, roomId];
}

/// Parameters for marking all messages in a room as read
class MarkAllMessagesAsReadParams extends Equatable {
  final String roomId;

  const MarkAllMessagesAsReadParams({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Use case for marking messages as read with status tracking
class MarkMessageAsReadUseCase
    implements UseCase<void, MarkMessageAsReadParams> {
  final ChatRepository repository;

  const MarkMessageAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkMessageAsReadParams params) async {
    // Validate message ID
    if (params.messageId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Message ID'));
    }

    // Validate room ID
    if (params.roomId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Room ID'));
    }

    try {
      return await repository.markMessageAsRead(
        messageId: params.messageId,
        roomId: params.roomId,
      );
    } catch (e) {
      return Left(
          ServerFailure('Failed to mark message as read: ${e.toString()}'));
    }
  }

  /// Marks all messages in a room as read
  Future<Either<Failure, void>> markAllMessagesAsRead(
    MarkAllMessagesAsReadParams params,
  ) async {
    // Validate room ID
    if (params.roomId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Room ID'));
    }

    try {
      return await repository.markAllMessagesAsRead(roomId: params.roomId);
    } catch (e) {
      return Left(ServerFailure(
          'Failed to mark all messages as read: ${e.toString()}'));
    }
  }
}
