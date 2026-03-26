// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  studentId: json['student_id'] as String,
  canteenId: json['canteen_id'] as String?,
  status: json['status'] as String,
  totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
  paymentStatus: json['payment_status'] as String?,
  cashfreeOrderId: json['cashfree_order_id'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  scheduledTime:
      json['scheduled_time'] == null
          ? null
          : DateTime.parse(json['scheduled_time'] as String),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'canteen_id': instance.canteenId,
  'status': instance.status,
  'total_amount': instance.totalAmount,
  'payment_status': instance.paymentStatus,
  'cashfree_order_id': instance.cashfreeOrderId,
  'created_at': instance.createdAt?.toIso8601String(),
  'scheduled_time': instance.scheduledTime?.toIso8601String(),
};
