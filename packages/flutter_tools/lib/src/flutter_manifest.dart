// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'globals.dart';
import 'plugins.dart';

/// A wrapper around the `flutter` section in the `pubspec.yaml` file.
class FlutterManifest {
  FlutterManifest._();

  /// Returns an empty manifest.
  static FlutterManifest empty() {
    final FlutterManifest manifest = FlutterManifest._();
    manifest._descriptor = const <String, dynamic>{};
    manifest._flutterDescriptor = const <String, dynamic>{};
    return manifest;
  }

  /// Returns null on invalid manifest. Returns empty manifest on missing file.
  static FlutterManifest createFromPath(String path) {
    if (path == null || !fs.isFileSync(path))
      return _createFromYaml(null);
    final String manifest = fs.file(path).readAsStringSync();
    return createFromString(manifest);
  }

  /// Returns null on missing or invalid manifest
  @visibleForTesting
  static FlutterManifest createFromString(String manifest) {
    return _createFromYaml(loadYaml(manifest));
  }

  static FlutterManifest _createFromYaml(dynamic yamlDocument) {
    final FlutterManifest pubspec = FlutterManifest._();
    if (yamlDocument != null && !_validate(yamlDocument))
      return null;

    final Map<dynamic, dynamic> yamlMap = yamlDocument;
    if (yamlMap != null) {
      pubspec._descriptor = yamlMap.cast<String, dynamic>();
    } else {
      pubspec._descriptor = <String, dynamic>{};
    }

    final Map<dynamic, dynamic> flutterMap = pubspec._descriptor['flutter'];
    if (flutterMap != null) {
      pubspec._flutterDescriptor = flutterMap.cast<String, dynamic>();
    } else {
      pubspec._flutterDescriptor = <String, dynamic>{};
    }

    return pubspec;
  }

  /// A map representation of the entire `pubspec.yaml` file.
  Map<String, dynamic> _descriptor;

  /// A map representation of the `flutter` section in the `pubspec.yaml` file.
  Map<String, dynamic> _flutterDescriptor;

  /// True if the `pubspec.yaml` file does not exist.
  bool get isEmpty => _descriptor.isEmpty;

  /// The string value of the top-level `name` property in the `pubspec.yaml` file.
  String get appName => _descriptor['name'] ?? '';

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
        printStatus(userMessages.invalidVersionSettingHintMessage(verStr), emphasis: true);
        _hasShowInvalidVersionMsg = true;
      }
    }
    return version?.toString();
  }

  /// The build version name from the `pubspec.yaml` file.
  /// Can be null if version isn't set or has a wrong format.
  String get buildName {
    if (appVersion != null && appVersion.contains('+'))
      return appVersion.split('+')?.elementAt(0);
    else
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
    return _flutterDescriptor['uses-material-design'] ?? false;
  }

  /// True if this Flutter module should use AndroidX dependencies.
  ///
  /// If false the deprecated Android Support library will be used.
  bool get usesAndroidX {
    return _flutterDescriptor['module']['androidX'] ?? false;
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
  String get androidPackage {
    if (isModule)
      return _flutterDescriptor['module']['androidPackage'];
    if (isPlugin) {
      final YamlMap plugin = _flutterDescriptor['plugin'];
      if (plugin.containsKey('platforms')) {
        return plugin['platforms']['android']['package'];
      } else {
        return plugin['androidPackage'];
      }
    }
    return null;
  }

  /// Returns the iOS bundle identifier declared by this manifest in its
  /// module descriptor. Returns null if there is no such declaration.
  String get iosBundleIdentifier {
    if (isModule)
      return _flutterDescriptor['module']['iosBundleIdentifier'];
    return null;
  }

  List<Map<String, dynamic>> get fontsDescriptor {
    return fonts.map((Font font) => font.descriptor).toList();
  }

  List<Map<String, dynamic>> get _rawFontsDescriptor {
    final List<dynamic> fontList = _flutterDescriptor['fonts'];
    return fontList == null
        ? const <Map<String, dynamic>>[]
        : fontList.map<Map<String, dynamic>>(castStringKeyedMap).toList();
  }

  List<Uri> get assets {
    final List<dynamic> assets = _flutterDescriptor['assets'];
    if (assets == null) {
      return const <Uri>[];
    }
    return assets
        .cast<String>()
        .map<String>(Uri.encodeFull)
        ?.map<Uri>(Uri.parse)
        ?.toList();
  }

  List<Font> _fonts;

  List<Font> get fonts {
    _fonts ??= _extractFonts();
    return _fonts;
  }

  List<Font> _extractFonts() {
    if (!_flutterDescriptor.containsKey('fonts'))
      return <Font>[];

    final List<Font> fonts = <Font>[];
    for (Map<String, dynamic> fontFamily in _rawFontsDescriptor) {
      final List<dynamic> fontFiles = fontFamily['fonts'];
      final String familyName = fontFamily['family'];
      if (familyName == null) {
        printError('Warning: Missing family name for font.', emphasis: true);
        continue;
      }
      if (fontFiles == null) {
        printError('Warning: No fonts specified for font $familyName', emphasis: true);
        continue;
      }

      final List<FontAsset> fontAssets = <FontAsset>[];
      for (Map<dynamic, dynamic> fontFile in fontFiles) {
        final String asset = fontFile['asset'];
        if (asset == null) {
          printError('Warning: Missing asset in fonts for $familyName', emphasis: true);
          continue;
        }

        fontAssets.add(FontAsset(
          Uri.parse(asset),
          weight: fontFile['weight'],
          style: fontFile['style'],
        ));
      }
      if (fontAssets.isNotEmpty)
        fonts.add(Font(fontFamily['family'], fontAssets));
    }
    return fonts;
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
    if (weight != null)
      descriptor['weight'] = weight;

    if (style != null)
      descriptor['style'] = style;

    descriptor['asset'] = assetUri.path;
    return descriptor;
  }

  @override
  String toString() => '$runtimeType(asset: ${assetUri.path}, weight; $weight, style: $style)';
}

