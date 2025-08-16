import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import '../../features/chat/data/models/chat_room_model.dart';
import '../../features/chat/data/models/message_model.dart';

/// Service for managing local caching using Hive
class CacheService {
  static const String _chatRoomsBoxName = 'chat_rooms';
  static const String _messagesBoxName = 'messages';
  static const String _userDataBoxName = 'user_data';
  static const String _settingsBoxName = 'settings';

  final Logger _logger;

  Box<String>? _chatRoomsBox;
  Box<String>? _messagesBox;
  Box<String>? _userDataBox;
  Box<String>? _settingsBox;

  CacheService({Logger? logger}) : _logger = logger ?? const Logger();

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      _logger.info('CacheService: Initializing Hive');

      await Hive.initFlutter();

      // Open boxes
      _chatRoomsBox = await Hive.openBox<String>(_chatRoomsBoxName);
      _messagesBox = await Hive.openBox<String>(_messagesBoxName);
      _userDataBox = await Hive.openBox<String>(_userDataBoxName);
      _settingsBox = await Hive.openBox<String>(_settingsBoxName);

      _logger.info('CacheService: Successfully initialized');
    } catch (e) {
      _logger.error('CacheService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Cache chat rooms
  Future<void> cacheChatRooms(List<ChatRoomModel> chatRooms) async {
    try {
      if (_chatRoomsBox == null) {
        _logger.warning('CacheService: Chat rooms box not initialized');
        return;
      }

      final roomsJson =
          chatRooms.map((room) => jsonEncode(room.toJson())).toList();
      await _chatRoomsBox!.put('rooms', jsonEncode(roomsJson));

      _logger.info('CacheService: Cached ${chatRooms.length} chat rooms');
    } catch (e) {
      _logger.error('CacheService: Failed to cache chat rooms: $e');
    }
  }

  /// Get cached chat rooms
  Future<List<ChatRoomModel>?> getCachedChatRooms() async {
    try {
      if (_chatRoomsBox == null) {
        _logger.warning('CacheService: Chat rooms box not initialized');
        return null;
      }

      final cachedData = _chatRoomsBox!.get('rooms');
      if (cachedData == null) {
        return null;
      }

      final roomsJsonList = List<String>.from(jsonDecode(cachedData));
      final chatRooms = roomsJsonList
          .map((roomJson) => ChatRoomModel.fromJson(jsonDecode(roomJson)))
          .toList();

      _logger.info(
          'CacheService: Retrieved ${chatRooms.length} cached chat rooms');
      return chatRooms;
    } catch (e) {
      _logger.error('CacheService: Failed to get cached chat rooms: $e');
      return null;
    }
  }

  /// Cache messages for a specific room
  Future<void> cacheMessages(String roomId, List<MessageModel> messages) async {
    try {
      if (_messagesBox == null) {
        _logger.warning('CacheService: Messages box not initialized');
        return;
      }

      final messagesJson =
          messages.map((msg) => jsonEncode(msg.toJson())).toList();
      await _messagesBox!.put('messages_$roomId', jsonEncode(messagesJson));

      _logger.info(
          'CacheService: Cached ${messages.length} messages for room $roomId');
    } catch (e) {
      _logger
          .error('CacheService: Failed to cache messages for room $roomId: $e');
    }
  }

  /// Get cached messages for a specific room
  Future<List<MessageModel>?> getCachedMessages(String roomId) async {
    try {
      if (_messagesBox == null) {
        _logger.warning('CacheService: Messages box not initialized');
        return null;
      }

      final cachedData = _messagesBox!.get('messages_$roomId');
      if (cachedData == null) {
        return null;
      }

      final messagesJsonList = List<String>.from(jsonDecode(cachedData));
      final messages = messagesJsonList
          .map((msgJson) => MessageModel.fromJson(jsonDecode(msgJson)))
          .toList();

      _logger.info(
          'CacheService: Retrieved ${messages.length} cached messages for room $roomId');
      return messages;
    } catch (e) {
      _logger.error(
          'CacheService: Failed to get cached messages for room $roomId: $e');
      return null;
    }
  }

  /// Cache a single message (for optimistic updates)
  Future<void> cacheMessage(String roomId, MessageModel message) async {
    try {
      final cachedMessages =
          await getCachedMessages(roomId) ?? <MessageModel>[];

      // Check if message already exists
      final existingIndex =
          cachedMessages.indexWhere((msg) => msg.id == message.id);
      if (existingIndex != -1) {
        // Update existing message
        cachedMessages[existingIndex] = message;
      } else {
        // Add new message
        cachedMessages.add(message);
      }

      // Sort by timestamp
      cachedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      await cacheMessages(roomId, cachedMessages);
    } catch (e) {
      _logger.error('CacheService: Failed to cache single message: $e');
    }
  }

  /// Remove cached messages for a room
  Future<void> removeCachedMessages(String roomId) async {
    try {
      if (_messagesBox == null) {
        _logger.warning('CacheService: Messages box not initialized');
        return;
      }

      await _messagesBox!.delete('messages_$roomId');
      _logger.info('CacheService: Removed cached messages for room $roomId');
    } catch (e) {
      _logger.error(
          'CacheService: Failed to remove cached messages for room $roomId: $e');
    }
  }

  /// Cache user data
  Future<void> cacheUserData(String key, Map<String, dynamic> data) async {
    try {
      if (_userDataBox == null) {
        _logger.warning('CacheService: User data box not initialized');
        return;
      }

      await _userDataBox!.put(key, jsonEncode(data));
      _logger.info('CacheService: Cached user data for key: $key');
    } catch (e) {
      _logger.error('CacheService: Failed to cache user data for key $key: $e');
    }
  }

  /// Get cached user data
  Future<Map<String, dynamic>?> getCachedUserData(String key) async {
    try {
      if (_userDataBox == null) {
        _logger.warning('CacheService: User data box not initialized');
        return null;
      }

      final cachedData = _userDataBox!.get(key);
      if (cachedData == null) {
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(cachedData));
    } catch (e) {
      _logger.error(
          'CacheService: Failed to get cached user data for key $key: $e');
      return null;
    }
  }

  /// Cache app settings
  Future<void> cacheSetting(String key, dynamic value) async {
    try {
      if (_settingsBox == null) {
        _logger.warning('CacheService: Settings box not initialized');
        return;
      }

      await _settingsBox!.put(key, jsonEncode(value));
      _logger.info('CacheService: Cached setting: $key');
    } catch (e) {
      _logger.error('CacheService: Failed to cache setting $key: $e');
    }
  }

  /// Get cached setting
  Future<T?> getCachedSetting<T>(String key) async {
    try {
      if (_settingsBox == null) {
        _logger.warning('CacheService: Settings box not initialized');
        return null;
      }

      final cachedData = _settingsBox!.get(key);
      if (cachedData == null) {
        return null;
      }

      return jsonDecode(cachedData) as T?;
    } catch (e) {
      _logger.error('CacheService: Failed to get cached setting $key: $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      await _chatRoomsBox?.clear();
      await _messagesBox?.clear();
      await _userDataBox?.clear();
      await _settingsBox?.clear();

      _logger.info('CacheService: Cleared all cached data');
    } catch (e) {
      _logger.error('CacheService: Failed to clear cache: $e');
    }
  }

  /// Clear cache for a specific room
  Future<void> clearRoomCache(String roomId) async {
    try {
      await removeCachedMessages(roomId);
      _logger.info('CacheService: Cleared cache for room $roomId');
    } catch (e) {
      _logger.error('CacheService: Failed to clear cache for room $roomId: $e');
    }
  }

  /// Get cache size information
  Future<Map<String, int>> getCacheInfo() async {
    try {
      return {
        'chatRooms': _chatRoomsBox?.length ?? 0,
        'messages': _messagesBox?.length ?? 0,
        'userData': _userDataBox?.length ?? 0,
        'settings': _settingsBox?.length ?? 0,
      };
    } catch (e) {
      _logger.error('CacheService: Failed to get cache info: $e');
      return {};
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _chatRoomsBox?.close();
      await _messagesBox?.close();
      await _userDataBox?.close();
      await _settingsBox?.close();

      _logger.info('CacheService: Disposed successfully');
    } catch (e) {
      _logger.error('CacheService: Failed to dispose: $e');
    }
  }
}
