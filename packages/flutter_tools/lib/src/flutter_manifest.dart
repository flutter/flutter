// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'base/deferred_component.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'plugins.dart';

const Set<String> _kValidPluginPlatforms = <String>{
  'android', 'ios', 'web', 'windows', 'linux', 'macos'
};

/// A wrapper around the `flutter` section in the `pubspec.yaml` file.
class FlutterManifest {
  FlutterManifest._({required Logger logger}) : _logger = logger;

  /// Returns an empty manifest.
  factory FlutterManifest.empty({ required Logger logger }) = FlutterManifest._;

  /// Returns null on invalid manifest. Returns empty manifest on missing file.
  static FlutterManifest? createFromPath(String path, {
    required FileSystem fileSystem,
    required Logger logger,
  }) {
    if (path == null || !fileSystem.isFileSync(path)) {
      return _createFromYaml(null, logger);
    }
    final String manifest = fileSystem.file(path).readAsStringSync();
    return FlutterManifest.createFromString(manifest, logger: logger);
  }

  /// Returns null on missing or invalid manifest.
  @visibleForTesting
  static FlutterManifest? createFromString(String manifest, { required Logger logger }) {
    return _createFromYaml(manifest != null ? loadYaml(manifest) : null, logger);
  }

  static FlutterManifest? _createFromYaml(Object? yamlDocument, Logger logger) {
    if (yamlDocument != null && !_validate(yamlDocument, logger)) {
      return null;
    }

    final FlutterManifest pubspec = FlutterManifest._(logger: logger);
    final Map<Object?, Object?>? yamlMap = yamlDocument as YamlMap?;
    if (yamlMap != null) {
      pubspec._descriptor = yamlMap.cast<String, Object?>();
    }

    final Map<Object?, Object?>? flutterMap = pubspec._descriptor['flutter'] as Map<Object?, Object?>?;
    if (flutterMap != null) {
      pubspec._flutterDescriptor = flutterMap.cast<String, Object?>();
    }

    return pubspec;
  }

  final Logger _logger;

  /// A map representation of the entire `pubspec.yaml` file.
  Map<String, Object?> _descriptor = <String, Object?>{};

  /// A map representation of the `flutter` section in the `pubspec.yaml` file.
  Map<String, Object?> _flutterDescriptor = <String, Object?>{};

  /// True if the `pubspec.yaml` file does not exist.
  bool get isEmpty => _descriptor.isEmpty;

  /// The string value of the top-level `name` property in the `pubspec.yaml` file.
  String get appName => _descriptor['name'] as String? ?? '';

  /// Contains the name of the dependencies.
  /// These are the keys specified in the `dependency` map.
  Set<String> get dependencies {
    final YamlMap? dependencies = _descriptor['dependencies'] as YamlMap?;
    return dependencies != null ? <String>{...dependencies.keys.cast<String>()} : <String>{};
  }

  // Flag to avoid printing multiple invalid version messages.
  bool _hasShowInvalidVersionMsg = false;

  /// The version String from the `pubspec.yaml` file.
  /// Can be null if it isn't set or has a wrong format.
  String? get appVersion {
    final String? verStr = _descriptor['version']?.toString();
    if (verStr == null) {
      return null;
    }

    Version? version;
    try {
      version = Version.parse(verStr);
    } on Exception {
      if (!_hasShowInvalidVersionMsg) {
        _logger.printStatus(userMessages.invalidVersionSettingHintMessage(verStr), emphasis: true);
        _hasShowInvalidVersionMsg = true;
      }
    }
    return version?.toString();
  }

  /// The build version name from the `pubspec.yaml` file.
  /// Can be null if version isn't set or has a wrong format.
  String? get buildName {
    final String? version = appVersion;
    if (version != null && version.contains('+')) {
      return version.split('+').elementAt(0);
    }
    return version;
  }

  /// The build version number from the `pubspec.yaml` file.
  /// Can be null if version isn't set or has a wrong format.
  String? get buildNumber {
    final String? version = appVersion;
    if (version != null && version.contains('+')) {
      final String value = version.split('+').elementAt(1);
      return value;
    } else {
      return null;
    }
  }

  bool get usesMaterialDesign {
    return _flutterDescriptor['uses-material-design'] as bool? ?? false;
  }

  /// True if this Flutter module should use AndroidX dependencies.
  ///
  /// If false the deprecated Android Support library will be used.
  bool get usesAndroidX {
    final Object? module = _flutterDescriptor['module'];
    if (module is YamlMap) {
      return module['androidX'] == true;
    }
    return false;
  }

