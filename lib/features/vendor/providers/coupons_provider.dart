import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/providers/menu_provider.dart';

// Provider to get the canteen's __COUPONS__ category ID
final couponsCategoryIdProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final canteenId = ref.watch(selectedCanteenIdProvider);
  if (canteenId.isEmpty) return null;

  try {
    // Find or create __COUPONS__ category
    final res = await supabase
        .from(kCategoriesTableName)
        .select('id')
        .eq('canteen_id', canteenId)
        .eq('name', '__COUPONS__')
        .maybeSingle();

    if (res != null) {
      return res['id'] as String;
    }

    // Create it
    final user = supabase.auth.currentUser;
    final newCat = await supabase
        .from(kCategoriesTableName)
        .insert({
          'canteen_id': canteenId,
          'name': '__COUPONS__',
          'vendor_id': user?.id ?? kAcktronVendorId,
        })
        .select('id')
        .single();

    return newCat['id'] as String;
  } catch (e) {
    debugPrint('[COUPONS] Error resolving category: $e');
    return null;
  }
});

// Provider to fetch all coupons for the selected canteen
final couponsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final catId = await ref.watch(couponsCategoryIdProvider.future);
  if (catId == null) return [];

  try {
    final response = await supabase
        .from(kMenuItemsTableName)
        .select()
        .eq('category_id', catId);

    final data = response as List<dynamic>;
    return data.map((row) => MenuItem.fromJson(row as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint('[COUPONS] Error fetching coupons: $e');
    return [];
  }
});

// Provider to fetch active coupons for a specific canteen (customer view)
final canteenCouponsProvider = FutureProvider.family<List<MenuItem>, String>((ref, canteenId) async {
  final supabase = ref.read(supabaseClientProvider);
  if (canteenId.isEmpty) return [];

  try {
    final res = await supabase
        .from(kCategoriesTableName)
        .select('id')
        .eq('canteen_id', canteenId)
        .eq('name', '__COUPONS__')
        .maybeSingle();

    if (res == null) return [];
    final catId = res['id'] as String;

    final response = await supabase
        .from(kMenuItemsTableName)
        .select()
        .eq('category_id', catId)
        .eq('is_available', true);

    final data = response as List<dynamic>;
    return data.map((row) => MenuItem.fromJson(row as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint('[COUPONS] Error fetching active coupons for canteen $canteenId: $e');
    return [];
  }
});
