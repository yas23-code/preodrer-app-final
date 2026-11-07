import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../canteen/providers/canteen_provider.dart';
import '../../menu/models/menu_item.dart';
import '../models/cart_model.dart';
import '../repositories/cart_repository.dart';
import '../../orders/providers/orders_provider.dart';
import '../../menu/providers/menu_provider.dart';
import '../../payment/providers/payment_provider.dart';

final cartControllerProvider =
    AsyncNotifierProvider<CartController, CartState>(CartController.new);

class CartController extends AsyncNotifier<CartState> {
  @override
  Future<CartState> build() async {
    debugPrint('[CartController] build -> checking auth state');
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;

    if (user == null) {
      debugPrint('[CartController] build -> returning empty cart (no user)');
      return const CartState.empty();
    }

    try {
      final repo = ref.read(cartRepositoryProvider);
      return await repo.loadCart(user.id);
    } catch (e, st) {
      debugPrint('[CartController] build -> Failed to load cart: $e\n$st');
      return const CartState.empty();
    }
  }

  String? get _userId => ref.read(authControllerProvider).asData?.value?.id;

  Future<String> _getCanteenName(String canteenId) async {
    final cached = ref.read(canteensProvider).value;
    if (cached != null) {
      for (final c in cached) {
        if (c.id == canteenId) return c.name;
      }
    }
    try {
      final supabase = ref.read(supabaseClientProvider);
      final res = await supabase.from(kCanteensTableName).select('name').eq('id', canteenId).maybeSingle();
      if (res != null && res['name'] != null) {
        return res['name'].toString();
      }
    } catch (_) {}
    return 'Other Canteen';
  }

  Future<bool> addItem(MenuItem item, [BuildContext? context]) async {
    debugPrint('[UI_WIRING] cart_controller.dart addItem() called for item=${item.name}');
    final userId = _userId;
    if (userId == null) {
      debugPrint('[UI_WIRING] cart_controller.dart addItem() failed: No user found!');
      return false;
    }

    final current = state.asData?.value ?? const CartState.empty();
    
    // Check if item is from a different canteen
    final activeCanteenId = current.lines.isNotEmpty 
        ? current.lines.values.first.item.canteenId 
        : null;

    if (activeCanteenId != null && item.canteenId != null && activeCanteenId != item.canteenId) {
      if (context == null) {
        debugPrint('[CartController] Different canteen, but context is null. Rejecting add.');
        return false;
      }

      final currentCanteenName = await _getCanteenName(activeCanteenId);
      final newCanteenName = await _getCanteenName(item.canteenId!);

      if (!context.mounted) return false;

      final replace = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFFF9EC), // Warm cream background
            title: const Text(
              'Replace Cart?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Your cart already contains items from '),
                  TextSpan(
                    text: currentCanteenName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const TextSpan(text: '.\n\nWould you like to clear your current cart and start a new order from '),
                  TextSpan(
                    text: newCanteenName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // Accent Red
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'Replace Cart',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (replace != true) {
        return false;
      }

      // Clear the current cart items first
      await clear();
    }

    // Refresh current reference since it could have been cleared
    final currentUpdated = state.asData?.value ?? const CartState.empty();
    final existing = currentUpdated.lines[item.id];
    final newQty = (existing?.quantity ?? 0) + 1;

    // Optimistic UI update
    final nextLines = Map<String, CartLine>.from(currentUpdated.lines);
    nextLines[item.id] = CartLine(item: item, quantity: newQty);
    state = AsyncValue.data(CartState(lines: nextLines));
    debugPrint('[CartController] addItem -> optimistic state updated (qty=$newQty)');

    try {
      await ref.read(cartRepositoryProvider).upsertCartItem(
            userId: userId,
            itemId: item.id,
            quantity: newQty,
          );
      return true;
    } catch (e) {
      debugPrint('[CartController] addItem -> DB failure, ROLLING BACK UI: $e');
      state = AsyncValue.data(currentUpdated);
      return false;
    }
  }

  Future<void> decrementItem(MenuItem item) async {
    final userId = _userId;
    if (userId == null) return;

    final current = state.asData?.value ?? const CartState.empty();
    final existing = current.lines[item.id];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      return removeItem(item);
    }

    final newQty = existing.quantity - 1;
    final nextLines = Map<String, CartLine>.from(current.lines);
    nextLines[item.id] = existing.copyWith(quantity: newQty);
    
    state = AsyncValue.data(CartState(lines: nextLines));

    try {
      await ref.read(cartRepositoryProvider).upsertCartItem(
            userId: userId,
            itemId: item.id,
            quantity: newQty,
          );
    } catch (e) {
      debugPrint('[CartController] decrementItem -> DB failure, ROLLING BACK UI: $e');
      state = AsyncValue.data(current);
    }
  }

  Future<void> removeItem(MenuItem item) async {
    final userId = _userId;
    if (userId == null) return;

    final current = state.asData?.value ?? const CartState.empty();
    final nextLines = Map<String, CartLine>.from(current.lines)..remove(item.id);
    
    state = AsyncValue.data(CartState(lines: nextLines));

    try {
      await ref.read(cartRepositoryProvider).deleteCartItem(
            userId: userId,
            itemId: item.id,
          );
    } catch (e) {
      debugPrint('[CartController] removeItem -> DB failure, ROLLING BACK UI: $e');
      state = AsyncValue.data(current);
    }
  }

