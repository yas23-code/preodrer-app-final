import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/formatters.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../main.dart';

final vendorOrdersProvider =
    AsyncNotifierProvider<VendorOrdersController, List<Map<String, dynamic>>>(
      VendorOrdersController.new,
    );

class VendorOrdersController extends AsyncNotifier<List<Map<String, dynamic>>> {
  String? _currentUserId;
  Timer? _pollTimer;
  /// Track known order IDs so we can detect NEW orders for notifications
  Set<String> _knownOrderIds = {};

  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Cancel polling when this provider is disposed
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });

    ref.listen<AsyncValue<User?>>(
      authControllerProvider,
      (previous, next) async {
        final user = next.maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
        if (user == null) {
          _currentUserId = null;
          _stopPolling();
          _knownOrderIds.clear();
          state = const AsyncValue.data([]);
          return;
        }

        if (_currentUserId == user.id) return;
        _currentUserId = user.id;

        final initial = await _fetchVendorOrders(user.id);
        // Seed known IDs from initial fetch (don't notify for existing orders)
        _knownOrderIds = initial.map((o) => o['id'] as String).toSet();
        state = AsyncValue.data(initial);
        _startPolling(user.id);
      },
    );

    final initialUser = ref.read(authControllerProvider).maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );
    
    if (initialUser == null) return const [];

    _currentUserId = initialUser.id;
    final initial = await _fetchVendorOrders(initialUser.id);
    // Seed known IDs from initial fetch
    _knownOrderIds = initial.map((o) => o['id'] as String).toSet();
    _startPolling(initialUser.id);
    return initial;
  }

  void _startPolling(String userId) {
    _stopPolling();
    debugPrint('[VENDOR POLL] Starting polling every 5 seconds for userId=$userId');
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final fresh = await _fetchVendorOrders(userId);
        
        // Detect new orders by comparing IDs
        final freshIds = fresh.map((o) => o['id'] as String).toSet();
        final newIds = freshIds.difference(_knownOrderIds);

        if (newIds.isNotEmpty) {
          debugPrint('[VENDOR POLL] Detected ${newIds.length} new order(s): $newIds');

          // Show a notification for each new order
          for (final newId in newIds) {
            final shortId = newId.length >= 4
                ? '#${newId.substring(0, 4).toUpperCase()}'
                : 'A new order';
            showLocalNotification(
              'New Order Received!',
              '$shortId has just been placed and is waiting for you.',
            );
          }

          // Update known IDs
          _knownOrderIds = freshIds;
        }

        // Always update the state so status changes (e.g. pending→ready) are reflected
        state = AsyncValue.data(fresh);
      } catch (e) {
        debugPrint('[VENDOR POLL] Error during poll: $e');
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<List<Map<String, dynamic>>> _fetchVendorOrders(String userId) async {
    final supabase = ref.read(supabaseClientProvider);

    try {
      final canteensRes = await supabase
          .from(kCanteensTableName)
          .select('id')
          .eq('vendor_id', userId);
          
      final List<dynamic> canteensList = canteensRes;
      if (canteensList.isEmpty) {
        return [];
      }
      
      final List<String> canteenIds = canteensList.map((c) => c['id'].toString()).toList();

      final response = await supabase
          .from(kOrdersTableName)
          .select('id, status, total_amount, created_at, canteen_id, student_id')
          .inFilter('canteen_id', canteenIds)
          .order('created_at', ascending: false);

      return _mapOrdersToUi(response as List<dynamic>);
    } catch (e, st) {
      debugPrint('[VENDOR POLL] EXCEPTION caught: $e\n$st');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _mapOrdersToUi(List<dynamic> data) {
    return data.map((row) {
      final id = row['id'] as String;
      final status = row['status'] as String? ?? 'pending';
      final totalAmount = row['total_amount'] as num? ?? 0.0;
      final createdAtStr = row['created_at'] as String?;
      
      String timeStr = 'N/A';
      if (createdAtStr != null) {
        final dt = DateTime.parse(createdAtStr).toLocal();
        timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }

      final customerName = 'Customer';
      final itemsStrList = ['Items unavailable'];

      // Transform status for UI Tabs
      String uiStatus = 'In Progress';
      if (status == 'ready') uiStatus = 'Ready';
      if (status == 'completed') uiStatus = 'Completed';

      return {
        'id': id,
        'customerName': customerName ?? 'Unknown',
        'amount': formatCurrency(totalAmount.toDouble()),
        'time': timeStr,
        'eta': 'Est. 10 mins', // Mock ETA
        'items': itemsStrList.join(', '),
        'type': 'Takeaway', // Mock
        'orderNumber': '#${id.substring(0, 4).toUpperCase()}',
        'status': uiStatus,
        'raw_status': status,
        'created_at': createdAtStr,
      };
    }).toList();
  }
}
