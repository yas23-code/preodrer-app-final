import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://erlsfpqmtzbcpcjhroop.supabase.co/functions/v1/notify-order-ready');
  // Use anon key just to trigger the function
  final anonKey = 'sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6'; // Replaced with valid key length

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
      },
      body: jsonEncode({'order_id': 'dummy-id'}),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
