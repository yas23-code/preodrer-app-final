import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/menu_item.dart';

final selectedCanteenIdProvider = NotifierProvider<SelectedCanteenNotifier, String?>(SelectedCanteenNotifier.new);

class SelectedCanteenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final menuItemsProvider =
    AsyncNotifierProvider<MenuController, List<MenuItem>>(MenuController.new);

class MenuController extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final selectedCanteenId = ref.watch(selectedCanteenIdProvider);
    var query = supabase.from(kMenuItemsTableName).select().eq('is_available', true);
    if (selectedCanteenId != null) {
      query = query.eq('canteen_id', selectedCanteenId);
    }
    final response = await query;
    final data = response as List<dynamic>;
    return data.map((row) => MenuItem.fromJson(row as Map<String, dynamic>)).toList();
  }
}
