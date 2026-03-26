// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  userId: json['userId'] as String,
  status: json['status'] as String,
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
  currency: json['currency'] as String? ?? 'INR',
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'status': instance.status,
  'totalAmount': instance.totalAmount,
  'currency': instance.currency,
  'createdAt': instance.createdAt?.toIso8601String(),
};
