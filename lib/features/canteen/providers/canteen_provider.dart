import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../models/canteen.dart';

final canteensProvider =
    AsyncNotifierProvider<CanteensController, List<Canteen>>(CanteensController.new);

class CanteensController extends AsyncNotifier<List<Canteen>> {
  @override
  Future<List<Canteen>> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.from(kCanteensTableName).select();
    final data = response as List<dynamic>;
    return data.map((row) => Canteen.fromJson(row as Map<String, dynamic>)).toList();
  }
}
