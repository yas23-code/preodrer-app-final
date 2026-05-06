import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Use the env file
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('Missing Supabase URL or Anon Key in .env');
    return;
  }

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  // Get latest order
  final data = await client.from('orders').select('*').order('created_at', ascending: false).limit(1);
  if (data.isEmpty) {
    print('No orders found');
    return;
  }
  final orderId = data[0]['id'];
  print('Testing with order_id: $orderId');

  try {
    final response = await client.functions.invoke(
      'notify-order-ready',
      body: {'order_id': orderId},
    );
    print('Status: ${response.status}');
    print('Response: ${response.data}');
  } on FunctionException catch (e) {
    print('Function Error: ${e.status} ${e.reasonPhrase} ${e.details}');
  } catch (e) {
    print('Error: $e');
  }
}
