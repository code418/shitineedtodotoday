// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Recurrence _$RecurrenceFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'strict':
          return StrictRecurrence.fromJson(
            json
          );
                case 'flexible':
          return FlexibleRecurrence.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'Recurrence',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Recurrence {



  /// Serializes this Recurrence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recurrence);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Recurrence()';
}


}

/// @nodoc
class $RecurrenceCopyWith<$Res>  {
$RecurrenceCopyWith(Recurrence _, $Res Function(Recurrence) __);
}


/// Adds pattern-matching-related methods to [Recurrence].
extension RecurrencePatterns on Recurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StrictRecurrence value)?  strict,TResult Function( FlexibleRecurrence value)?  flexible,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StrictRecurrence() when strict != null:
return strict(_that);case FlexibleRecurrence() when flexible != null:
return flexible(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StrictRecurrence value)  strict,required TResult Function( FlexibleRecurrence value)  flexible,}){
final _that = this;
switch (_that) {
case StrictRecurrence():
return strict(_that);case FlexibleRecurrence():
return flexible(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StrictRecurrence value)?  strict,TResult? Function( FlexibleRecurrence value)?  flexible,}){
final _that = this;
switch (_that) {
case StrictRecurrence() when strict != null:
return strict(_that);case FlexibleRecurrence() when flexible != null:
return flexible(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<int> weekdays,  int? dayOfMonth,  DateTime? exactDate)?  strict,TResult Function( int timesPerPeriod,  FrequencyPeriod period,  int windowDays,  Season? season)?  flexible,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StrictRecurrence() when strict != null:
return strict(_that.weekdays,_that.dayOfMonth,_that.exactDate);case FlexibleRecurrence() when flexible != null:
return flexible(_that.timesPerPeriod,_that.period,_that.windowDays,_that.season);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<int> weekdays,  int? dayOfMonth,  DateTime? exactDate)  strict,required TResult Function( int timesPerPeriod,  FrequencyPeriod period,  int windowDays,  Season? season)  flexible,}) {final _that = this;
switch (_that) {
case StrictRecurrence():
return strict(_that.weekdays,_that.dayOfMonth,_that.exactDate);case FlexibleRecurrence():
return flexible(_that.timesPerPeriod,_that.period,_that.windowDays,_that.season);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<int> weekdays,  int? dayOfMonth,  DateTime? exactDate)?  strict,TResult? Function( int timesPerPeriod,  FrequencyPeriod period,  int windowDays,  Season? season)?  flexible,}) {final _that = this;
switch (_that) {
case StrictRecurrence() when strict != null:
return strict(_that.weekdays,_that.dayOfMonth,_that.exactDate);case FlexibleRecurrence() when flexible != null:
return flexible(_that.timesPerPeriod,_that.period,_that.windowDays,_that.season);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class StrictRecurrence extends Recurrence {
  const StrictRecurrence({final  List<int> weekdays = const <int>[], this.dayOfMonth, this.exactDate, final  String? $type}): _weekdays = weekdays,$type = $type ?? 'strict',super._();
  factory StrictRecurrence.fromJson(Map<String, dynamic> json) => _$StrictRecurrenceFromJson(json);

 final  List<int> _weekdays;
@JsonKey() List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

 final  int? dayOfMonth;
 final  DateTime? exactDate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrictRecurrenceCopyWith<StrictRecurrence> get copyWith => _$StrictRecurrenceCopyWithImpl<StrictRecurrence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StrictRecurrenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrictRecurrence&&const DeepCollectionEquality().equals(other._weekdays, _weekdays)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.exactDate, exactDate) || other.exactDate == exactDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_weekdays),dayOfMonth,exactDate);

@override
String toString() {
  return 'Recurrence.strict(weekdays: $weekdays, dayOfMonth: $dayOfMonth, exactDate: $exactDate)';
}


}

/// @nodoc
abstract mixin class $StrictRecurrenceCopyWith<$Res> implements $RecurrenceCopyWith<$Res> {
  factory $StrictRecurrenceCopyWith(StrictRecurrence value, $Res Function(StrictRecurrence) _then) = _$StrictRecurrenceCopyWithImpl;
@useResult
$Res call({
 List<int> weekdays, int? dayOfMonth, DateTime? exactDate
});




}
/// @nodoc
class _$StrictRecurrenceCopyWithImpl<$Res>
    implements $StrictRecurrenceCopyWith<$Res> {
  _$StrictRecurrenceCopyWithImpl(this._self, this._then);

  final StrictRecurrence _self;
  final $Res Function(StrictRecurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? weekdays = null,Object? dayOfMonth = freezed,Object? exactDate = freezed,}) {
  return _then(StrictRecurrence(
weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,exactDate: freezed == exactDate ? _self.exactDate : exactDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FlexibleRecurrence extends Recurrence {
  const FlexibleRecurrence({this.timesPerPeriod = 1, this.period = FrequencyPeriod.week, this.windowDays = 0, this.season, final  String? $type}): $type = $type ?? 'flexible',super._();
  factory FlexibleRecurrence.fromJson(Map<String, dynamic> json) => _$FlexibleRecurrenceFromJson(json);

@JsonKey() final  int timesPerPeriod;
@JsonKey() final  FrequencyPeriod period;
@JsonKey() final  int windowDays;
 final  Season? season;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlexibleRecurrenceCopyWith<FlexibleRecurrence> get copyWith => _$FlexibleRecurrenceCopyWithImpl<FlexibleRecurrence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlexibleRecurrenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlexibleRecurrence&&(identical(other.timesPerPeriod, timesPerPeriod) || other.timesPerPeriod == timesPerPeriod)&&(identical(other.period, period) || other.period == period)&&(identical(other.windowDays, windowDays) || other.windowDays == windowDays)&&(identical(other.season, season) || other.season == season));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timesPerPeriod,period,windowDays,season);

@override
String toString() {
  return 'Recurrence.flexible(timesPerPeriod: $timesPerPeriod, period: $period, windowDays: $windowDays, season: $season)';
}


}

/// @nodoc
abstract mixin class $FlexibleRecurrenceCopyWith<$Res> implements $RecurrenceCopyWith<$Res> {
  factory $FlexibleRecurrenceCopyWith(FlexibleRecurrence value, $Res Function(FlexibleRecurrence) _then) = _$FlexibleRecurrenceCopyWithImpl;
@useResult
$Res call({
 int timesPerPeriod, FrequencyPeriod period, int windowDays, Season? season
});




}
/// @nodoc
class _$FlexibleRecurrenceCopyWithImpl<$Res>
    implements $FlexibleRecurrenceCopyWith<$Res> {
  _$FlexibleRecurrenceCopyWithImpl(this._self, this._then);

  final FlexibleRecurrence _self;
  final $Res Function(FlexibleRecurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? timesPerPeriod = null,Object? period = null,Object? windowDays = null,Object? season = freezed,}) {
  return _then(FlexibleRecurrence(
timesPerPeriod: null == timesPerPeriod ? _self.timesPerPeriod : timesPerPeriod // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FrequencyPeriod,windowDays: null == windowDays ? _self.windowDays : windowDays // ignore: cast_nullable_to_non_nullable
as int,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as Season?,
  ));
}


}

// dart format on
