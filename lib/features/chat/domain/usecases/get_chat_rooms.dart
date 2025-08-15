import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

/// Use case for retrieving all available chat rooms
class GetChatRoomsUseCase implements NoParamsUseCase<List<ChatRoom>> {
  final ChatRepository repository;

  const GetChatRoomsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatRoom>>> call() async {
    try {
      return await repository.getChatRooms();
    } catch (e) {
      return Left(
          ServerFailure('Failed to retrieve chat rooms: ${e.toString()}'));
    }
  }

  /// Gets real-time stream of chat rooms
  Stream<List<ChatRoom>> getChatRoomsStream() {
    return repository.chatRoomsStream;
  }
}
