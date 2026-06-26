import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

class RefundsState {
  final List<Map<String, dynamic>> allOrders; // all orders with refund_status != 'none'
  final bool isLoading;
  final String? errorMessage;
  
  // Filters
  final String searchQuery;
  final String canteenFilter; // 'all' or canteen name
  final String studentFilter; // student name/email
  final String orderIdFilter;
  final String statusFilter; // 'all', 'pending', 'processed'
  final DateTimeRange? dateRangeFilter;

  RefundsState({
    required this.allOrders,
    required this.isLoading,
    this.errorMessage,
    required this.searchQuery,
    required this.canteenFilter,
    required this.studentFilter,
    required this.orderIdFilter,
    required this.statusFilter,
    this.dateRangeFilter,
  });

  RefundsState copyWith({
    List<Map<String, dynamic>>? allOrders,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? canteenFilter,
    String? studentFilter,
    String? orderIdFilter,
    String? statusFilter,
    DateTimeRange? dateRangeFilter,
    bool clearDateRange = false,
  }) {
    return RefundsState(
      allOrders: allOrders ?? this.allOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      canteenFilter: canteenFilter ?? this.canteenFilter,
      studentFilter: studentFilter ?? this.studentFilter,
      orderIdFilter: orderIdFilter ?? this.orderIdFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      dateRangeFilter: clearDateRange ? null : (dateRangeFilter ?? this.dateRangeFilter),
    );
  }
}

class RefundsNotifier extends Notifier<RefundsState> {
  @override
  RefundsState build() {
    Future.microtask(() => fetchRefundOrders());
    return RefundsState(
      allOrders: [],
      isLoading: false,
      searchQuery: '',
      canteenFilter: 'all',
      studentFilter: '',
      orderIdFilter: '',
      statusFilter: 'pending', // Default view pending refunds
    );
  }

  Future<void> fetchRefundOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Fetch all orders that are declined, rejected, or have pending/processed refund status
      final response = await supabase
          .from('orders')
          .select('id, total_amount, created_at, status, refund_status, rejection_reason, refund_processed_at, refund_processed_by, canteen_id, student_id, profiles!student_id(*), canteens(name)')
          .or('status.eq.declined,status.eq.rejected,refund_status.eq.pending,refund_status.eq.processed')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(response);
      
      // Map any declined/rejected order without a set refund status to 'pending'
      final List<Map<String, dynamic>> list = rawList.map((order) {
        final orderStatus = order['status'] as String? ?? '';
        var refundStatus = order['refund_status'] as String? ?? 'none';
        
        if ((orderStatus == 'declined' || orderStatus == 'rejected') && refundStatus == 'none') {
          refundStatus = 'pending';
        }
        
        return {
          ...order,
          'refund_status': refundStatus,
        };
      }).toList();

      state = state.copyWith(
        allOrders: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearchQuery(String val) => state = state.copyWith(searchQuery: val);
  void setCanteenFilter(String val) => state = state.copyWith(canteenFilter: val);
  void setStudentFilter(String val) => state = state.copyWith(studentFilter: val);
  void setOrderIdFilter(String val) => state = state.copyWith(orderIdFilter: val);
  void setStatusFilter(String val) => state = state.copyWith(statusFilter: val);
  void setDateRangeFilter(DateTimeRange? val) => state = state.copyWith(dateRangeFilter: val);
  void clearDateRangeFilter() => state = state.copyWith(clearDateRange: true);

  Future<bool> markRefundAsProcessed(String orderId) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = ref.read(authControllerProvider).asData?.value;
    if (user == null) return false;

    try {
      await supabase.from('orders').update({
        'refund_status': 'processed',
        'refund_processed_at': DateTime.now().toIso8601String(),
        'refund_processed_by': user.id,
      }).eq('id', orderId);

      await fetchRefundOrders();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Global Provider
final refundsProvider =
    NotifierProvider<RefundsNotifier, RefundsState>(RefundsNotifier.new);

// Computed Stats Provider
class RefundsStats {
  final int totalPendingCount;
  final double totalPendingAmount;
  final int todayRejectedCount;
  final int monthRejectedCount;

  RefundsStats({
    required this.totalPendingCount,
    required this.totalPendingAmount,
    required this.todayRejectedCount,
    required this.monthRejectedCount,
  });
}

final refundsStatsProvider = Provider.autoDispose<RefundsStats>((ref) {
  final state = ref.watch(refundsProvider);
  final all = state.allOrders;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);

  int pendingCount = 0;
  double pendingAmount = 0.0;
  int todayRejected = 0;
  int monthRejected = 0;

  for (final order in all) {
    final refundStatus = order['refund_status'] as String? ?? 'none';
    final amount = (order['total_amount'] as num? ?? 0.0).toDouble();
    final createdAtStr = order['created_at'] as String?;

    if (refundStatus == 'pending') {
      pendingCount++;
      pendingAmount += amount;
    }

    if (createdAtStr != null) {
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt != null) {
        if (createdAt.isAfter(startOfToday)) {
          todayRejected++;
        }
        if (createdAt.isAfter(startOfMonth)) {
          monthRejected++;
        }
      }
    }
  }

  return RefundsStats(
    totalPendingCount: pendingCount,
    totalPendingAmount: pendingAmount,
    todayRejectedCount: todayRejected,
    monthRejectedCount: monthRejected,
  );
});

// Filtered refunds selector
final filteredRefundsProvider = Provider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final state = ref.watch(refundsProvider);
  var list = state.allOrders;

