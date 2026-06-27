import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../core/storage_service.dart';
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
  }) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    await supabase.from(kProfilesTableName).update({
      'name': fullName,
      'phone': phone,
      'college': college,
    }).eq('id', user.id);

    // Invalidate the profile provider so the UI updates
    _ref.invalidate(currentUserProfileProvider);
  }

  Future<void> uploadProfilePicture(File file) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final storage = _ref.read(storageServiceProvider);

    // 1. Upload to Supabase storage in 'avatars' folder
    final publicUrl = await storage.uploadImage(file, folder: 'avatars');

    // 2. Update the profile with new avatar_url
    await supabase.from(kProfilesTableName).update({
      'avatar_url': publicUrl,
    }).eq('id', user.id);

    // 3. Invalidate to reload the screen
    _ref.invalidate(currentUserProfileProvider);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

