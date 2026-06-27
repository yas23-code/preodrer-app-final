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

  Future<void> placeOrder() async {
    final userId = _userId;
    if (userId == null) return;

    // ── Phone number validation (fresh DB query) ──────────────────────
    final supabaseForCheck = ref.read(supabaseClientProvider);
    final profileRow = await supabaseForCheck
        .from(kProfilesTableName)
        .select('phone')
        .eq('id', userId)
        .maybeSingle();
    final phone = profileRow?['phone']?.toString().trim();
    debugPrint('[CartController] placeOrder -> phone check: "$phone"');
    if (phone == null || phone.isEmpty) {
      throw Exception(
        'Phone number is required.\n'
        'Go to Profile → Edit Profile and add your phone number before ordering.',
      );
    }

    final currentCart = state.asData?.value;
    if (currentCart == null || currentCart.lines.isEmpty) return;

    // ── CANTEEN ID RESOLUTION ──────────────────────────────────────────
    // ALWAYS use kAcktronCanteenId for the order row. The item.canteenId
    // field can carry a stale / wrong value (e.g. Gori Cafe 38a27df9-...)
    // if old cart_items or menu_items reference a different canteen.
    // This is the authoritative canteen for all customer orders in the
    // Acktron deployment.
    const orderCanteenId = kAcktronCanteenId;

    // ── Debug diagnostics ──────────────────────────────────────────────
    for (final line in currentCart.lines.values) {
      debugPrint('[CANTEEN_DEBUG] placeOrder -> cart item: '
          'id=${line.item.id}, name=${line.item.name}, '
          'item.canteenId=${line.item.canteenId}');
    }
    debugPrint('[CANTEEN_DEBUG] placeOrder -> FINAL order canteen_id=$orderCanteenId');
    debugPrint('[CANTEEN_DEBUG] placeOrder -> Expected Acktron=$kAcktronCanteenId');

    try {
      final supabase = ref.read(supabaseClientProvider);

      // 1. Insert order — always Acktron canteen
      final orderPayload = {
        'student_id': userId,
        'canteen_id': orderCanteenId,
        'status': 'pending',
        'total_amount': currentCart.totalAmount,
      };
      debugPrint('[CANTEEN_DEBUG] placeOrder -> INSERT payload: $orderPayload');

      final newOrder = await supabase
          .from(kOrdersTableName)
          .insert(orderPayload)
          .select()
          .single();

      final orderId = newOrder['id'];
      debugPrint('[CANTEEN_DEBUG] placeOrder -> created order id=$orderId');

      // 2. Insert order items
      final orderItemsData = currentCart.lines.values.map((line) => {
        'order_id': orderId,
        'menu_item_id': line.item.id,
        'quantity': line.quantity,
        'price': line.item.price,
      }).toList();

      await supabase.from(kOrderItemsTableName).insert(orderItemsData);

      debugPrint('[CartController] Order $orderId placed successfully.');

      // Vendor dashboard uses polling to detect new orders — no broadcast needed.

      // 3. Successfully placed — clear cart
      await clear();
      
      // 4. Invalidate the orders provider so that it instantly fetches the new order
      // when the customer navigates to the Orders tab.
      ref.invalidate(ordersProvider);
    } catch (e) {
      debugPrint('[CartController] placeOrder -> DB failure: $e');
      throw Exception('Failed to place order: $e');
    }
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
