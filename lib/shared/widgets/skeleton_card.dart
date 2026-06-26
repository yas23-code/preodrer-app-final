import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'shimmer_loader.dart';

/// Skeleton placeholder cards for loading states.
///
/// These widgets display animated shimmer placeholders that mimic the
/// layout of real content cards, providing visual feedback while data loads.

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Food Card
// ─────────────────────────────────────────────────────────────────────────────

/// A skeleton placeholder that mimics a [FoodItemCard] layout.
///
/// Shows an image placeholder on the left and three text-line placeholders
/// on the right, wrapped in a shimmer animation.
///
/// Use [count] to render multiple skeletons stacked in a [Column].
///
/// ```dart
/// SkeletonFoodCard(count: 4)
/// ```
class SkeletonFoodCard extends StatelessWidget {
  /// Number of skeleton cards to display.
  final int count;

  const SkeletonFoodCard({super.key, this.count = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < count - 1 ? AppShadows.spacingMd : 0,
          ),
          child: const _SingleSkeletonFoodCard(),
        );
      }),
    );
  }
}

class _SingleSkeletonFoodCard extends StatelessWidget {
  const _SingleSkeletonFoodCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppShadows.borderRadiusMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: AppShadows.borderRadiusMd,
              ),
            ),
            const SizedBox(width: 12),
            // Text line placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _SkeletonLine(
                    width: double.infinity,
                    height: 14,
                    color: skeletonColor,
                  ),
                  const SizedBox(height: 10),
                  _SkeletonLine(
                    width: 160,
                    height: 12,
                    color: skeletonColor,
                  ),
                  const SizedBox(height: 10),
                  _SkeletonLine(
                    width: 80,
                    height: 12,
                    color: skeletonColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Order Card
// ─────────────────────────────────────────────────────────────────────────────

/// A skeleton placeholder that mimics an order list card layout.
///
/// Shows a header line, a status badge placeholder, and item-line
/// placeholders, all wrapped in a shimmer animation.
///
/// Use [count] to render multiple skeletons stacked in a [Column].
///
/// ```dart
/// SkeletonOrderCard(count: 3)
/// ```
class SkeletonOrderCard extends StatelessWidget {
  /// Number of skeleton cards to display.
  final int count;

  const SkeletonOrderCard({super.key, this.count = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < count - 1 ? AppShadows.spacingMd : 0,
          ),
          child: const _SingleSkeletonOrderCard(),
        );
      }),
    );
  }
}

class _SingleSkeletonOrderCard extends StatelessWidget {
  const _SingleSkeletonOrderCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppShadows.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonLine(
                  width: 120,
                  height: 14,
                  color: skeletonColor,
                ),
                _SkeletonLine(
                  width: 80,
                  height: 24,
                  color: skeletonColor,
                  borderRadius: AppShadows.borderRadiusSm,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Item lines
            _SkeletonLine(
              width: double.infinity,
              height: 12,
              color: skeletonColor,
            ),
            const SizedBox(height: 8),
            _SkeletonLine(
              width: 200,
              height: 12,
              color: skeletonColor,
            ),
            const SizedBox(height: 14),
            // Footer row (date + total)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonLine(
                  width: 100,
                  height: 12,
                  color: skeletonColor,
                ),
                _SkeletonLine(
                  width: 60,
                  height: 14,
                  color: skeletonColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Skeleton Line
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadius? borderRadius;

  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppShadows.radiusXs),
      ),
    );
  }
}
