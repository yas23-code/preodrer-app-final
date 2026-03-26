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
  imagePath: json['imagePath'] as String?,
  category: json['category'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'imagePath': instance.imagePath,
  'category': instance.category,
  'isAvailable': instance.isAvailable,
};
