// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canteen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Canteen _$CanteenFromJson(Map<String, dynamic> json) => _Canteen(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String?,
  imageUrl: json['image_url'] as String?,
  vendorId: json['vendor_id'] as String?,
  isOpen: json['is_open'] as bool? ?? true,
);

Map<String, dynamic> _$CanteenToJson(_Canteen instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'image_url': instance.imageUrl,
  'vendor_id': instance.vendorId,
  'is_open': instance.isOpen,
};
