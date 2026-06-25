import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase_client.dart';

// ── Data Models ──────────────────────────────────────────────────

class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;

  const MonthKey(this.year, this.month);

  String get label => DateFormat.yMMM().format(DateTime(year, month));
  String get shortLabel => DateFormat.MMM().format(DateTime(year, month));

  @override
  int compareTo(MonthKey other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => year * 100 + month;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

class CanteenMonthlyIncome {
  final String canteenId;
  final String canteenName;
  final Map<MonthKey, double> monthlyIncome; // month -> income
  final double total;

  CanteenMonthlyIncome({
    required this.canteenId,
    required this.canteenName,
    required this.monthlyIncome,
    required this.total,
  });
}

class IncomeAnalyticsState {
  final List<Map<String, dynamic>> rawOrders;
  final List<CanteenMonthlyIncome> canteenIncomes;
  final List<MonthKey> months;
  final Map<MonthKey, double> grandTotalByMonth;
  final double grandTotal;
  final bool isLoading;
  final String? errorMessage;
  final int selectedYear;
  final int? startMonth; // null = all months
  final int? endMonth;
  final String sortBy; // 'name' or 'total'
  final bool sortAscending;

  IncomeAnalyticsState({
    required this.rawOrders,
    required this.canteenIncomes,
    required this.months,
    required this.grandTotalByMonth,
    required this.grandTotal,
    required this.isLoading,
    this.errorMessage,
    required this.selectedYear,
    this.startMonth,
    this.endMonth,
    required this.sortBy,
    required this.sortAscending,
  });

  IncomeAnalyticsState copyWith({
    List<Map<String, dynamic>>? rawOrders,
    List<CanteenMonthlyIncome>? canteenIncomes,
    List<MonthKey>? months,
    Map<MonthKey, double>? grandTotalByMonth,
    double? grandTotal,
    bool? isLoading,
    String? errorMessage,
    int? selectedYear,
    int? startMonth,
    int? endMonth,
    String? sortBy,
    bool? sortAscending,
  }) {
    return IncomeAnalyticsState(
      rawOrders: rawOrders ?? this.rawOrders,
      canteenIncomes: canteenIncomes ?? this.canteenIncomes,
      months: months ?? this.months,
      grandTotalByMonth: grandTotalByMonth ?? this.grandTotalByMonth,
      grandTotal: grandTotal ?? this.grandTotal,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedYear: selectedYear ?? this.selectedYear,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

// ── KPI Stats ────────────────────────────────────────────────────

class IncomeKpiStats {
  final double totalRevenue;
  final String highestEarningCanteen;
  final double highestEarningAmount;
  final String lowestEarningCanteen;
  final double lowestEarningAmount;
  final int activeCanteenCount;

  IncomeKpiStats({
    required this.totalRevenue,
    required this.highestEarningCanteen,
    required this.highestEarningAmount,
    required this.lowestEarningCanteen,
    required this.lowestEarningAmount,
    required this.activeCanteenCount,
  });
}

// ── Notifier ─────────────────────────────────────────────────────

class IncomeAnalyticsNotifier extends Notifier<IncomeAnalyticsState> {
  @override
  IncomeAnalyticsState build() {
    Future.microtask(() => fetchIncomeData());
    return IncomeAnalyticsState(
      rawOrders: [],
      canteenIncomes: [],
      months: [],
      grandTotalByMonth: {},
      grandTotal: 0,
      isLoading: false,
      selectedYear: DateTime.now().year,
      sortBy: 'total',
      sortAscending: false,
    );
  }

  Future<void> fetchIncomeData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final supabase = ref.read(supabaseClientProvider);

      // Fetch completed orders with canteen info
      // Completed = revenue-generating. Exclude cancelled/rejected.
      final response = await supabase
          .from('orders')
          .select('id, total_amount, created_at, status, refund_status, canteen_id, canteens(id, name)')
          .eq('status', 'completed')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> orders =
          List<Map<String, dynamic>>.from(response);

      // Also exclude orders with refund_status = 'processed' (refunded)
      final filtered = orders.where((o) {
        final refundStatus = o['refund_status']?.toString() ?? 'none';
        return refundStatus != 'processed';
      }).toList();

      state = state.copyWith(rawOrders: filtered, isLoading: false);
      _recompute();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setYear(int year) {
    state = state.copyWith(selectedYear: year);
    _recompute();
  }

  void setMonthRange(int? start, int? end) {
    state = state.copyWith(startMonth: start ?? 0, endMonth: end ?? 0);
    // Handle clearing: if 0, treat as null
    if ((start ?? 0) == 0) state = IncomeAnalyticsState(
      rawOrders: state.rawOrders,
      canteenIncomes: state.canteenIncomes,
      months: state.months,
      grandTotalByMonth: state.grandTotalByMonth,
      grandTotal: state.grandTotal,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      selectedYear: state.selectedYear,
      startMonth: null,
      endMonth: end,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );
    if ((end ?? 0) == 0) state = IncomeAnalyticsState(
      rawOrders: state.rawOrders,
      canteenIncomes: state.canteenIncomes,
      months: state.months,
      grandTotalByMonth: state.grandTotalByMonth,
      grandTotal: state.grandTotal,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      selectedYear: state.selectedYear,
      startMonth: state.startMonth,
      endMonth: null,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );
    _recompute();
  }

  void toggleSort(String field) {
    if (state.sortBy == field) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortBy: field, sortAscending: field == 'name');
    }
    _recompute();
  }

  void _recompute() {
    final orders = state.rawOrders;
    final year = state.selectedYear;
    final startM = state.startMonth ?? 1;
    final endM = state.endMonth ?? 12;

    // Filter orders for selected year and month range
    final yearOrders = orders.where((o) {
      final dateStr = o['created_at']?.toString();
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.year == year && date.month >= startM && date.month <= endM;
    }).toList();

    // Group by canteen
    final Map<String, Map<String, dynamic>> canteenMap = {};
    final Set<MonthKey> monthSet = {};

    for (final order in yearOrders) {
      final canteenData = order['canteens'];
      String canteenId;
      String canteenName;

      if (canteenData is Map) {
        canteenId = canteenData['id']?.toString() ?? order['canteen_id']?.toString() ?? 'unknown';
        canteenName = canteenData['name']?.toString() ?? 'Unknown';
      } else {
        canteenId = order['canteen_id']?.toString() ?? 'unknown';
        canteenName = 'Unknown';
      }

      final date = DateTime.parse(order['created_at']);
      final monthKey = MonthKey(date.year, date.month);
      final amount = (order['total_amount'] as num? ?? 0).toDouble();

      monthSet.add(monthKey);

      if (!canteenMap.containsKey(canteenId)) {
        canteenMap[canteenId] = {
          'name': canteenName,
          'months': <MonthKey, double>{},
          'total': 0.0,
        };
      }

      final entry = canteenMap[canteenId]!;
      final monthData = entry['months'] as Map<MonthKey, double>;
      monthData[monthKey] = (monthData[monthKey] ?? 0.0) + amount;
      entry['total'] = (entry['total'] as double) + amount;
    }

    // Build all months in the range (even if no data)
    final List<MonthKey> allMonths = [];
    for (int m = startM; m <= endM; m++) {
      allMonths.add(MonthKey(year, m));
    }

    // Build canteen incomes
    List<CanteenMonthlyIncome> canteenIncomes = canteenMap.entries.map((entry) {
      return CanteenMonthlyIncome(
        canteenId: entry.key,
        canteenName: entry.value['name'] as String,
        monthlyIncome: entry.value['months'] as Map<MonthKey, double>,
        total: entry.value['total'] as double,
      );
    }).toList();

    // Sort
    if (state.sortBy == 'name') {
      canteenIncomes.sort((a, b) => state.sortAscending
          ? a.canteenName.compareTo(b.canteenName)
          : b.canteenName.compareTo(a.canteenName));
    } else {
      canteenIncomes.sort((a, b) => state.sortAscending
          ? a.total.compareTo(b.total)
          : b.total.compareTo(a.total));
    }

    // Grand totals
    final Map<MonthKey, double> grandByMonth = {};
    double grandTotal = 0;
    for (final mk in allMonths) {
      double monthTotal = 0;
      for (final ci in canteenIncomes) {
        monthTotal += ci.monthlyIncome[mk] ?? 0;
      }
      grandByMonth[mk] = monthTotal;
      grandTotal += monthTotal;
    }

    state = state.copyWith(
      canteenIncomes: canteenIncomes,
      months: allMonths,
      grandTotalByMonth: grandByMonth,
      grandTotal: grandTotal,
    );
  }

  // Generate CSV string
  String generateCsv() {
    final buf = StringBuffer();
    final months = state.months;

    // Header
    buf.write('Canteen Name');
    for (final m in months) {
      buf.write(',${m.label}');
    }
    buf.writeln(',Total');

    // Rows
    for (final ci in state.canteenIncomes) {
      buf.write('"${ci.canteenName}"');
      for (final m in months) {
        buf.write(',${(ci.monthlyIncome[m] ?? 0).toStringAsFixed(2)}');
      }
      buf.writeln(',${ci.total.toStringAsFixed(2)}');
    }

    // Grand total
    buf.write('Grand Total');
    for (final m in months) {
      buf.write(',${(state.grandTotalByMonth[m] ?? 0).toStringAsFixed(2)}');
    }
    buf.writeln(',${state.grandTotal.toStringAsFixed(2)}');

    return buf.toString();
  }
}

// ── Providers ────────────────────────────────────────────────────

final incomeAnalyticsProvider =
    NotifierProvider<IncomeAnalyticsNotifier, IncomeAnalyticsState>(
        IncomeAnalyticsNotifier.new);

final incomeKpiProvider = Provider<IncomeKpiStats>((ref) {
  final state = ref.watch(incomeAnalyticsProvider);
  final canteens = state.canteenIncomes;

  if (canteens.isEmpty) {
    return IncomeKpiStats(
      totalRevenue: 0,
      highestEarningCanteen: '—',
      highestEarningAmount: 0,
      lowestEarningCanteen: '—',
      lowestEarningAmount: 0,
      activeCanteenCount: 0,
    );
  }

  // Sort by total descending to find highest/lowest
  final sorted = List<CanteenMonthlyIncome>.from(canteens)
    ..sort((a, b) => b.total.compareTo(a.total));

  // Active = has at least some income
  final active = sorted.where((c) => c.total > 0).toList();
  final lowest = active.isNotEmpty ? active.last : sorted.last;

  return IncomeKpiStats(
    totalRevenue: state.grandTotal,
    highestEarningCanteen: sorted.first.canteenName,
    highestEarningAmount: sorted.first.total,
    lowestEarningCanteen: lowest.canteenName,
    lowestEarningAmount: lowest.total,
    activeCanteenCount: active.length,
  );
});
