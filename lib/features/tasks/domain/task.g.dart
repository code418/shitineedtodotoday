// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  title: json['title'] as String,
  notes: json['notes'] as String? ?? '',
  category: json['category'] as String?,
  recurrence: Recurrence.fromJson(json['recurrence'] as Map<String, dynamic>),
  estimatedEffortMinutes:
      (json['estimatedEffortMinutes'] as num?)?.toInt() ?? 15,
  priority:
      $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
      TaskPriority.normal,
  assigneeId: json['assigneeId'] as String?,
  reminderTimeOfDay: json['reminderTimeOfDay'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'title': instance.title,
  'notes': instance.notes,
  'category': instance.category,
  'recurrence': instance.recurrence.toJson(),
  'estimatedEffortMinutes': instance.estimatedEffortMinutes,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'assigneeId': instance.assigneeId,
  'reminderTimeOfDay': instance.reminderTimeOfDay,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 'low',
  TaskPriority.normal: 'normal',
  TaskPriority.high: 'high',
};
