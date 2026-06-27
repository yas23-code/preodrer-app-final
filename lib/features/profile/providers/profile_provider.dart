import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

final profileProvider = Provider<AsyncValue<Map<String, dynamic>?>>(
  (ref) => ref.watch(currentUserProfileProvider),
);

class ProfileController {
  final Ref _ref;
  ProfileController(this._ref);

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String college,
    required String hostel,
  }) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    await supabase.from(kProfilesTableName).update({
      'name': fullName,
      'phone': phone,
      'college': college,
      'hostel': hostel,
    }).eq('id', user.id);

    // Invalidate the profile provider so the UI updates
    _ref.invalidate(currentUserProfileProvider);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

