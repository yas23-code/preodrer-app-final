import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import 'menu_provider.dart'; // for selectedCanteenIdProvider

final categoryProvider = Provider<CategoryService>((ref) {
  return CategoryService(
    ref.read(supabaseClientProvider),
    ref.read(selectedCanteenIdProvider),
  );
});

class CategoryService {
  final SupabaseClient _supabase;
  final String _canteenId;
  final _uuid = const Uuid();

  CategoryService(this._supabase, this._canteenId);

  /// Gets a category by name for the current canteen, or creates it if it doesn't exist.
  /// Returns the category ID.
  Future<String> getOrCreateCategory(String name, {String? imageUrl}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    // Try to find the existing category
    final existing = await _supabase
        .from(kCategoriesTableName)
        .select('id')
        .eq('canteen_id', _canteenId)
        .ilike('name', normalizedName)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create a new one
    final newId = _uuid.v4();
    await _supabase.from(kCategoriesTableName).insert({
      'id': newId,
      'canteen_id': _canteenId,
      'name': normalizedName,
      'vendor_id': _supabase.auth.currentUser!.id,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    return newId;
  }
}
