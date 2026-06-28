// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_occurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskOccurrence {

 String get id; String get taskId;/// The day this occurrence is currently planned for.
 DateTime get scheduledDate;/// For flexible recurrences, the inclusive window the occurrence may move
/// within before it is considered overdue.
 DateTime? get windowStart; DateTime? get windowEnd; OccurrenceStatus get status;/// The day this occurrence was first planned for, preserved across
/// reschedules so we can reason about how far it has slipped.
 DateTime? get originalDate;/// When the user marked it done.
 DateTime? get completedAt;/// How long the user reported it actually took. Feeds effort learning so
/// future scheduling can be more realistic.
 int? get actualDurationMinutes;/// Set when the user has *deliberately* placed this occurrence on a day
/// (e.g. dragged it on the agenda). The load balancer leaves pinned
/// occurrences where they are rather than spreading them.
 bool get pinned;
/// Create a copy of TaskOccurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskOccurrenceCopyWith<TaskOccurrence> get copyWith => _$TaskOccurrenceCopyWithImpl<TaskOccurrence>(this as TaskOccurrence, _$identity);

  /// Serializes this TaskOccurrence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOccurrence&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.status, status) || other.status == status)&&(identical(other.originalDate, originalDate) || other.originalDate == originalDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.actualDurationMinutes, actualDurationMinutes) || other.actualDurationMinutes == actualDurationMinutes)&&(identical(other.pinned, pinned) || other.pinned == pinned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,scheduledDate,windowStart,windowEnd,status,originalDate,completedAt,actualDurationMinutes,pinned);

@override
String toString() {
  return 'TaskOccurrence(id: $id, taskId: $taskId, scheduledDate: $scheduledDate, windowStart: $windowStart, windowEnd: $windowEnd, status: $status, originalDate: $originalDate, completedAt: $completedAt, actualDurationMinutes: $actualDurationMinutes, pinned: $pinned)';
}


}

