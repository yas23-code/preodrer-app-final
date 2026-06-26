import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A configurable shimmer loading effect widget.
///
/// Wraps a [child] widget with a sliding gradient shimmer animation.
/// The shimmer effect repeats every 1.5 seconds and supports both
/// light and dark themes.
///
/// When [enabled] is `false`, the child is returned directly without
/// any shimmer effect — useful for toggling loading states.
///
/// ```dart
/// ShimmerLoader(
///   enabled: isLoading,
///   child: Container(
///     width: 200,
///     height: 16,
///     color: Colors.grey,
///   ),
/// )
/// ```
class ShimmerLoader extends StatefulWidget {
  /// The widget to apply the shimmer effect over.
  final Widget child;

  /// Whether the shimmer animation is active.
  ///
  /// When `false`, [child] is rendered as-is.
  final bool enabled;

  const ShimmerLoader({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? AppColors.shimmerGradientDark : AppColors.shimmerGradient;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Slide the gradient from left (-1) to right (+2) over the
            // course of the animation, creating a sweeping shine effect.
            final double slide =
                _controller.value * 3.0 - 1.0; // range: -1 → 2
            return LinearGradient(
              colors: gradient.colors,
              stops: gradient.stops,
              begin: Alignment(slide - 1, (gradient.begin as Alignment).y),
              end: Alignment(slide + 1, (gradient.end as Alignment).y),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