@visibleForTesting
String buildSchemaDir(FileSystem fs) {
  return fs.path.join(
    fs.path.absolute(Cache.flutterRoot), 'packages', 'flutter_tools', 'schema',
  );
}

@visibleForTesting
String buildSchemaPath(FileSystem fs) {
  return fs.path.join(
    buildSchemaDir(fs),
    'pubspec_yaml.json',
  );
}

/// This method should be kept in sync with the schema in
/// `$FLUTTER_ROOT/packages/flutter_tools/schema/pubspec_yaml.json`,
/// but avoid introducing depdendencies on packages for simple validation.
bool _validate(YamlMap manifest) {
  final List<String> errors = <String>[];
  for (final MapEntry<dynamic, dynamic> kvp in manifest.entries) {
    if (kvp.key is! String) {
      errors.add('Expected YAML key to be a a string, but got ${kvp.key}.');
      continue;
    }
    switch (kvp.key) {
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
        }
        _validateFlutter(kvp.value, errors);
        break;
      default:
        // additionalProperties are allowed.
        break;
    }
  }

  if (errors.isNotEmpty) {
    printStatus('Error detected in pubspec.yaml:', emphasis: true);
    printError(errors.join('\n'));
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
      errors.add('Expected YAML key to be a a string, but got ${kvp.key} (${kvp.value.runtimeType}).');
      continue;
    }
    switch (kvp.key) {
      case 'uses-material-design':
        if (kvp.value is! bool) {
          errors.add('Expected "${kvp.key}" to be a bool, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }
        break;
      case 'assets':
      case 'services':
        if (kvp.value is! YamlList || kvp.value[0] is! String) {
          errors.add('Expected "${kvp.key}" to be a list, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }
        break;
      case 'fonts':
        if (kvp.value is! YamlList || kvp.value[0] is! YamlMap) {
          errors.add('Expected "${kvp.key}" to be a list, but got ${kvp.value} (${kvp.value.runtimeType}).');
        } else {
          _validateFonts(kvp.value, errors);
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
        if (kvp.value is! YamlMap) {
          errors.add('Expected "${kvp.key}" to be an object, but got ${kvp.value} (${kvp.value.runtimeType}).');
        }
        final List<String> pluginErrors = Plugin.validatePluginYaml(kvp.value);
        errors.addAll(pluginErrors);
        break;
      default:
        errors.add('Unexpected child "${kvp.key}" found under "flutter".');
        break;
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
    final YamlMap fontMap = fontListEntry;
    for (dynamic key in fontMap.keys.where((dynamic key) => key != 'family' && key != 'fonts')) {
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
    for (final YamlMap fontListItem in fontMap['fonts']) {
      for (final MapEntry<dynamic, dynamic> kvp in fontListItem.entries) {
        if (kvp.key is! String) {
          errors.add('Expected "${kvp.key}" under "fonts" to be a string.');
        }
        switch(kvp.key) {
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