  /// Any additional license files listed under the `flutter` key.
  ///
  /// This is expected to be a list of file paths that should be treated as
  /// relative to the pubspec in this directory.
  ///
  /// For example:
  ///
  /// ```yaml
  /// flutter:
  ///   licenses:
  ///     - assets/foo_license.txt
  /// ```
  List<String> get additionalLicenses {
    final Object? licenses = _flutterDescriptor['licenses'];
    if (licenses is YamlList) {
      return licenses.map((Object? element) => element.toString()).toList();
    }
    return <String>[];
  }

  /// True if this manifest declares a Flutter module project.
  ///
  /// A Flutter project is considered a module when it has a `module:`
  /// descriptor. A Flutter module project supports integration into an
  /// existing host app, and has managed platform host code.
  ///
  /// Such a project can be created using `flutter create -t module`.
  bool get isModule => _flutterDescriptor.containsKey('module');

  /// True if this manifest declares a Flutter plugin project.
  ///
  /// A Flutter project is considered a plugin when it has a `plugin:`
  /// descriptor. A Flutter plugin project wraps custom Android and/or
  /// iOS code in a Dart interface for consumption by other Flutter app
  /// projects.
  ///
  /// Such a project can be created using `flutter create -t plugin`.
  bool get isPlugin => _flutterDescriptor.containsKey('plugin');

  /// Returns the Android package declared by this manifest in its
  /// module or plugin descriptor. Returns null, if there is no
  /// such declaration.
  String? get androidPackage {
    if (isModule) {
      final Object? module = _flutterDescriptor['module'];
      if (module is YamlMap) {
        return module['androidPackage'] as String?;
      }
    }
    final Map<String, Object?>? platforms = supportedPlatforms;
    if (platforms == null) {
      // Pre-multi-platform plugin format
      if (isPlugin) {
        final YamlMap? plugin = _flutterDescriptor['plugin'] as YamlMap?;
        return plugin?['androidPackage'] as String?;
      }
      return null;
    }
    if (platforms.containsKey('android')) {
      final Object? android = platforms['android'];
      if (android is YamlMap) {
        return android['package'] as String?;
      }
    }
    return null;
  }

  /// Returns the deferred components configuration if declared. Returns
  /// null if no deferred components are declared.
  late final List<DeferredComponent>? deferredComponents = computeDeferredComponents();
  List<DeferredComponent>? computeDeferredComponents() {
    if (!_flutterDescriptor.containsKey('deferred-components')) {
      return null;
    }
    final List<DeferredComponent> components = <DeferredComponent>[];
    final Object? deferredComponents = _flutterDescriptor['deferred-components'];
    if (deferredComponents is! YamlList) {
      return components;
    }
    for (final Object? component in deferredComponents) {
      if (component is! YamlMap) {
        _logger.printError('Expected deferred component manifest to be a map.');
        continue;
      }
      List<Uri> assetsUri = <Uri>[];
      final List<Object?>? assets = component['assets'] as List<Object?>?;
      if (assets == null) {
        assetsUri = const <Uri>[];
      } else {
        for (final Object? asset in assets) {
          if (asset is! String || asset == null || asset == '') {
            _logger.printError('Deferred component asset manifest contains a null or empty uri.');
            continue;
          }
          try {
            assetsUri.add(Uri.parse(asset));
          } on FormatException {
            _logger.printError('Asset manifest contains invalid uri: $asset.');
          }
        }
      }
      components.add(
        DeferredComponent(
          name: component['name'] as String,
          libraries: component['libraries'] == null ?
              <String>[] : (component['libraries'] as List<dynamic>).cast<String>(),
          assets: assetsUri,
        )
      );
    }
    return components;
  }

  /// Returns the iOS bundle identifier declared by this manifest in its
  /// module descriptor. Returns null if there is no such declaration.
  String? get iosBundleIdentifier {
    if (isModule) {
      final Object? module = _flutterDescriptor['module'];
      if (module is YamlMap) {
        return module['iosBundleIdentifier'] as String?;
      }
    }
    return null;
  }

  /// Gets the supported platforms. This only supports the new `platforms` format.
  ///
  /// If the plugin uses the legacy pubspec format, this method returns null.
  Map<String, Object?>? get supportedPlatforms {
    if (isPlugin) {
      final YamlMap? plugin = _flutterDescriptor['plugin'] as YamlMap?;
      if (plugin?.containsKey('platforms') ?? false) {
        final YamlMap? platformsMap = plugin!['platforms'] as YamlMap?;
        return platformsMap?.value.cast<String, Object?>();
      }
    }
    return null;
  }

