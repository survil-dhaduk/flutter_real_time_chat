import 'dart:async';
import 'dart:io';
import 'dart:math';

/// Helper class for implementing retry mechanisms
class RetryHelper {
  /// Executes a function with exponential backoff retry
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if we should retry based on the error
        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);

        // Calculate next delay with jitter to avoid thundering herd
        final nextDelay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );

        // Add jitter (±25% of the delay)
        final jitter = Random().nextDouble() * 0.5 - 0.25;
        final jitteredDelay = Duration(
          milliseconds: (nextDelay.inMilliseconds * (1 + jitter)).round(),
        );

        delay = jitteredDelay > maxDelay ? maxDelay : jitteredDelay;
      }
    }

    throw StateError('This should never be reached');
  }

  /// Executes a function with linear retry
  static Future<T> executeWithLinearRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }

        if (attempt >= maxRetries) {
          rethrow;
        }

        await Future.delayed(delay);
      }
    }

    throw StateError('This should never be reached');
  }

  /// Checks if an error is retryable (network-related)
  static bool isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;

    // Check error message for common network issues
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('unreachable') ||
        errorMessage.contains('failed host lookup');
  }

  /// Creates a retry function for BLoC operations
  static void Function() createRetryCallback(
    Future<void> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) {
    return () {
      executeWithRetry(
        operation,
        maxRetries: maxRetries,
        initialDelay: initialDelay,
        retryIf: isRetryableError,
      );
    };
  }
}
