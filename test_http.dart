import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://erlsfpqmtzbcpcjhroop.supabase.co/rest/v1/cart_items';
  final anonKey = 'sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6';
  
  // We need a valid user auth token to interact because of RLS!
  // I don't have a user token.
  print('Need auth token for RLS');
}
