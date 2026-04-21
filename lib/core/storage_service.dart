import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'supabase_client.dart';
import 'constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(supabaseClientProvider));
});

class StorageService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  StorageService(this._supabase);

  /// Uploads a file to Supabase Storage and returns the public URL.
  Future<String> uploadImage(File file, {String? folder}) async {
    final extension = p.extension(file.path);
    final fileName = '${_uuid.v4()}$extension';
    final path = folder != null ? '$folder/$fileName' : fileName;

    await _supabase.storage.from(kFoodImagesBucketName).upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final publicUrl =
        _supabase.storage.from(kFoodImagesBucketName).getPublicUrl(path);

    return publicUrl;
  }

  /// Deletes a file from Supabase Storage given its public URL.
  Future<void> deleteImageFromUrl(String publicUrl) async {
    try {
      final bucketUrlPart = '/storage/v1/object/public/$kFoodImagesBucketName/';
      final startIndex = publicUrl.indexOf(bucketUrlPart);
      if (startIndex != -1) {
        final path = publicUrl.substring(startIndex + bucketUrlPart.length);
        await _supabase.storage.from(kFoodImagesBucketName).remove([path]);
      }
    } catch (e) {
      // Ignore errors for deletion, since it might have been already deleted
    }
  }
}
