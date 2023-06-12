// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSlice _$TimeSliceFromJson(Map<String, dynamic> json) {
  return TimeSlice(
    DateTime.parse(json['startTime'] as String),
    DateTime.parse(json['stopTime'] as String),
  );
}

Map<String, dynamic> _$TimeSliceToJson(TimeSlice instance) => <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'stopTime': instance.stopTime.toIso8601String(),
    };

TimeSliceGroup _$TimeSliceGroupFromJson(Map<String, dynamic> json) {
  return TimeSliceGroup(
    (json['slices'] as List<dynamic>)
        .map((e) => TimeSlice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$TimeSliceGroupToJson(TimeSliceGroup instance) =>
    <String, dynamic>{
      'slices': instance.slices,
    };
