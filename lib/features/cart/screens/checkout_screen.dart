import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/utils/formatters.dart';
import '../providers/cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _handlePlaceOrder() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(cartControllerProvider.notifier).placeOrder();
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppShadows.borderRadiusXxl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 20),
              Text('Order Placed!', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Your order has been placed successfully.\nYou\'ll be notified when it\'s ready.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/orders');
                  },
                  child: const Text('Track Order'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartAsync = ref.watch(cartControllerProvider);
    final cart = cartAsync.asData?.value;

    if (cart == null || cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    final lineValues = cart.lines.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order Summary ──────────────────────────────────────
          Text('Order Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: AppShadows.borderRadiusLg,
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, width: 0.5),
            ),
            child: Column(
              children: lineValues.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${line.quantity}x ${line.item.name}', style: theme.textTheme.bodyMedium)),
                    Text(formatCurrency(line.item.price * line.quantity), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Price Breakdown ────────────────────────────────────
          Text('Price Breakdown', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: AppShadows.borderRadiusLg,
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, width: 0.5),
            ),
            child: Column(
              children: [
                _priceRow(theme, 'Subtotal', formatCurrency(cart.totalAmount)),
                const SizedBox(height: 8),
                _priceRow(theme, 'Packing Charges', '₹0.00'),
                const SizedBox(height: 8),
                _priceRow(theme, 'GST', '₹0.00'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(formatCurrency(cart.totalAmount), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Pickup Info ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: AppShadows.borderRadiusLg,
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: AppShadows.borderRadiusMd,
                  ),
                  child: Icon(Icons.storefront, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup from Acktron Canteen', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('~10-15 minutes', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),

      // ── Sticky Pay Button ──────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: AppShadows.bottomSheetShadow,
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isProcessing ? null : _handlePlaceOrder,
              child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Place Order  •  ${formatCurrency(cart.totalAmount)}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
