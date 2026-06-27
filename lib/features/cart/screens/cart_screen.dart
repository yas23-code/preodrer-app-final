import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_controller.dart';
import '../../canteen/providers/canteen_provider.dart';
<<<<<<< HEAD
import '../../auth/providers/auth_provider.dart';
=======
import '../../vendor/providers/coupons_provider.dart';
import '../../menu/models/menu_item.dart';
>>>>>>> origin/friend-feature-new

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  bool _isOrdering = false;
  bool _orderSuccess = false;
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _orderType = 'Dine In';
  double _discountAmount = 0.0;
  String? _appliedCouponCode;

  late final AnimationController _successAnimController;
  late final Animation<double> _successScaleAnim;

  // Design tokens
  static const _bg = Color(0xFFFFF9EC);
  static const _yellow = Color(0xFFFFC107);
  static const _red = Color(0xFFE53935);
  static const _textPrimary = Color(0xFF222222);
  static const _textSecondary = Color(0xFF666666);

  bool _phoneAutoFilled = false;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
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
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(double total) async {
    setState(() => _isOrdering = true);
    try {
      await ref.read(cartControllerProvider.notifier).placeOrder(customTotal: total);
      if (!mounted) return;
      setState(() {
        _isOrdering = false;
        _orderSuccess = true;
      });
      _successAnimController.forward();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Success overlay ──────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return Container(
      color: _bg,
      child: Center(
        child: ScaleTransition(
          scale: _successScaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 64),
              ),
              const SizedBox(height: 20),
              const Text(
                '🎉 Order Placed\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Redirecting to your orders...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartControllerProvider);
    final currentCanteen = ref.watch(currentCanteenProvider);
    final canteenId = currentCanteen?.id ?? '';
    final couponsAsync = ref.watch(canteenCouponsProvider(canteenId));

    debugPrint('[UI_WIRING] cart_screen.dart build() called');
    if (cartAsync.hasValue) {
      final cart = cartAsync.value!;
      debugPrint('[DB_DIAGNOSIS] cart_screen.dart: cart.itemCount=${cart.itemCount}, keys=${cart.lines.keys}');
      for (final line in cart.lines.values) {
        debugPrint('[DB_DIAGNOSIS] cart_screen.dart: rendering item="${line.item.name}", quantity=${line.quantity}');
      }
    } else {
      debugPrint('[DB_DIAGNOSIS] cart_screen.dart: cartAsync has no value yet');
    }

    if (_orderSuccess) return _buildSuccessOverlay();

    return Scaffold(
      backgroundColor: _bg,
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _yellow)),
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
                            child: const Icon(Icons.arrow_back,
                                size: 22, color: _textPrimary),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.shopping_cart_rounded,
                              color: _textPrimary, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Cart',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SCROLLABLE BODY ───────────────────────────────────
                  Expanded(
                    child: cart.lines.isEmpty
                        ? _buildEmptyCart()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Canteen + ETA
                              _buildCanteenHeader(
                                  currentCanteen?.name ?? 'Canteen'),
                              const SizedBox(height: 14),

                              // Cart items — compact rows
                              ...cart.lines.values.map((line) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildCartItemRow(
                                    line.item.name,
                                    line.item.price,
                                    line.quantity,
                                    line.item.prepTime,
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
                              }),

                              const SizedBox(height: 10),

                              // Coupon + Price breakdown
                              _buildCouponAndPriceSection(
                                orderAmount: orderAmount,
                                packingCharge: packingCharge,
                                discountAmount: _discountAmount,
                                total: total,
                                couponsAsync: couponsAsync,
                              ),

                              const SizedBox(height: 14),

                              // Phone
                              _buildPhoneSection(),

                              const SizedBox(height: 14),

                              // Order type
                              _buildOrderTypeSection(),
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
                  child: _buildBottomBar(cart.lines.isEmpty, total),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Empty cart ────────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add some delicious food!',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Canteen + ETA (compact, matches reference) ────────────────────
  Widget _buildCanteenHeader(String canteenName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canteenName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Your order from this canteen',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        // ETA badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.access_time_rounded, color: _red, size: 16),
              SizedBox(width: 4),
              Text(
                '~30\nmin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _red,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Cart item row (compact, no image — matches reference) ─────────
  Widget _buildCartItemRow(
    String name,
    double price,
    int quantity,
    int? prepTime, {
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onDelete,
  }) {
    return Row(
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
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  if (prepTime != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(
                      '${prepTime}m',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '₹${price.toStringAsFixed(0)} × $quantity',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Right side — qty controls + delete
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qtyCircle(Icons.remove, onDecrement),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
            _qtyCircle(Icons.add, onIncrement),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _qtyCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Icon(icon, size: 16, color: _textPrimary),
      ),
    );
  }

  // ─── Coupon + Price summary (all inline, compact) ──────────────────
  Widget _buildCouponAndPriceSection({
    required double orderAmount,
    required double packingCharge,
    required double discountAmount,
    required double total,
    required AsyncValue<List<MenuItem>> couponsAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coupon heading
        Row(
          children: const [
            Icon(Icons.local_offer_outlined, color: _red, size: 18),
            SizedBox(width: 6),
            Text(
              'Coupon Code',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input + Apply
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _yellow, width: 1.2),
                ),
                child: TextField(
                  controller: _couponController,
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ENTER COUPON CODE',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
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
                      backgroundColor: Colors.green[700],
                    ),
                  );
                } else {
                  setState(() {
                    _discountAmount = 0.0;
                    _appliedCouponCode = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid or expired coupon code.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red, width: 1.2),
                ),
                child: const Center(
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Available Coupons Horizontal List (Screenshot 5 detail)
        couponsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (coupons) {
            if (coupons.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Available Coupons:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
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
                        child: FilterChip(
                          selected: isApplied,
                          label: Text(
                            '${coupon.name} (Flat ₹${coupon.price.toStringAsFixed(0)} off)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isApplied ? Colors.white : const Color(0xFFC62828),
                            ),
                          ),
                          selectedColor: const Color(0xFFC62828),
                          backgroundColor: const Color(0xFFFFEBEE),
                          side: BorderSide(
                            color: isApplied ? const Color(0xFFC62828) : const Color(0xFFFFCDD2),
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
                                  backgroundColor: Colors.green[700],
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

        const SizedBox(height: 16),

        // Price rows
        _priceRow('Order Amount', '₹${orderAmount.toStringAsFixed(2)}'),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text(
              'Packing Charge',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _textSecondary),
            ),
            const Spacer(),
            Text(
              '₹${packingCharge.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary),
            ),
          ],
        ),
        if (discountAmount > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Discount ($_appliedCouponCode)',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '-₹${discountAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Payable',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: _textSecondary)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textPrimary)),
      ],
    );
  }

  // ─── Phone number (compact) ────────────────────────────────────────
  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number (Required)',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _red,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _red, width: 1.2),
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: _textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Enter phone number',
              hintStyle: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: _textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Order type (compact toggles) ──────────────────────────────────
  Widget _buildOrderTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Type',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _orderTypeBtn('Dine In', Icons.restaurant_menu_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _orderTypeBtn('Pack', Icons.takeout_dining_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _orderTypeBtn(String type, IconData icon) {
    final sel = _orderType == type;
    return GestureDetector(
      onTap: () => setState(() => _orderType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? _red : _yellow,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: sel ? _red : _textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? _red : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sticky bottom bar ─────────────────────────────────────────────
  Widget _buildBottomBar(bool isEmpty, double total) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (isEmpty || _isOrdering) ? null : () => _placeOrder(total),
          style: ElevatedButton.styleFrom(
            backgroundColor: _yellow,
            foregroundColor: _textPrimary,
            disabledBackgroundColor: Colors.grey.shade200,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isOrdering
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _textPrimary),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
