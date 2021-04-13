// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
  FlutterManifest._(this._logger);

  /// Returns an empty manifest.
  factory FlutterManifest.empty({ @required Logger logger }) {
    final FlutterManifest manifest = FlutterManifest._(logger);
    manifest._descriptor = const <String, dynamic>{};
    manifest._flutterDescriptor = const <String, dynamic>{};
    return manifest;
  }

  /// Returns null on invalid manifest. Returns empty manifest on missing file.
  static FlutterManifest createFromPath(String path, {
    @required FileSystem fileSystem,
    @required Logger logger,
  }) {
    if (path == null || !fileSystem.isFileSync(path)) {
      return _createFromYaml(null, logger);
    }
    final String manifest = fileSystem.file(path).readAsStringSync();
    return FlutterManifest.createFromString(manifest, logger: logger);
  }

  /// Returns null on missing or invalid manifest.
  @visibleForTesting
  static FlutterManifest createFromString(String manifest, { @required Logger logger }) {
    return _createFromYaml(manifest != null ? loadYaml(manifest) : null, logger);
  }

  static FlutterManifest _createFromYaml(dynamic yamlDocument, Logger logger) {
    if (yamlDocument != null && !_validate(yamlDocument, logger)) {
      return null;
    }

    final FlutterManifest pubspec = FlutterManifest._(logger);
    final Map<dynamic, dynamic> yamlMap = yamlDocument as YamlMap;
    if (yamlMap != null) {
      pubspec._descriptor = yamlMap.cast<String, dynamic>();
    } else {
      pubspec._descriptor = <String, dynamic>{};
    }

    final Map<dynamic, dynamic> flutterMap = pubspec._descriptor['flutter'] as Map<dynamic, dynamic>;
    if (flutterMap != null) {
      pubspec._flutterDescriptor = flutterMap.cast<String, dynamic>();
    } else {
      pubspec._flutterDescriptor = <String, dynamic>{};
    }

    return pubspec;
  }

  final Logger _logger;

  /// A map representation of the entire `pubspec.yaml` file.
  Map<String, dynamic> _descriptor;

  /// A map representation of the `flutter` section in the `pubspec.yaml` file.
  Map<String, dynamic> _flutterDescriptor;

  /// True if the `pubspec.yaml` file does not exist.
  bool get isEmpty => _descriptor.isEmpty;

  /// The string value of the top-level `name` property in the `pubspec.yaml` file.
  String get appName => _descriptor['name'] as String ?? '';

  // Flag to avoid printing multiple invalid version messages.
  bool _hasShowInvalidVersionMsg = false;

  /// The version String from the `pubspec.yaml` file.
  /// Can be null if it isn't set or has a wrong format.
  String get appVersion {
    final String verStr = _descriptor['version']?.toString();
    if (verStr == null) {
      return null;
    }

    Version version;
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
  String get buildName {
    if (appVersion != null && appVersion.contains('+')) {
      return appVersion.split('+')?.elementAt(0);
    }
    return appVersion;
  }

  /// The build version number from the `pubspec.yaml` file.
  /// Can be null if version isn't set or has a wrong format.
  String get buildNumber {
    if (appVersion != null && appVersion.contains('+')) {
      final String value = appVersion.split('+')?.elementAt(1);
      return value;
    } else {
      return null;
    }
  }

  bool get usesMaterialDesign {
    return _flutterDescriptor['uses-material-design'] as bool ?? false;
  }

  /// True if this Flutter module should use AndroidX dependencies.
  ///
  /// If false the deprecated Android Support library will be used.
  bool get usesAndroidX {
    if (_flutterDescriptor.containsKey('module')) {
      return _flutterDescriptor['module']['androidX'] as bool;
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
  List<String> get additionalLicenses => _flutterDescriptor.containsKey('licenses')
    ? (_flutterDescriptor['licenses'] as YamlList).map((dynamic element) => element.toString()).toList()
    : <String>[];

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
  String get androidPackage {
    if (isModule) {
      return _flutterDescriptor['module']['androidPackage'] as String;
    }
    if (supportedPlatforms == null) {
      // Pre-multi-platform plugin format
      if (isPlugin) {
        final YamlMap plugin = _flutterDescriptor['plugin'] as YamlMap;
        return plugin['androidPackage'] as String;
      }
      return null;
    }
    if (supportedPlatforms.containsKey('android')) {
       return supportedPlatforms['android']['package'] as String;
    }
    return null;
  }

  /// Returns the deferred components configuration if declared. Returns
  /// null if no deferred components are declared.
  List<DeferredComponent> get deferredComponents => _deferredComponents ??= computeDeferredComponents();
  List<DeferredComponent> _deferredComponents;
  List<DeferredComponent> computeDeferredComponents() {
    if (!_flutterDescriptor.containsKey('deferred-components')) {
      return null;
    }
    final List<DeferredComponent> components = <DeferredComponent>[];
    if (_flutterDescriptor['deferred-components'] == null) {
      return components;
    }
    for (final dynamic componentData in _flutterDescriptor['deferred-components']) {
      final YamlMap component = componentData as YamlMap;
      List<Uri> assetsUri = <Uri>[];
      final List<dynamic> assets = component['assets'] as List<dynamic>;
      if (assets == null) {
        assetsUri = const <Uri>[];
      } else {
        for (final Object asset in assets) {
          if (asset is! String || asset == null || asset == '') {
            _logger.printError('Deferred component asset manifest contains a null or empty uri.');
            continue;
          }
          final String stringAsset = asset as String;
          try {
            assetsUri.add(Uri.parse(stringAsset));
          } on FormatException {
            _logger.printError('Asset manifest contains invalid uri: $asset.');
          }
        }
      }
      components.add(
        DeferredComponent(
          name: component['name'] as String,
          libraries: component['libraries'] == null ?
              <String>[] : component['libraries'].cast<String>() as List<String>,
          assets: assetsUri,
        )
      );
    }
    return components;
  }

  /// Returns the iOS bundle identifier declared by this manifest in its
  /// module descriptor. Returns null if there is no such declaration.
  String get iosBundleIdentifier {
    if (isModule) {
      return _flutterDescriptor['module']['iosBundleIdentifier'] as String;
    }
    return null;
  }

  /// Gets the supported platforms. This only supports the new `platforms` format.
  ///
  /// If the plugin uses the legacy pubspec format, this method returns null.
  Map<String, dynamic> get supportedPlatforms {
    if (isPlugin) {
      final YamlMap plugin = _flutterDescriptor['plugin'] as YamlMap;
      if (plugin.containsKey('platforms')) {
        final YamlMap platformsMap = plugin['platforms'] as YamlMap;
        return platformsMap.value.cast<String, dynamic>();
      }
    }
    return null;
  }

  /// Like [supportedPlatforms], but only returns the valid platforms that are supported in flutter plugins.
  Map<String, dynamic> get validSupportedPlatforms {
    final Map<String, dynamic> allPlatforms = supportedPlatforms;
    if (allPlatforms == null) {
      return null;
    }
    final Map<String, dynamic> platforms = <String, dynamic>{}..addAll(supportedPlatforms);
    platforms.removeWhere((String key, dynamic _) => !_kValidPluginPlatforms.contains(key));
    if (platforms.isEmpty) {
      return null;
    }
    return platforms;
  }

  List<Map<String, dynamic>> get fontsDescriptor {
    return fonts.map((Font font) => font.descriptor).toList();
  }

  List<Map<String, dynamic>> get _rawFontsDescriptor {
    final List<dynamic> fontList = _flutterDescriptor['fonts'] as List<dynamic>;
    return fontList == null
        ? const <Map<String, dynamic>>[]
        : fontList.map<Map<String, dynamic>>(castStringKeyedMap).toList();
  }

  List<Uri> get assets => _assets ??= _computeAssets();
  List<Uri> _assets;
  List<Uri> _computeAssets() {
    final List<dynamic> assets = _flutterDescriptor['assets'] as List<dynamic>;
    if (assets == null) {
      return const <Uri>[];
    }
    final List<Uri> results = <Uri>[];
    for (final Object asset in assets) {
      if (asset is! String || asset == null || asset == '') {
        _logger.printError('Asset manifest contains a null or empty uri.');
        continue;
      }
      final String stringAsset = asset as String;
      try {
        results.add(Uri(pathSegments: stringAsset.split('/')));
      } on FormatException {
        _logger.printError('Asset manifest contains invalid uri: $asset.');
      }
    }
    return results;
  }

  List<Font> _fonts;

  List<Font> get fonts {
    _fonts ??= _extractFonts();
    return _fonts;
  }

  List<Font> _extractFonts() {
    if (!_flutterDescriptor.containsKey('fonts')) {
      return <Font>[];
    }

    final List<Font> fonts = <Font>[];
    for (final Map<String, dynamic> fontFamily in _rawFontsDescriptor) {
      final YamlList fontFiles = fontFamily['fonts'] as YamlList;
      final String familyName = fontFamily['family'] as String;
      if (familyName == null) {
        _logger.printError('Warning: Missing family name for font.', emphasis: true);
        continue;
      }
      if (fontFiles == null) {
        _logger.printError('Warning: No fonts specified for font $familyName', emphasis: true);
        continue;
      }

      final List<FontAsset> fontAssets = <FontAsset>[];
      for (final Map<dynamic, dynamic> fontFile in fontFiles.cast<Map<dynamic, dynamic>>()) {
        final String asset = fontFile['asset'] as String;
        if (asset == null) {
          _logger.printError('Warning: Missing asset in fonts for $familyName', emphasis: true);
          continue;
        }

        fontAssets.add(FontAsset(
          Uri.parse(asset),
          weight: fontFile['weight'] as int,
          style: fontFile['style'] as String,
        ));
      }
      if (fontAssets.isNotEmpty) {
        fonts.add(Font(fontFamily['family'] as String, fontAssets));
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
  bool get generateSyntheticPackage => _generateSyntheticPackage ??= _computeGenerateSyntheticPackage();
  bool _generateSyntheticPackage;
  bool _computeGenerateSyntheticPackage() {
    if (!_flutterDescriptor.containsKey('generate')) {
      return false;
    }
    final Object value = _flutterDescriptor['generate'];
    if (value is! bool) {
      return false;
    }
    return value as bool;
  }
}

class Font {
  Font(this.familyName, this.fontAssets)
    : assert(familyName != null),
      assert(fontAssets != null),
      assert(fontAssets.isNotEmpty);

  final String familyName;
  final List<FontAsset> fontAssets;

  Map<String, dynamic> get descriptor {
    return <String, dynamic>{
      'family': familyName,
      'fonts': fontAssets.map<Map<String, dynamic>>((FontAsset a) => a.descriptor).toList(),
    };
  }

  @override
  String toString() => '$runtimeType(family: $familyName, assets: $fontAssets)';
}

class FontAsset {
  FontAsset(this.assetUri, {this.weight, this.style})
    : assert(assetUri != null);

  final Uri assetUri;
  final int weight;
  final String style;

  Map<String, dynamic> get descriptor {
    final Map<String, dynamic> descriptor = <String, dynamic>{};
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


bool _validate(dynamic manifest, Logger logger) {
  final List<String> errors = <String>[];
  if (manifest is! YamlMap) {
    errors.add('Expected YAML map');
  } else {
    for (final MapEntry<dynamic, dynamic> kvp in (manifest as YamlMap).entries) {
      if (kvp.key is! String) {
        errors.add('Expected YAML key to be a string, but got ${kvp.key}.');
        continue;
      }
      switch (kvp.key as String) {
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
            _validateFlutter(kvp.value as YamlMap, errors);
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

void _validateFlutter(YamlMap yaml, List<String> errors) {
  if (yaml == null || yaml.entries == null) {
    return;
  }
  for (final MapEntry<dynamic, dynamic> kvp in yaml.entries) {
    if (kvp.key is! String) {
      errors.add('Expected YAML key to be a string, but got ${kvp.key} (${kvp.value.runtimeType}).');
      continue;
    }
    switch (kvp.key as String) {
      case 'uses-material-design':
        if (kvp.value is! bool) {
          errors.add('Expected "${kvp.key}" to be a bool, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }
        break;
      case 'assets':
        if (kvp.value is! YamlList || kvp.value[0] is! String) {
          errors.add('Expected "${kvp.key}" to be a list, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }
        break;
      case 'fonts':
        if (kvp.value is! YamlList || kvp.value[0] is! YamlMap) {
          errors.add('Expected "${kvp.key}" to be a list, but got ${kvp.value} (${kvp.value.runtimeType}).');
        } else {
          _validateFonts(kvp.value as YamlList, errors);
        }
        break;
      case 'licenses':
        final dynamic value = kvp.value;
        if (value is YamlList) {
          _validateListType<String>(value, errors, '"${kvp.key}"', 'files');
        } else {
          errors.add('Expected "${kvp.key}" to be a list of files, but got $value (${value.runtimeType})');
        }
        break;
      case 'module':
        if (kvp.value is! YamlMap) {
          errors.add('Expected "${kvp.key}" to be an object, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }

        if (kvp.value['androidX'] != null && kvp.value['androidX'] is! bool) {
          errors.add('The "androidX" value must be a bool if set.');
        }
        if (kvp.value['androidPackage'] != null && kvp.value['androidPackage'] is! String) {
          errors.add('The "androidPackage" value must be a string if set.');
        }
        if (kvp.value['iosBundleIdentifier'] != null && kvp.value['iosBundleIdentifier'] is! String) {
          errors.add('The "iosBundleIdentifier" section must be a string if set.');
        }
        break;
      case 'plugin':
        if (kvp.value is! YamlMap || kvp.value == null) {
          errors.add('Expected "${kvp.key}" to be an object, but got ${kvp.value} (${kvp.value.runtimeType}).');
          break;
        }
        final List<String> pluginErrors = Plugin.validatePluginYaml(kvp.value as YamlMap);
        errors.addAll(pluginErrors);
        break;
      case 'generate':
        break;
      case 'deferred-components':
        _validateDeferredComponents(kvp, errors);
        break;
      default:
        errors.add('Unexpected child "${kvp.key}" found under "flutter".');
        break;
    }
  }
}

void _validateListType<T>(YamlList yamlList, List<String> errors, String context, String typeAlias) {
  for (int i = 0; i < yamlList.length; i++) {
    if (yamlList[i] is! T) {
      errors.add('Expected $context to be a list of $typeAlias, but element $i was a ${yamlList[i].runtimeType}');
    }
  }
}

void _validateDeferredComponents(MapEntry<dynamic, dynamic> kvp, List<String> errors) {
  if (kvp.value != null && (kvp.value is! YamlList || kvp.value[0] is! YamlMap)) {
    errors.add('Expected "${kvp.key}" to be a list, but got ${kvp.value} (${kvp.value.runtimeType}).');
  } else if (kvp.value != null) {
    for (int i = 0; i < (kvp.value as YamlList).length; i++) {
      if (kvp.value[i] is! YamlMap) {
        errors.add('Expected the $i element in "${kvp.key}" to be a map, but got ${kvp.value[i]} (${kvp.value[i].runtimeType}).');
        continue;
      }
      if (!(kvp.value[i] as YamlMap).containsKey('name') || kvp.value[i]['name'] is! String) {
        errors.add('Expected the $i element in "${kvp.key}" to have required key "name" of type String');
      }
      if ((kvp.value[i] as YamlMap).containsKey('libraries')) {
        if (kvp.value[i]['libraries'] is! YamlList) {
          errors.add('Expected "libraries" key in the $i element of "${kvp.key}" to be a list, but got ${kvp.value[i]['libraries']} (${kvp.value[i]['libraries'].runtimeType}).');
        } else {
          _validateListType<String>(kvp.value[i]['libraries'] as YamlList, errors, '"libraries" key in the $i element of "${kvp.key}"', 'dart library Strings');
        }
      }
      if ((kvp.value[i] as YamlMap).containsKey('assets')) {
        if (kvp.value[i]['assets'] is! YamlList) {
          errors.add('Expected "assets" key in the $i element of "${kvp.key}" to be a list, but got ${kvp.value[i]['assets']} (${kvp.value[i]['assets'].runtimeType}).');
        } else {
          _validateListType<String>(kvp.value[i]['assets'] as YamlList, errors, '"assets" key in the $i element of "${kvp.key}"', 'file paths');
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
  for (final dynamic fontListEntry in fonts) {
    if (fontListEntry is! YamlMap) {
      errors.add('Unexpected child "$fontListEntry" found under "fonts". Expected a map.');
      continue;
    }
    final YamlMap fontMap = fontListEntry as YamlMap;
    for (final dynamic key in fontMap.keys.where((dynamic key) => key != 'family' && key != 'fonts')) {
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
    for (final dynamic fontListItem in fontMap['fonts']) {
      if (fontListItem is! YamlMap) {
        errors.add('Expected "fonts" to be a list of maps.');
        continue;
      }
      final YamlMap fontMapList = fontListItem as YamlMap;
      for (final MapEntry<dynamic, dynamic> kvp in fontMapList.entries) {
        if (kvp.key is! String) {
          errors.add('Expected "${kvp.key}" under "fonts" to be a string.');
        }
        switch(kvp.key as String) {
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
            errors.add('Unexpected key ${kvp.key} ((${kvp.value.runtimeType})) under font.');
            break;
        }
      }
    }
  }
}
