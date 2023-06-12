// GENERATED CODE - DO NOT MODIFY BY HAND

part of build_runner.src.generate.performance_tracker;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildPerformance _$BuildPerformanceFromJson(Map<String, dynamic> json) {
  return BuildPerformance(
      (json['phases'] as List)?.map((e) => e == null
          ? null
          : BuildPhasePerformance.fromJson(e as Map<String, dynamic>)),
      (json['actions'] as List)?.map((e) => e == null
          ? null
          : BuilderActionPerformance.fromJson(e as Map<String, dynamic>)),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuildPerformanceToJson(BuildPerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'phases': instance.phases?.toList(),
      'actions': instance.actions?.toList()
    };

BuildPhasePerformance _$BuildPhasePerformanceFromJson(
    Map<String, dynamic> json) {
  return BuildPhasePerformance(
      (json['builderKeys'] as List)?.map((e) => e as String)?.toList(),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuildPhasePerformanceToJson(
        BuildPhasePerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'builderKeys': instance.builderKeys
    };

BuilderActionPerformance _$BuilderActionPerformanceFromJson(
    Map<String, dynamic> json) {
  return BuilderActionPerformance(
      json['builderKey'] as String,
      _assetIdFromJson(json['primaryInput'] as String),
      (json['stages'] as List)?.map((e) => e == null
          ? null
          : BuilderActionStagePerformance.fromJson(e as Map<String, dynamic>)),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuilderActionPerformanceToJson(
        BuilderActionPerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'builderKey': instance.builderKey,
      'primaryInput': _assetIdToJson(instance.primaryInput),
      'stages': instance.stages?.toList()
    };

BuilderActionStagePerformance _$BuilderActionStagePerformanceFromJson(
    Map<String, dynamic> json) {
  return BuilderActionStagePerformance(
      json['label'] as String,
      (json['slices'] as List)
          ?.map((e) =>
              e == null ? null : TimeSlice.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$BuilderActionStagePerformanceToJson(
        BuilderActionStagePerformance instance) =>
    <String, dynamic>{'slices': instance.slices, 'label': instance.label};
