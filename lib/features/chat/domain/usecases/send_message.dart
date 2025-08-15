import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Parameters for sending a message
class SendMessageParams extends Equatable {
  final String roomId;
  final String content;
  final MessageType type;

  const SendMessageParams({
    required this.roomId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object> get props => [roomId, content, type];
}

/// Use case for sending a message with validation
class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final ChatRepository repository;

  const SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    // Validate room ID
    if (params.roomId.trim().isEmpty) {
      return const Left(ValidationFailure.emptyField('Room ID'));
    }

    // Validate message content based on type
    if (!_isValidContent(params.content, params.type)) {
      return const Left(ValidationFailure.invalidMessageContent());
    }

    try {
      return await repository.sendMessage(
        roomId: params.roomId,
        content: params.content.trim(),
        type: params.type,
      );
    } catch (e) {
      return Left(ServerFailure('Failed to send message: ${e.toString()}'));
    }
  }

  /// Validates message content based on message type
  bool _isValidContent(String content, MessageType type) {
    switch (type) {
      case MessageType.text:
        final trimmed = content.trim();
        return trimmed.isNotEmpty && trimmed.length <= 1000;
      case MessageType.image:
      case MessageType.file:
        return content.isNotEmpty; // Should be a URL or file path
    }
  }
}
