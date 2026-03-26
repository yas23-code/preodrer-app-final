import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order.dart';

final ordersProvider =
    AsyncNotifierProvider<OrdersController, List<Order>>(
      OrdersController.new,
    );

class OrdersController extends AsyncNotifier<List<Order>> {
  String? _currentUserId;
  dynamic _channel;

  @override
  Future<List<Order>> build() async {
    ref.listen<AsyncValue<User?>>(
      authControllerProvider,
      (previous, next) async {
        final user = next.maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
        if (user == null) {
          _currentUserId = null;
          await _unsubscribe();
          state = const AsyncValue.data([]);
          return;
        }

        if (_currentUserId == user.id) return;
        _currentUserId = user.id;

        await _unsubscribe();
        final initial = await _fetchOrders(user.id);
        state = AsyncValue.data(initial);
        _subscribeRealtime(user.id);
      },
    );

    final initialUser = ref.read(authControllerProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    if (initialUser == null) return const [];

    _currentUserId = initialUser.id;
    final initial = await _fetchOrders(initialUser.id);
    _subscribeRealtime(initialUser.id);
    return initial;
  }

  Future<void> _unsubscribe() async {
    try {
      await _channel?.unsubscribe();
    } catch (_) {
      // ignore unsubscribe errors
    }
    _channel = null;
  }

  Future<List<Order>> _fetchOrders(String userId) async {
    final supabase = ref.read(supabaseClientProvider);

    // TODO: fill in the actual orders table column names and filters.
    final response = await supabase
        .from(kOrdersTableName)
        .select()
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    return data
        .map((row) => Order.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  void _subscribeRealtime(String userId) {
    final supabase = ref.read(supabaseClientProvider);

    // TODO: ensure schema/table names + user_id filter match your DB/RLS setup.
    _channel = supabase
        .channel('orders-realtime-$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: kOrdersTableName,
          // TODO: fill in the correct user_id column name if yours differs.
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord as Map<String, dynamic>?;
            if (newRecord == null) return;

            // TODO: if your column names differ, map them into Order.fromJson keys here.
            final updatedOrder = Order.fromJson(newRecord);

            final current = state.value ?? const [];
            final idx = current.indexWhere((o) => o.id == updatedOrder.id);
            final next = List<Order>.from(current);
            if (idx >= 0) {
              next[idx] = updatedOrder;
            } else {
              next.insert(0, updatedOrder);
            }
            state = AsyncValue.data(next);
          },
        )
        ..subscribe();
  }
}

