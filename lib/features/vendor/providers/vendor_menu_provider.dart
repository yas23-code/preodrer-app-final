import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/storage_service.dart';
import '../../../core/supabase_client.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/providers/category_provider.dart';
import '../../menu/providers/menu_provider.dart';

// Provider to fetch all menu items for the vendor (including unavailable)
final vendorMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final canteenId = ref.watch(selectedCanteenIdProvider);

  final response = await supabase
      .from(kMenuItemsTableName)
      .select()
      .eq('canteen_id', canteenId);

  final data = response as List<dynamic>;
  return data.map((row) => MenuItem.fromJson(row as Map<String, dynamic>)).toList();
});

// Provider to fetch all categories for the vendor
final vendorCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final canteenId = ref.watch(selectedCanteenIdProvider);

  final response = await supabase
      .from(kCategoriesTableName)
      .select()
      .eq('canteen_id', canteenId);

  return List<Map<String, dynamic>>.from(response);
});

// Provider to handle deletion and updates of menu items and categories
final vendorMenuActionProvider = Provider<VendorMenuActionService>((ref) {
  return VendorMenuActionService(ref);
});

class VendorMenuActionService {
  final Ref _ref;

  VendorMenuActionService(this._ref);

  Future<void> deleteCategory(String categoryId) async {
    final supabase = _ref.read(supabaseClientProvider);

    try {
      // 1. Unlink items from this category (set category_id = null)
      await supabase
          .from(kMenuItemsTableName)
          .update({'category_id': null})
          .eq('category_id', categoryId);

      // 2. Delete the category itself
      await supabase
          .from(kCategoriesTableName)
          .delete()
          .eq('id', categoryId);

      // 3. Refresh the UI providers
      _ref.invalidate(vendorMenuItemsProvider);
      _ref.invalidate(vendorCategoriesProvider);
      _ref.invalidate(menuItemsProvider); // Refresh customer menu as well
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final storage = _ref.read(storageServiceProvider);
    try {
      // Fetch the item first to get its image URL
      final itemData = await supabase
          .from(kMenuItemsTableName)
          .select('image_url')
          .eq('id', itemId)
          .maybeSingle();

      // Delete from database
      await supabase
          .from(kMenuItemsTableName)
          .delete()
          .eq('id', itemId);

      // Delete the image from storage if it exists
      if (itemData != null && itemData['image_url'] != null) {
        await storage.deleteImageFromUrl(itemData['image_url'] as String);
      }

      _ref.invalidate(vendorMenuItemsProvider);
      _ref.invalidate(menuItemsProvider);
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem({
    required MenuItem currentItem,
    required String name,
    required double price,
    required double packingCharge,
    String? description,
    String? prepTime,
    required String categoryName,
    File? newItemImage,
    File? newCategoryImage,
    required bool isAvailable,
    bool isImageRemoved = false,
  }) async {
    final storage = _ref.read(storageServiceProvider);
    final categoryService = _ref.read(categoryProvider);
    final supabase = _ref.read(supabaseClientProvider);

    try {
      // 1. Upload new image if provided, or remove if requested
      String? itemImageUrl = currentItem.imageUrl;
      if (newItemImage != null) {
        itemImageUrl = await storage.uploadImage(newItemImage, folder: 'items');
        // Delete old image if it existed
        if (currentItem.imageUrl != null) {
          await storage.deleteImageFromUrl(currentItem.imageUrl!);
        }
      } else if (isImageRemoved) {
        itemImageUrl = null;
        if (currentItem.imageUrl != null) {
          await storage.deleteImageFromUrl(currentItem.imageUrl!);
        }
      }

      String? categoryImageUrl;
      if (newCategoryImage != null) {
        categoryImageUrl =
            await storage.uploadImage(newCategoryImage, folder: 'categories');
      }

      // 2. Resolve Category
      final categoryId = await categoryService.getOrCreateCategory(
        categoryName,
        imageUrl: categoryImageUrl,
      );

      // 3. Update Item
      final updatedItem = currentItem.copyWith(
        name: name,
        price: price,
        packingCharge: packingCharge,
        description: description?.isNotEmpty == true ? description : null,
        prepTime: prepTime != null ? int.tryParse(prepTime) : null,
        imageUrl: itemImageUrl,
        categoryId: categoryId,
        isAvailable: isAvailable,
      );

      // 4. Save to DB
      await supabase
          .from(kMenuItemsTableName)
          .update(updatedItem.toJson())
          .eq('id', currentItem.id);

      _ref.invalidate(vendorMenuItemsProvider);
      _ref.invalidate(vendorCategoriesProvider);
      _ref.invalidate(menuItemsProvider);
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> toggleItemAvailability(MenuItem item, bool isAvailable) async {
    final supabase = _ref.read(supabaseClientProvider);
    try {
      await supabase
          .from(kMenuItemsTableName)
          .update({'is_available': isAvailable})
          .eq('id', item.id);

      _ref.invalidate(vendorMenuItemsProvider);
      _ref.invalidate(menuItemsProvider);
    } catch (e) {
      debugPrint('Error toggling availability: $e');
      rethrow;
    }
  }
}