  // 1. Refund Status Filter
  if (state.statusFilter != 'all') {
    list = list.where((o) => o['refund_status'] == state.statusFilter).toList();
  }

  // 2. Search query (matches student name, email, or canteen name)
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    list = list.where((o) {
      final canteenData = o['canteens'];
      final canteen = (canteenData is Map ? canteenData['name'] as String? ?? '' : '').toLowerCase();
      final profileData = o['profiles'];
      Map<String, dynamic>? profile;
      if (profileData is Map) {
        profile = Map<String, dynamic>.from(profileData);
      } else if (profileData is List && profileData.isNotEmpty) {
        profile = Map<String, dynamic>.from(profileData.first);
      }
      final studentName = (profile?['name'] as String? ?? profile?['full_name'] as String? ?? '').toLowerCase();
      final email = (profile?['email'] as String? ?? '').toLowerCase();
      final orderId = (o['id']?.toString() ?? '').toLowerCase();
      
      return canteen.contains(query) || studentName.contains(query) || email.contains(query) || orderId.contains(query);
    }).toList();
  }

  // 3. Canteen Filter
  if (state.canteenFilter != 'all') {
    list = list.where((o) {
      final canteenData = o['canteens'];
      final name = canteenData is Map ? canteenData['name'] as String? ?? '' : '';
      return name == state.canteenFilter;
    }).toList();
  }

  // 4. Student Name Filter
  if (state.studentFilter.isNotEmpty) {
    final sFilter = state.studentFilter.toLowerCase();
    list = list.where((o) {
      final profileData = o['profiles'];
      Map<String, dynamic>? profile;
      if (profileData is Map) {
        profile = Map<String, dynamic>.from(profileData);
      } else if (profileData is List && profileData.isNotEmpty) {
        profile = Map<String, dynamic>.from(profileData.first);
      }
      final name = (profile?['name'] as String? ?? profile?['full_name'] as String? ?? '').toLowerCase();
      final email = (profile?['email'] as String? ?? '').toLowerCase();
      return name.contains(sFilter) || email.contains(sFilter);
    }).toList();
  }

  // 5. Order ID Filter
  if (state.orderIdFilter.isNotEmpty) {
    final idFilter = state.orderIdFilter.toLowerCase();
    list = list.where((o) {
      final orderId = (o['id'] as String? ?? '').toLowerCase();
      return orderId.contains(idFilter);
    }).toList();
  }

  // 6. Date Range Filter
  if (state.dateRangeFilter != null) {
    final start = state.dateRangeFilter!.start;
    final end = state.dateRangeFilter!.end.add(const Duration(days: 1)); // inclusive of end day
    list = list.where((o) {
      final createdAtStr = o['created_at'] as String?;
      if (createdAtStr == null) return false;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;
      return createdAt.isAfter(start) && createdAt.isBefore(end);
    }).toList();
  }

  return list;
});
