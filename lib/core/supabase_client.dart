import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the [SupabaseClient] singleton that was initialized via
/// `Supabase.initialize()` in main.dart.
///
/// This uses the supabase_flutter built-in session persistence
/// (SharedPreferences) so auth tokens survive app restarts.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
