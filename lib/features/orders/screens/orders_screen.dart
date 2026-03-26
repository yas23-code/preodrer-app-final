import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/orders_provider.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/order_status_badge.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load orders: $e')),
      data: (orders) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text('Order #${order.id}'),
            subtitle: Text(
              order.createdAt == null ? '—' : formatDate(order.createdAt!),
            ),
            trailing: OrderStatusBadge(status: order.status),
            onTap: () => context.go('/order/${order.id}'),
          );
        },
      ),
    );
  }
}

