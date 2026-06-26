import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/income_analytics_provider.dart';
import '../../../shared/utils/formatters.dart';

class IncomeAnalyticsView extends ConsumerWidget {
  const IncomeAnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomeAnalyticsProvider);
    final kpi = ref.watch(incomeKpiProvider);

    final List<Widget> items = [];

    // 1. Year & Month Range Selector
    items.add(_buildPeriodSelector(context, ref, state));
    items.add(const SizedBox(height: 16));

    // 2. KPI Cards
    items.add(_buildKpiCards(kpi));
    items.add(const SizedBox(height: 16));

    // 3. Actions Row
    items.add(_buildActionsRow(context, ref, state));
    items.add(const SizedBox(height: 12));

    // 4. Income Table
    if (state.isLoading) {
      items.add(const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: Color(0xFFDA291C)),
        ),
      ));
    } else if (state.errorMessage != null) {
      items.add(_buildErrorState(state.errorMessage!));
    } else if (state.canteenIncomes.isEmpty) {
      items.add(_buildEmptyState());
    } else {
      items.add(_buildIncomeTable(context, ref, state));
    }

    items.add(const SizedBox(height: 24));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  // ── Period Selector ──────────────────────────────────────────
  Widget _buildPeriodSelector(
      BuildContext context, WidgetRef ref, IncomeAnalyticsState state) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Income by Canteen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Year selector chips
          Row(
            children: [
              const Text('Year: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black54)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: years.map((y) {
                      final isSelected = state.selectedYear == y;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(incomeAnalyticsProvider.notifier)
                              .setYear(y),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFDA291C)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$y',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Month range selector
          Row(
            children: [
              const Text('Months: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black54)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final startM = state.startMonth ?? 1;
                      final endM = state.endMonth ?? 12;
                      final isInRange = m >= startM && m <= endM;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () {
                            // Single tap: set as start, double tap or shift: set as end
                            final notifier = ref.read(
                                incomeAnalyticsProvider.notifier);
                            if (state.startMonth == null || m < startM) {
                              notifier.setMonthRange(m, endM);
                            } else if (m > startM) {
                              notifier.setMonthRange(startM, m);
                            } else {
                              // Reset
                              notifier.setMonthRange(1, 12);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isInRange
                                  ? const Color(0xFFDA291C).withOpacity(
                                      m == startM || m == endM ? 1.0 : 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              monthNames[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (m == startM || m == endM)
                                    ? Colors.white
                                    : isInRange
                                        ? const Color(0xFFDA291C)
                                        : Colors.black38,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── KPI Cards ────────────────────────────────────────────────
  Widget _buildKpiCards(IncomeKpiStats kpi) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Total Revenue',
                formatCurrency(kpi.totalRevenue),
                Icons.account_balance_wallet_rounded,
                const Color(0xFFDA291C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                'Active Canteens',
                '${kpi.activeCanteenCount}',
                Icons.storefront_rounded,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Highest Earner',
                kpi.highestEarningCanteen,
                Icons.trending_up_rounded,
                Colors.green,
                subtitle: formatCurrency(kpi.highestEarningAmount),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                'Lowest Earner',
                kpi.lowestEarningCanteen,
                Icons.trending_down_rounded,
                Colors.orange,
                subtitle: formatCurrency(kpi.lowestEarningAmount),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions Row ──────────────────────────────────────────────
  Widget _buildActionsRow(
      BuildContext context, WidgetRef ref, IncomeAnalyticsState state) {
    return Row(
      children: [
        GestureDetector(
          onTap: () =>
              ref.read(incomeAnalyticsProvider.notifier).toggleSort('total'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.sortBy == 'total'
                  ? const Color(0xFFDA291C)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color:
                      state.sortBy == 'total' ? Colors.white : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  'Sort by Income',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: state.sortBy == 'total'
                        ? Colors.white
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () =>
              ref.read(incomeAnalyticsProvider.notifier).toggleSort('name'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.sortBy == 'name'
                  ? const Color(0xFFDA291C)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Sort A-Z',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    state.sortBy == 'name' ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _exportCsv(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Export CSV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () =>
              ref.read(incomeAnalyticsProvider.notifier).fetchIncomeData(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.refresh_rounded, size: 18, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  void _exportCsv(BuildContext context, WidgetRef ref) {
    final csv = ref.read(incomeAnalyticsProvider.notifier).generateCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data copied to clipboard!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Income Table ─────────────────────────────────────────────
  Widget _buildIncomeTable(
      BuildContext context, WidgetRef ref, IncomeAnalyticsState state) {
    final months = state.months;
    final canteens = state.canteenIncomes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              _buildHeaderRow(months),
              // Data rows
              for (int i = 0; i < canteens.length; i++)
                _buildDataRow(context, canteens[i], months, i),
              // Grand total row
              _buildGrandTotalRow(state, months),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(List<MonthKey> months) {
    return Container(
      color: const Color(0xFFFDF6EC), // Beige header
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Canteen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.brown[700],
                letterSpacing: 0.2,
              ),
            ),
          ),
          for (final m in months)
            SizedBox(
              width: 80,
              child: Text(
                m.shortLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown[700],
                ),
              ),
            ),
          SizedBox(
            width: 90,
            child: Text(
              'Total',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.brown[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, CanteenMonthlyIncome canteen,
      List<MonthKey> months, int index) {
    final isEven = index % 2 == 0;
    return GestureDetector(
      onTap: () => _showCanteenBreakdown(context, canteen, months),
      child: Container(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                canteen.canteenName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final m in months)
              SizedBox(
                width: 80,
                child: Text(
                  _formatAmount(canteen.monthlyIncome[m] ?? 0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: (canteen.monthlyIncome[m] ?? 0) > 0
                        ? Colors.black87
                        : Colors.grey[400],
                  ),
                ),
              ),
            SizedBox(
              width: 90,
              child: Text(
                _formatAmount(canteen.total),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalRow(IncomeAnalyticsState state, List<MonthKey> months) {
    return Container(
      color: const Color(0xFFFDF6EC),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Grand Total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.brown[900],
              ),
            ),
          ),
          for (final m in months)
            SizedBox(
              width: 80,
              child: Text(
                _formatAmount(state.grandTotalByMonth[m] ?? 0),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown[800],
                ),
              ),
            ),
          SizedBox(
            width: 90,
            child: Text(
              _formatAmount(state.grandTotal),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.brown[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '₹0';
    if (amount >= 1000) {
      return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  // ── Canteen Breakdown Dialog ─────────────────────────────────
  void _showCanteenBreakdown(BuildContext context,
      CanteenMonthlyIncome canteen, List<MonthKey> months) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          canteen.canteenName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Income',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        formatCurrency(canteen.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFFDA291C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final m in months)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          (canteen.monthlyIncome[m] ?? 0) > 0
                              ? formatCurrency(canteen.monthlyIncome[m] ?? 0.0)
                              : '—',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: (canteen.monthlyIncome[m] ?? 0) > 0
                                ? Colors.black87
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Empty / Error States ─────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No income data for selected period',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDA291C).withOpacity(0.2)),
      ),
      child: Text('Error: $error',
          style: const TextStyle(color: Color(0xFFDA291C), fontSize: 14)),
    );
  }
}