  // ── Private: create the order row in DB + insert order items ─────────
  // Returns the new order's UUID.
  Future<String> _createOrder({required double customTotal, required String userId, required String phone}) async {
    final supabase = ref.read(supabaseClientProvider);
    final currentCart = state.asData?.value;
    if (currentCart == null || currentCart.lines.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final orderCanteenId = ref.read(selectedCanteenIdProvider);

    // ── Debug diagnostics ──────────────────────────────────────────────
    for (final line in currentCart.lines.values) {
      debugPrint('[CANTEEN_DEBUG] _createOrder -> cart item: '
          'id=${line.item.id}, name=${line.item.name}, '
          'item.canteenId=${line.item.canteenId}');
    }
    debugPrint('[CANTEEN_DEBUG] _createOrder -> FINAL order canteen_id=$orderCanteenId');

    // Check concurrent orders limit
    final canteenRow = await supabase
        .from('canteens')
        .select('max_concurrent_orders')
        .eq('id', orderCanteenId)
        .maybeSingle();

    if (canteenRow != null) {
      int maxConcurrent = 99999;
      try {
        if (canteenRow['max_concurrent_orders'] != null) {
          maxConcurrent = canteenRow['max_concurrent_orders'] as int;
        }
      } catch (_) {}

      final activeCountRes = await supabase
          .from('orders')
          .select('id')
          .eq('canteen_id', orderCanteenId)
          .not('status', 'in', '("completed","delivered","declined","rejected","cancelled")');
      final activeCount = activeCountRes.length;

      if (maxConcurrent < 99999 && activeCount >= maxConcurrent) {
        throw Exception(
          'The canteen is currently busy and has paused taking new orders. '
          'Please try again in a few minutes when some orders are completed.',
        );
      }
    }

    // 1. Insert order row with payment_status='pending'
    final orderPayload = <String, dynamic>{
      'student_id': userId,
      'canteen_id': orderCanteenId,
      'status': 'pending',
      'payment_status': 'pending',
      'total_amount': customTotal,
    };
    debugPrint('[CANTEEN_DEBUG] _createOrder -> INSERT payload: $orderPayload');

    final newOrder = await supabase
        .from(kOrdersTableName)
        .insert(orderPayload)
        .select()
        .single();

    final orderId = newOrder['id'] as String;
    debugPrint('[CANTEEN_DEBUG] _createOrder -> created order id=$orderId');

    // 2. Insert order items
    final orderItemsData = currentCart.lines.values.map((line) => {
      'order_id': orderId,
      'menu_item_id': line.item.id,
      'quantity': line.quantity,
      'price': line.item.price,
    }).toList();

    await supabase.from(kOrderItemsTableName).insert(orderItemsData);
    debugPrint('[CartController] _createOrder -> order items inserted for $orderId');
    return orderId;
  }

  /// Public method called from CartScreen.
  ///
  /// 1. Updates/validates the phone number
  /// 2. Creates the order in the DB (payment_status='pending')
  /// 3. Calls the `create-razorpay-order` edge function
  /// 4. Returns [RazorpaySessionData] so the UI can open the payment sheet
  ///
  /// Does NOT clear the cart — that happens after payment confirmation.
  Future<RazorpaySessionData> initiatePayment({
    required double total,
    required String phone,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated.');

    final supabase = ref.read(supabaseClientProvider);

    // 1. Persist the phone number to the profile
    if (phone.trim().isNotEmpty) {
      try {
        await supabase
            .from(kProfilesTableName)
            .update({'phone': phone.trim()})
            .eq('id', userId);
      } catch (e) {
        debugPrint('[CartController] Failed to update phone in profile: $e');
      }
    }

    // 2. Validate phone from DB
    final profileRow = await supabase
        .from(kProfilesTableName)
        .select('phone, name, email')
        .eq('id', userId)
        .maybeSingle();
    final dbPhone = profileRow?['phone']?.toString().trim();
    debugPrint('[CartController] initiatePayment -> phone check: "$dbPhone"');
    if (dbPhone == null || dbPhone.isEmpty) {
      throw Exception(
        'Phone number is required.\n'
        'Please enter a valid phone number before confirming.',
      );
    }

    // 3. Create order in DB
    final orderId = await _createOrder(
      customTotal: total,
      userId: userId,
      phone: dbPhone,
    );

    // 4. Create Razorpay order via edge function
    final paymentController = ref.read(paymentControllerProvider);
    final session = await paymentController.createRazorpayOrder(
      appOrderId: orderId,
      amount: total,
      customerPhone: dbPhone,
      customerEmail: profileRow?['email']?.toString(),
      customerName: profileRow?['name']?.toString(),
      customerId: userId,
    );

    debugPrint('[CartController] initiatePayment -> session created: razorpayOrderId=${session.razorpayOrderId}');
    return session;
  }

  /// Called by the payment screen after successful payment verification
  /// to clear the cart and refresh orders.
  Future<void> onPaymentSuccess() async {
    await clear();
    ref.invalidate(ordersProvider);
  }

  Future<void> clear() async {
    final userId = _userId;
    state = const AsyncValue.data(CartState.empty());

    if (userId == null) return;
    try {
      await ref.read(cartRepositoryProvider).clearCart(userId);
    } catch (e) {
      debugPrint('[CartController] clear -> DB failure: $e');
    }
  }
}
