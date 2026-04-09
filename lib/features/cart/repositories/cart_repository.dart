import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../menu/models/menu_item.dart';
import '../models/cart_model.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(supabase: ref.watch(supabaseClientProvider));
});

/// Pure remote data layer for the cart. It completely lacks local state.
class CartRepository {
  final SupabaseClient _supabase;

  const CartRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Loads the entire cart from the database for the given user ID.
  Future<CartState> loadCart(String userId) async {
    developer.log('[UI_WIRING] cart_repository.dart loadCart() -> fetching rows for user=$userId', name: 'CartRepository');
    
    // 1. Fetch raw cart items
    final cartRows = await _supabase
        .from(kCartItemsTableName)
        .select('item_id, quantity, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    if (cartRows.isEmpty) {
      return const CartState.empty();
    }

    final itemIds = cartRows
        .map((row) => row['item_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (itemIds.isEmpty) {
      return const CartState.empty();
    }

    // 2. Fetch the corresponding menu items
    final menuRows = await _supabase
        .from(kMenuItemsTableName)
        .select()
        .filter('id', 'in', itemIds);

    final menuById = <String, MenuItem>{};
    for (final row in menuRows) {
      try {
        final item = MenuItem.fromJson(row);
        menuById[item.id] = item;
      } catch (e) {
        developer.log('[CartRepository] loadCart -> Failed to parse MenuItem: $e', name: 'CartRepository');
      }
    }

    // 3. Hydrate state
    final lines = <String, CartLine>{};
    for (final row in cartRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null) continue;
      
      final item = menuById[itemId];
      if (item == null) continue;

      final quantityRaw = row['quantity'];
      final quantity = quantityRaw is num ? quantityRaw.toInt() : 1;
      if (quantity <= 0) continue;

      lines[item.id] = CartLine(item: item, quantity: quantity);
    }

    developer.log('[CartRepository] loadCart -> Hydrated ${lines.length} lines', name: 'CartRepository');
    return CartState(lines: lines);
  }

  /// Upserts a cart item quantity.
  Future<void> upsertCartItem({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    developer.log('[UI_WIRING] cart_repository.dart upsert -> item=$itemId qty=$quantity', name: 'CartRepository');

    final payload = {
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
    };

    try {
      final existingRows = await _supabase
          .from(kCartItemsTableName)
          .select('id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .limit(1);

      if (existingRows.isNotEmpty) {
        final existingId = existingRows.first['id'];
        await _supabase
            .from(kCartItemsTableName)
            .update({'quantity': quantity})
            .eq('id', existingId);
        developer.log('[UI_WIRING] cart_repository.dart -> updated existing row', name: 'CartRepository');
        return;
      }

      await _supabase.from(kCartItemsTableName).insert(payload);
      developer.log('[UI_WIRING] cart_repository.dart -> inserted new row', name: 'CartRepository');
    } on PostgrestException catch (e) {
      developer.log('[DB_DIAGNOSIS] PostgrestException in upsertCartItem: message="${e.message}", details="${e.details}", hint="${e.hint}", code="${e.code}"', name: 'CartRepository');
      rethrow;
    } catch (e) {
      developer.log('[DB_DIAGNOSIS] Generic Exception in upsertCartItem: $e', name: 'CartRepository');
      rethrow;
    }
  }

  /// Deletes a specific item from the cart.
  Future<void> deleteCartItem({
    required String userId,
    required String itemId,
  }) async {
    developer.log('[CartRepository] delete -> item=$itemId', name: 'CartRepository');
    await _supabase
        .from(kCartItemsTableName)
        .delete()
        .eq('user_id', userId)
        .eq('item_id', itemId);
  }

  /// Clears the entire cart for a user.
  Future<void> clearCart(String userId) async {
    developer.log('[CartRepository] clearCart -> user=$userId', name: 'CartRepository');
    await _supabase
        .from(kCartItemsTableName)
        .delete()
        .eq('user_id', userId);
  }
}
