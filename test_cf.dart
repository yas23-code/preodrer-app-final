import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://erlsfpqmtzbcpcjhroop.supabase.co/functions/v1/create-cashfree-order');
  
  // NOTE: In testing, we use the service_role_key which is a valid JWT with the 'role': 'service_role'
  final serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODc0MDM4MSwiZXhwIjoyMDU0MzE2MzgxfQ.oXl4fH9Pq8Bf4PzXkVd6N4JvQXq5c2Bw1gR8kF8X8Lw';
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + serviceRoleKey,
    },
    body: jsonEncode({
      'app_order_id': 'test-${DateTime.now().millisecondsSinceEpoch}',
      'amount': 100.0,
      'customer_id': 'test_user',
    }),
  );
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + response.body);
}
