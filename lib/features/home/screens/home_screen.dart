
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';



import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../canteen/providers/canteen_provider.dart';

import '../../menu/providers/menu_provider.dart';
import '../widgets/category_strip.dart';
import '../widgets/popular_items.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final menuAsync = ref.watch(menuItemsProvider);
    final canteen = ref.watch(currentCanteenProvider);
    final isClosed = canteen != null && !canteen.isOpen;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppShadows.borderRadiusMd,
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Acktron', style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(menuItemsProvider);
          ref.invalidate(canteensProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),

            // ── Search Bar ──────────────────────────────────────────
            GestureDetector(
              onTap: () => context.push('/menu'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: AppShadows.borderRadiusFull,
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Search for food...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Canteen Status ──────────────────────────────────────
            if (isClosed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppShadows.borderRadiusMd,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Canteen is currently closed',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),

            // ── Categories ──────────────────────────────────────────
            Text('Categories', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            CategoryStrip(onCategoryTap: (category) {
              context.push('/menu');
            }),
            const SizedBox(height: 24),

            // ── Popular Items ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Popular Items', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => context.push('/menu'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const PopularItems(),
            const SizedBox(height: 24),

            // ── Today's Special Banner ──────────────────────────────
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: AppShadows.borderRadiusXl,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    bottom: 0,
                    child: Icon(Icons.lunch_dining, size: 100, color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Today's Special", style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        )),
                        const SizedBox(height: 6),
                        Text('Skip the Queue!', style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                        const SizedBox(height: 4),
                        Text('Pre-order & pickup when ready', style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Stats ─────────────────────────────────────────
            menuAsync.when(
              data: (items) => Row(
                children: [
                  _buildQuickStat(context, '${items.length}', 'Items Available', Icons.restaurant_menu),
                  const SizedBox(width: 12),
                  _buildQuickStat(context, '~10m', 'Avg. Prep Time', Icons.timer_outlined),
                  const SizedBox(width: 12),
                  _buildQuickStat(context, canteen?.isOpen == true ? 'Open' : 'Closed', 'Status', Icons.storefront),
                ],
              ),
              loading: () => ShimmerLoader(
                child: Row(
                  children: [
                    Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.grey, borderRadius: AppShadows.borderRadiusMd))),
                    const SizedBox(width: 12),
                    Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.grey, borderRadius: AppShadows.borderRadiusMd))),
                    const SizedBox(width: 12),
                    Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.grey, borderRadius: AppShadows.borderRadiusMd))),
                  ],
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          borderRadius: AppShadows.borderRadiusMd,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
