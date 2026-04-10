import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import 'auth_provider.dart';

enum AppRole { customer, vendor }

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

    if (response != null && response['role'] == 'vendor') {
      return AppRole.vendor;
    }
    
    return AppRole.customer;
  } catch (e) {
    return AppRole.customer;
  }
});
