import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    required String status,
    @Default(0) double totalAmount,
    @Default('INR') String currency,
    DateTime? createdAt,

    // TODO: extend this model with order items/line details as needed.
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

