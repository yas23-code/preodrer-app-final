import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'YOUR_URL_HERE',
    'YOUR_KEY_HERE',
  );
  try {
    final data = await supabase.from('profiles').select().limit(1);
    print(data);
  } catch (e) {
    print(e);
  }
}
