import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A branded error state widget for displaying error messages.
///
/// Shows a 48px error icon, a [message] describing the issue, and an
/// optional retry button that invokes [onRetry].
///
/// ```dart
/// ErrorState(
///   message: 'Failed to load menu items.',
///   onRetry: () => ref.invalidate(menuProvider),
/// )
/// ```
class ErrorState extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  ///
  /// When `null`, the retry button is hidden.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
