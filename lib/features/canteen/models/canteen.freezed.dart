// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canteen.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Canteen {

 String get id; String get name; String? get location;@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'vendor_id') String? get vendorId;@JsonKey(name: 'is_open') bool get isOpen;
/// Create a copy of Canteen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanteenCopyWith<Canteen> get copyWith => _$CanteenCopyWithImpl<Canteen>(this as Canteen, _$identity);

  /// Serializes this Canteen to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Canteen&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,imageUrl,vendorId,isOpen);

@override
String toString() {
  return 'Canteen(id: $id, name: $name, location: $location, imageUrl: $imageUrl, vendorId: $vendorId, isOpen: $isOpen)';
}


}

/// @nodoc
abstract mixin class $CanteenCopyWith<$Res>  {
  factory $CanteenCopyWith(Canteen value, $Res Function(Canteen) _then) = _$CanteenCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? location,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'vendor_id') String? vendorId,@JsonKey(name: 'is_open') bool isOpen
});




}
/// @nodoc
class _$CanteenCopyWithImpl<$Res>
    implements $CanteenCopyWith<$Res> {
  _$CanteenCopyWithImpl(this._self, this._then);

  final Canteen _self;
  final $Res Function(Canteen) _then;

/// Create a copy of Canteen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? location = freezed,Object? imageUrl = freezed,Object? vendorId = freezed,Object? isOpen = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,vendorId: freezed == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Canteen].
extension CanteenPatterns on Canteen {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Canteen value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Canteen() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Canteen value)  $default,){
final _that = this;
switch (_that) {
case _Canteen():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Canteen value)?  $default,){
final _that = this;
switch (_that) {
case _Canteen() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? location, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'vendor_id')  String? vendorId, @JsonKey(name: 'is_open')  bool isOpen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Canteen() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.imageUrl,_that.vendorId,_that.isOpen);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? location, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'vendor_id')  String? vendorId, @JsonKey(name: 'is_open')  bool isOpen)  $default,) {final _that = this;
switch (_that) {
case _Canteen():
return $default(_that.id,_that.name,_that.location,_that.imageUrl,_that.vendorId,_that.isOpen);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? location, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'vendor_id')  String? vendorId, @JsonKey(name: 'is_open')  bool isOpen)?  $default,) {final _that = this;
switch (_that) {
case _Canteen() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.imageUrl,_that.vendorId,_that.isOpen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Canteen implements Canteen {
  const _Canteen({required this.id, required this.name, this.location, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'vendor_id') this.vendorId, @JsonKey(name: 'is_open') this.isOpen = true});
  factory _Canteen.fromJson(Map<String, dynamic> json) => _$CanteenFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? location;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'vendor_id') final  String? vendorId;
@override@JsonKey(name: 'is_open') final  bool isOpen;

/// Create a copy of Canteen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanteenCopyWith<_Canteen> get copyWith => __$CanteenCopyWithImpl<_Canteen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanteenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Canteen&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,imageUrl,vendorId,isOpen);

@override
String toString() {
  return 'Canteen(id: $id, name: $name, location: $location, imageUrl: $imageUrl, vendorId: $vendorId, isOpen: $isOpen)';
}


}

/// @nodoc
abstract mixin class _$CanteenCopyWith<$Res> implements $CanteenCopyWith<$Res> {
  factory _$CanteenCopyWith(_Canteen value, $Res Function(_Canteen) _then) = __$CanteenCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? location,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'vendor_id') String? vendorId,@JsonKey(name: 'is_open') bool isOpen
});




}
/// @nodoc
class __$CanteenCopyWithImpl<$Res>
    implements _$CanteenCopyWith<$Res> {
  __$CanteenCopyWithImpl(this._self, this._then);

  final _Canteen _self;
  final $Res Function(_Canteen) _then;

/// Create a copy of Canteen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? location = freezed,Object? imageUrl = freezed,Object? vendorId = freezed,Object? isOpen = null,}) {
  return _then(_Canteen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,vendorId: freezed == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
