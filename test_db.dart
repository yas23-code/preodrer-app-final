import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://erlsfpqmtzbcpcjhroop.supabase.co',
    'sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6',
  );

  final res = await supabase.from('menu_items').select().limit(1);
  print('Menu Item: \$res');
  
  if (res.isNotEmpty) {
    final item = res.first;
    print('Item ID type: \${item['id'].runtimeType}');
    print('Item ID: \${item['id']}');
  }
}
