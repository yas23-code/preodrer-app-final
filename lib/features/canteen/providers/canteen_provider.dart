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
      .map((data) => data.map((row) => Canteen.fromJson(row)).toList());
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
