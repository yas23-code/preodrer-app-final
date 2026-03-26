// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

 String get id;@JsonKey(name: 'student_id') String get studentId;@JsonKey(name: 'canteen_id') String? get canteenId; String get status;@JsonKey(name: 'total_amount') double get totalAmount;@JsonKey(name: 'payment_status') String? get paymentStatus;@JsonKey(name: 'cashfree_order_id') String? get cashfreeOrderId;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'scheduled_time') DateTime? get scheduledTime;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.canteenId, canteenId) || other.canteenId == canteenId)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.cashfreeOrderId, cashfreeOrderId) || other.cashfreeOrderId == cashfreeOrderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,canteenId,status,totalAmount,paymentStatus,cashfreeOrderId,createdAt,scheduledTime);

@override
String toString() {
  return 'Order(id: $id, studentId: $studentId, canteenId: $canteenId, status: $status, totalAmount: $totalAmount, paymentStatus: $paymentStatus, cashfreeOrderId: $cashfreeOrderId, createdAt: $createdAt, scheduledTime: $scheduledTime)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'canteen_id') String? canteenId, String status,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'payment_status') String? paymentStatus,@JsonKey(name: 'cashfree_order_id') String? cashfreeOrderId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'scheduled_time') DateTime? scheduledTime
});




}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? canteenId = freezed,Object? status = null,Object? totalAmount = null,Object? paymentStatus = freezed,Object? cashfreeOrderId = freezed,Object? createdAt = freezed,Object? scheduledTime = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,canteenId: freezed == canteenId ? _self.canteenId : canteenId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,cashfreeOrderId: freezed == cashfreeOrderId ? _self.cashfreeOrderId : cashfreeOrderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'canteen_id')  String? canteenId,  String status, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'payment_status')  String? paymentStatus, @JsonKey(name: 'cashfree_order_id')  String? cashfreeOrderId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'scheduled_time')  DateTime? scheduledTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.studentId,_that.canteenId,_that.status,_that.totalAmount,_that.paymentStatus,_that.cashfreeOrderId,_that.createdAt,_that.scheduledTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'canteen_id')  String? canteenId,  String status, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'payment_status')  String? paymentStatus, @JsonKey(name: 'cashfree_order_id')  String? cashfreeOrderId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'scheduled_time')  DateTime? scheduledTime)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.studentId,_that.canteenId,_that.status,_that.totalAmount,_that.paymentStatus,_that.cashfreeOrderId,_that.createdAt,_that.scheduledTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'canteen_id')  String? canteenId,  String status, @JsonKey(name: 'total_amount')  double totalAmount, @JsonKey(name: 'payment_status')  String? paymentStatus, @JsonKey(name: 'cashfree_order_id')  String? cashfreeOrderId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'scheduled_time')  DateTime? scheduledTime)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.studentId,_that.canteenId,_that.status,_that.totalAmount,_that.paymentStatus,_that.cashfreeOrderId,_that.createdAt,_that.scheduledTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order implements Order {
  const _Order({required this.id, @JsonKey(name: 'student_id') required this.studentId, @JsonKey(name: 'canteen_id') this.canteenId, required this.status, @JsonKey(name: 'total_amount') this.totalAmount = 0.0, @JsonKey(name: 'payment_status') this.paymentStatus, @JsonKey(name: 'cashfree_order_id') this.cashfreeOrderId, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'scheduled_time') this.scheduledTime});
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  String id;
@override@JsonKey(name: 'student_id') final  String studentId;
@override@JsonKey(name: 'canteen_id') final  String? canteenId;
@override final  String status;
@override@JsonKey(name: 'total_amount') final  double totalAmount;
@override@JsonKey(name: 'payment_status') final  String? paymentStatus;
@override@JsonKey(name: 'cashfree_order_id') final  String? cashfreeOrderId;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'scheduled_time') final  DateTime? scheduledTime;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.canteenId, canteenId) || other.canteenId == canteenId)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.cashfreeOrderId, cashfreeOrderId) || other.cashfreeOrderId == cashfreeOrderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,canteenId,status,totalAmount,paymentStatus,cashfreeOrderId,createdAt,scheduledTime);

@override
String toString() {
  return 'Order(id: $id, studentId: $studentId, canteenId: $canteenId, status: $status, totalAmount: $totalAmount, paymentStatus: $paymentStatus, cashfreeOrderId: $cashfreeOrderId, createdAt: $createdAt, scheduledTime: $scheduledTime)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'canteen_id') String? canteenId, String status,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'payment_status') String? paymentStatus,@JsonKey(name: 'cashfree_order_id') String? cashfreeOrderId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'scheduled_time') DateTime? scheduledTime
});




}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? canteenId = freezed,Object? status = null,Object? totalAmount = null,Object? paymentStatus = freezed,Object? cashfreeOrderId = freezed,Object? createdAt = freezed,Object? scheduledTime = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,canteenId: freezed == canteenId ? _self.canteenId : canteenId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,cashfreeOrderId: freezed == cashfreeOrderId ? _self.cashfreeOrderId : cashfreeOrderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
