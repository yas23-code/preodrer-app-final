import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/orders_provider.dart';
import '../../../shared/utils/formatters.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  // Theme Design Tokens
  static const _bg = Color(0xFFFFF9EC);
  static const _yellow = Color(0xFFFFC107);
  static const _red = Color(0xFFE53935);
  static const _success = Color(0xFF2E7D32);
  static const _cancelled = Color(0xFFD32F2F);
  static const _textPrimary = Color(0xFF222222);
  static const _textSecondary = Color(0xFF666666);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── PREMIUM TOP HEADER ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: _red,
                      ),
                    ),
                  ),
                  const Text(
                    'Order History',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── ORDERS LIST ─────────────────────────────────────────────
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _yellow),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load orders: $e',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders yet.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final orderMap = orders[index];
                      return _buildOrderCard(context, orderMap);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id'] as String? ?? '';
    final displayId = orderId.length >= 8
        ? orderId.substring(4, 8).toUpperCase()
        : orderId;
    final secretPin = orderId.length >= 4
        ? orderId.substring(0, 4).toUpperCase()
        : '----';

    final status = (order['status'] as String? ?? 'processing').toLowerCase();
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    
    // Parse Date
    final rawCreatedAt = order['created_at'] as String?;
    final createdAt =
        rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt)?.toLocal() : null;

    // Parse Canteen relations
    final canteen = order['canteens'] as Map<String, dynamic>?;
    final canteenName =
        (canteen?['name'] as String? ?? 'Canteen').toUpperCase();
    final canteenLocation =
        canteen?['location'] as String? ?? 'Main Campus Canteen';

    // Parse items relations
    final orderItems = order['order_items'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/order/$orderId'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── CANTEEN NAME + ORDER NUMBER BADGE ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        canteenName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _yellow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ORDER #$displayId',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC49000),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── STATUS CAPSULE BADGE + ETA BADGE ──────────────────────
                Row(
                  children: [
                    _buildStatusCapsule(status),
                    if (status != 'completed' && status != 'delivered' && status != 'cancelled' && status != 'rejected') ...[
                      const SizedBox(width: 10),
                      _buildEtaBadge(order),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── LOCATION ──────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: _textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        canteenLocation,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── DATE & TIME ───────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      createdAt == null
                          ? '—'
                          : '${formatDate(createdAt)} • ${formatTime(createdAt)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── ORDERED ITEMS & TOTAL AMOUNT ──────────────────────────
                const Text(
                  'Items:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: orderItems.isEmpty
                            ? [
                                const Text(
                                  '• Items details inside',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                )
                              ]
                            : orderItems.map((item) {
                                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                                final menuItem =
                                    item['menu_items'] as Map<String, dynamic>?;
                                final name =
                                    menuItem?['name'] as String? ?? 'Item';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• $name ×$qty',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: _textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _red,
                      ),
                    ),
                  ],
                ),

                // ── DIVIDER + LIVE STATUS SECTION ─────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: _yellow, height: 1, thickness: 0.5),
                ),

                // Live status or delivery state inside order card
                _buildLiveStatusCard(status),

                // ── QR CODE & PICKUP PIN ──────────────────────────────────
                if (status == 'ready' || status == 'preparing' || status == 'waiting') ...[
                  const SizedBox(height: 14),
                  _buildQrAndPinSection(status, secretPin),
                ] else if (status == 'completed' || status == 'delivered') ...[
                  const SizedBox(height: 14),
                  _buildCompletedCard(createdAt),
                ] else if (status == 'cancelled' || status == 'rejected') ...[
                  const SizedBox(height: 14),
                  _buildCancelledCard(order),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCapsule(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade600;
    String label = status.toUpperCase();

    if (status.contains('waiting') || status.contains('pending')) {
      bg = const Color(0xFFFFF9C4); // Light yellow
      fg = const Color(0xFFF57F17); // Dark yellow
      label = '🟡 Waiting';
    } else if (status.contains('ready')) {
      bg = const Color(0xFFE8F5E9); // Light green
      fg = _success;
      label = '🟢 Ready';
    } else if (status.contains('completed') || status.contains('delivered')) {
      bg = const Color(0xFFE3F2FD); // Light blue
      fg = const Color(0xFF1565C0);
      label = '🔵 Completed';
    } else if (status.contains('cancel') || status.contains('rejected')) {
      bg = const Color(0xFFFFEBEE); // Light red
      fg = _cancelled;
      label = '🔴 Cancelled';
    } else if (status.contains('preparing') || status.contains('making') || status.contains('cooking') || status.contains('processing')) {
      bg = const Color(0xFFF3E5F5); // Light purple
      fg = Colors.purple.shade700;
      label = '⚪ Processing';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
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

  Widget _buildLiveStatusCard(String status) {
    String text = 'Processing order...';
    IconData icon = Icons.timer_outlined;

    if (status.contains('waiting') || status.contains('pending')) {
      text = 'Waiting for Confirmation';
      icon = Icons.hourglass_empty;
    } else if (status.contains('ready')) {
      text = 'Order Ready for Pickup';
      icon = Icons.check_circle_outline;
    } else if (status.contains('completed') || status.contains('delivered')) {
      text = 'Order Completed Successfully';
      icon = Icons.done_all;
    } else if (status.contains('cancel') || status.contains('rejected')) {
      text = 'Cancelled';
      icon = Icons.cancel_outlined;
    } else if (status.contains('preparing') || status.contains('cooking')) {
      text = 'Preparing Your Food';
      icon = Icons.cookie_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: _textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrAndPinSection(String status, String secretPin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR Code
          Center(
            child: QrImageView(
              data: secretPin,
              version: QrVersions.auto,
              size: 140.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Show this QR code while collecting your order.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Pickup PIN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Pickup PIN',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secretPin,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _red,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(DateTime? completedTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: _success, size: 18),
          const SizedBox(width: 8),
          Text(
            completedTime == null
                ? 'Order Delivered'
                : 'Delivered at ${formatTime(completedTime)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(Map<String, dynamic> order) {
    final reason = order['cancellation_reason'] as String? ?? 'No reason provided';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: _cancelled, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Cancelled',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _cancelled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: _cancelled,
            ),
          ),
        ],
      ),
    );
  }

  // Format Helper
  String formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
