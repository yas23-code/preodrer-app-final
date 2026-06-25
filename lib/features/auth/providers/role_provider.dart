import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import 'auth_provider.dart';

enum AppRole { customer, vendor, superadmin }

final roleProvider = FutureProvider<AppRole>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return AppRole.customer;
  }

  try {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      final roleStr = response['role'] as String;
      if (roleStr == 'superadmin') {
        return AppRole.superadmin;
      } else if (roleStr == 'vendor') {
        return AppRole.vendor;
      }
    }
    
    // Fallback: check profile table's role column if user_roles is empty/not set
    final profileResponse = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (profileResponse != null) {
      final roleStr = profileResponse['role'] as String;
      if (roleStr == 'superadmin') {
        return AppRole.superadmin;
      } else if (roleStr == 'vendor') {
        return AppRole.vendor;
      }
    }
    
    return AppRole.customer;
  } catch (e) {
    return AppRole.customer;
  }
});

final myRegistrationProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.asData?.value;
  if (user == null) return null;

  final supabase = ref.read(supabaseClientProvider);
  try {
    final response = await supabase
        .from('canteen_registrations')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    return response;
  } catch (_) {
    return null;
  }
});
