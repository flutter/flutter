import 'package:yaml/yaml.dart';


const String _kAndroidModuleKey = 'android';
const String _kIosModuleKey = 'ios';

class Module {
  static List<String> validateModuleYaml(YamlMap? yaml) {
    if (yaml == null) {
      return <String>['Invalid "module" specification.'];
    }

    final bool usesOldModuleFormat = const <String>{
      'androidX',
      'androidPackage',
      'iosBundleIdentifier',
    }.any(yaml.containsKey);

    final bool usesNewModuleFormat = yaml.containsKey('platforms');

    if (usesOldModuleFormat && usesNewModuleFormat) {
      const String errorMessage =
          'The flutter.module.platforms key cannot be used in combination with the old '
          'flutter.module.{androidX,androidPackage,iosBundleIdentifier} keys. '
          'See: https://flutter.dev/docs/development/add-to-app/developing-modules#module';
      return <String>[errorMessage];
    }

    if (!usesOldModuleFormat && !usesNewModuleFormat) {
      const String errorMessage =
          'Cannot find the `flutter.module.platforms` key in the `pubspec.yaml` file. '
          'An instruction to format the `pubspec.yaml` can be found here: '
          'https://flutter.dev/docs/development/add-to-app/developing-modules#module-platforms';
      return <String>[errorMessage];
    }

    if (usesNewModuleFormat) {
      if (yaml['platforms'] != null && yaml['platforms'] is! YamlMap) {
        const String errorMessage =
            'flutter.module.platforms should be a map with the platform name as the key';
        return <String>[errorMessage];
      }
      return _validateMultiPlatformYaml(yaml['platforms'] as YamlMap?);
    } else {
      return _validateLegacyYaml(yaml);
    }
  }

  static void _validateKey<T extends Object>(YamlMap yaml, List<String> errors, String key) {
    if (yaml[key] != null && yaml[key] is! T) {
      errors.add('The "$key" value must be a ${T.runtimeType} if set.');
    }
  }

  static List<String> _validateMultiPlatformYaml(YamlMap? yaml) {
    void validatePlatform(List<String> errors, String platform, void Function(YamlMap yaml, List<String> errors) validate) {
      if (!yaml!.containsKey(platform)) {
        return;
      }
      final dynamic yamlValue = yaml[platform];
      if (yamlValue is! YamlMap) {
        errors.add('Invalid "$platform" module specification.');
        return;
      }

      validate(yamlValue, errors);
    }

    if (yaml == null) {
      return <String>['Invalid "platforms" specification in flutter.module'];
    }

    final List<String> errors = <String>[];

    validatePlatform(errors, _kAndroidModuleKey, _androidModuleValidate);
    validatePlatform(errors, _kIosModuleKey, _iOSModuleValidate);

    return errors;
  }

  static List<String> _validateLegacyYaml(YamlMap yaml) {
    final List<String> errors = <String>[];

    _validateKey<bool>(yaml, errors, 'androidX');
    _validateKey<String>(yaml, errors, 'androidPackage');
    _validateKey<String>(yaml, errors, 'iosBundleIdentifier');

    return errors;
  }

  static void _androidModuleValidate(YamlMap yaml, List<String> errors) {
    _validateKey<bool>(yaml, errors, 'androidX');
    _validateKey<String>(yaml, errors, 'package');
  }

  static void _iOSModuleValidate(YamlMap yaml, List<String> errors) {
    _validateKey<String>(yaml, errors, 'bundleIdentifier');
  }
}
