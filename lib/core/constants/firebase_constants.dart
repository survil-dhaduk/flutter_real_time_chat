/// Firebase collection names and field constants
class FirebaseConstants {
  // Collection names
  static const String usersCollection = 'users';
  static const String chatRoomsCollection = 'chatRooms';
  static const String messagesCollection = 'messages';

  // User fields
  static const String userIdField = 'id';
  static const String userEmailField = 'email';
  static const String userDisplayNameField = 'displayName';
  static const String userPhotoUrlField = 'photoUrl';
  static const String userCreatedAtField = 'createdAt';
  static const String userLastSeenField = 'lastSeen';
  static const String userIsOnlineField = 'isOnline';

  // ChatRoom fields
  static const String roomIdField = 'id';
  static const String roomNameField = 'name';
  static const String roomDescriptionField = 'description';
  static const String roomCreatedByField = 'createdBy';
  static const String roomCreatedAtField = 'createdAt';
  static const String roomParticipantsField = 'participants';
  static const String roomLastMessageIdField = 'lastMessageId';
  static const String roomLastMessageTimeField = 'lastMessageTime';

  // Message fields
  static const String messageIdField = 'id';
  static const String messageRoomIdField = 'roomId';
  static const String messageSenderIdField = 'senderId';
  static const String messageContentField = 'content';
  static const String messageTypeField = 'type';
  static const String messageTimestampField = 'timestamp';
  static const String messageStatusField = 'status';
  static const String messageReadByField = 'readBy';

  // Message type values
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';

  // Message status values
  static const String messageStatusSent = 'sent';
  static const String messageStatusDelivered = 'delivered';
  static const String messageStatusRead = 'read';
}