  /// Like [supportedPlatforms], but only returns the valid platforms that are supported in flutter plugins.
  Map<String, Object?>? get validSupportedPlatforms {
    final Map<String, Object?>? allPlatforms = supportedPlatforms;
    if (allPlatforms == null) {
      return null;
    }
    final Map<String, Object?> platforms = <String, Object?>{}..addAll(allPlatforms);
    platforms.removeWhere((String key, Object? _) => !_kValidPluginPlatforms.contains(key));
    if (platforms.isEmpty) {
      return null;
    }
    return platforms;
  }

  List<Map<String, Object?>> get fontsDescriptor {
    return fonts.map((Font font) => font.descriptor).toList();
  }

  List<Map<String, Object?>> get _rawFontsDescriptor {
    final List<Object?>? fontList = _flutterDescriptor['fonts'] as List<Object?>?;
    return fontList == null
        ? const <Map<String, Object?>>[]
        : fontList.map<Map<String, Object?>?>(castStringKeyedMap).whereType<Map<String, Object?>>().toList();
  }

  late final List<Uri> assets = _computeAssets();
  List<Uri> _computeAssets() {
    final List<Object?>? assets = _flutterDescriptor['assets'] as List<Object?>?;
    if (assets == null) {
      return const <Uri>[];
    }
    final List<Uri> results = <Uri>[];
    for (final Object? asset in assets) {
      if (asset is! String || asset == null || asset == '') {
        _logger.printError('Asset manifest contains a null or empty uri.');
        continue;
      }
      try {
        results.add(Uri(pathSegments: asset.split('/')));
      } on FormatException {
        _logger.printError('Asset manifest contains invalid uri: $asset.');
      }
    }
    return results;
  }

  late final List<Font> fonts = _extractFonts();

  List<Font> _extractFonts() {
    if (!_flutterDescriptor.containsKey('fonts')) {
      return <Font>[];
    }

    final List<Font> fonts = <Font>[];
    for (final Map<String, Object?> fontFamily in _rawFontsDescriptor) {
      final YamlList? fontFiles = fontFamily['fonts'] as YamlList?;
      final String? familyName = fontFamily['family'] as String?;
      if (familyName == null) {
        _logger.printWarning('Warning: Missing family name for font.', emphasis: true);
        continue;
      }
      if (fontFiles == null) {
        _logger.printWarning('Warning: No fonts specified for font $familyName', emphasis: true);
        continue;
      }

      final List<FontAsset> fontAssets = <FontAsset>[];
      for (final Map<Object?, Object?> fontFile in fontFiles.cast<Map<Object?, Object?>>()) {
        final String? asset = fontFile['asset'] as String?;
        if (asset == null) {
          _logger.printWarning('Warning: Missing asset in fonts for $familyName', emphasis: true);
          continue;
        }

        fontAssets.add(FontAsset(
          Uri.parse(asset),
          weight: fontFile['weight'] as int?,
          style: fontFile['style'] as String?,
        ));
      }
      if (fontAssets.isNotEmpty) {
        fonts.add(Font(familyName, fontAssets));
      }
    }
    return fonts;
  }

  /// Whether a synthetic flutter_gen package should be generated.
  ///
  /// This can be provided to the [Pub] interface to inject a new entry
  /// into the package_config.json file which points to `.dart_tool/flutter_gen`.
  ///
  /// This allows generated source code to be imported using a package
  /// alias.
  late final bool generateSyntheticPackage = _computeGenerateSyntheticPackage();
  bool _computeGenerateSyntheticPackage() {
    if (!_flutterDescriptor.containsKey('generate')) {
      return false;
    }
    final Object? value = _flutterDescriptor['generate'];
    if (value is! bool) {
      return false;
    }
    return value;
  }
}

class Font {
  Font(this.familyName, this.fontAssets)
    : assert(familyName != null),
      assert(fontAssets != null),
      assert(fontAssets.isNotEmpty);

  final String familyName;
  final List<FontAsset> fontAssets;

  Map<String, Object?> get descriptor {
    return <String, Object?>{
      'family': familyName,
      'fonts': fontAssets.map<Map<String, Object?>>((FontAsset a) => a.descriptor).toList(),
    };
  }

  @override
  String toString() => '$runtimeType(family: $familyName, assets: $fontAssets)';
}

class FontAsset {
  FontAsset(this.assetUri, {this.weight, this.style})
    : assert(assetUri != null);

  final Uri assetUri;
  final int? weight;
  final String? style;

  Map<String, Object?> get descriptor {
    final Map<String, Object?> descriptor = <String, Object?>{};
    if (weight != null) {
      descriptor['weight'] = weight;
    }

    if (style != null) {
      descriptor['style'] = style;
    }

    descriptor['asset'] = assetUri.path;
    return descriptor;
  }

