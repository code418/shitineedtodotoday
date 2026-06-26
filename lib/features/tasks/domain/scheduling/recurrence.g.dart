// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrictRecurrence _$StrictRecurrenceFromJson(Map<String, dynamic> json) =>
    StrictRecurrence(
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      exactDate: json['exactDate'] == null
          ? null
          : DateTime.parse(json['exactDate'] as String),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$StrictRecurrenceToJson(StrictRecurrence instance) =>
    <String, dynamic>{
      'weekdays': instance.weekdays,
      'dayOfMonth': instance.dayOfMonth,
      'exactDate': instance.exactDate?.toIso8601String(),
      'runtimeType': instance.$type,
    };

FlexibleRecurrence _$FlexibleRecurrenceFromJson(Map<String, dynamic> json) =>
    FlexibleRecurrence(
      timesPerPeriod: (json['timesPerPeriod'] as num?)?.toInt() ?? 1,
      period:
          $enumDecodeNullable(_$FrequencyPeriodEnumMap, json['period']) ??
          FrequencyPeriod.week,
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 0,
      season: $enumDecodeNullable(_$SeasonEnumMap, json['season']),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$FlexibleRecurrenceToJson(FlexibleRecurrence instance) =>
    <String, dynamic>{
      'timesPerPeriod': instance.timesPerPeriod,
      'period': _$FrequencyPeriodEnumMap[instance.period]!,
      'windowDays': instance.windowDays,
      'season': _$SeasonEnumMap[instance.season],
      'runtimeType': instance.$type,
    };

const _$FrequencyPeriodEnumMap = {
  FrequencyPeriod.day: 'day',
  FrequencyPeriod.week: 'week',
  FrequencyPeriod.month: 'month',
  FrequencyPeriod.year: 'year',
};

const _$SeasonEnumMap = {
  Season.spring: 'spring',
  Season.summer: 'summer',
  Season.autumn: 'autumn',
  Season.winter: 'winter',
};
