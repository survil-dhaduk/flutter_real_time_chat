import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

/// Parameters for joining a chat room
class JoinChatRoomParams extends Equatable {
  final String roomId;

  const JoinChatRoomParams({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Use case for joining an existing chat room with participant management
class JoinChatRoomUseCase implements UseCase<ChatRoom, JoinChatRoomParams> {
  final ChatRepository repository;

  const JoinChatRoomUseCase(this.repository);

  @override
  Future<Either<Failure, ChatRoom>> call(JoinChatRoomParams params) async {
    // Validate room ID
    if (params.roomId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Room ID'));
    }

    try {
      // First check if the room exists
      final roomResult =
          await repository.getChatRoomById(roomId: params.roomId);

      return roomResult.fold(
        (failure) => Left(failure),
        (room) async {
          // Join the room
          return await repository.joinChatRoom(roomId: params.roomId);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to join chat room: ${e.toString()}'));
    }
  }
}
