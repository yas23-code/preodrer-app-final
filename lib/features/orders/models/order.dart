import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'canteen_id') String? canteenId,
    required String status,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'cashfree_order_id') String? cashfreeOrderId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'scheduled_time') DateTime? scheduledTime,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
