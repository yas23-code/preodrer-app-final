import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// An illustrated empty state widget for screens with no data.
///
/// Displays a large [icon] with a fade-in animation, a [title],
/// an optional [subtitle], and an optional action button.
///
/// All content is centered vertically within the available space.
///
/// ```dart
/// EmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: 'No orders yet',
///   subtitle: 'Your past orders will appear here.',
///   actionLabel: 'Browse Menu',
///   onAction: () => context.go('/menu'),
/// )
/// ```
class EmptyState extends StatefulWidget {
  /// The icon displayed at the top of the empty state.
  final IconData icon;

  /// The primary title text.
  final String title;

  /// An optional secondary description.
  final String? subtitle;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback when the action button is tapped.
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                widget.icon,
                size: 64,
                color: iconColor,
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              // Subtitle
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Action button
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: widget.onAction,
                  child: Text(widget.actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
