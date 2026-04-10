import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/vendor_orders_provider.dart';
import '../../../core/supabase_client.dart';

final vendorCanteenProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userAsync = ref.watch(authControllerProvider);
  final userId = userAsync.value?.id;
  
  if (userId == null) return null;
  
  final res = await supabase
      .from('canteens')
      .select('name, location')
      .eq('vendor_id', userId)
      .maybeSingle();
      
  return res;
});

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  bool _isOpen = true;
  int _selectedTab = 0; // 0: In Progress, 1: Ready, 2: Completed

  void _handleSignOut() {
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Read live data from Supabase provider
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final allOrders = ordersAsync.value ?? [];

    final canteenAsync = ref.watch(vendorCanteenProvider);
    final canteenName = canteenAsync.value?['name'] ?? 'Loading...';
    final canteenLocation = canteenAsync.value?['location'] ?? '';

    debugPrint('[VENDOR UI] ordersAsync build: isLoading=${ordersAsync.isLoading}, hasError=${ordersAsync.hasError}, hasValue=${ordersAsync.hasValue}');
    if (ordersAsync.hasError) {
      debugPrint('[VENDOR UI] Error: ${ordersAsync.error}\n${ordersAsync.stackTrace}');
    }
    
    // Filter by selected tab
    final filteredOrders = allOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      if (_selectedTab == 0) {
        return rawStatus == 'pending' || 
               rawStatus == 'accepted' || 
               rawStatus == 'preparing' || 
               rawStatus == 'in_progress';
      }
      if (_selectedTab == 1) return rawStatus == 'ready';
      if (_selectedTab == 2) return rawStatus == 'completed';
      return false;
    }).toList();

    debugPrint('[VENDOR UI] Total orders via provider: ${allOrders.length}');
    debugPrint('[VENDOR UI] Orders raw_statuses: ${allOrders.map((o) => o['raw_status']).toList()}');
    debugPrint('[VENDOR UI] Filtered orders for tab $_selectedTab: ${filteredOrders.length}');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(canteenName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (canteenLocation.isNotEmpty)
              Text(canteenLocation, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(_isOpen ? 'Open' : 'Closed', style: theme.textTheme.labelMedium),
              Switch(
                value: _isOpen,
                onChanged: (val) {
                  setState(() {
                    _isOpen = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Quick Actions ────────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.restaurant_menu, size: 16),
                      label: const Text('Manage Menu'),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.local_offer, size: 16),
                      label: const Text('Coupons'),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.settings, size: 16),
                      label: const Text('Settings'),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign Out'),
                      onPressed: _handleSignOut,
                      backgroundColor: colorScheme.errorContainer,
                      labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Complete an Order Card ───────────────────────────────────────
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Complete an Order', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('OR', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter 4-digit pickup code',
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Orders Section ───────────────────────────────────────────────
              Text('Live Orders', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('In Progress')),
                  ButtonSegment(value: 1, label: Text('Ready')),
                  ButtonSegment(value: 2, label: Text('Completed')),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (filteredOrders.isNotEmpty)
                ...filteredOrders.map((order) => _buildOrderCard(order, theme, colorScheme)),
              
              if (filteredOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        if (ordersAsync.isLoading && !ordersAsync.hasValue)
                          const CircularProgressIndicator()
                        else if (ordersAsync.hasError) ...[
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Failed to load orders', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              ordersAsync.error.toString(), 
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]
                        else ...[
                          Icon(Icons.inbox_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No orders in this category', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ]
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // ── Lower Dashboard Metrics ──────────────────────────────────────
              Text('Dashboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Today\'s Income', '\$240.50', Icons.attach_money, colorScheme.primaryContainer, colorScheme.onPrimaryContainer)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(context, 'This Month', '\$3,120', Icons.account_balance_wallet, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer)),
                ],
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(context, 'AI Demand Prediction', 'Expect high demand for Samosas between 2-4 PM today.', Icons.auto_graph, colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
              const SizedBox(height: 12),
              _buildFeatureCard(context, 'Stock Management Mode', 'Automate low stock alerts and updates.', Icons.inventory_2, colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              _buildFeatureCard(context, 'Order Limits', 'Currently accepting max 20 orders per 15 mins.', Icons.speed, colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              _buildFeatureCard(context, 'Member Discounts', 'Active: 10% off for staff members.', Icons.card_membership, colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ThemeData theme, ColorScheme colorScheme) {
    final isDineIn = order['type'] == 'Dine-in';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['orderNumber'],
                        style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDineIn ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['type'],
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDineIn ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(order['amount'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text(order['customerName'], style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Time / ETA', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Row(
                      children: [
                        Text(order['time'], style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        Icon(Icons.timer_outlined, size: 14, color: colorScheme.error),
                        const SizedBox(width: 2),
                        Text(order['eta'], style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.receipt_long, size: 20, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['items'],
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Mark Ready'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color bgColor, Color fgColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fgColor),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: fgColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: fgColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, Color bgColor, Color fgColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fgColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: fgColor),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: fgColor)),
        subtitle: Text(description, style: theme.textTheme.bodySmall?.copyWith(color: fgColor.withOpacity(0.8))),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: fgColor.withOpacity(0.5)),
        onTap: () {},
      ),
    );
  }
}
