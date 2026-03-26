import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/menu_item.dart';

final menuItemsProvider =
    AsyncNotifierProvider<MenuController, List<MenuItem>>(MenuController.new);

class MenuController extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    final supabase = ref.read(supabaseClientProvider);

    // TODO: update table/column names + any required filters (e.g. availability).
    final response = await supabase.from(kMenuItemsTableName).select();
    final data = response as List<dynamic>;

    return data
        .map((row) => MenuItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

