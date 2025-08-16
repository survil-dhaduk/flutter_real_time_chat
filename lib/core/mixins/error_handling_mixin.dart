import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../errors/failures.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

/// Mixin that provides error handling capabilities to BLoCs
mixin ErrorHandlingMixin<Event, State> on BlocBase<State> {
  /// Handles errors and emits appropriate error states
  void handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? operation,
    State? previousState,
  }) {
    // Log the error for debugging
    debugPrint('Error in $runtimeType: $error');
    debugPrint('Stack trace: $stackTrace');

    // Convert error to Failure if needed
    final failure = _convertToFailure(error);

    // Emit error state (this should be implemented by the BLoC)
    emitErrorState(failure, operation: operation, previousState: previousState);
  }

  /// Executes an operation with error handling and retry capability
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxRetries = 3,
    bool enableRetry = true,
  }) async {
    try {
      if (enableRetry) {
        return await RetryHelper.executeWithRetry(
          operation,
          maxRetries: maxRetries,
          retryIf: RetryHelper.isRetryableError,
        );
      } else {
        return await operation();
      }
    } catch (error, stackTrace) {
      handleError(error, stackTrace, operation: operationName);
      rethrow;
    }
  }

  /// Converts various error types to Failure objects
  Failure _convertToFailure(dynamic error) {
    if (error is Failure) {
      return error;
    }

    // Handle common error types
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return NetworkFailure(error.toString());
    }

    // Handle Firebase Auth errors
    if (error.toString().contains('firebase_auth')) {
      return AuthFailure(error.toString());
    }

    // Handle Firebase Firestore errors
    if (error.toString().contains('cloud_firestore')) {
      return ServerFailure.firebase(error.toString());
    }

    // Default to server failure
    return ServerFailure(error.toString());
  }

  /// Abstract method that BLoCs should implement to emit error states
  void emitErrorState(
    Failure failure, {
    String? operation,
    State? previousState,
  });
}

/// Extension to provide error handling to BuildContext
extension ErrorHandlingContext on BuildContext {
  /// Shows error with retry functionality
  void showError(
    Failure failure, {
    VoidCallback? onRetry,
    bool showRetry = false,
  }) {
    ErrorHandler.handleBlocError(
      this,
      failure,
      onRetry: onRetry,
      showRetry: showRetry,
    );
  }

  /// Shows success message
  void showSuccess(String message) {
    ErrorHandler.showSuccessSnackBar(this, message);
  }

  /// Shows info message
  void showInfo(String message) {
    ErrorHandler.showInfoSnackBar(this, message);
  }

  /// Shows warning message
  void showWarning(String message) {
    ErrorHandler.showWarningSnackBar(this, message);
  }
}
