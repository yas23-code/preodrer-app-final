// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => _MenuItem(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  imageUrl: json['image_url'] as String?,
  categoryId: json['category_id'] as String?,
  canteenId: json['canteen_id'] as String?,
  isAvailable: json['is_available'] as bool? ?? true,
  prepTime: (json['prep_time'] as num?)?.toInt(),
  packingCharge: (json['packing_charge'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'image_url': instance.imageUrl,
  'category_id': instance.categoryId,
  'canteen_id': instance.canteenId,
  'is_available': instance.isAvailable,
  'prep_time': instance.prepTime,
  'packing_charge': instance.packingCharge,
};