/// @nodoc
abstract mixin class $TaskOccurrenceCopyWith<$Res>  {
  factory $TaskOccurrenceCopyWith(TaskOccurrence value, $Res Function(TaskOccurrence) _then) = _$TaskOccurrenceCopyWithImpl;
@useResult
$Res call({
 String id, String taskId, DateTime scheduledDate, DateTime? windowStart, DateTime? windowEnd, OccurrenceStatus status, DateTime? originalDate, DateTime? completedAt, int? actualDurationMinutes, bool pinned
});




}
/// @nodoc
class _$TaskOccurrenceCopyWithImpl<$Res>
    implements $TaskOccurrenceCopyWith<$Res> {
  _$TaskOccurrenceCopyWithImpl(this._self, this._then);

  final TaskOccurrence _self;
  final $Res Function(TaskOccurrence) _then;

/// Create a copy of TaskOccurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? scheduledDate = null,Object? windowStart = freezed,Object? windowEnd = freezed,Object? status = null,Object? originalDate = freezed,Object? completedAt = freezed,Object? actualDurationMinutes = freezed,Object? pinned = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,windowStart: freezed == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime?,windowEnd: freezed == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OccurrenceStatus,originalDate: freezed == originalDate ? _self.originalDate : originalDate // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actualDurationMinutes: freezed == actualDurationMinutes ? _self.actualDurationMinutes : actualDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskOccurrence].
extension TaskOccurrencePatterns on TaskOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskOccurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskOccurrence value)  $default,){
final _that = this;
switch (_that) {
case _TaskOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case _TaskOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskId,  DateTime scheduledDate,  DateTime? windowStart,  DateTime? windowEnd,  OccurrenceStatus status,  DateTime? originalDate,  DateTime? completedAt,  int? actualDurationMinutes,  bool pinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskOccurrence() when $default != null:
return $default(_that.id,_that.taskId,_that.scheduledDate,_that.windowStart,_that.windowEnd,_that.status,_that.originalDate,_that.completedAt,_that.actualDurationMinutes,_that.pinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskId,  DateTime scheduledDate,  DateTime? windowStart,  DateTime? windowEnd,  OccurrenceStatus status,  DateTime? originalDate,  DateTime? completedAt,  int? actualDurationMinutes,  bool pinned)  $default,) {final _that = this;
switch (_that) {
case _TaskOccurrence():
return $default(_that.id,_that.taskId,_that.scheduledDate,_that.windowStart,_that.windowEnd,_that.status,_that.originalDate,_that.completedAt,_that.actualDurationMinutes,_that.pinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskId,  DateTime scheduledDate,  DateTime? windowStart,  DateTime? windowEnd,  OccurrenceStatus status,  DateTime? originalDate,  DateTime? completedAt,  int? actualDurationMinutes,  bool pinned)?  $default,) {final _that = this;
switch (_that) {
case _TaskOccurrence() when $default != null:
return $default(_that.id,_that.taskId,_that.scheduledDate,_that.windowStart,_that.windowEnd,_that.status,_that.originalDate,_that.completedAt,_that.actualDurationMinutes,_that.pinned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskOccurrence extends TaskOccurrence {
  const _TaskOccurrence({required this.id, required this.taskId, required this.scheduledDate, this.windowStart, this.windowEnd, this.status = OccurrenceStatus.pending, this.originalDate, this.completedAt, this.actualDurationMinutes, this.pinned = false}): super._();
  factory _TaskOccurrence.fromJson(Map<String, dynamic> json) => _$TaskOccurrenceFromJson(json);

@override final  String id;
@override final  String taskId;
/// The day this occurrence is currently planned for.
@override final  DateTime scheduledDate;
/// For flexible recurrences, the inclusive window the occurrence may move
/// within before it is considered overdue.
@override final  DateTime? windowStart;
@override final  DateTime? windowEnd;
@override@JsonKey() final  OccurrenceStatus status;
/// The day this occurrence was first planned for, preserved across
/// reschedules so we can reason about how far it has slipped.
@override final  DateTime? originalDate;
/// When the user marked it done.
@override final  DateTime? completedAt;
/// How long the user reported it actually took. Feeds effort learning so
/// future scheduling can be more realistic.
@override final  int? actualDurationMinutes;
/// Set when the user has *deliberately* placed this occurrence on a day
/// (e.g. dragged it on the agenda). The load balancer leaves pinned
/// occurrences where they are rather than spreading them.
@override@JsonKey() final  bool pinned;

/// Create a copy of TaskOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskOccurrenceCopyWith<_TaskOccurrence> get copyWith => __$TaskOccurrenceCopyWithImpl<_TaskOccurrence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskOccurrenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskOccurrence&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.status, status) || other.status == status)&&(identical(other.originalDate, originalDate) || other.originalDate == originalDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.actualDurationMinutes, actualDurationMinutes) || other.actualDurationMinutes == actualDurationMinutes)&&(identical(other.pinned, pinned) || other.pinned == pinned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,scheduledDate,windowStart,windowEnd,status,originalDate,completedAt,actualDurationMinutes,pinned);

@override
String toString() {
  return 'TaskOccurrence(id: $id, taskId: $taskId, scheduledDate: $scheduledDate, windowStart: $windowStart, windowEnd: $windowEnd, status: $status, originalDate: $originalDate, completedAt: $completedAt, actualDurationMinutes: $actualDurationMinutes, pinned: $pinned)';
}


}

/// @nodoc
abstract mixin class _$TaskOccurrenceCopyWith<$Res> implements $TaskOccurrenceCopyWith<$Res> {
  factory _$TaskOccurrenceCopyWith(_TaskOccurrence value, $Res Function(_TaskOccurrence) _then) = __$TaskOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskId, DateTime scheduledDate, DateTime? windowStart, DateTime? windowEnd, OccurrenceStatus status, DateTime? originalDate, DateTime? completedAt, int? actualDurationMinutes, bool pinned
});




}
/// @nodoc
class __$TaskOccurrenceCopyWithImpl<$Res>
    implements _$TaskOccurrenceCopyWith<$Res> {
  __$TaskOccurrenceCopyWithImpl(this._self, this._then);

  final _TaskOccurrence _self;
  final $Res Function(_TaskOccurrence) _then;

/// Create a copy of TaskOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? scheduledDate = null,Object? windowStart = freezed,Object? windowEnd = freezed,Object? status = null,Object? originalDate = freezed,Object? completedAt = freezed,Object? actualDurationMinutes = freezed,Object? pinned = null,}) {
  return _then(_TaskOccurrence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,windowStart: freezed == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime?,windowEnd: freezed == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OccurrenceStatus,originalDate: freezed == originalDate ? _self.originalDate : originalDate // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actualDurationMinutes: freezed == actualDurationMinutes ? _self.actualDurationMinutes : actualDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
