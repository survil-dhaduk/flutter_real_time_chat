import '../utils/logger.dart';
import '../../features/chat/domain/entities/message.dart';

/// Service for managing pagination of messages
class PaginationService {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  final Logger _logger;
  final Map<String, PaginationState> _paginationStates = {};

  PaginationService({Logger? logger}) : _logger = logger ?? const Logger();

  /// Initialize pagination for a room
  void initializePagination(String roomId, {int pageSize = defaultPageSize}) {
    if (pageSize > maxPageSize) {
      pageSize = maxPageSize;
    }

    _paginationStates[roomId] = PaginationState(
      roomId: roomId,
      pageSize: pageSize,
    );

    _logger.info(
        'PaginationService: Initialized pagination for room $roomId with page size $pageSize');
  }

  /// Get pagination state for a room
  PaginationState? getPaginationState(String roomId) {
    return _paginationStates[roomId];
  }

  /// Check if there are more messages to load
  bool hasMoreMessages(String roomId) {
    final state = _paginationStates[roomId];
    return state?.hasMoreMessages ?? true;
  }

  /// Get the last message ID for pagination
  String? getLastMessageId(String roomId) {
    final state = _paginationStates[roomId];
    return state?.lastMessageId;
  }

  /// Get the page size for a room
  int getPageSize(String roomId) {
    final state = _paginationStates[roomId];
    return state?.pageSize ?? defaultPageSize;
  }

  /// Update pagination state after loading messages
  void updatePaginationState(String roomId, List<Message> newMessages) {
    final state = _paginationStates[roomId];
    if (state == null) {
      _logger.warning(
          'PaginationService: No pagination state found for room $roomId');
      return;
    }

    // Update last message ID
    if (newMessages.isNotEmpty) {
      state.lastMessageId = newMessages.last.id;
    }

    // Check if we have more messages
    state.hasMoreMessages = newMessages.length >= state.pageSize;

    // Update total loaded count
    state.totalLoadedMessages += newMessages.length;

    _logger.info('PaginationService: Updated pagination for room $roomId - '
        'loaded ${newMessages.length} messages, total: ${state.totalLoadedMessages}, '
        'hasMore: ${state.hasMoreMessages}');
  }

  /// Reset pagination for a room
  void resetPagination(String roomId) {
    final state = _paginationStates[roomId];
    if (state != null) {
      state.reset();
      _logger.info('PaginationService: Reset pagination for room $roomId');
    }
  }

  /// Remove pagination state for a room
  void removePagination(String roomId) {
    _paginationStates.remove(roomId);
    _logger.info('PaginationService: Removed pagination for room $roomId');
  }

  /// Get pagination parameters for API calls
  PaginationParams getPaginationParams(String roomId) {
    final state = _paginationStates[roomId];
    return PaginationParams(
      limit: state?.pageSize ?? defaultPageSize,
      lastMessageId: state?.lastMessageId,
    );
  }

  /// Check if we should load more messages based on scroll position
  bool shouldLoadMore(
    String roomId, {
    required int currentIndex,
    required int totalMessages,
    int threshold = 5,
  }) {
    // Load more when we're within 'threshold' messages from the beginning
    final shouldLoad = currentIndex <= threshold && hasMoreMessages(roomId);

    if (shouldLoad) {
      _logger
          .info('PaginationService: Should load more messages for room $roomId '
              '(currentIndex: $currentIndex, threshold: $threshold)');
    }

    return shouldLoad;
  }

  /// Optimize message list by removing old messages if list gets too large
  List<Message> optimizeMessageList(List<Message> messages,
      {int maxMessages = 500}) {
    if (messages.length <= maxMessages) {
      return messages;
    }

    // Keep the most recent messages
    final optimizedMessages = messages.sublist(messages.length - maxMessages);

    _logger.info(
        'PaginationService: Optimized message list from ${messages.length} to ${optimizedMessages.length} messages');

    return optimizedMessages;
  }

  /// Clear all pagination states
  void clearAll() {
    _paginationStates.clear();
    _logger.info('PaginationService: Cleared all pagination states');
  }

  /// Get pagination statistics
  Map<String, dynamic> getPaginationStats() {
    final stats = <String, dynamic>{};

    for (final entry in _paginationStates.entries) {
      stats[entry.key] = {
        'totalLoadedMessages': entry.value.totalLoadedMessages,
        'hasMoreMessages': entry.value.hasMoreMessages,
        'pageSize': entry.value.pageSize,
        'lastMessageId': entry.value.lastMessageId,
      };
    }

    return stats;
  }
}

/// Pagination state for a specific room
class PaginationState {
  final String roomId;
  final int pageSize;
  String? lastMessageId;
  bool hasMoreMessages;
  int totalLoadedMessages;

  PaginationState({
    required this.roomId,
    required this.pageSize,
    this.lastMessageId,
    this.hasMoreMessages = true,
    this.totalLoadedMessages = 0,
  });

  /// Reset pagination state
  void reset() {
    lastMessageId = null;
    hasMoreMessages = true;
    totalLoadedMessages = 0;
  }

  @override
  String toString() {
    return 'PaginationState(roomId: $roomId, pageSize: $pageSize, '
        'lastMessageId: $lastMessageId, hasMoreMessages: $hasMoreMessages, '
        'totalLoadedMessages: $totalLoadedMessages)';
  }
}

/// Parameters for pagination API calls
class PaginationParams {
  final int limit;
  final String? lastMessageId;

  const PaginationParams({
    required this.limit,
    this.lastMessageId,
  });

  @override
  String toString() {
    return 'PaginationParams(limit: $limit, lastMessageId: $lastMessageId)';
  }
}
