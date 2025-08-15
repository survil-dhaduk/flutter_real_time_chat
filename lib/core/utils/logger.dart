import 'dart:developer' as developer;

/// Simple logger utility for the application
class Logger {
  static const String _defaultTag = 'ChatApp';

  final String _tag;

  const Logger([this._tag = _defaultTag]);

  /// Logs an info message
  void info(String message) {
    developer.log(
      message,
      name: _tag,
      level: 800, // Info level
    );
  }

  /// Logs a warning message
  void warning(String message) {
    developer.log(
      message,
      name: _tag,
      level: 900, // Warning level
    );
  }

  /// Logs an error message
  void error(String message) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Error level
    );
  }

  /// Logs a debug message
  void debug(String message) {
    developer.log(
      message,
      name: _tag,
      level: 700, // Debug level
    );
  }

  /// Creates a logger with a specific tag
  Logger withTag(String tag) {
    return Logger(tag);
  }
}
