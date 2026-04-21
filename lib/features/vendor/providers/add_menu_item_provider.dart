import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/storage_service.dart';
import '../../../core/supabase_client.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/providers/category_provider.dart';
import '../../menu/providers/menu_provider.dart';
import 'vendor_menu_provider.dart';

final addMenuItemProvider =
    AsyncNotifierProvider<AddMenuItemNotifier, void>(AddMenuItemNotifier.new);

class AddMenuItemNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addMenuItem({
    required String name,
    required double price,
    required double packingCharge,
    String? description,
    String? prepTime,
    required String categoryName,
    File? itemImage,
    File? categoryImage,
    required bool isAvailable,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(storageServiceProvider);
      final categoryService = ref.read(categoryProvider);
      final supabase = ref.read(supabaseClientProvider);
      final canteenId = ref.read(selectedCanteenIdProvider);
      final uuid = const Uuid();

      // 1. Upload Images (if any)
      String? itemImageUrl;
      if (itemImage != null) {
        itemImageUrl =
            await storage.uploadImage(itemImage, folder: 'items');
      }

      String? categoryImageUrl;
      if (categoryImage != null) {
        categoryImageUrl =
            await storage.uploadImage(categoryImage, folder: 'categories');
      }

      // 2. Get or Create Category
      final categoryId = await categoryService.getOrCreateCategory(
        categoryName,
        imageUrl: categoryImageUrl,
      );

      // 3. Create MenuItem
      final newItem = MenuItem(
        id: uuid.v4(),
        name: name,
        price: price,
        packingCharge: packingCharge,
        description: description?.isNotEmpty == true ? description : null,
        prepTime: prepTime != null ? int.tryParse(prepTime) : null,
        imageUrl: itemImageUrl,
        categoryId: categoryId,
        canteenId: canteenId,
        isAvailable: isAvailable,
      );

      // 4. Insert into Supabase
      await supabase.from(kMenuItemsTableName).insert(newItem.toJson());

      // Invalidate menu items to refresh the list
      ref.invalidate(vendorMenuItemsProvider);
      ref.invalidate(vendorCategoriesProvider);
      ref.invalidate(menuItemsProvider);
    });
  }
}
