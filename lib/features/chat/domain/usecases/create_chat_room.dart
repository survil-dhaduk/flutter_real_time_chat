import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

/// Parameters for creating a chat room
class CreateChatRoomParams extends Equatable {
  final String name;
  final String description;

  const CreateChatRoomParams({
    required this.name,
    required this.description,
  });

  @override
  List<Object> get props => [name, description];
}

/// Use case for creating a new chat room with validation
class CreateChatRoomUseCase implements UseCase<ChatRoom, CreateChatRoomParams> {
  final ChatRepository repository;

  const CreateChatRoomUseCase(this.repository);

  @override
  Future<Either<Failure, ChatRoom>> call(CreateChatRoomParams params) async {
    // Validate room name
    if (!ChatRoom.isValidName(params.name)) {
      return const Left(ValidationFailure.invalidRoomName());
    }

    // Validate room description
    if (!ChatRoom.isValidDescription(params.description)) {
      return const Left(ValidationFailure(
        'Room description cannot exceed 500 characters.',
      ));
    }

    try {
      return await repository.createChatRoom(
        name: params.name.trim(),
        description: params.description.trim(),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to create chat room: ${e.toString()}'));
    }
  }
}
