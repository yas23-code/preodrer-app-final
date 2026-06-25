import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_collection_provider.dart';
import '../../../shared/utils/formatters.dart';

class DailyCollectionView extends ConsumerWidget {
  const DailyCollectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyCollectionProvider);
    final kpi = ref.watch(dailyKpiProvider);
    final reports = ref.watch(dailyCanteenReportsProvider);

    final List<Widget> items = [];

    // 1. Date & Canteen Filter Selector
    items.add(_buildFilterSelector(context, ref, state));
    items.add(const SizedBox(height: 16));

    // 2. KPI Cards
    items.add(_buildKpiCards(kpi));
    items.add(const SizedBox(height: 16));

    // 3. Actions & Exports Row
    items.add(_buildActionsRow(context, ref, state, reports, kpi));
    items.add(const SizedBox(height: 12));

    // 4. Data View
    if (state.isLoading) {
      items.add(const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: Color(0xFFDA291C)),
        ),
      ));
    } else if (state.errorMessage != null) {
      items.add(_buildErrorState(state.errorMessage!));
    } else if (reports.isEmpty) {
      items.add(_buildEmptyState());
    } else {
      items.add(_buildReportTable(context, ref, state, reports, kpi));
    }

    items.add(const SizedBox(height: 24));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  // ── Filters & Presets Selector ──────────────────────────────
  Widget _buildFilterSelector(
      BuildContext context, WidgetRef ref, DailyCollectionState state) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    final sevenDaysAgoDate = todayDate.subtract(const Duration(days: 6));

    final isToday = state.startDate == todayDate && state.endDate == todayDate;
    final isYesterday = state.startDate == yesterdayDate && state.endDate == yesterdayDate;
    final isLast7 = state.startDate == sevenDaysAgoDate && state.endDate == todayDate;

    final fmtDate = state.startDate == state.endDate 
        ? '${state.startDate.day}/${state.startDate.month}/${state.startDate.year}'
        : '${state.startDate.day}/${state.startDate.month}/${state.startDate.year} - ${state.endDate.day}/${state.endDate.month}/${state.endDate.year}';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Collection Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
              // Date picker button
              GestureDetector(
                onTap: () async {
                  final initialDateRange = DateTimeRange(
                    start: state.startDate,
                    end: state.endDate,
                  );
                  final pickedRange = await showDateRangePicker(
                    context: context,
                    initialDateRange: initialDateRange,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFDA291C),
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedRange != null) {
                    ref.read(dailyCollectionProvider.notifier).setDateRange(
                          pickedRange.start,
                          pickedRange.end,
                        );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        fmtDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets row
          Row(
            children: [
              _presetChip(ref, 'Today', isToday, () {
                ref.read(dailyCollectionProvider.notifier).setDateRange(todayDate, todayDate);
              }),
              const SizedBox(width: 8),
              _presetChip(ref, 'Yesterday', isYesterday, () {
                ref.read(dailyCollectionProvider.notifier).setDateRange(yesterdayDate, yesterdayDate);
              }),
              const SizedBox(width: 8),
              _presetChip(ref, 'Last 7 Days', isLast7, () {
                ref.read(dailyCollectionProvider.notifier).setDateRange(sevenDaysAgoDate, todayDate);
              }),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // Canteen filter dropdown
          Row(
            children: [
              const Text(
                'Filter Canteen:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.canteenFilter,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Canteens')),
                        ...state.canteens.map((c) => DropdownMenuItem(
                              value: c['name'].toString(),
                              child: Text(c['name'].toString()),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(dailyCollectionProvider.notifier).setCanteenFilter(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(WidgetRef ref, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDA291C) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // ── KPI Cards ────────────────────────────────────────────────
  Widget _buildKpiCards(DailyKpiStats kpi) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Food Revenue',
                formatCurrency(kpi.foodRevenue),
                Icons.account_balance_wallet_rounded,
                const Color(0xFFDA291C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                'Platform Fees',
                formatCurrency(kpi.platformFees),
                Icons.toll_rounded,
                const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Total Orders',
                '${kpi.totalOrders}',
                Icons.shopping_bag_rounded,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                'Completed',
                '${kpi.completedOrders}',
                Icons.check_circle_rounded,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'In Progress',
                '${kpi.inProgressOrders}',
                Icons.hourglass_empty_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                'Rejected Orders',
                '${kpi.rejectedOrders}',
                Icons.cancel_rounded,
                Colors.redAccent,
                subtitle: 'Refund: ${formatCurrency(kpi.refundedAmount)}',
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
      padding: const EdgeInsets.all(12),
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
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.1,
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions & Exports Row ────────────────────────────────────
  Widget _buildActionsRow(
      BuildContext context,
      WidgetRef ref,
      DailyCollectionState state,
      List<CanteenDailyReport> reports,
      DailyKpiStats kpi) {
    return Row(
      children: [
        const Text(
          'Canteen Breakdown',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        const Spacer(),
        // CSV Export
        GestureDetector(
          onTap: () {
            final csv = ref.read(dailyCollectionProvider.notifier).generateCsv(reports, kpi);
            Clipboard.setData(ClipboardData(text: csv));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CSV Report copied to clipboard!'),
                backgroundColor: Color(0xFF2E7D32),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'CSV',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // PDF / Text Export
        GestureDetector(
          onTap: () {
            final txt = ref.read(dailyCollectionProvider.notifier).generateTextReport(reports, kpi);
            Clipboard.setData(ClipboardData(text: txt));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF Text Report copied to clipboard!'),
                backgroundColor: Color(0xFF1976D2),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'PDF Report',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Refresh Button
        GestureDetector(
          onTap: () => ref.read(dailyCollectionProvider.notifier).fetchData(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.refresh_rounded, size: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // ── Table UI ─────────────────────────────────────────────────
  Widget _buildReportTable(
      BuildContext context,
      WidgetRef ref,
      DailyCollectionState state,
      List<CanteenDailyReport> reports,
      DailyKpiStats totals) {
    
    // Sum columns for overall totals row
    final totalOrders = reports.fold(0, (sum, item) => sum + item.totalOrders);
    final totalCompleted = reports.fold(0, (sum, item) => sum + item.completedOrders);
    final totalInProgress = reports.fold(0, (sum, item) => sum + item.inProgressOrders);
    final totalRejected = reports.fold(0, (sum, item) => sum + item.rejectedOrders);
    final totalGross = reports.fold(0.0, (sum, item) => sum + item.grossCollection);
    final totalPlatform = reports.fold(0.0, (sum, item) => sum + item.platformFee);
    final totalNet = reports.fold(0.0, (sum, item) => sum + item.netCollection);
    final totalRefunds = reports.fold(0.0, (sum, item) => sum + item.refunds);
    final totalPayable = reports.fold(0.0, (sum, item) => sum + item.finalPayable);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 12,
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingRowHeight: 46,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 44,
            columns: const [
              DataColumn(label: Text('Canteen Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(numeric: true, label: Text('Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(numeric: true, label: Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.teal))),
              DataColumn(numeric: true, label: Text('Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.orange))),
              DataColumn(numeric: true, label: Text('Rejected', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.redAccent))),
              DataColumn(numeric: true, label: Text('Gross (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(numeric: true, label: Text('Fee (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF2E7D32)))),
              DataColumn(numeric: true, label: Text('Net (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              DataColumn(numeric: true, label: Text('Refunds (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.redAccent))),
              DataColumn(numeric: true, label: Text('Final Payable (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFDA291C)))),
            ],
            rows: [
              // Canteen rows
              ...reports.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.canteenName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    DataCell(Text('${r.totalOrders}', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${r.completedOrders}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal))),
                    DataCell(Text('${r.inProgressOrders}', style: const TextStyle(fontSize: 12, color: Colors.orange))),
                    DataCell(Text('${r.rejectedOrders}', style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                    DataCell(Text(r.grossCollection > 0 ? '₹${r.grossCollection.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(r.platformFee > 0 ? '₹${r.platformFee.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)))),
                    DataCell(Text(r.netCollection > 0 ? '₹${r.netCollection.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(r.refunds > 0 ? '₹${r.refunds.toStringAsFixed(0)}' : '—', style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                    DataCell(Text(r.finalPayable > 0 ? '₹${r.finalPayable.toStringAsFixed(0)}' : '—', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFDA291C)))),
                  ],
                );
              }),
              
              // Grand Totals row
              DataRow(
                color: WidgetStateProperty.all(Colors.red.shade50.withOpacity(0.3)),
                cells: [
                  const DataCell(Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black87))),
                  DataCell(Text('$totalOrders', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                  DataCell(Text('$totalCompleted', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.teal))),
                  DataCell(Text('$totalInProgress', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.orange))),
                  DataCell(Text('$totalRejected', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.redAccent))),
                  DataCell(Text('₹${totalGross.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                  DataCell(Text('₹${totalPlatform.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF2E7D32)))),
                  DataCell(Text('₹${totalNet.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                  DataCell(Text('₹${totalRefunds.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.redAccent))),
                  DataCell(Text('₹${totalPayable.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFDA291C)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── States ───────────────────────────────────────────────────
  Widget _buildErrorState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text(
            'No transaction collections for this range',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
