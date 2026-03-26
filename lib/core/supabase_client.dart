import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final url = dotenv.env[kSupabaseUrlEnvKey];
  final anonKey = dotenv.env[kSupabaseAnonKeyEnvKey];

  if (url == null || url.isEmpty) {
    throw StateError('Missing env var: $kSupabaseUrlEnvKey');
  }
  if (anonKey == null || anonKey.isEmpty) {
    throw StateError('Missing env var: $kSupabaseAnonKeyEnvKey');
  }

  return SupabaseClient(url, anonKey);
});

