import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Parameters for getting messages with pagination support
class GetMessagesParams extends Equatable {
  final String roomId;
  final int? limit;
  final String? lastMessageId;

  const GetMessagesParams({
    required this.roomId,
    this.limit,
    this.lastMessageId,
  });

  @override
  List<Object?> get props => [roomId, limit, lastMessageId];
}

/// Use case for retrieving messages with pagination support
class GetMessagesUseCase implements UseCase<List<Message>, GetMessagesParams> {
  final ChatRepository repository;

  const GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) async {
    // Validate room ID
    if (params.roomId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Room ID'));
    }

    // Validate limit if provided
    if (params.limit != null && params.limit! <= 0) {
      return const Left(ValidationFailure('Limit must be greater than 0'));
    }

    try {
      return await repository.getMessages(
        roomId: params.roomId,
        limit: params.limit,
        lastMessageId: params.lastMessageId,
      );
    } catch (e) {
      return Left(
          ServerFailure('Failed to retrieve messages: ${e.toString()}'));
    }
  }

  /// Gets real-time stream of messages for a room
  Stream<List<Message>> getMessagesStream(String roomId) {
    return repository.getMessagesStream(roomId: roomId);
  }
}
