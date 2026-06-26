import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

class DailyCollectionState {
  final DateTime startDate;
  final DateTime endDate;
  final String canteenFilter; // 'all' or canteen name
  final List<Map<String, dynamic>> rawOrders;
  final List<Map<String, dynamic>> canteens;
  final bool isLoading;
  final String? errorMessage;

  DailyCollectionState({
    required this.startDate,
    required this.endDate,
    required this.canteenFilter,
    required this.rawOrders,
    required this.canteens,
    required this.isLoading,
    this.errorMessage,
  });

  DailyCollectionState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? canteenFilter,
    List<Map<String, dynamic>>? rawOrders,
    List<Map<String, dynamic>>? canteens,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DailyCollectionState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      canteenFilter: canteenFilter ?? this.canteenFilter,
      rawOrders: rawOrders ?? this.rawOrders,
      canteens: canteens ?? this.canteens,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CanteenDailyReport {
  final String canteenId;
  final String canteenName;
  final int totalOrders;
  final int completedOrders;
  final int inProgressOrders;
  final int rejectedOrders;
  final double grossCollection;
  final double platformFee;
  final double netCollection;
  final double refunds;
  final double finalPayable;

  CanteenDailyReport({
    required this.canteenId,
    required this.canteenName,
    required this.totalOrders,
    required this.completedOrders,
    required this.inProgressOrders,
    required this.rejectedOrders,
    required this.grossCollection,
    required this.platformFee,
    required this.netCollection,
    required this.refunds,
    required this.finalPayable,
  });
}

class DailyCollectionNotifier extends Notifier<DailyCollectionState> {
  @override
  DailyCollectionState build() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    Future.microtask(() => fetchData());
    return DailyCollectionState(
      startDate: todayDate,
      endDate: todayDate,
      canteenFilter: 'all',
      rawOrders: [],
      canteens: [],
      isLoading: false,
    );
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Fetch canteens list for the filter
      final canteenRes = await supabase.from('canteens').select('id, name').order('name');
      final List<Map<String, dynamic>> canteens = List<Map<String, dynamic>>.from(canteenRes);

      // Define date range
      final start = DateTime(state.startDate.year, state.startDate.month, state.startDate.day);
      final end = DateTime(state.endDate.year, state.endDate.month, state.endDate.day).add(const Duration(days: 1));

      // Fetch all orders in the selected date range
      final response = await supabase
          .from('orders')
          .select('id, total_amount, created_at, status, refund_status, canteen_id, canteens(id, name)')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(response);

      state = state.copyWith(
        rawOrders: orders,
        canteens: canteens,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
    );
    fetchData();
  }

  void setCanteenFilter(String canteenName) {
    state = state.copyWith(canteenFilter: canteenName);
  }

  // Generate CSV representation
  String generateCsv(List<CanteenDailyReport> reports, DailyKpiStats totals) {
    final buf = StringBuffer();
    // Headers
    buf.writeln('Canteen Name,Total Orders,Completed,In Progress,Rejected,Gross Collection (₹),Platform Fee (₹),Net Collection (₹),Refunds (₹),Final Payable (₹)');

    // Rows
    for (final r in reports) {
      buf.writeln('"${r.canteenName}",${r.totalOrders},${r.completedOrders},${r.inProgressOrders},${r.rejectedOrders},${r.grossCollection.toStringAsFixed(2)},${r.platformFee.toStringAsFixed(2)},${r.netCollection.toStringAsFixed(2)},${r.refunds.toStringAsFixed(2)},${r.finalPayable.toStringAsFixed(2)}');
    }

    // Totals Row
    final totalGross = reports.fold(0.0, (sum, item) => sum + item.grossCollection);
    final totalPlatform = reports.fold(0.0, (sum, item) => sum + item.platformFee);
    final totalNet = reports.fold(0.0, (sum, item) => sum + item.netCollection);
    final totalRefunds = reports.fold(0.0, (sum, item) => sum + item.refunds);
    final totalPayable = reports.fold(0.0, (sum, item) => sum + item.finalPayable);

    buf.writeln('"Grand Total",${totals.totalOrders},${totals.completedOrders},${totals.inProgressOrders},${totals.rejectedOrders},${totalGross.toStringAsFixed(2)},${totalPlatform.toStringAsFixed(2)},${totalNet.toStringAsFixed(2)},${totalRefunds.toStringAsFixed(2)},${totalPayable.toStringAsFixed(2)}');

    return buf.toString();
  }

  // Generate PDF / Plain Text Report representation
  String generateTextReport(List<CanteenDailyReport> reports, DailyKpiStats totals) {
    final buf = StringBuffer();
    final fmtDate = state.startDate == state.endDate 
        ? '${state.startDate.day}/${state.startDate.month}/${state.startDate.year}'
        : '${state.startDate.day}/${state.startDate.month}/${state.startDate.year} to ${state.endDate.day}/${state.endDate.month}/${state.endDate.year}';
    
    buf.writeln('==================================================');
    buf.writeln('           DAILY COLLECTION REPORT (CANTEEN WISE)  ');
    buf.writeln('           Period: $fmtDate                       ');
    buf.writeln('==================================================\n');

    buf.writeln('OVERALL COLLECTION METRICS:');
    buf.writeln('---------------------------');
    buf.writeln('Food Revenue:       ₹${totals.foodRevenue.toStringAsFixed(2)}');
    buf.writeln('Platform Fees:      ₹${totals.platformFees.toStringAsFixed(2)}');
    buf.writeln('Total Orders:       ${totals.totalOrders}');
    buf.writeln('Completed Orders:   ${totals.completedOrders}');
    buf.writeln('In Progress:        ${totals.inProgressOrders}');
    buf.writeln('Rejected Orders:    ${totals.rejectedOrders}');
    buf.writeln('Refunded Amount:    ₹${totals.refundedAmount.toStringAsFixed(2)}\n');

    buf.writeln('CANTEEN DETAILS:');
    buf.writeln('----------------');
    for (final r in reports) {
      buf.writeln('Canteen: ${r.canteenName}');
      buf.writeln('  Orders: [Total: ${r.totalOrders}, Completed: ${r.completedOrders}, InProgress: ${r.inProgressOrders}, Rejected: ${r.rejectedOrders}]');
      buf.writeln('  Gross Collection: ₹${r.grossCollection.toStringAsFixed(2)}');
      buf.writeln('  Platform Fee:     ₹${r.platformFee.toStringAsFixed(2)}');
      buf.writeln('  Refunds:          ₹${r.refunds.toStringAsFixed(2)}');
      buf.writeln('  Net Collection:   ₹${r.netCollection.toStringAsFixed(2)}');
      buf.writeln('  Final Payable:    ₹${r.finalPayable.toStringAsFixed(2)}');
      buf.writeln('--------------------------------------------------');
    }
    
    return buf.toString();
  }
}

