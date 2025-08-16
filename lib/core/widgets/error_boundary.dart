import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../widgets/error_widgets.dart';

/// A widget that catches and handles errors in its child widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? fallbackMessage;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackMessage,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ErrorDisplay(
        message: _errorMessage ??
            widget.fallbackMessage ??
            AppStrings.unexpectedError,
        onRetry: () {
          setState(() {
            _hasError = false;
            _errorMessage = null;
          });
        },
      );
    }

    return widget.child;
  }

  /// Handles errors that occur in the widget tree
  void _handleError(FlutterErrorDetails details) {
    setState(() {
      _hasError = true;
      _errorMessage = details.exception.toString();
    });

    // Log the error
    debugPrint('ErrorBoundary caught error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');

    // Call the error callback if provided
    widget.onError?.call();
  }

  @override
  void initState() {
    super.initState();

    // Set up error handling for the widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        _handleError(details);
      }
    };
  }
}

/// A mixin that provides error handling capabilities to StatefulWidgets
mixin ErrorHandlingStateMixin<T extends StatefulWidget> on State<T> {
  bool _hasError = false;
  String? _errorMessage;

  /// Handles errors that occur in the widget
  void handleError(dynamic error, [StackTrace? stackTrace]) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });

      // Log the error
      debugPrint('Widget error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Clears the error state
  void clearError() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  /// Builds the error widget when an error occurs
  Widget buildErrorWidget({
    String? message,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplay(
      message: message ?? _errorMessage ?? AppStrings.unexpectedError,
      onRetry: onRetry ?? clearError,
    );
  }

  /// Returns true if the widget is in an error state
  bool get hasError => _hasError;

  /// Returns the current error message
  String? get errorMessage => _errorMessage;
}
