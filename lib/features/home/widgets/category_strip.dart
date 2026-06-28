import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';

/// A category model for the horizontal strip.
class CategoryItem {
  final String emoji;
  final String label;
  final String value;

  const CategoryItem({
    required this.emoji,
    required this.label,
    required this.value,
  });
}

/// Horizontal scrolling category strip with emoji-labeled chips.
class CategoryStrip extends StatelessWidget {
  /// Callback fired when a category chip is tapped.
  final ValueChanged<String> onCategoryTap;

  /// The currently selected category value.
  final String selectedCategory;

  /// List of categories to display.
  final List<CategoryItem> categories;

  const CategoryStrip({
    super.key,
    required this.onCategoryTap,
    required this.categories,
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
          children: categories.map((category) {
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
