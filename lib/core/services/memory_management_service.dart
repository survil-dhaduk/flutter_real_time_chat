import 'dart:async';
import 'dart:collection';

import '../utils/logger.dart';

/// Service for managing memory usage and real-time listeners
class MemoryManagementService {
  static const int maxActiveListeners = 10;
  static const int maxCachedItems = 1000;
  static const Duration listenerTimeout = Duration(minutes: 30);

  final Logger _logger;
  final Map<String, ListenerInfo> _activeListeners = {};
  final Queue<String> _listenerQueue = Queue<String>();
  final Map<String, Timer> _listenerTimers = {};

  MemoryManagementService({Logger? logger})
      : _logger = logger ?? const Logger();

  /// Register a new listener
  void registerListener(
    String listenerId,
    StreamSubscription subscription, {
    String? description,
  }) {
    // Cancel existing listener if it exists
    if (_activeListeners.containsKey(listenerId)) {
      unregisterListener(listenerId);
    }

    // If we have too many listeners, remove the oldest one
    if (_activeListeners.length >= maxActiveListeners) {
      _removeOldestListener();
    }

    final listenerInfo = ListenerInfo(
      id: listenerId,
      subscription: subscription,
      description: description ?? 'Unknown listener',
      createdAt: DateTime.now(),
    );

    _activeListeners[listenerId] = listenerInfo;
    _listenerQueue.add(listenerId);

    // Set up automatic cleanup timer
    _setupListenerTimer(listenerId);

    _logger.info('MemoryManagementService: Registered listener $listenerId '
        '(${listenerInfo.description}). Active listeners: ${_activeListeners.length}');
  }

  /// Unregister a listener
  void unregisterListener(String listenerId) {
    final listenerInfo = _activeListeners.remove(listenerId);
    if (listenerInfo != null) {
      listenerInfo.subscription.cancel();
      _listenerQueue.remove(listenerId);

      // Cancel the timer
      _listenerTimers[listenerId]?.cancel();
      _listenerTimers.remove(listenerId);

      _logger.info('MemoryManagementService: Unregistered listener $listenerId '
          '(${listenerInfo.description}). Active listeners: ${_activeListeners.length}');
    }
  }

  /// Get information about active listeners
  List<ListenerInfo> getActiveListeners() {
    return _activeListeners.values.toList();
  }

  /// Get listener count
  int getListenerCount() {
    return _activeListeners.length;
  }

  /// Check if a listener is active
  bool isListenerActive(String listenerId) {
    return _activeListeners.containsKey(listenerId);
  }

  /// Refresh a listener's timeout
  void refreshListener(String listenerId) {
    if (_activeListeners.containsKey(listenerId)) {
      _setupListenerTimer(listenerId);
      _logger.info('MemoryManagementService: Refreshed listener $listenerId');
    }
  }

  /// Clean up inactive listeners
  void cleanupInactiveListeners() {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _activeListeners.entries) {
      final timeSinceCreated = now.difference(entry.value.createdAt);
      if (timeSinceCreated > listenerTimeout) {
        toRemove.add(entry.key);
      }
    }

    for (final listenerId in toRemove) {
      _logger.info(
          'MemoryManagementService: Cleaning up inactive listener $listenerId');
      unregisterListener(listenerId);
    }

    if (toRemove.isNotEmpty) {
      _logger.info(
          'MemoryManagementService: Cleaned up ${toRemove.length} inactive listeners');
    }
  }

  /// Force cleanup of all listeners
  void cleanupAllListeners() {
    final listenerIds = _activeListeners.keys.toList();
    for (final listenerId in listenerIds) {
      unregisterListener(listenerId);
    }

    _logger.info('MemoryManagementService: Cleaned up all listeners');
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    final now = DateTime.now();
    final stats = <String, dynamic>{
      'activeListeners': _activeListeners.length,
      'maxActiveListeners': maxActiveListeners,
      'listeners': <Map<String, dynamic>>[],
    };

    for (final entry in _activeListeners.entries) {
      final listenerInfo = entry.value;
      final age = now.difference(listenerInfo.createdAt);

      stats['listeners'].add({
        'id': entry.key,
        'description': listenerInfo.description,
        'ageInMinutes': age.inMinutes,
        'createdAt': listenerInfo.createdAt.toIso8601String(),
      });
    }

    return stats;
  }

  /// Optimize memory usage by cleaning up old data
  void optimizeMemory() {
    cleanupInactiveListeners();

    // Force garbage collection hint (not guaranteed to work)
    // This is more of a hint to the Dart VM
    _logger.info('MemoryManagementService: Memory optimization completed');
  }

  /// Set up automatic cleanup timer for a listener
  void _setupListenerTimer(String listenerId) {
    // Cancel existing timer
    _listenerTimers[listenerId]?.cancel();

    // Set up new timer
    _listenerTimers[listenerId] = Timer(listenerTimeout, () {
      _logger.info('MemoryManagementService: Listener $listenerId timed out');
      unregisterListener(listenerId);
    });
  }

  /// Remove the oldest listener to make room for new ones
  void _removeOldestListener() {
    if (_listenerQueue.isNotEmpty) {
      final oldestListenerId = _listenerQueue.removeFirst();
      _logger.info(
          'MemoryManagementService: Removing oldest listener $oldestListenerId to make room');
      unregisterListener(oldestListenerId);
    }
  }

  /// Dispose all resources
  void dispose() {
    cleanupAllListeners();

    // Cancel all timers
    for (final timer in _listenerTimers.values) {
      timer.cancel();
    }
    _listenerTimers.clear();

    _logger.info('MemoryManagementService: Disposed successfully');
  }
}

/// Information about an active listener
class ListenerInfo {
  final String id;
  final StreamSubscription subscription;
  final String description;
  final DateTime createdAt;

  ListenerInfo({
    required this.id,
    required this.subscription,
    required this.description,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'ListenerInfo(id: $id, description: $description, createdAt: $createdAt)';
  }
}
