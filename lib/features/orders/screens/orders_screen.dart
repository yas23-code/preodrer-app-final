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
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final order = orders[index];
            final displayId = order.id.length >= 8 ? order.id.substring(4, 8).toUpperCase() : order.id;
            final secretPin = order.id.length >= 4 ? order.id.substring(0, 4).toUpperCase() : '----';
            return ListTile(
              title: Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.createdAt == null ? '—' : formatDate(order.createdAt!)),
                  if (order.status == 'ready') ...[
                    const SizedBox(height: 8),
                    Text('Secret Pickup PIN: $secretPin', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700, fontSize: 16)),
                  ],
                  const SizedBox(height: 8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              onTap: () => context.push('/order/${order.id}'),
            );
          },
        );
      },
    );
  }
}

