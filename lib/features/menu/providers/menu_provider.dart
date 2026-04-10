import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/menu_item.dart';

// ── Selected canteen notifier ─────────────────────────────────────────────────
// Defaults to Acktron Canteen. Kept as a notifier for future multi-canteen
// support, but currently always resolves to kAcktronCanteenId.
final selectedCanteenIdProvider =
    NotifierProvider<SelectedCanteenNotifier, String>(
      SelectedCanteenNotifier.new,
    );

class SelectedCanteenNotifier extends Notifier<String> {
  @override
  String build() => kAcktronCanteenId;

  void select(String id) => state = id;
}

// ── Menu items provider ───────────────────────────────────────────────────────
final menuItemsProvider =
    AsyncNotifierProvider<MenuController, List<MenuItem>>(MenuController.new);

class MenuController extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final selectedCanteenId = ref.watch(selectedCanteenIdProvider);

    debugPrint('[CANTEEN_DEBUG] MenuController.build() -> selectedCanteenId=$selectedCanteenId');
    debugPrint('[CANTEEN_DEBUG] Expected Acktron canteen_id=$kAcktronCanteenId');

    final response = await supabase
        .from(kMenuItemsTableName)
        .select()
        .eq('canteen_id', selectedCanteenId)
        .eq('is_available', true);

    final data = response as List<dynamic>;
    final items = data
        .map((row) => MenuItem.fromJson(row as Map<String, dynamic>))
        .toList();

    debugPrint('[CANTEEN_DEBUG] MenuController.build() -> fetched ${items.length} items');
    for (final item in items) {
      debugPrint('[CANTEEN_DEBUG]   item id=${item.id}, name=${item.name}, canteen_id=${item.canteenId}');
    }

    return items;
  }
}
