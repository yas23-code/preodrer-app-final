import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

class CanteenApprovalsState {
  final List<Map<String, dynamic>> registrations;
  final List<Map<String, dynamic>> allHistory; // all approved/rejected to count stats
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String dateFilter; // 'all', 'today', 'week', 'month'

  CanteenApprovalsState({
    required this.registrations,
    required this.allHistory,
    required this.isLoading,
    this.errorMessage,
    required this.searchQuery,
    required this.dateFilter,
  });

  CanteenApprovalsState copyWith({
    List<Map<String, dynamic>>? registrations,
    List<Map<String, dynamic>>? allHistory,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? dateFilter,
  }) {
    return CanteenApprovalsState(
      registrations: registrations ?? this.registrations,
      allHistory: allHistory ?? this.allHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

class CanteenApprovalsNotifier extends Notifier<CanteenApprovalsState> {
  @override
  CanteenApprovalsState build() {
    Future.microtask(() => fetchRegistrations());
    return CanteenApprovalsState(
      registrations: [],
      allHistory: [],
      isLoading: false,
      searchQuery: '',
      dateFilter: 'all',
    );
  }

  Future<void> fetchRegistrations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Fetch all registrations (pending, approved, rejected) to support stats & list
      final response = await supabase
          .from('canteen_registrations')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(response);
      
      final pending = list.where((r) => r['status'] == 'pending').toList();
      
      state = state.copyWith(
        registrations: pending,
        allHistory: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateFilter(String filter) {
    state = state.copyWith(dateFilter: filter);
  }

  // Action: Approve Canteen
  Future<bool> approveCanteen(Map<String, dynamic> reg) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = reg['user_id'] as String;
    final canteenName = reg['canteen_name'] as String;
    final location = reg['location'] as String;
    final regId = reg['id'] as String;

    try {
      // 1. Assign Vendor role in user_roles
      await supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': 'vendor',
      });

      // 2. Also update profiles role column
      try {
        await supabase.from('profiles').update({
          'role': 'vendor',
        }).eq('id', userId);
      } catch (_) {}

      // 3. Create Canteen account
      await supabase.from('canteens').insert({
        'name': canteenName,
        'location': location,
        'vendor_id': userId,
        'is_open': true,
      });

      // 4. Update status in canteen_registrations to approved
      await supabase.from('canteen_registrations').update({
        'status': 'approved',
      }).eq('id', regId);

      // Refresh list
      await fetchRegistrations();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Action: Reject Canteen
  Future<bool> rejectCanteen(String regId, String reason) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.from('canteen_registrations').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', regId);

      await fetchRegistrations();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// State Provider
final canteenApprovalsProvider =
    NotifierProvider<CanteenApprovalsNotifier, CanteenApprovalsState>(CanteenApprovalsNotifier.new);

// Computed Stats Provider
class ApprovalsStats {
  final int totalPending;
  final int approvedToday;
  final int rejectedToday;

  ApprovalsStats({
    required this.totalPending,
    required this.approvedToday,
    required this.rejectedToday,
  });
}

final approvalsStatsProvider = Provider.autoDispose<ApprovalsStats>((ref) {
  final state = ref.watch(canteenApprovalsProvider);
  final all = state.allHistory;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  int pending = 0;
  int approvedToday = 0;
  int rejectedToday = 0;

  for (final reg in all) {
    final status = reg['status'] as String? ?? 'pending';
    final createdAtStr = reg['created_at'] as String?;
    
    if (status == 'pending') {
      pending++;
    } else if (createdAtStr != null) {
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt != null && createdAt.isAfter(startOfToday)) {
        if (status == 'approved') {
          approvedToday++;
        } else if (status == 'rejected') {
          rejectedToday++;
        }
      }
    }
  }

  return ApprovalsStats(
    totalPending: pending,
    approvedToday: approvedToday,
    rejectedToday: rejectedToday,
  );
});

// Computed Filtered Pending Registrations
final filteredRegistrationsProvider = Provider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final state = ref.watch(canteenApprovalsProvider);
  var list = state.registrations;

  // 1. Search Query Filter
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    list = list.where((reg) {
      final canteenName = (reg['canteen_name'] as String? ?? '').toLowerCase();
      final ownerName = (reg['owner_name'] as String? ?? '').toLowerCase();
      final email = (reg['email'] as String? ?? '').toLowerCase();
      return canteenName.contains(query) ||
          ownerName.contains(query) ||
          email.contains(query);
    }).toList();
  }

  // 2. Date Filter
  if (state.dateFilter != 'all') {
    final now = DateTime.now();
    final DateTime limitDate;

    if (state.dateFilter == 'today') {
      limitDate = DateTime(now.year, now.month, now.day);
    } else if (state.dateFilter == 'week') {
      limitDate = now.subtract(const Duration(days: 7));
    } else if (state.dateFilter == 'month') {
      limitDate = now.subtract(const Duration(days: 30));
    } else {
      limitDate = DateTime(1970);
    }

    list = list.where((reg) {
      final createdAtStr = reg['created_at'] as String?;
      if (createdAtStr == null) return false;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;
      return createdAt.isAfter(limitDate);
    }).toList();
  }

  return list;
});
