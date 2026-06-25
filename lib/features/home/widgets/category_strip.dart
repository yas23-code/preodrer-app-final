import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';

/// A category model for the horizontal strip.
class _Category {
  final String emoji;
  final String label;
  final String value;

  const _Category({
    required this.emoji,
    required this.label,
    required this.value,
  });
}

/// Predefined food categories displayed in the home screen.
const _kCategories = [
  _Category(emoji: '⭐', label: 'All', value: 'all'),
  _Category(emoji: '🍟', label: 'Snacks', value: 'snacks'),
  _Category(emoji: '☕', label: 'Beverages', value: 'beverages'),
  _Category(emoji: '🍛', label: 'Meals', value: 'meals'),
  _Category(emoji: '🍰', label: 'Desserts', value: 'desserts'),
  _Category(emoji: '🎁', label: 'Combos', value: 'combos'),
];

/// Horizontal scrolling category strip with emoji-labeled chips.
///
/// Displays predefined food categories as tappable chips. The currently
/// selected category is highlighted with the primary color background
/// and a subtle scale animation.
///
/// ```dart
/// CategoryStrip(
///   selectedCategory: 'all',
///   onCategoryTap: (category) => print('Selected: $category'),
/// )
/// ```
class CategoryStrip extends StatelessWidget {
  /// Callback fired when a category chip is tapped.
  final ValueChanged<String> onCategoryTap;

  /// The currently selected category value.
  final String selectedCategory;

  const CategoryStrip({
    super.key,
    required this.onCategoryTap,
    this.selectedCategory = 'all',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppShadows.spacingLg,
        ),
        child: Row(
          children: _kCategories.map((category) {
            final isSelected = category.value == selectedCategory;

            return Padding(
              padding: const EdgeInsets.only(right: AppShadows.spacingSm),
              child: GestureDetector(
                onTap: () => onCategoryTap(category.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppShadows.spacingLg,
                    vertical: AppShadows.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                    borderRadius: AppShadows.borderRadiusXl,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.textOnPrimary
                              : isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                        ),
                        child: Text(category.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
