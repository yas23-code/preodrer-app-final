import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/storage_service.dart';
import '../../../core/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/providers/category_provider.dart';
import '../../menu/providers/menu_provider.dart';

// Provider to fetch or auto-create the vendor's canteen
final vendorCanteenProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userAsync = ref.watch(authControllerProvider);
  final userId = userAsync.value?.id;
  
  if (userId == null) return null;
  
  try {
    final res = await supabase
        .from('canteens')
        .select('id, name, location, is_open, banned')
        .eq('vendor_id', userId)
        .maybeSingle();
        
    if (res == null) {
      // Auto-create default canteen for new vendor
      final newCanteen = await supabase
          .from('canteens')
          .insert({
            'vendor_id': userId,
            'name': 'New Canteen',
            'location': 'Main Block',
            'is_open': true,
          })
          .select()
          .single();
      return newCanteen;
    }
    return res;
  } catch (e) {
    debugPrint('[VENDOR_CANTEEN] Error resolving/auto-creating canteen: $e');
    return null;
  }
});

// Provider to fetch all menu items for the vendor (including unavailable)
final vendorMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final canteen = await ref.watch(vendorCanteenProvider.future);
  final canteenId = canteen?['id'] as String?;
  
  if (canteenId == null || canteenId.isEmpty) return [];

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
  final canteen = await ref.watch(vendorCanteenProvider.future);
  final canteenId = canteen?['id'] as String?;
  
  if (canteenId == null || canteenId.isEmpty) return [];

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
    final supabase = _ref.read(supabaseClientProvider);

    final canteen = await _ref.read(vendorCanteenProvider.future);
    final canteenId = canteen?['id'] as String?;
    if (canteenId == null || canteenId.isEmpty) {
      throw Exception("No canteen found for this vendor");
    }

    final categoryService = CategoryService(
      supabase,
      canteenId,
    );

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

final vendorAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, canteenId) async {
  final supabase = ref.read(supabaseClientProvider);
  if (canteenId.isEmpty) return {};

  try {
    final ordersRes = await supabase
        .from('orders')
        .select('id, total_amount, status, created_at')
        .eq('canteen_id', canteenId);

    final orders = List<Map<String, dynamic>>.from(ordersRes);

    final totalOrders = orders.length;
    final completedOrders = orders.where((o) => o['status'] == 'delivered' || o['status'] == 'completed').toList();
    final completedCount = completedOrders.length;
    
    final double completionRate = totalOrders > 0 ? (completedCount / totalOrders) * 100 : 100.0;
    
    double weeklyRevenue = 0.0;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    for (final o in completedOrders) {
      final createdAtStr = o['created_at'] as String?;
      if (createdAtStr != null) {
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt != null && createdAt.isAfter(sevenDaysAgo)) {
          weeklyRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    final dailyRevenue = List.generate(7, (index) {
      final date = now.subtract(Duration(days: index));
      final dayName = _getDayName(date.weekday);
      double amount = 0.0;
      for (final o in completedOrders) {
        final createdAtStr = o['created_at'] as String?;
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null && 
              createdAt.year == date.year && 
              createdAt.month == date.month && 
              createdAt.day == date.day) {
            amount += (o['total_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
      return {'day': dayName, 'amount': amount};
    }).reversed.toList();

    final hourCounts = List.filled(24, 0);
    for (final o in orders) {
      final createdAtStr = o['created_at'] as String?;
      if (createdAtStr != null) {
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt != null) {
          hourCounts[createdAt.hour]++;
        }
      }
    }

    final breakfastCount = hourCounts[8] + hourCounts[9] + hourCounts[10];
    final lunchCount = hourCounts[12] + hourCounts[13] + hourCounts[14];
    final snacksCount = hourCounts[16] + hourCounts[17] + hourCounts[18];
    final dinnerCount = hourCounts[20] + hourCounts[21] + hourCounts[22];

    // Popular items
    final Map<String, int> itemCounts = {};
    final Map<String, double> itemRevenue = {};
    
    try {
      final orderIds = orders.map((o) => o['id']).toList();
      if (orderIds.isNotEmpty) {
        final itemsRes = await supabase
            .from('order_items')
            .select('item_name, quantity, price')
            .inFilter('order_id', orderIds);
            
        for (final item in List<Map<String, dynamic>>.from(itemsRes)) {
          final name = item['item_name'] as String? ?? 'Item';
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          
          itemCounts[name] = (itemCounts[name] ?? 0) + qty;
          itemRevenue[name] = (itemRevenue[name] ?? 0.0) + (qty * price);
        }
      }
    } catch (_) {}

    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final popularItemsList = sortedItems.take(4).map((entry) {
      final name = entry.key;
      final count = entry.value;
      final rev = itemRevenue[name] ?? 0.0;
      return {
        'itemName': name,
        'count': count,
        'revenue': '₹${rev.toStringAsFixed(0)}',
      };
    }).toList();

    return {
      'totalOrders': totalOrders,
      'completedCount': completedCount,
      'completionRate': completionRate,
      'weeklyRevenue': weeklyRevenue,
      'dailyRevenue': dailyRevenue,
      'peakHours': {
        'breakfast': breakfastCount,
        'lunch': lunchCount,
        'snacks': snacksCount,
        'dinner': dinnerCount,
      },
      'popularItems': popularItemsList,
    };
  } catch (e) {
    debugPrint('[ANALYTICS] Error fetching real analytics: $e');
    return {};
  }
});

String _getDayName(int weekday) {
  switch (weekday) {
    case DateTime.monday: return 'Mon';
    case DateTime.tuesday: return 'Tue';
    case DateTime.wednesday: return 'Wed';
    case DateTime.thursday: return 'Thu';
    case DateTime.friday: return 'Fri';
    case DateTime.saturday: return 'Sat';
    case DateTime.sunday: return 'Sun';
    default: return '';
  }
}
