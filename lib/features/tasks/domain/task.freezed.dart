// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id;/// The owning user's uid (anonymous or upgraded account).
 String get ownerId; String get title; String get notes;/// Optional grouping such as a room or zone ("Kitchen", "Bathroom").
 String? get category;/// How often this task needs doing — strict or fuzzy.
 Recurrence get recurrence;/// Best current estimate of how long it takes, in minutes. Seeded on
/// creation and refined from recorded actuals
/// ([TaskOccurrence.actualDurationMinutes]) over time.
 int get estimatedEffortMinutes; TaskPriority get priority;/// Household member this task is currently assigned to ("whose turn"), or
/// null for unassigned / anyone.
 String? get assigneeId;/// Preferred reminder time as `HH:mm` (local). Drives the future
/// server-side FCM reminder scheduling.
 String? get reminderTimeOfDay; bool get isActive; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.category, category) || other.category == category)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.estimatedEffortMinutes, estimatedEffortMinutes) || other.estimatedEffortMinutes == estimatedEffortMinutes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.reminderTimeOfDay, reminderTimeOfDay) || other.reminderTimeOfDay == reminderTimeOfDay)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,notes,category,recurrence,estimatedEffortMinutes,priority,assigneeId,reminderTimeOfDay,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, ownerId: $ownerId, title: $title, notes: $notes, category: $category, recurrence: $recurrence, estimatedEffortMinutes: $estimatedEffortMinutes, priority: $priority, assigneeId: $assigneeId, reminderTimeOfDay: $reminderTimeOfDay, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String title, String notes, String? category, Recurrence recurrence, int estimatedEffortMinutes, TaskPriority priority, String? assigneeId, String? reminderTimeOfDay, bool isActive, DateTime createdAt, DateTime updatedAt
});


$RecurrenceCopyWith<$Res> get recurrence;

}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? notes = null,Object? category = freezed,Object? recurrence = null,Object? estimatedEffortMinutes = null,Object? priority = null,Object? assigneeId = freezed,Object? reminderTimeOfDay = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,estimatedEffortMinutes: null == estimatedEffortMinutes ? _self.estimatedEffortMinutes : estimatedEffortMinutes // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,reminderTimeOfDay: freezed == reminderTimeOfDay ? _self.reminderTimeOfDay : reminderTimeOfDay // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<$Res> get recurrence {
  
  return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String title,  String notes,  String? category,  Recurrence recurrence,  int estimatedEffortMinutes,  TaskPriority priority,  String? assigneeId,  String? reminderTimeOfDay,  bool isActive,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.notes,_that.category,_that.recurrence,_that.estimatedEffortMinutes,_that.priority,_that.assigneeId,_that.reminderTimeOfDay,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String title,  String notes,  String? category,  Recurrence recurrence,  int estimatedEffortMinutes,  TaskPriority priority,  String? assigneeId,  String? reminderTimeOfDay,  bool isActive,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.ownerId,_that.title,_that.notes,_that.category,_that.recurrence,_that.estimatedEffortMinutes,_that.priority,_that.assigneeId,_that.reminderTimeOfDay,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String title,  String notes,  String? category,  Recurrence recurrence,  int estimatedEffortMinutes,  TaskPriority priority,  String? assigneeId,  String? reminderTimeOfDay,  bool isActive,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.notes,_that.category,_that.recurrence,_that.estimatedEffortMinutes,_that.priority,_that.assigneeId,_that.reminderTimeOfDay,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task extends Task {
  const _Task({required this.id, required this.ownerId, required this.title, this.notes = '', this.category, required this.recurrence, this.estimatedEffortMinutes = 15, this.priority = TaskPriority.normal, this.assigneeId, this.reminderTimeOfDay, this.isActive = true, required this.createdAt, required this.updatedAt}): super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
/// The owning user's uid (anonymous or upgraded account).
@override final  String ownerId;
@override final  String title;
@override@JsonKey() final  String notes;
/// Optional grouping such as a room or zone ("Kitchen", "Bathroom").
@override final  String? category;
/// How often this task needs doing — strict or fuzzy.
@override final  Recurrence recurrence;
/// Best current estimate of how long it takes, in minutes. Seeded on
/// creation and refined from recorded actuals
/// ([TaskOccurrence.actualDurationMinutes]) over time.
@override@JsonKey() final  int estimatedEffortMinutes;
@override@JsonKey() final  TaskPriority priority;
/// Household member this task is currently assigned to ("whose turn"), or
/// null for unassigned / anyone.
@override final  String? assigneeId;
/// Preferred reminder time as `HH:mm` (local). Drives the future
/// server-side FCM reminder scheduling.
@override final  String? reminderTimeOfDay;
@override@JsonKey() final  bool isActive;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.category, category) || other.category == category)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.estimatedEffortMinutes, estimatedEffortMinutes) || other.estimatedEffortMinutes == estimatedEffortMinutes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.reminderTimeOfDay, reminderTimeOfDay) || other.reminderTimeOfDay == reminderTimeOfDay)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,notes,category,recurrence,estimatedEffortMinutes,priority,assigneeId,reminderTimeOfDay,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, ownerId: $ownerId, title: $title, notes: $notes, category: $category, recurrence: $recurrence, estimatedEffortMinutes: $estimatedEffortMinutes, priority: $priority, assigneeId: $assigneeId, reminderTimeOfDay: $reminderTimeOfDay, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String title, String notes, String? category, Recurrence recurrence, int estimatedEffortMinutes, TaskPriority priority, String? assigneeId, String? reminderTimeOfDay, bool isActive, DateTime createdAt, DateTime updatedAt
});


@override $RecurrenceCopyWith<$Res> get recurrence;

}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? notes = null,Object? category = freezed,Object? recurrence = null,Object? estimatedEffortMinutes = null,Object? priority = null,Object? assigneeId = freezed,Object? reminderTimeOfDay = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,estimatedEffortMinutes: null == estimatedEffortMinutes ? _self.estimatedEffortMinutes : estimatedEffortMinutes // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,reminderTimeOfDay: freezed == reminderTimeOfDay ? _self.reminderTimeOfDay : reminderTimeOfDay // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<$Res> get recurrence {
  
  return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}

// dart format on
