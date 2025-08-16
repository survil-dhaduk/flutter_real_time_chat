import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/logger.dart';

/// A widget that monitors performance metrics and provides optimization hints
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? screenName;
  final bool enableLogging;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.screenName,
    this.enableLogging = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  final Logger _logger = const Logger();
  late final Stopwatch _buildStopwatch;
  int _frameCount = 0;
  double _averageFrameTime = 0.0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _buildStopwatch = Stopwatch();
    WidgetsBinding.instance.addObserver(this);

    if (widget.enableLogging) {
      _startPerformanceMonitoring();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      _frameCount++;

      // Calculate rolling average
      _averageFrameTime =
          ((_averageFrameTime * (_frameCount - 1)) + frameTime) / _frameCount;

      // Log performance warnings
      if (frameTime > 16.67) {
        // 60 FPS threshold
        _logger.warning(
            'PerformanceMonitor: Frame took ${frameTime.toStringAsFixed(2)}ms '
            '(${widget.screenName ?? 'Unknown screen'})');
      }

      // Reset counters periodically
      if (_frameCount >= 60) {
        if (widget.enableLogging) {
          _logger.info(
              'PerformanceMonitor: Average frame time: ${_averageFrameTime.toStringAsFixed(2)}ms '
              '(${widget.screenName ?? 'Unknown screen'})');
        }
        _frameCount = 0;
        _averageFrameTime = 0.0;
      }
    }

    _lastFrameTime = now;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableLogging) {
      _buildStopwatch.start();
    }

    final child = widget.child;

    if (widget.enableLogging) {
      _buildStopwatch.stop();
      final buildTime = _buildStopwatch.elapsedMicroseconds / 1000.0;

      if (buildTime > 16.67) {
        // 60 FPS threshold
        _logger.warning(
            'PerformanceMonitor: Build took ${buildTime.toStringAsFixed(2)}ms '
            '(${widget.screenName ?? 'Unknown screen'})');
      }

      _buildStopwatch.reset();
    }

    return child;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (widget.enableLogging) {
      _logger.info('PerformanceMonitor: App lifecycle changed to $state '
          '(${widget.screenName ?? 'Unknown screen'})');
    }
  }
}

/// A mixin that provides performance monitoring capabilities to widgets
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  final Logger _logger = const Logger();
  late final Stopwatch _operationStopwatch;

  @override
  void initState() {
    super.initState();
    _operationStopwatch = Stopwatch();
  }

  /// Measure the performance of an operation
  Future<R> measureOperation<R>(
    String operationName,
    Future<R> Function() operation, {
    bool logResult = true,
  }) async {
    _operationStopwatch.start();

    try {
      final result = await operation();

      _operationStopwatch.stop();
      final duration = _operationStopwatch.elapsedMilliseconds;

      if (logResult) {
        if (duration > 1000) {
          _logger
              .warning('PerformanceMonitor: $operationName took ${duration}ms');
        } else {
          _logger.info(
              'PerformanceMonitor: $operationName completed in ${duration}ms');
        }
      }

      return result;
    } catch (e) {
      _operationStopwatch.stop();
      final duration = _operationStopwatch.elapsedMilliseconds;

      _logger.error(
          'PerformanceMonitor: $operationName failed after ${duration}ms: $e');
      rethrow;
    } finally {
      _operationStopwatch.reset();
    }
  }

  /// Measure the performance of a synchronous operation
  R measureSyncOperation<R>(
    String operationName,
    R Function() operation, {
    bool logResult = true,
  }) {
    _operationStopwatch.start();

    try {
      final result = operation();

      _operationStopwatch.stop();
      final duration = _operationStopwatch.elapsedMilliseconds;

      if (logResult) {
        if (duration > 100) {
          _logger
              .warning('PerformanceMonitor: $operationName took ${duration}ms');
        } else if (logResult) {
          _logger.info(
              'PerformanceMonitor: $operationName completed in ${duration}ms');
        }
      }

      return result;
    } catch (e) {
      _operationStopwatch.stop();
      final duration = _operationStopwatch.elapsedMilliseconds;

      _logger.error(
          'PerformanceMonitor: $operationName failed after ${duration}ms: $e');
      rethrow;
    } finally {
      _operationStopwatch.reset();
    }
  }
}

/// Performance statistics collector
class PerformanceStats {
  static final Map<String, List<double>> _operationTimes = {};
  static final Logger _logger = const Logger();

  /// Record an operation time
  static void recordOperation(String operationName, double timeMs) {
    _operationTimes.putIfAbsent(operationName, () => <double>[]);
    _operationTimes[operationName]!.add(timeMs);

    // Keep only the last 100 measurements
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  /// Get average time for an operation
  static double getAverageTime(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return 0.0;

    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get performance report
  static Map<String, Map<String, double>> getPerformanceReport() {
    final report = <String, Map<String, double>>{};

    for (final entry in _operationTimes.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        times.sort();

        report[entry.key] = {
          'average': times.reduce((a, b) => a + b) / times.length,
          'min': times.first,
          'max': times.last,
          'median': times[times.length ~/ 2],
          'p95': times[(times.length * 0.95).floor()],
          'count': times.length.toDouble(),
        };
      }
    }

    return report;
  }

  /// Log performance report
  static void logPerformanceReport() {
    final report = getPerformanceReport();

    _logger.info('=== Performance Report ===');
    for (final entry in report.entries) {
      final stats = entry.value;
      _logger.info('${entry.key}:');
      _logger.info('  Average: ${stats['average']?.toStringAsFixed(2)}ms');
      _logger.info('  Min: ${stats['min']?.toStringAsFixed(2)}ms');
      _logger.info('  Max: ${stats['max']?.toStringAsFixed(2)}ms');
      _logger.info('  Median: ${stats['median']?.toStringAsFixed(2)}ms');
      _logger.info('  P95: ${stats['p95']?.toStringAsFixed(2)}ms');
      _logger.info('  Count: ${stats['count']?.toInt()}');
    }
    _logger.info('========================');
  }

  /// Clear all statistics
  static void clearStats() {
    _operationTimes.clear();
    _logger.info('PerformanceStats: Cleared all statistics');
  }
}
