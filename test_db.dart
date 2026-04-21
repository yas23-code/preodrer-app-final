import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://erlsfpqmtzbcpcjhroop.supabase.co',
    'sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6',
  );

  final res = await supabase.from('menu_items').select().limit(1);
  if (res.isNotEmpty) {
    print("Columns: ${res.first.keys.toList()}");
  } else {
    print("Table is empty but accessible.");
  }
}
