import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../errors/failures.dart';

/// Global error handler for the application
class ErrorHandler {
  ErrorHandler._();

  /// Shows an error snackbar with retry functionality
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
    bool showRetry = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: duration,
        action: showRetry && onRetry != null
            ? SnackBarAction(
                label: AppStrings.tryAgain,
                textColor: AppColors.onError,
                onPressed: onRetry,
              )
            : SnackBarAction(
                label: AppStrings.ok,
                textColor: AppColors.onError,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: duration,
      ),
    );
  }

  /// Shows an info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        duration: duration,
      ),
    );
  }

  /// Shows a warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: duration,
      ),
    );
  }

  /// Converts a Failure to a user-friendly error message
  static String getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Shows an error dialog with retry functionality
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    bool showRetry = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            if (showRetry && onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text(AppStrings.tryAgain),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(AppStrings.ok),
            ),
          ],
        );
      },
    );
  }

  /// Handles BLoC errors with appropriate UI feedback
  static void handleBlocError(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    bool showRetry = false,
  }) {
    final message = getErrorMessage(failure);

    if (failure is NetworkFailure) {
      showErrorSnackBar(
        context,
        message,
        onRetry: onRetry,
        showRetry: showRetry,
        duration: const Duration(seconds: 6),
      );
    } else if (failure is AuthFailure) {
      showErrorSnackBar(
        context,
        message,
        onRetry: onRetry,
        showRetry: showRetry,
      );
    } else {
      showErrorSnackBar(
        context,
        message,
        onRetry: onRetry,
        showRetry: showRetry,
      );
    }
  }
}
