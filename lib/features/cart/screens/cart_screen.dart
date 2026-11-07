import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_controller.dart';
import '../../canteen/providers/canteen_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vendor/providers/coupons_provider.dart';
import '../../menu/models/menu_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isOrdering = false;
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _orderType = 'Dine In';
  double _discountAmount = 0.0;
  String? _appliedCouponCode;

  bool _phoneAutoFilled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_phoneAutoFilled) {
      final profileAsync = ref.read(currentUserProfileProvider);
      profileAsync.whenData((profile) {
        final phone = profile?['phone'] as String? ?? '';
        if (phone.isNotEmpty) {
          _phoneController.text = phone;
          _phoneAutoFilled = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment(double total) async {
    setState(() => _isOrdering = true);
    try {
      final session = await ref
          .read(cartControllerProvider.notifier)
          .initiatePayment(
            total: total,
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;
      // Navigate to payment screen, passing the session as GoRouter extra
      setState(() => _isOrdering = false);
      context.push('/payment', extra: session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFFFF9EC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final cartAsync = ref.watch(cartControllerProvider);
    final currentCanteen = ref.watch(currentCanteenProvider);
    final canteenId = currentCanteen?.id ?? '';
    final couponsAsync = ref.watch(canteenCouponsProvider(canteenId));

    return Scaffold(
      backgroundColor: bg,
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Failed to load cart: $e')),
        data: (cart) {
          final orderAmount = cart.totalAmount;
          final packingCharge = cart.lines.values.fold(
            0.0,
            (sum, line) => sum + ((line.item.packingCharge) * line.quantity),
          );
          final calculatedTotal = (orderAmount + packingCharge) - _discountAmount;
          final total = calculatedTotal < 0 ? 0.0 : calculatedTotal;

          return Stack(
            children: [
              Column(
                children: [
                  // ── HEADER ────────────────────────────────────────────
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                            child: Icon(Icons.arrow_back,
                                size: 22, color: textPrimary),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.shopping_cart_rounded,
                              color: textPrimary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SCROLLABLE BODY ───────────────────────────────────
                  Expanded(
                    child: cart.lines.isEmpty
                        ? _buildEmptyCart(context, isDark)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Canteen + ETA Card
                              _buildCanteenHeader(
                                context,
                                currentCanteen?.name ?? 'Canteen',
                                isDark,
                                cart.lines.values
                                    .where((l) => l.item.prepTime != null)
                                    .map((l) => l.item.prepTime! * l.quantity)
                                    .fold<int?>(null, (max, t) => max == null || t > max ? t : max),
                                ref.watch(canteenActiveOrdersCountProvider(canteenId)).value ?? 0,
                              ),
                              const SizedBox(height: 16),

                              // Cart items Card container
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  borderRadius: AppShadows.borderRadiusLg,
                                  boxShadow: AppShadows.cardShadow(context),
                                ),
                                child: Column(
                                  children: [
                                    ...() {
                                      final List<Widget> itemRows = [];
                                      final lines = cart.lines.values.toList();
                                      for (int i = 0; i < lines.length; i++) {
                                        final line = lines[i];
                                        itemRows.add(
                                          _buildCartItemRow(
                                            context,
                                            line.item.name,
                                            line.item.price,
                                            line.quantity,
                                            line.item.prepTime,
                                            isDark,
                                            onDecrement: () => ref
                                                .read(cartControllerProvider.notifier)
                                                .decrementItem(line.item),
                                            onIncrement: () => ref
                                                .read(cartControllerProvider.notifier)
                                                .addItem(line.item),
                                            onDelete: () => ref
                                                .read(cartControllerProvider.notifier)
                                                .removeItem(line.item),
                                          ),
                                        );
                                        if (i < lines.length - 1) {
                                          itemRows.add(Divider(
                                            height: 1,
                                            thickness: 0.5,
                                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                          ));
                                        }
                                      }
                                      return itemRows;
                                    }(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Coupon + Price breakdown Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  borderRadius: AppShadows.borderRadiusLg,
                                  boxShadow: AppShadows.cardShadow(context),
                                ),
                                child: _buildCouponAndPriceSection(
                                  context: context,
                                  isDark: isDark,
                                  orderAmount: orderAmount,
                                  packingCharge: packingCharge,
                                  discountAmount: _discountAmount,
                                  total: total,
                                  couponsAsync: couponsAsync,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Phone Card
                              _buildPhoneSection(context, isDark),
                              const SizedBox(height: 16),

                              // Order type Card
                              _buildOrderTypeSection(context, isDark),
                            ],
                          ),
                  ),
                ],
              ),

              // ── STICKY BOTTOM BUTTON ──────────────────────────────
              if (cart.lines.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(context, cart.lines.isEmpty, total, isDark),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Empty cart ────────────────────────────────────────────────────
  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add some delicious food!',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Canteen + ETA Card ────────────────────────────────────────────
  Widget _buildCanteenHeader(BuildContext context, String canteenName, bool isDark, int? maxPrepTime, int activeOrders) {
    final theme = Theme.of(context);
    
    // Formula: ready_in = max_prep_time + active_orders × 2
    final readyInMinutes = maxPrepTime != null ? maxPrepTime + (activeOrders * 2) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppShadows.borderRadiusLg,
        boxShadow: AppShadows.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canteenName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your order from this canteen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Poppins',
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // ETA badge (Only show if maxPrepTime is not null)
          if (maxPrepTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppShadows.borderRadiusMd,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ready in $readyInMinutes min',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Cart item row ────────────────────────────────────────────────
  Widget _buildCartItemRow(
    BuildContext context,
    String name,
    double price,
    int quantity,
    int? prepTime,
    bool isDark, {
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final textSecondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side — name + prep time + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (prepTime != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 13, color: textSecondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        '${prepTime}m',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(0)} × $quantity',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Right side — qty controls + delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyCircle(Icons.remove, onDecrement, isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$quantity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _qtyCircle(Icons.add, onIncrement, isDark),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyCircle(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );
  }

  // ─── Coupon + Price summary Card contents ─────────────────────────
  Widget _buildCouponAndPriceSection({
    required BuildContext context,
    required bool isDark,
    required double orderAmount,
    required double packingCharge,
    required double discountAmount,
    required double total,
    required AsyncValue<List<MenuItem>> couponsAsync,
  }) {
    final theme = Theme.of(context);
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coupon heading
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Coupon Code',
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Input + Apply in a single container
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(AppShadows.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENTER COUPON CODE',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      letterSpacing: 0.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final enteredCode = _couponController.text.trim().toUpperCase();
                  final coupons = couponsAsync.value ?? [];
                  final matching = coupons.where((c) => c.name == enteredCode).firstOrNull;

                  if (matching != null) {
                    setState(() {
                      _discountAmount = matching.price;
                      _appliedCouponCode = matching.name;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coupon "$enteredCode" applied! Flat ₹${matching.price.toStringAsFixed(0)} discount.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    setState(() {
                      _discountAmount = 0.0;
                      _appliedCouponCode = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Invalid or expired coupon code.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppShadows.radiusSm),
                  ),
                  child: const Center(
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Available Coupons Chips List
        couponsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (coupons) {
            if (coupons.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Text(
                  'Available Coupons:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final isApplied = _appliedCouponCode == coupon.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          selected: isApplied,
                          label: Text(
                            '${coupon.name} (₹${coupon.price.toStringAsFixed(0)} off)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isApplied ? Colors.white : AppColors.primary,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _couponController.text = coupon.name;
                              setState(() {
                                _discountAmount = coupon.price;
                                _appliedCouponCode = coupon.name;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Coupon "${coupon.name}" applied! Flat ₹${coupon.price.toStringAsFixed(0)} discount.'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              _couponController.clear();
                              setState(() {
                                _discountAmount = 0.0;
                                _appliedCouponCode = null;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),
        Divider(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, height: 1),
        const SizedBox(height: 14),

        // Price rows
        _priceRow(context, 'Order Amount', '₹${orderAmount.toStringAsFixed(2)}', isDark),
        const SizedBox(height: 8),
        _priceRow(context, 'Packing Charge', '₹${packingCharge.toStringAsFixed(2)}', isDark),
        if (discountAmount > 0) ...[
          const SizedBox(height: 8),
          _priceRow(context, 'Discount ($_appliedCouponCode)', '-₹${discountAmount.toStringAsFixed(2)}', isDark, isDiscount: true),
        ],
        const SizedBox(height: 14),
        Divider(color: isDark ? AppColors.dividerDark : AppColors.dividerLight, height: 1),
        const SizedBox(height: 14),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Payable',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String value, bool isDark, {bool isDiscount = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDiscount
                ? AppColors.success
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDiscount
                ? AppColors.success
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─── Phone number Card ────────────────────────────────────────────
  Widget _buildPhoneSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppShadows.borderRadiusLg,
        boxShadow: AppShadows.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Phone Number',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(AppShadows.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.phone_iphone_rounded,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '+91 ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter 10-digit number',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order type Card ──────────────────────────────────────────────
  Widget _buildOrderTypeSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppShadows.borderRadiusLg,
        boxShadow: AppShadows.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Preference',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _orderTypeBtn(context, 'Dine In', Icons.restaurant_rounded, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _orderTypeBtn(context, 'Pack', Icons.takeout_dining_rounded, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTypeBtn(BuildContext context, String type, IconData icon, bool isDark) {
    final isSelected = _orderType == type;

    return GestureDetector(
      onTap: () => setState(() => _orderType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight),
          borderRadius: BorderRadius.circular(AppShadows.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sticky bottom bar ─────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, bool isEmpty, double total, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppShadows.radiusXl),
          topRight: Radius.circular(AppShadows.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            gradient: (isEmpty || _isOrdering) ? null : AppColors.primaryGradient,
            color: (isEmpty || _isOrdering) ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : null,
            borderRadius: BorderRadius.circular(AppShadows.radiusMd),
            boxShadow: (isEmpty || _isOrdering) ? null : AppShadows.primaryGlow,
          ),
          child: ElevatedButton(
            onPressed: (isEmpty || _isOrdering) ? null : () => _initiatePayment(total),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShadows.radiusMd),
              ),
            ),
            child: _isOrdering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.currency_rupee_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Pay with Razorpay',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
