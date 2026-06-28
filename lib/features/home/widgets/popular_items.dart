import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../cart/providers/cart_controller.dart';
import '../../menu/models/menu_item.dart' as models;
import '../../menu/providers/menu_provider.dart';

/// Horizontal scrolling section displaying popular menu items.
///
/// Watches [menuItemsProvider] and shows the first 8 available items
/// in a horizontally-scrollable list of premium food cards. Each card
/// features a food image with a gradient price overlay and a quick-add
/// button.
///
/// Displays shimmer skeletons while loading and gracefully handles
/// empty or error states.
///
/// ```dart
/// const PopularItems()
/// ```
class PopularItems extends ConsumerWidget {
  const PopularItems({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuItemsProvider);

    return menuAsync.when(
      loading: () => _buildShimmer(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        // Show first 8 items as "popular"
        final popularItems = items.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppShadows.spacingLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Items',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppShadows.spacingMd),

            // Horizontal list
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppShadows.spacingLg,
                ),
                itemCount: popularItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < popularItems.length - 1
                          ? AppShadows.spacingMd
                          : 0,
                    ),
                    child: _PopularItemCard(item: popularItems[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a shimmer placeholder row mimicking the popular items layout.
  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppShadows.spacingLg,
          ),
          child: ShimmerLoader(
            child: Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppShadows.radiusXs),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppShadows.spacingMd),

        // Cards shimmer
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppShadows.spacingLg,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppShadows.spacingMd),
                child: ShimmerLoader(
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: AppShadows.borderRadiusLg,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popular Item Card
// ─────────────────────────────────────────────────────────────────────────────

/// A premium card for a single popular menu item.
///
/// Features:
/// - Full-bleed food image (160×120) with rounded top corners
/// - Dark gradient overlay at the bottom of the image
/// - Item name and price below the image
/// - Quick-add button in the bottom-right corner
class _PopularItemCard extends ConsumerWidget {
  final models.MenuItem item;

  const _PopularItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve image URL from Supabase storage
    final imageUrl = item.imageUrl == null
        ? null
        : item.imageUrl!.startsWith('http')
            ? item.imageUrl
            : supabase.storage
                .from(kFoodImagesBucketName)
                .getPublicUrl(item.imageUrl!);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppShadows.borderRadiusLg,
        boxShadow: AppShadows.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image section ──────────────────────────────────────────────
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Food image
                if (imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      child: const Icon(
                        Icons.restaurant_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Container(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    child: const Icon(
                      Icons.restaurant_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),

                // Gradient overlay at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.darkOverlayGradient,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          // ── Info section ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShadows.spacingMd,
                AppShadows.spacingSm,
                AppShadows.spacingXs,
                AppShadows.spacingSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),

                  // Price + Add button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          formatCurrency(item.price),
                          style: AppTypography.priceSmall.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Quick-add button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .addItem(item, context)
                                  .then((success) {
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.name} added to cart'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              });
                            },
                            child: const Icon(
                              Icons.add_rounded,
                              color: AppColors.textOnPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