  @override
  String toString() => '$runtimeType(asset: ${assetUri.path}, weight; $weight, style: $style)';
}


bool _validate(Object? manifest, Logger logger) {
  final List<String> errors = <String>[];
  if (manifest is! YamlMap) {
    errors.add('Expected YAML map');
  } else {
    for (final MapEntry<Object?, Object?> kvp in manifest.entries) {
      if (kvp.key is! String) {
        errors.add('Expected YAML key to be a string, but got ${kvp.key}.');
        continue;
      }
      switch (kvp.key as String?) {
        case 'name':
          if (kvp.value is! String) {
            errors.add('Expected "${kvp.key}" to be a string, but got ${kvp.value}.');
          }
          break;
        case 'flutter':
          if (kvp.value == null) {
            continue;
          }
          if (kvp.value is! YamlMap) {
            errors.add('Expected "${kvp.key}" section to be an object or null, but got ${kvp.value}.');
          } else {
            _validateFlutter(kvp.value as YamlMap?, errors);
          }
          break;
        default:
        // additionalProperties are allowed.
          break;
      }
    }
  }

  if (errors.isNotEmpty) {
    logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
    logger.printError(errors.join('\n'));
    return false;
  }

  return true;
}

void _validateFlutter(YamlMap? yaml, List<String> errors) {
  if (yaml == null || yaml.entries == null) {
    return;
  }
  for (final MapEntry<Object?, Object?> kvp in yaml.entries) {
    final Object? yamlKey = kvp.key;
    final Object? yamlValue = kvp.value;
    if (yamlKey is! String) {
      errors.add('Expected YAML key to be a string, but got $yamlKey (${yamlValue.runtimeType}).');
      continue;
    }
    switch (yamlKey) {
      case 'uses-material-design':
        if (yamlValue is! bool) {
          errors.add('Expected "$yamlKey" to be a bool, but got $yamlValue (${yamlValue.runtimeType}).');
        }
        break;
      case 'assets':
        if (yamlValue is! YamlList) {

          errors.add('Expected "$yamlKey" to be a list, but got $yamlValue (${yamlValue.runtimeType}).');
        } else if (yamlValue.isEmpty) {
          break;
        } else if (yamlValue[0] is! String) {
          errors.add(
            'Expected "$yamlKey" to be a list of strings, but the first element is $yamlValue (${yamlValue.runtimeType}).',
          );
        }
        break;
      case 'fonts':
        if (yamlValue is! YamlList) {
          errors.add('Expected "$yamlKey" to be a list, but got $yamlValue (${yamlValue.runtimeType}).');
        } else if (yamlValue.isEmpty) {
          break;
        } else if (yamlValue.first is! YamlMap) {
          errors.add(
            'Expected "$yamlKey" to contain maps, but the first element is $yamlValue (${yamlValue.runtimeType}).',
          );
        } else {
          _validateFonts(yamlValue, errors);
        }
        break;
      case 'licenses':
        if (yamlValue is! YamlList) {
          errors.add('Expected "$yamlKey" to be a list of files, but got $yamlValue (${yamlValue.runtimeType})');
        } else if (yamlValue.isEmpty) {
          break;
        } else if (yamlValue.first is! String) {
          errors.add(
            'Expected "$yamlKey" to contain strings, but the first element is $yamlValue (${yamlValue.runtimeType}).',
          );
        } else {
          _validateListType<String>(yamlValue, errors, '"$yamlKey"', 'files');
        }
        break;
      case 'module':
        if (yamlValue is! YamlMap) {
          errors.add('Expected "$yamlKey" to be an object, but got $yamlValue (${yamlValue.runtimeType}).');
          break;
        }

        if (yamlValue['androidX'] != null && yamlValue['androidX'] is! bool) {
          errors.add('The "androidX" value must be a bool if set.');
        }
        if (yamlValue['androidPackage'] != null && yamlValue['androidPackage'] is! String) {
          errors.add('The "androidPackage" value must be a string if set.');
        }
        if (yamlValue['iosBundleIdentifier'] != null && yamlValue['iosBundleIdentifier'] is! String) {
          errors.add('The "iosBundleIdentifier" section must be a string if set.');
        }
        break;
      case 'plugin':
        if (yamlValue is! YamlMap || yamlValue == null) {
          errors.add('Expected "$yamlKey" to be an object, but got $yamlValue (${yamlValue.runtimeType}).');
          break;
        }
        final List<String> pluginErrors = Plugin.validatePluginYaml(yamlValue);
        errors.addAll(pluginErrors);
        break;
      case 'generate':
        break;
      case 'deferred-components':
        _validateDeferredComponents(kvp, errors);
        break;
      default:
        errors.add('Unexpected child "$yamlKey" found under "flutter".');
        break;
    }
  }
}

