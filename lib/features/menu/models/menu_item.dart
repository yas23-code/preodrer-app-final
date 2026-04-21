import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String name,
    String? description,
    required double price,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'canteen_id') String? canteenId,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'prep_time') int? prepTime,
    @JsonKey(name: 'packing_charge') @Default(0.0) double packingCharge,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}
