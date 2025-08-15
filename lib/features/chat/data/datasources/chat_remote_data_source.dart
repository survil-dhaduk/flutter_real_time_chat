import '../models/chat_room_model.dart';
import '../models/message_model.dart';

/// Abstract interface for chat remote data source operations
abstract class ChatRemoteDataSource {
  /// Gets all available chat rooms
  /// Returns a list of ChatRoomModel objects
  Future<List<ChatRoomModel>> getChatRooms();

  /// Creates a new chat room
  /// Returns the created ChatRoomModel with generated ID
  Future<ChatRoomModel> createChatRoom({
    required String name,
    required String description,
    required String createdBy,
  });

  /// Joins a chat room by adding user to participants
  /// Throws exception if room doesn't exist or user already joined
  Future<void> joinChatRoom({
    required String roomId,
    required String userId,
  });

  /// Sends a message to a chat room
  /// Returns the sent MessageModel with generated ID and timestamp
  Future<MessageModel> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    required String messageType,
  });

  /// Gets messages for a specific chat room with real-time updates
  /// Returns a stream of message lists ordered by timestamp
  Stream<List<MessageModel>> getMessages(String roomId);

  /// Gets chat rooms with real-time updates
  /// Returns a stream of chat room lists
  Stream<List<ChatRoomModel>> getChatRoomsStream();

  /// Marks a message as read by a specific user
  /// Updates the message's readBy field and status
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  });

  /// Updates message status (sent -> delivered -> read)
  /// Used for automatic status progression
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  });

  /// Gets participant information for a chat room
  /// Returns list of user IDs who are participants
  Future<List<String>> getRoomParticipants(String roomId);

  /// Leaves a chat room by removing user from participants
  /// Throws exception if room doesn't exist or user not a participant
  Future<void> leaveChatRoom({
    required String roomId,
    required String userId,
  });
}
