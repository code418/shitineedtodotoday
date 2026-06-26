// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_occurrence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskOccurrence _$TaskOccurrenceFromJson(Map<String, dynamic> json) =>
    _TaskOccurrence(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      windowStart: json['windowStart'] == null
          ? null
          : DateTime.parse(json['windowStart'] as String),
      windowEnd: json['windowEnd'] == null
          ? null
          : DateTime.parse(json['windowEnd'] as String),
      status:
          $enumDecodeNullable(_$OccurrenceStatusEnumMap, json['status']) ??
          OccurrenceStatus.pending,
      originalDate: json['originalDate'] == null
          ? null
          : DateTime.parse(json['originalDate'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      actualDurationMinutes: (json['actualDurationMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TaskOccurrenceToJson(_TaskOccurrence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'scheduledDate': instance.scheduledDate.toIso8601String(),
      'windowStart': instance.windowStart?.toIso8601String(),
      'windowEnd': instance.windowEnd?.toIso8601String(),
      'status': _$OccurrenceStatusEnumMap[instance.status]!,
      'originalDate': instance.originalDate?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'actualDurationMinutes': instance.actualDurationMinutes,
    };

const _$OccurrenceStatusEnumMap = {
  OccurrenceStatus.pending: 'pending',
  OccurrenceStatus.done: 'done',
  OccurrenceStatus.skipped: 'skipped',
  OccurrenceStatus.rescheduled: 'rescheduled',
};
