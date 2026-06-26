import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../../core/constants.dart';

class AdminSearchState {
  final String searchQuery;
  final String activeTab; // 'students' or 'canteens'
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> canteens;
  final Map<String, dynamic>? selectedStudent;
  final List<Map<String, dynamic>> selectedStudentOrders;
  final Map<String, dynamic>? selectedStudentStats;
  final Map<String, dynamic>? selectedCanteen;
  final Map<String, dynamic>? selectedCanteenStats;
  final bool isLoading;
  final String? errorMessage;

  AdminSearchState({
    required this.searchQuery,
    required this.activeTab,
    required this.students,
    required this.canteens,
    this.selectedStudent,
    required this.selectedStudentOrders,
    this.selectedStudentStats,
    this.selectedCanteen,
    this.selectedCanteenStats,
    required this.isLoading,
    this.errorMessage,
  });

  AdminSearchState copyWith({
    String? searchQuery,
    String? activeTab,
    List<Map<String, dynamic>>? students,
    List<Map<String, dynamic>>? canteens,
    Map<String, dynamic>? selectedStudent,
    List<Map<String, dynamic>>? selectedStudentOrders,
    Map<String, dynamic>? selectedStudentStats,
    Map<String, dynamic>? selectedCanteen,
    Map<String, dynamic>? selectedCanteenStats,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedStudent = false,
    bool clearSelectedCanteen = false,
  }) {
    return AdminSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      activeTab: activeTab ?? this.activeTab,
      students: students ?? this.students,
      canteens: canteens ?? this.canteens,
      selectedStudent: clearSelectedStudent ? null : (selectedStudent ?? this.selectedStudent),
      selectedStudentOrders: selectedStudentOrders ?? this.selectedStudentOrders,
      selectedStudentStats: clearSelectedStudent ? null : (selectedStudentStats ?? this.selectedStudentStats),
      selectedCanteen: clearSelectedCanteen ? null : (selectedCanteen ?? this.selectedCanteen),
      selectedCanteenStats: clearSelectedCanteen ? null : (selectedCanteenStats ?? this.selectedCanteenStats),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final adminSearchProvider = NotifierProvider<AdminSearchNotifier, AdminSearchState>(
  AdminSearchNotifier.new,
);

class AdminSearchNotifier extends Notifier<AdminSearchState> {
  Timer? _debounceTimer;

  @override
  AdminSearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return AdminSearchState(
      searchQuery: '',
      activeTab: 'students',
      students: [],
      canteens: [],
      selectedStudentOrders: [],
      isLoading: false,
    );
  }

  void setTab(String tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(
      activeTab: tab,
      clearSelectedStudent: true,
      clearSelectedCanteen: true,
    );
    // Trigger search for the new tab immediately
    performSearch();
  }

  void setQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      performSearch();
    });
  }

  Future<void> performSearch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = ref.read(supabaseClientProvider);
    final query = state.searchQuery.trim();

    try {
      if (state.activeTab == 'students') {
        var builder = supabase.from(kProfilesTableName).select().eq('role', 'student');
        if (query.isNotEmpty) {
          builder = builder.or(
            'name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%,student_id.ilike.%$query%'
          );
        }
        final res = await builder.limit(50).order('name');
        state = state.copyWith(
          students: List<Map<String, dynamic>>.from(res),
          isLoading: false,
        );
      } else {
        var builder = supabase.from(kCanteensTableName).select();
        if (query.isNotEmpty) {
          final uuidRegExp = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false,
          );
          final isUuid = uuidRegExp.hasMatch(query);
          String orFilter = 'name.ilike.%$query%,location.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%';
          if (isUuid) {
            orFilter += ',vendor_id.eq.$query';
          }
          builder = builder.or(orFilter);
        }
        final res = await builder.limit(50).order('name');
        state = state.copyWith(
          canteens: List<Map<String, dynamic>>.from(res),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Database query failed. If columns (email, phone, banned, student_id) are missing, please make sure the migration script 20260625200000_search_module.sql has been executed in the Supabase SQL Editor.',
      );
    }
  }

  Future<void> selectStudent(Map<String, dynamic>? student) async {
    if (student == null) {
      state = state.copyWith(clearSelectedStudent: true, selectedStudentOrders: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = ref.read(supabaseClientProvider);
    final studentId = student['id'] as String;

    try {
      // 1. Fetch Student Orders (Read-only history)
      final ordersRes = await supabase
          .from(kOrdersTableName)
          .select('id, total_amount, created_at, status, canteens(name)')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersRes);

      // 2. Calculate Stats
      int totalOrdersCount = orders.length;
      double totalSpent = 0.0;
      for (final order in orders) {
        final status = (order['status'] as String? ?? '').toLowerCase();
        if (status == 'completed' || status == 'delivered' || status == 'ready') {
          totalSpent += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      state = state.copyWith(
        selectedStudent: student,
        selectedStudentOrders: orders,
        selectedStudentStats: {
          'totalOrders': totalOrdersCount,
          'totalSpent': totalSpent,
        },
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load student details: $e',
      );
    }
  }

  Future<void> selectCanteen(Map<String, dynamic>? canteen) async {
    if (canteen == null) {
      state = state.copyWith(clearSelectedCanteen: true);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = ref.read(supabaseClientProvider);
    final canteenId = canteen['id'] as String;

    try {
      // 1. Fetch Canteen Orders
      final ordersRes = await supabase
          .from(kOrdersTableName)
          .select('id, total_amount, created_at, status')
          .eq('canteen_id', canteenId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersRes);

      // Calculate Canteen Stats
      int totalOrders = orders.length;
      double earnings = 0.0;
      int pending = 0;
      int ready = 0;
      int completed = 0;

      // Group orders by date (Orders-by-date section)
      final Map<String, Map<String, dynamic>> dateGroupMap = {};

      for (final order in orders) {
        final status = (order['status'] as String? ?? '').toLowerCase();
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

        if (status == 'completed' || status == 'delivered') {
          earnings += amount;
          completed++;
        } else if (status == 'ready') {
          earnings += amount; // Ready orders are usually paid/collected, count in earnings too
          ready++;
        } else if (status == 'pending' || status == 'in_progress' || status == 'accepted' || status == 'confirmed') {
          pending++;
        }

        // Group by Date (YYYY-MM-DD)
        final createdAtStr = order['created_at'] as String?;
        if (createdAtStr != null) {
          final dateStr = createdAtStr.substring(0, 10);
          if (!dateGroupMap.containsKey(dateStr)) {
            dateGroupMap[dateStr] = {
              'date': dateStr,
              'ordersCount': 0,
              'revenue': 0.0,
            };
          }
          dateGroupMap[dateStr]!['ordersCount'] = (dateGroupMap[dateStr]!['ordersCount'] as int) + 1;
          if (status == 'completed' || status == 'delivered' || status == 'ready') {
            dateGroupMap[dateStr]!['revenue'] = (dateGroupMap[dateStr]!['revenue'] as double) + amount;
          }
        }
      }

      final List<Map<String, dynamic>> ordersByDate = dateGroupMap.values.toList()
        ..sort((a, b) => b['date'].compareTo(a['date']));

      state = state.copyWith(
        selectedCanteen: canteen,
        selectedCanteenStats: {
          'totalOrders': totalOrders,
          'earnings': earnings,
          'pending': pending,
          'ready': ready,
          'completed': completed,
          'ordersByDate': ordersByDate,
        },
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load canteen details: $e',
      );
    }
  }

  Future<bool> toggleBanStudent(String studentId, bool currentBannedStatus) async {
    final supabase = ref.read(supabaseClientProvider);
    final targetBanned = !currentBannedStatus;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await supabase
          .from(kProfilesTableName)
          .update({'banned': targetBanned})
          .eq('id', studentId);

      // Refresh currently selected student
      if (state.selectedStudent != null && state.selectedStudent!['id'] == studentId) {
        final updatedStudent = Map<String, dynamic>.from(state.selectedStudent!)..['banned'] = targetBanned;
        state = state.copyWith(selectedStudent: updatedStudent);
      }

      // Refresh list results
      final updatedStudentsList = state.students.map((stu) {
        if (stu['id'] == studentId) {
          return Map<String, dynamic>.from(stu)..['banned'] = targetBanned;
        }
        return stu;
      }).toList();

      state = state.copyWith(
        students: updatedStudentsList,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update student ban status: $e',
      );
      return false;
    }
  }

  Future<bool> toggleBanCanteen(String canteenId, bool currentBannedStatus) async {
    final supabase = ref.read(supabaseClientProvider);
    final targetBanned = !currentBannedStatus;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await supabase
          .from(kCanteensTableName)
          .update({'banned': targetBanned})
          .eq('id', canteenId);

      // Refresh currently selected canteen
      if (state.selectedCanteen != null && state.selectedCanteen!['id'] == canteenId) {
        final updatedCanteen = Map<String, dynamic>.from(state.selectedCanteen!)..['banned'] = targetBanned;
        state = state.copyWith(selectedCanteen: updatedCanteen);
      }

      // Refresh list results
      final updatedCanteensList = state.canteens.map((cant) {
        if (cant['id'] == canteenId) {
          return Map<String, dynamic>.from(cant)..['banned'] = targetBanned;
        }
        return cant;
      }).toList();

      state = state.copyWith(
        canteens: updatedCanteensList,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update canteen ban status: $e',
      );
      return false;
    }
  }
}
