import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
