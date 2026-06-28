import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/canteen.dart';

import '../../menu/providers/menu_provider.dart';

final canteensProvider = StreamProvider.autoDispose<List<Canteen>>((ref) {
  final supabase = ref.read(supabaseClientProvider);
  return supabase
      .from(kCanteensTableName)
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((row) => row['banned'] != true)
          .map((row) => Canteen.fromJson(row))
          .toList());
});

final currentCanteenProvider = Provider.autoDispose<Canteen?>((ref) {
  final canteensAsync = ref.watch(canteensProvider);
  final selectedId = ref.watch(selectedCanteenIdProvider);
  
  final canteens = canteensAsync.value;
  if (canteens == null || selectedId.isEmpty) return null;
  
  try {
    return canteens.firstWhere((c) => c.id == selectedId);
  } catch (_) {
    return null;
  }
});

final canteenActiveOrdersCountProvider = StreamProvider.family.autoDispose<int, String>((ref, canteenId) {
  final supabase = ref.read(supabaseClientProvider);
  if (canteenId.isEmpty) return Stream.value(0);

  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('canteen_id', canteenId)
      .map((data) {
        return data.where((o) {
          final status = o['status'] as String? ?? '';
          return status != 'completed' &&
                 status != 'delivered' &&
                 status != 'declined' &&
                 status != 'rejected' &&
                 status != 'cancelled';
        }).length;
      });
});

final canteenMaxOrdersProvider = StreamProvider.family.autoDispose<int, String>((ref, canteenId) {
  final supabase = ref.read(supabaseClientProvider);
  if (canteenId.isEmpty) return Stream.value(10);

  return supabase
      .from('canteens')
      .stream(primaryKey: ['id'])
      .eq('id', canteenId)
      .map((data) {
        if (data.isEmpty) return 10;
        try {
          return data.first['max_concurrent_orders'] as int? ?? 10;
        } catch (_) {
          return 99999;
        }
      });
});
