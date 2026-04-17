import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/formatters.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

final vendorOrdersProvider =
    AsyncNotifierProvider<VendorOrdersController, List<Map<String, dynamic>>>(
      VendorOrdersController.new,
    );

class VendorOrdersController extends AsyncNotifier<List<Map<String, dynamic>>> {
  String? _currentUserId;
  dynamic _channel;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    ref.listen<AsyncValue<User?>>(
      authControllerProvider,
      (previous, next) async {
        final user = next.maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
        if (user == null) {
          _currentUserId = null;
          await _unsubscribe();
          state = const AsyncValue.data([]);
          return;
        }

        if (_currentUserId == user.id) return;
        _currentUserId = user.id;

        await _unsubscribe();
        final initial = await _fetchVendorOrders(user.id);
        state = AsyncValue.data(initial);
        _subscribeRealtime(user.id);
      },
    );

    final initialUser = ref.read(authControllerProvider).maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );
    
    if (initialUser == null) return const [];

    _currentUserId = initialUser.id;
    final initial = await _fetchVendorOrders(initialUser.id);
    _subscribeRealtime(initialUser.id);
    return initial;
  }

  Future<void> _unsubscribe() async {
    try {
      await _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;
  }

  Future<List<Map<String, dynamic>>> _fetchVendorOrders(String userId) async {
    debugPrint('[PROVIDER DIAGNOSIS] _fetchVendorOrders called for userId=$userId');
    final supabase = ref.read(supabaseClientProvider);

    try {
      final canteensRes = await supabase
          .from(kCanteensTableName)
          .select('id')
          .eq('vendor_id', userId);
          
      debugPrint('[PROVIDER DIAGNOSIS] canteensRes: $canteensRes');
      final List<dynamic> canteensList = canteensRes;
      if (canteensList.isEmpty) {
        debugPrint('[PROVIDER DIAGNOSIS] The logged-in auth user does NOT own any canteen in public.canteens. vendor_id=$userId');
        return [];
      }
      
      final List<String> canteenIds = canteensList.map((c) => c['id'].toString()).toList();
      debugPrint('[PROVIDER DIAGNOSIS] Resolved canteenIds: $canteenIds');

      final response = await supabase
          .from(kOrdersTableName)
          .select('id, status, total_amount, created_at, canteen_id, student_id')
          .inFilter('canteen_id', canteenIds)
          .order('created_at', ascending: false);

      debugPrint('[PROVIDER DIAGNOSIS] Final orders query result count: ${(response as List).length}');
      return _mapOrdersToUi(response as List<dynamic>);
    } catch (e, st) {
      debugPrint('[PROVIDER DIAGNOSIS] EXCEPTION caught: $e\n$st');
      rethrow; // rethrow to expose to UI
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

  void _subscribeRealtime(String userId) async {
    final supabase = ref.read(supabaseClientProvider);

    final canteensRes = await supabase
        .from(kCanteensTableName)
        .select('id')
        .eq('vendor_id', userId);
    
    final List<dynamic> canteensList = canteensRes;
    if (canteensList.isEmpty) return;
    
    final List<String> canteenIds = canteensList.map((c) => c['id'].toString()).toList();

    _channel = supabase
        .channel('vendor-broadcast-$userId')
        ..onBroadcast(
          event: 'refresh_orders',
          callback: (payload) async {
            debugPrint('[BROADCAST DIAGNOSIS] Refresh signal received: $payload');
            final fresh = await _fetchVendorOrders(userId);
            state = AsyncValue.data(fresh);
            debugPrint('[BROADCAST DIAGNOSIS] State updated with ${fresh.length} orders');
          },
        )
        ..subscribe((status, [error]) {
           debugPrint('[BROADCAST DIAGNOSIS] Channel subscribe status: $status, error: $error');
        });
  }
}
