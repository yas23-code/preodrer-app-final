import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order.dart';

final ordersProvider =
    AsyncNotifierProvider<OrdersController, List<Map<String, dynamic>>>(
      OrdersController.new,
    );

class OrdersController extends AsyncNotifier<List<Map<String, dynamic>>> {
  String? _currentUserId;
  Timer? _pollTimer;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Cancel polling when this provider is disposed
    ref.onDispose(() {
      _stopPolling();
    });

    ref.listen<AsyncValue<User?>>(
      authControllerProvider,
      (previous, next) async {
        final user = next.maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
        if (user == null) {
          _currentUserId = null;
          _stopPolling();
          state = const AsyncValue.data([]);
          return;
        }

        if (_currentUserId == user.id) return;
        _currentUserId = user.id;

        final initial = await _fetchOrders(user.id);
        state = AsyncValue.data(initial);
        _startPolling(user.id);
      },
    );

    final initialUser = ref.read(authControllerProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    if (initialUser == null) return const [];

    _currentUserId = initialUser.id;
    final initial = await _fetchOrders(initialUser.id);
    _startPolling(initialUser.id);
    return initial;
  }

  void _startPolling(String userId) {
    _stopPolling();
    debugPrint('[ORDERS POLL] Starting polling every 5 seconds for studentId=$userId');
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final fresh = await _fetchOrders(userId);
        state = AsyncValue.data(fresh);
      } catch (e) {
        debugPrint('[ORDERS POLL] Error during poll: $e');
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<List<Map<String, dynamic>>> _fetchOrders(String userId) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase
        .from(kOrdersTableName)
        .select('*, canteens:canteen_id(*), order_items(*, menu_items(*))')
        .eq('student_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    final orders = data.cast<Map<String, dynamic>>();

    // Collect unique canteen IDs from non-completed orders
    final activeStatuses = ['pending', 'accepted', 'preparing', 'ready'];
    final canteenIdsToFetch = orders
        .where((o) => activeStatuses.contains((o['status'] as String? ?? '').toLowerCase()))
        .map((o) => o['canteen_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // For each canteen, fetch active order count (orders ahead = total active - 1 for this order)
    final activeCountByCanteen = <String, int>{};
    for (final canteenId in canteenIdsToFetch) {
      try {
        final countRes = await supabase
            .from(kOrdersTableName)
            .select('id')
            .eq('canteen_id', canteenId)
            .not('status', 'in', '(completed,delivered,declined,rejected,cancelled)');
        activeCountByCanteen[canteenId] = (countRes as List).length;
      } catch (_) {
        activeCountByCanteen[canteenId] = 0;
      }
    }

    // Embed active count in each order map for ETA calculation on the UI
    return orders.map((order) {
      final canteenId = order['canteen_id']?.toString() ?? '';
      final activeCount = activeCountByCanteen[canteenId] ?? 0;
      return {
        ...order,
        '_active_orders_count': activeCount,
      };
    }).toList();
  }
}
