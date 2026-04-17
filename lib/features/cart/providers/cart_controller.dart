import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../menu/models/menu_item.dart';
import '../models/cart_model.dart';
import '../repositories/cart_repository.dart';

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

  Future<void> addItem(MenuItem item) async {
    debugPrint('[UI_WIRING] cart_controller.dart addItem() called for item=${item.name}');
    final userId = _userId;
    if (userId == null) {
      debugPrint('[UI_WIRING] cart_controller.dart addItem() failed: No user found!');
      return;
    }

    final current = state.asData?.value ?? const CartState.empty();
    debugPrint('[UI_WIRING] cart_controller.dart current state lines count: ${current.lines.length}');
    final existing = current.lines[item.id];
    final newQty = (existing?.quantity ?? 0) + 1;

    // Optimistic UI update
    final nextLines = Map<String, CartLine>.from(current.lines);
    nextLines[item.id] = CartLine(item: item, quantity: newQty);
    state = AsyncValue.data(CartState(lines: nextLines));
    debugPrint('[CartController] addItem -> optimistic state updated (qty=$newQty)');

    try {
      await ref.read(cartRepositoryProvider).upsertCartItem(
            userId: userId,
            itemId: item.id,
            quantity: newQty,
          );
    } catch (e) {
      debugPrint('[CartController] addItem -> DB failure, ROLLING BACK UI: $e');
      state = AsyncValue.data(current);
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

      // --- BROADCAST TO VENDOR ---
      // This bypasses any database RLS locking limitations for Realtime WAL streams
      // by pinging the vendor app directly to fetch the new orders.
      supabase.channel('vendor-broadcast-$kAcktronVendorId').sendBroadcastMessage(
        event: 'refresh_orders',
        payload: {'order_id': orderId, 'canteen_id': orderCanteenId},
      );

      // 3. Successfully placed — clear cart
      await clear();
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
