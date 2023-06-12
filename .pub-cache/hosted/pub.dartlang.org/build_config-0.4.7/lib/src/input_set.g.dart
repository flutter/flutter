// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InputSet _$InputSetFromJson(Map json) {
  return $checkedNew('InputSet', json, () {
    $checkKeys(json, allowedKeys: const ['include', 'exclude']);
    final val = InputSet(
      include: $checkedConvert(json, 'include',
          (v) => (v as List)?.map((e) => e as String)?.toList()),
      exclude: $checkedConvert(json, 'exclude',
          (v) => (v as List)?.map((e) => e as String)?.toList()),
    );
    return val;
  });
}
