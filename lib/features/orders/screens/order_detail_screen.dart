import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
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
        future: _fetchOrderData(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load order: ${snapshot.error}'));
          }

          final orderData = snapshot.data;
          if (orderData == null) {
            return const Center(child: Text('Order not found.'));
          }

          final status = orderData['status'] as String? ?? 'unknown';
          final rawCreatedAt = orderData['created_at'] as String?;
          final createdAt = rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null;
          final totalAmount = (orderData['total_amount'] as num?)?.toDouble() ?? 0.0;
          
          final orderItems = orderData['order_items'] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OrderStatusBadge(status: status),
                      if (status != 'completed' && status != 'delivered' && status != 'cancelled' && status != 'rejected') ...[
                        const SizedBox(width: 8),
                        _buildEtaBadge(orderData),
                      ],
                    ],
                  ),
                  Text(
                    createdAt == null ? '—' : formatDate(createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              if (status == 'ready') ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('Your Secret Pickup PIN', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(secretPin, style: TextStyle(fontSize: 36, letterSpacing: 12, fontWeight: FontWeight.w900, color: Colors.purple.shade900)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: QrImageView(
                          data: secretPin,
                          version: QrVersions.auto,
                          size: 140.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ]
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              Text(
                'Order Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (orderItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No items found for this order.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...orderItems.map((itemData) {
                  final qty = (itemData['quantity'] as num?)?.toInt() ?? 1;
                  final price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
                  final lineTotal = qty * price;
                  
                  final menuItem = itemData['menu_items'] as Map<String, dynamic>?;
                  final name = menuItem?['name'] as String? ?? 'Unknown Item';
                  final imageUrl = menuItem?['image_url'] as String?;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${formatCurrency(price)} x $qty', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        // Line total
                        Text(
                          formatCurrency(lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }),
                
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Order Summary
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: TextStyle(color: Colors.grey.shade700)),
                  Text(formatCurrency(totalAmount)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taxes & Fees', style: TextStyle(color: Colors.grey.shade700)),
                  const Text('₹0.00'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(formatCurrency(totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.fastfood_outlined, color: Colors.grey),
    );
  }

  Future<Map<String, dynamic>?> _fetchOrderData(SupabaseClient supabase) async {
    final response = await supabase
        .from(kOrdersTableName)
        .select('*, order_items(*, menu_items(*))')
        .eq('id', orderId)
        .maybeSingle();

    return response;
  }

  int _getEtaMinutes(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    int maxPrepTime = 10; // Default fallback
    for (final item in orderItems) {
      final menuItem = item['menu_items'] as Map<String, dynamic>?;
      if (menuItem != null) {
        final prep = menuItem['prep_time'] as int?;
        if (prep != null && prep > maxPrepTime) {
          maxPrepTime = prep;
        }
      }
    }
    return maxPrepTime;
  }

  Widget _buildEtaBadge(Map<String, dynamic> order) {
    final eta = _getEtaMinutes(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFE65100)),
          const SizedBox(width: 4),
          Text(
            'ETA: $eta mins',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

