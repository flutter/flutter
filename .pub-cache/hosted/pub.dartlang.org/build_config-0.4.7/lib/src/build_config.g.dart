// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map json) {
  return $checkedNew('BuildConfig', json, () {
    $checkKeys(json, allowedKeys: const [
      'builders',
      'post_process_builders',
      'targets',
      'global_options',
      'additional_public_assets'
    ]);
    final val = BuildConfig(
      buildTargets: $checkedConvert(
          json, 'targets', (v) => _buildTargetsFromJson(v as Map)),
      globalOptions: $checkedConvert(
          json,
          'global_options',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    e == null ? null : GlobalBuilderConfig.fromJson(e as Map)),
              )),
      builderDefinitions: $checkedConvert(
          json,
          'builders',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    e == null ? null : BuilderDefinition.fromJson(e as Map)),
              )),
      postProcessBuilderDefinitions: $checkedConvert(
          json,
          'post_process_builders',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(
                    k as String,
                    e == null
                        ? null
                        : PostProcessBuilderDefinition.fromJson(e as Map)),
              )),
      additionalPublicAssets: $checkedConvert(json, 'additional_public_assets',
          (v) => (v as List)?.map((e) => e as String)?.toList()),
    );
    return val;
  }, fieldKeyMap: const {
    'buildTargets': 'targets',
    'globalOptions': 'global_options',
    'builderDefinitions': 'builders',
    'postProcessBuilderDefinitions': 'post_process_builders',
    'additionalPublicAssets': 'additional_public_assets'
  });
}
