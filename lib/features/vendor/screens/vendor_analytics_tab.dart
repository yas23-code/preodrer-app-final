import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vendor_menu_provider.dart';

class VendorAnalyticsTab extends ConsumerWidget {
  const VendorAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final canteenAsync = ref.watch(vendorCanteenProvider);
    final canteenId = canteenAsync.value?['id'] as String? ?? '';
    final analyticsAsync = ref.watch(vendorAnalyticsProvider(canteenId));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7), // Premium cream background
      body: RefreshIndicator(
        color: const Color(0xFFFFC300),
        onRefresh: () async {
          ref.invalidate(vendorAnalyticsProvider(canteenId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Analytics Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B1D0E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time business insights',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8D7F70),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF2B1D0E)),
                    onPressed: () {
                      ref.invalidate(vendorAnalyticsProvider(canteenId));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              analyticsAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC300))),
                ),
                error: (e, _) => SizedBox(
                  height: 200,
                  child: Center(child: Text('Failed to load analytics: $e', style: const TextStyle(fontWeight: FontWeight.bold))),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No order data available yet to display insights.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D7F70)),
                        ),
                      ),
                    );
                  }

                  final completionRate = data['completionRate'] as double;
                  final totalOrders = data['totalOrders'] as int;
                  final completedCount = data['completedCount'] as int;
                  final weeklyRevenue = data['weeklyRevenue'] as double;
                  final dailyRevenue = data['dailyRevenue'] as List<dynamic>;
                  final peakHours = data['peakHours'] as Map<String, dynamic>;
                  final popularItems = data['popularItems'] as List<dynamic>;

                  // Find max daily amount for chart scaling
                  final double maxDailyAmount = dailyRevenue.fold<double>(
                    1.0,
                    (max, item) => (item['amount'] as double) > max ? (item['amount'] as double) : max,
                  );

                  // Find max peak hour count for scale
                  final List<int> hourCountsList = [
                    peakHours['breakfast'] as int,
                    peakHours['lunch'] as int,
                    peakHours['snacks'] as int,
                    peakHours['dinner'] as int,
                  ];
                  final int maxHourCount = hourCountsList.fold<int>(1, (max, val) => val > max ? val : max);

                  // Find max popular item sold count for scale
                  final int maxPopularCount = popularItems.fold<int>(
                    1,
                    (max, item) => (item['count'] as int) > max ? (item['count'] as int) : max,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── High Level Stats row ──────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricRingCard(
                              context: context,
                              title: 'Order Completion',
                              value: '${completionRate.toStringAsFixed(1)}%',
                              subtitle: '$completedCount completed',
                              percentage: completionRate / 100,
                              activeColor: Colors.green[700]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricRingCard(
                              context: context,
                              title: 'Total Orders Received',
                              value: '$totalOrders',
                              subtitle: 'All lifetime orders',
                              percentage: totalOrders > 0 ? 1.0 : 0.0,
                              activeColor: const Color(0xFFFFC300),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Revenue Card ──────────────────────────────────────────────────
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFECE6DA)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Weekly Revenue',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${weeklyRevenue.toStringAsFixed(2)} total this week',
                                        style: const TextStyle(color: Color(0xFF8D7F70), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green[700]!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.trending_up, color: Colors.green[700], size: 16),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Active',
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Dynamic weekly bar chart
                              SizedBox(
                                height: 160,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: dailyRevenue.map((item) {
                                    final dayName = item['day'] as String;
                                    final amount = item['amount'] as double;
                                    final fraction = amount / maxDailyAmount;
                                    return _buildBar(
                                      context: context,
                                      day: dayName,
                                      heightFraction: fraction < 0.05 ? 0.05 : fraction,
                                      amount: '₹${amount.toStringAsFixed(0)}',
                                      isHighest: amount == maxDailyAmount && amount > 0,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Peak Hours Card ───────────────────────────────────────────────
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFECE6DA)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Peak Hours Distribution',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Busy order periods based on time of placement',
                                style: TextStyle(color: Color(0xFF8D7F70), fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              _buildHourBand(
                                context: context,
                                time: 'Breakfast (8 AM - 11 AM)',
                                count: peakHours['breakfast'] as int,
                                percentage: (peakHours['breakfast'] as int) / maxHourCount,
                              ),
                              _buildHourBand(
                                context: context,
                                time: 'Lunch (12 PM - 3 PM)',
                                count: peakHours['lunch'] as int,
                                percentage: (peakHours['lunch'] as int) / maxHourCount,
                                isPeak: (peakHours['lunch'] as int) == maxHourCount && maxHourCount > 0,
                              ),
                              _buildHourBand(
                                context: context,
                                time: 'Snacks (4 PM - 7 PM)',
                                count: peakHours['snacks'] as int,
                                percentage: (peakHours['snacks'] as int) / maxHourCount,
                              ),
                              _buildHourBand(
                                context: context,
                                time: 'Dinner (8 PM - 10 PM)',
                                count: peakHours['dinner'] as int,
                                percentage: (peakHours['dinner'] as int) / maxHourCount,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Popular Items Card ────────────────────────────────────────────
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFECE6DA)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Top Selling Items',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Top dishes sold this week',
                                style: TextStyle(color: Color(0xFF8D7F70), fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              if (popularItems.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'No item order breakdown available.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D7F70)),
                                    ),
                                  ),
                                )
                              else
                                ...popularItems.map((item) {
                                  final name = item['itemName'] as String;
                                  final count = item['count'] as int;
                                  final rev = item['revenue'] as String;
                                  final fraction = count / maxPopularCount;
                                  return _buildPopularItemRow(
                                    context: context,
                                    itemName: name,
                                    count: count,
                                    revenue: rev,
                                    percentage: fraction < 0.05 ? 0.05 : fraction,
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRingCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required double percentage,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFECE6DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8D7F70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2B1D0E)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7F70)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    color: activeColor,
                    backgroundColor: activeColor.withOpacity(0.1),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Icon(
                      percentage > 0.9 ? Icons.check_circle_outline : Icons.bolt,
                      color: activeColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required BuildContext context,
    required String day,
    required double heightFraction,
    required String amount,
    bool isHighest = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight - 32;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                color: isHighest ? const Color(0xFFFFC300) : const Color(0xFF8D7F70),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: totalHeight * heightFraction,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHighest
                      ? [const Color(0xFFFFC300), const Color(0xFFFFD54F)]
                      : [const Color(0xFFECE6DA), const Color(0xFFECE6DA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              day,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                color: isHighest ? const Color(0xFF2B1D0E) : const Color(0xFF8D7F70),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHourBand({
    required BuildContext context,
    required String time,
    required int count,
    required double percentage,
    bool isPeak = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                  color: isPeak ? const Color(0xFF2B1D0E) : const Color(0xFF8D7F70),
                ),
              ),
              Text(
                '$count orders',
                style: TextStyle(
                  fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                  color: isPeak ? const Color(0xFFFFC300) : const Color(0xFF2B1D0E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.isNaN ? 0.0 : percentage,
              minHeight: 8,
              color: isPeak ? const Color(0xFFFFC300) : const Color(0xFFECE6DA),
              backgroundColor: const Color(0xFFF5F0E3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemRow({
    required BuildContext context,
    required String itemName,
    required int count,
    required String revenue,
    required double percentage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
                    Text('$count sold', style: const TextStyle(color: Color(0xFF8D7F70), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage.isNaN ? 0.0 : percentage,
                    minHeight: 6,
                    color: const Color(0xFFFFC300),
                    backgroundColor: const Color(0xFFECE6DA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(revenue, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                const Text('Revenue', style: TextStyle(color: Color(0xFF8D7F70), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
