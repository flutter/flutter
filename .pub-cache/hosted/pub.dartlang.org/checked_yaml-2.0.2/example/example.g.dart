// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Configuration _$ConfigurationFromJson(Map json) => $checkedCreate(
      'Configuration',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['name', 'count'],
          requiredKeys: const ['name'],
        );
        final val = Configuration(
          name: $checkedConvert('name', (v) => v as String),
          count: $checkedConvert('count', (v) => v as int),
        );
        return val;
      },
    );

Map<String, dynamic> _$ConfigurationToJson(Configuration instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
    };
