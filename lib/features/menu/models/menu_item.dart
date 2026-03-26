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

    // TODO: fill in your actual storage path/column mapping.
    String? imagePath,
    String? category,
    @Default(true) bool isAvailable,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}

