import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/order.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/order_status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.read(supabaseClientProvider);

    final displayId = orderId.length >= 8 ? orderId.substring(4, 8).toUpperCase() : orderId;
    final secretPin = orderId.length >= 4 ? orderId.substring(0, 4).toUpperCase() : '----';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$displayId'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
      ),
      body: FutureBuilder(
        future: _fetchOrder(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load order: ${snapshot.error}'));
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              OrderStatusBadge(status: order.status),
              if (order.status == 'ready') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('Your Secret Pickup PIN', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                      Text(secretPin, style: TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.w900, color: Colors.purple.shade900)),
                    ]
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Placed: ${order.createdAt == null ? '—' : formatDate(order.createdAt!)}',
              ),
              const SizedBox(height: 12),
              Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // TODO: add UI for order line items once you define the schema.
              const Text('Order items will appear here (TODO).'),
            ],
          );
        },
      ),
    );
  }

  Future<Order?> _fetchOrder(SupabaseClient supabase) async {
    // TODO: fill in the correct orders table column names for primary key mapping.
    final response = await supabase
        .from(kOrdersTableName)
        .select()
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }
}