void _validateListType<T>(YamlList yamlList, List<String> errors, String context, String typeAlias) {
  for (int i = 0; i < yamlList.length; i++) {
    if (yamlList[i] is! T) {
      // ignore: avoid_dynamic_calls
      errors.add('Expected $context to be a list of $typeAlias, but element $i was a ${yamlList[i].runtimeType}');
    }
  }
}

void _validateDeferredComponents(MapEntry<Object?, Object?> kvp, List<String> errors) {
  final Object? yamlList = kvp.value;
  if (yamlList != null && (yamlList is! YamlList || yamlList[0] is! YamlMap)) {
    errors.add('Expected "${kvp.key}" to be a list, but got $yamlList (${yamlList.runtimeType}).');
  } else if (yamlList is YamlList) {
    for (int i = 0; i < yamlList.length; i++) {
      final Object? valueMap = yamlList[i];
      if (valueMap is! YamlMap) {
        // ignore: avoid_dynamic_calls
        errors.add('Expected the $i element in "${kvp.key}" to be a map, but got ${yamlList[i]} (${yamlList[i].runtimeType}).');
        continue;
      }
      if (!valueMap.containsKey('name') || valueMap['name'] is! String) {
        errors.add('Expected the $i element in "${kvp.key}" to have required key "name" of type String');
      }
      if (valueMap.containsKey('libraries')) {
        final Object? libraries = valueMap['libraries'];
        if (libraries is! YamlList) {
          errors.add('Expected "libraries" key in the $i element of "${kvp.key}" to be a list, but got $libraries (${libraries.runtimeType}).');
        } else {
          _validateListType<String>(libraries, errors, '"libraries" key in the $i element of "${kvp.key}"', 'dart library Strings');
        }
      }
      if (valueMap.containsKey('assets')) {
        final Object? assets = valueMap['assets'];
        if (assets is! YamlList) {
          errors.add('Expected "assets" key in the $i element of "${kvp.key}" to be a list, but got $assets (${assets.runtimeType}).');
        } else {
          _validateListType<String>(assets, errors, '"assets" key in the $i element of "${kvp.key}"', 'file paths');
        }
      }
    }
  }
}

void _validateFonts(YamlList fonts, List<String> errors) {
  if (fonts == null) {
    return;
  }
  const Set<int> fontWeights = <int>{
    100, 200, 300, 400, 500, 600, 700, 800, 900,
  };
  for (final Object? fontMap in fonts) {
    if (fontMap is! YamlMap) {
      errors.add('Unexpected child "$fontMap" found under "fonts". Expected a map.');
      continue;
    }
    for (final Object? key in fontMap.keys.where((Object? key) => key != 'family' && key != 'fonts')) {
      errors.add('Unexpected child "$key" found under "fonts".');
    }
    if (fontMap['family'] != null && fontMap['family'] is! String) {
      errors.add('Font family must either be null or a String.');
    }
    if (fontMap['fonts'] == null) {
      continue;
    } else if (fontMap['fonts'] is! YamlList) {
      errors.add('Expected "fonts" to either be null or a list.');
      continue;
    }
    for (final Object? fontMapList in fontMap['fonts']) {
      if (fontMapList is! YamlMap) {
        errors.add('Expected "fonts" to be a list of maps.');
        continue;
      }
      for (final MapEntry<Object?, Object?> kvp in fontMapList.entries) {
        final Object? fontKey = kvp.key;
        if (fontKey is! String) {
          errors.add('Expected "$fontKey" under "fonts" to be a string.');
        }
        switch(fontKey) {
          case 'asset':
            if (kvp.value is! String) {
              errors.add('Expected font asset ${kvp.value} ((${kvp.value.runtimeType})) to be a string.');
            }
            break;
          case 'weight':
            if (!fontWeights.contains(kvp.value)) {
              errors.add('Invalid value ${kvp.value} ((${kvp.value.runtimeType})) for font -> weight.');
            }
            break;
          case 'style':
            if (kvp.value != 'normal' && kvp.value != 'italic') {
              errors.add('Invalid value ${kvp.value} ((${kvp.value.runtimeType})) for font -> style.');
            }
            break;
          default:
            errors.add('Unexpected key $fontKey ((${kvp.value.runtimeType})) under font.');
            break;
        }
      }
    }
  }
}