// Global Provider
final dailyCollectionProvider =
    NotifierProvider<DailyCollectionNotifier, DailyCollectionState>(DailyCollectionNotifier.new);

// Computed stats/KPIs selector
class DailyKpiStats {
  final double foodRevenue; // Completed orders
  final double platformFees; // 5% of completed orders
  final int totalOrders;
  final int completedOrders;
  final int inProgressOrders;
  final int rejectedOrders;
  final double refundedAmount;

  DailyKpiStats({
    required this.foodRevenue,
    required this.platformFees,
    required this.totalOrders,
    required this.completedOrders,
    required this.inProgressOrders,
    required this.rejectedOrders,
    required this.refundedAmount,
  });
}

final dailyKpiProvider = Provider.autoDispose<DailyKpiStats>((ref) {
  final state = ref.watch(dailyCollectionProvider);
  final allOrders = state.rawOrders;

  double revenue = 0.0;
  double refunds = 0.0;
  int total = 0;
  int completed = 0;
  int inProgress = 0;
  int rejected = 0;

  for (final order in allOrders) {
    // If canteen filter is applied
    if (state.canteenFilter != 'all') {
      final canteenData = order['canteens'];
      final name = canteenData is Map ? canteenData['name'] as String? ?? '' : '';
      if (name != state.canteenFilter) {
        continue;
      }
    }

    final status = order['status'] as String? ?? '';
    final refundStatus = order['refund_status'] as String? ?? 'none';
    final amount = (order['total_amount'] as num? ?? 0.0).toDouble();

    total++;

    if (status == 'completed') {
      completed++;
      revenue += amount;
    } else if (status == 'declined' || status == 'rejected') {
      rejected++;
      if (refundStatus == 'processed') {
        refunds += amount;
      }
    } else if (status == 'cancelled') {
      // Not completed, not rejected, just cancelled.
    } else {
      inProgress++;
    }
  }

  return DailyKpiStats(
    foodRevenue: revenue,
    platformFees: revenue * 0.05,
    totalOrders: total,
    completedOrders: completed,
    inProgressOrders: inProgress,
    rejectedOrders: rejected,
    refundedAmount: refunds,
  );
});

// Computed canteen-wise report selector
final dailyCanteenReportsProvider = Provider.autoDispose<List<CanteenDailyReport>>((ref) {
  final state = ref.watch(dailyCollectionProvider);
  final allOrders = state.rawOrders;
  final canteens = state.canteens;

  // Initialize map for canteens
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final c in canteens) {
    grouped[c['id'].toString()] = [];
  }

  // Populate maps
  for (final order in allOrders) {
    final canteenId = order['canteen_id']?.toString() ?? 'unknown';
    if (grouped.containsKey(canteenId)) {
      grouped[canteenId]!.add(order);
    } else {
      grouped[canteenId] = [order];
    }
  }

  final List<CanteenDailyReport> reports = [];

  grouped.forEach((canteenId, orders) {
    final canteenName = canteens.firstWhere(
      (c) => c['id'].toString() == canteenId,
      orElse: () => {'name': 'Unknown Canteen'},
    )['name'] as String;

    // Filter by canteen if specified
    if (state.canteenFilter != 'all' && canteenName != state.canteenFilter) {
      return;
    }

    int total = 0;
    int completed = 0;
    int inProgress = 0;
    int rejected = 0;
    double gross = 0.0;
    double refunds = 0.0;

    for (final order in orders) {
      final status = order['status'] as String? ?? '';
      final refundStatus = order['refund_status'] as String? ?? 'none';
      final amount = (order['total_amount'] as num? ?? 0.0).toDouble();

      total++;

      if (status == 'completed') {
        completed++;
        gross += amount; // Only completed orders generate collection/revenue
      } else if (status == 'declined' || status == 'rejected') {
        rejected++;
        if (refundStatus == 'processed') {
          refunds += amount;
        }
      } else if (status == 'cancelled') {
        // cancelled
      } else {
        inProgress++;
      }
    }

    final platformFee = gross * 0.05;
    final netCollection = gross - refunds;
    final finalPayable = netCollection - platformFee;

    reports.add(CanteenDailyReport(
      canteenId: canteenId,
      canteenName: canteenName,
      totalOrders: total,
      completedOrders: completed,
      inProgressOrders: inProgress,
      rejectedOrders: rejected,
      grossCollection: gross,
      platformFee: platformFee,
      netCollection: netCollection,
      refunds: refunds,
      finalPayable: finalPayable,
    ));
  });

  // Sort by canteen name
  reports.sort((a, b) => a.canteenName.compareTo(b.canteenName));
  return reports;
});
