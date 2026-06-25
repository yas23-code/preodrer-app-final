import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// A frosted glass (glassmorphism) card widget.
///
/// Uses [BackdropFilter] with [ImageFilter.blur] to create a translucent
/// blurred background effect behind the [child]. The card adapts its
/// background and border colors to the current theme brightness.
///
/// ```dart
/// GlassmorphicCard(
///   blur: 24,
///   padding: EdgeInsets.all(16),
///   child: Text('Hello Glass'),
/// )
/// ```
class GlassmorphicCard extends StatelessWidget {
  /// The content rendered inside the glass card.
  final Widget child;

  /// The sigma value for the blur effect.
  ///
  /// Higher values produce a more opaque frosted look.
  /// Defaults to `20`.
  final double blur;

  /// Padding applied inside the glass container.
  final EdgeInsetsGeometry? padding;

  /// The border radius of the card.
  ///
  /// Defaults to [AppShadows.borderRadiusXl].
  final BorderRadius? borderRadius;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? AppShadows.borderRadiusXl;

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : AppColors.glassLight,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
