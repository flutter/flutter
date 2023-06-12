// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuilderDefinition _$BuilderDefinitionFromJson(Map json) {
  return $checkedNew('BuilderDefinition', json, () {
    $checkKeys(json, allowedKeys: const [
      'builder_factories',
      'import',
      'build_extensions',
      'target',
      'auto_apply',
      'required_inputs',
      'runs_before',
      'applies_builders',
      'is_optional',
      'build_to',
      'defaults'
    ], requiredKeys: const [
      'builder_factories',
      'import',
      'build_extensions'
    ], disallowNullValues: const [
      'builder_factories',
      'import',
      'build_extensions'
    ]);
    final val = BuilderDefinition(
      builderFactories: $checkedConvert(json, 'builder_factories',
          (v) => (v as List).map((e) => e as String).toList()),
      buildExtensions: $checkedConvert(
          json,
          'build_extensions',
          (v) => (v as Map).map(
                (k, e) => MapEntry(
                    k as String, (e as List).map((e) => e as String).toList()),
              )),
      import: $checkedConvert(json, 'import', (v) => v as String),
      target: $checkedConvert(json, 'target', (v) => v as String),
      autoApply: $checkedConvert(json, 'auto_apply',
          (v) => _$enumDecodeNullable(_$AutoApplyEnumMap, v)),
      requiredInputs: $checkedConvert(
          json, 'required_inputs', (v) => (v as List)?.map((e) => e as String)),
      runsBefore: $checkedConvert(
          json, 'runs_before', (v) => (v as List)?.map((e) => e as String)),
      appliesBuilders: $checkedConvert(json, 'applies_builders',
          (v) => (v as List)?.map((e) => e as String)),
      isOptional: $checkedConvert(json, 'is_optional', (v) => v as bool),
      buildTo: $checkedConvert(
          json, 'build_to', (v) => _$enumDecodeNullable(_$BuildToEnumMap, v)),
      defaults: $checkedConvert(
          json,
          'defaults',
          (v) => v == null
              ? null
              : TargetBuilderConfigDefaults.fromJson(v as Map)),
    );
    return val;
  }, fieldKeyMap: const {
    'builderFactories': 'builder_factories',
    'buildExtensions': 'build_extensions',
    'autoApply': 'auto_apply',
    'requiredInputs': 'required_inputs',
    'runsBefore': 'runs_before',
    'appliesBuilders': 'applies_builders',
    'isOptional': 'is_optional',
    'buildTo': 'build_to'
  });
}

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$AutoApplyEnumMap = {
  AutoApply.none: 'none',
  AutoApply.dependents: 'dependents',
  AutoApply.allPackages: 'all_packages',
  AutoApply.rootPackage: 'root_package',
};

const _$BuildToEnumMap = {
  BuildTo.source: 'source',
  BuildTo.cache: 'cache',
};

PostProcessBuilderDefinition _$PostProcessBuilderDefinitionFromJson(Map json) {
  return $checkedNew('PostProcessBuilderDefinition', json, () {
    $checkKeys(json, allowedKeys: const [
      'builder_factory',
      'import',
      'input_extensions',
      'target',
      'defaults'
    ], requiredKeys: const [
      'builder_factory',
      'import'
    ], disallowNullValues: const [
      'builder_factory',
      'import'
    ]);
    final val = PostProcessBuilderDefinition(
      builderFactory:
          $checkedConvert(json, 'builder_factory', (v) => v as String),
      import: $checkedConvert(json, 'import', (v) => v as String),
      inputExtensions: $checkedConvert(json, 'input_extensions',
          (v) => (v as List)?.map((e) => e as String)),
      target: $checkedConvert(json, 'target', (v) => v as String),
      defaults: $checkedConvert(
          json,
          'defaults',
          (v) => v == null
              ? null
              : TargetBuilderConfigDefaults.fromJson(v as Map)),
    );
    return val;
  }, fieldKeyMap: const {
    'builderFactory': 'builder_factory',
    'inputExtensions': 'input_extensions'
  });
}

TargetBuilderConfigDefaults _$TargetBuilderConfigDefaultsFromJson(Map json) {
  return $checkedNew('TargetBuilderConfigDefaults', json, () {
    $checkKeys(json, allowedKeys: const [
      'generate_for',
      'options',
      'dev_options',
      'release_options'
    ]);
    final val = TargetBuilderConfigDefaults(
      generateFor: $checkedConvert(
          json, 'generate_for', (v) => v == null ? null : InputSet.fromJson(v)),
      options: $checkedConvert(
          json,
          'options',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )),
      devOptions: $checkedConvert(
          json,
          'dev_options',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )),
      releaseOptions: $checkedConvert(
          json,
          'release_options',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )),
    );
    return val;
  }, fieldKeyMap: const {
    'generateFor': 'generate_for',
    'devOptions': 'dev_options',
    'releaseOptions': 'release_options'
  });
}
