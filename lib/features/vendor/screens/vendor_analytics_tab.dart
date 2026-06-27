import 'package:flutter/material.dart';

class VendorAnalyticsTab extends StatelessWidget {
  const VendorAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
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
                  Text(
                    'Analytics Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time business insights',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── High Level Stats row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricRingCard(
                  context: context,
                  title: 'Order Completion',
                  value: '94.2%',
                  subtitle: '245 completed',
                  percentage: 0.942,
                  activeColor: Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricRingCard(
                  context: context,
                  title: 'On-time Prep',
                  value: '88.5%',
                  subtitle: 'Avg: 11 mins',
                  percentage: 0.885,
                  activeColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Revenue Card ──────────────────────────────────────────────────
          Card(
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
                          Text('Weekly Revenue', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('₹24,530.00 total this week', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[700]!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green[700], size: 16),
                            const SizedBox(width: 4),
                            Text('+14.2%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Custom bar chart
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(context: context, day: 'Mon', heightFraction: 0.45, amount: '₹3,200'),
                        _buildBar(context: context, day: 'Tue', heightFraction: 0.60, amount: '₹4,100'),
                        _buildBar(context: context, day: 'Wed', heightFraction: 0.35, amount: '₹2,900'),
                        _buildBar(context: context, day: 'Thu', heightFraction: 0.85, amount: '₹5,600', isHighest: true),
                        _buildBar(context: context, day: 'Fri', heightFraction: 0.70, amount: '₹4,900'),
                        _buildBar(context: context, day: 'Sat', heightFraction: 0.50, amount: '₹3,850'),
                        _buildBar(context: context, day: 'Sun', heightFraction: 0.20, amount: '₹1,500'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Peak Hours Card ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peak Hours Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Busy order periods during the day', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  // Hour bands
                  _buildHourBand(context: context, time: '8 AM - 11 AM (Breakfast)', count: 48, percentage: 0.45),
                  _buildHourBand(context: context, time: '12 PM - 3 PM (Lunch)', count: 98, percentage: 0.90, isPeak: true),
                  _buildHourBand(context: context, time: '4 PM - 7 PM (Snacks)', count: 64, percentage: 0.60),
                  _buildHourBand(context: context, time: '8 PM - 10 PM (Dinner)', count: 20, percentage: 0.20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Popular Items Card ────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Top dishes sold this week', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  _buildPopularItemRow(context: context, itemName: 'Paneer Roll', count: 145, revenue: '₹16,675', percentage: 1.0),
                  _buildPopularItemRow(context: context, itemName: 'Samosa', count: 120, revenue: '₹2,400', percentage: 0.82),
                  _buildPopularItemRow(context: context, itemName: 'Cold Coffee', count: 85, revenue: '₹6,800', percentage: 0.58),
                  _buildPopularItemRow(context: context, itemName: 'Cheese Burger', count: 50, revenue: '₹4,950', percentage: 0.34),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                    backgroundColor: activeColor.withValues(alpha: 0.1),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                color: isHighest ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: totalHeight * heightFraction,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHighest
                      ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.6)]
                      : [colorScheme.primary.withValues(alpha: 0.3), colorScheme.primary.withValues(alpha: 0.5)],
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
                color: isHighest ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                  color: isPeak ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$count orders',
                style: TextStyle(
                  fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                  color: isPeak ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              color: isPeak ? Colors.amber[700] : colorScheme.primary.withValues(alpha: 0.4),
              backgroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                    Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('$count sold', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
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
                Text('Revenue', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
