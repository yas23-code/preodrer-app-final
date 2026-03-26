import 'package:freezed_annotation/freezed_annotation.dart';

part 'canteen.freezed.dart';
part 'canteen.g.dart';

@freezed
abstract class Canteen with _$Canteen {
  const factory Canteen({
    required String id,
    required String name,
    String? location,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'vendor_id') String? vendorId,
    @Default(true) bool isOpen,
  }) = _Canteen;

  factory Canteen.fromJson(Map<String, dynamic> json) => _$CanteenFromJson(json);
}
