// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'globals.dart';

/// The type of the Flutter project created using `flutter create -t <type>`
enum ProjectType {
  /// A Flutter project is considered an app when it doesn't a `module:`
  /// or `plugin:` descriptor.
  ///
  /// Such a project can be created using `flutter create -t app`.
  app,

  /// A Flutter project is considered a module when it has a `module:`
  /// descriptor. A Flutter module project supports integration into an
  /// existing host app, and has managed platform host code.
  ///
  /// Such a project can be created using `flutter create -t module`.
  module,

  /// A Flutter project is considered a plugin when it has a `plugin:`
  /// descriptor. A Flutter plugin project wraps custom Android and/or
  /// iOS code in a Dart interface for consumption by other Flutter app
  /// projects.
  ///
  /// Such a project can be created using `flutter create -t plugin`.
  plugin,
}

/// A wrapper around the `flutter:` section in the `pubspec.yaml` file.
class FlutterManifest {
  FlutterManifest({
    @required this.appName,
    @required this.appVersion,
    @required this.buildName,
    @required this.buildNumber,
    @required this.usesMaterialDesign,
    @required this.projectType,
    @required this.assets,
    @required this.fonts,
  })  : assert(appName != null),
        assert(appVersion != null),
        assert(buildName != null),
        assert(buildNumber != null),
        assert(usesMaterialDesign != null),
        assert(projectType != null),
        assert(assets != null),
        assert(fonts != null);

  /// The string value of the top-level `name` property in the `pubspec.yaml` file.
  final String appName;

  /// The version String from the `pubspec.yaml` file.
  final String appVersion;

  /// The build version name from the `pubspec.yaml` file.
  final String buildName;

  /// The build version number from the `pubspec.yaml` file.
  final String buildNumber;

  /// True if the project uses Material Design.
  final bool usesMaterialDesign;

  /// The type of Flutter project.
  final ProjectType projectType;

  /// The list of assets.
  final List<Uri> assets;

  /// The list of fonts.
  final List<Font> fonts;

  @override
  String toString() {
    return '$runtimeType(appName: $appName, appVersion: $appVersion, buildName: $buildName, '
        'buildNumber: $buildNumber, projectType: $projectType)';
  }
}

/// A wrapper around each of the sections under `fonts:` in `pubspec.yaml`.
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

/// A wrapper around each of the nested `fonts:` in `pubspec.yaml`.
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

/// A service class for creating [FlutterManifest].
abstract class FlutterManifestService {
  const FlutterManifestService();

  /// Creates a [FlutterManifest] by parsing the `pubspec.yaml` file in [path].
  /// Returns [null] if the manifest is invalid.
  FlutterManifest createFromPath(String path);

  /// Creates a [FlutterManifest] by parsing the [manifest].
  /// Returns [null] if the manifest is invalid.
  FlutterManifest createFromString(String manifest);
}

/// Default implementation of [FlutterManifestService].
class FlutterManifestServiceImpl extends FlutterManifestService {
  /// Creates a [FlutterManifest] by parsing the `pubspec.yaml` file in [path].
  /// Returns [null] if the manifest is invalid.
  @override
  FlutterManifest createFromPath(String path) {
    if (path == null || !fs.isFileSync(path)) {
      return FlutterManifest();
    }
    final String manifest = fs.file(path).readAsStringSync();
    return createFromString(manifest);
  }

  /// Creates a [FlutterManifest] by parsing the [manifest].
  /// Returns [null] if the manifest is invalid.
  @override
  FlutterManifest createFromString(String manifest) {
    return _createFromYaml(loadYaml(manifest));
  }
}

/// If not injected, a default implementation is provided.
FlutterManifestService get flutterManifestService =>
    context.get<FlutterManifestService>() ?? FlutterManifestServiceImpl();

/// Returns the [FlutterManifest] if [yamlDocument] is valid.
/// Otherwise, it returns [null].
FlutterManifest _createFromYaml(dynamic yamlDocument) {
  if (!_validateManifest(yamlDocument)) {
    return null;
  }

  final Map<String, dynamic> descriptor = yamlDocument.cast<String, dynamic>();
  final Map<String, dynamic> flutterDescriptor = _getFlutterDescriptor(descriptor);

  return FlutterManifest(
    appName: descriptor['name'] ?? '',
    appVersion: _getAppVersion(descriptor),
    buildName: _getBuildName(descriptor),
    buildNumber: _getBuildNumber(descriptor),
    projectType: _getProjectType(flutterDescriptor),
    usesMaterialDesign: _usesMaterialDesign(flutterDescriptor),
    assets: _getAssets(flutterDescriptor),
    fonts: _getFonts(flutterDescriptor),
  );
}

/// Gets the `flutter:` descriptor from `pubspec.yaml`.
Map<String, dynamic> _getFlutterDescriptor(Map<String, dynamic> descriptor) {
  final Map<dynamic, dynamic> flutterMap = descriptor['flutter'];
  if (flutterMap == null) {
    return const <String, dynamic>{};
  }
  return flutterMap.cast<String, dynamic>();
}

/// Gets the project type defined via `flutter create -t <type>`.
ProjectType _getProjectType(Map<String, dynamic> futterDescriptor) {
  if (futterDescriptor.containsKey('module')) {
    return ProjectType.module;
  }
  if (futterDescriptor.containsKey('plugin')) {
    return ProjectType.plugin;
  }
  return ProjectType.app;
}

/// True if the app uses Material Design.
bool _usesMaterialDesign(Map<String, dynamic> futterDescriptor) {
  return futterDescriptor['uses-material-design'] ?? false;
}

// Flag to avoid printing multiple invalid version messages.
bool _hasShowInvalidVersionMsg = false;
/// The version from the `pubspec.yaml` file.
String _getAppVersion(Map<String, dynamic> descriptor) {
  final String verStr = descriptor['version']?.toString();
  if (verStr == null) {
    return '';
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
  return version?.toString() ?? '';
}

/// The build version name from the `pubspec.yaml` file.
String _getBuildName(Map<String, dynamic> descriptor) {
  final String appVersion = _getAppVersion(descriptor);

  if (appVersion != null && appVersion.contains('+')) {
    return appVersion.split('+')?.elementAt(0) ?? '';
  }
  return appVersion;
}

/// The build version number from the `pubspec.yaml` file.
String _getBuildNumber(Map<String, dynamic> descriptor) {
  final String appVersion = _getAppVersion(descriptor);

  if (appVersion != null && appVersion.contains('+')) {
    return appVersion.split('+')?.elementAt(1) ?? '';
  }
  return '';
}

/// Gets the list of assets URI's defined withtin the `assets:` descriptor in `pubspec.yaml`.
List<Uri> _getAssets(Map<String, dynamic> flutterDescriptor) {
  final List<dynamic> assets = flutterDescriptor['assets'];
  if (assets == null) {
    return const <Uri>[];
  }
  return assets
      .cast<String>()
      .map<String>(Uri.encodeFull)
      ?.map<Uri>(Uri.parse)
      ?.toList();
}

/// Gets the list of [Font] defined within the `fonts:` descriptor in `pubspec.yaml`.
List<Font> _getFonts(Map<String, dynamic> flutterDescriptor) {
  if (!flutterDescriptor.containsKey('fonts')) {
    return const <Font>[];
  }

  final List<dynamic> fontList = flutterDescriptor['fonts'];
  final List<Map<String, dynamic>> rawFontsDescriptor = fontList == null
      ? const <Map<String, dynamic>>[]
      : fontList.map<Map<String, dynamic>>(castStringKeyedMap).toList();

  final List<Font> fonts = <Font>[];

  for (Map<String, dynamic> fontFamily in rawFontsDescriptor) {
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

/// This method should be kept in sync with the schema in
/// `$FLUTTER_ROOT/packages/flutter_tools/schema/pubspec_yaml.json`,
/// but avoid introducing depdendencies on packages for simple validation.
bool _validateManifest(YamlMap manifest) {
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

/// Validates that the `flutter:` descriptor is correct. Produces [errors] otherwise.
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
        }
        _validateFonts(kvp.value, errors);
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
        if (kvp.value['androidPackage'] != null && kvp.value['androidPackage'] is! String) {
          errors.add('The "androidPackage" must either be null or a string.');
        }
        if (kvp.value['iosPrefix'] != null && kvp.value['iosPrefix'] is! String) {
          errors.add('The "iosPrefix" must either be null or a string.');
        }
        if (kvp.value['macosPrefix'] != null && kvp.value['macosPrefix'] is! String) {
          errors.add('The "macosPrefix" must either be null or a string.');
        }
        if (kvp.value['pluginClass'] != null && kvp.value['pluginClass'] is! String) {
          errors.add('The "pluginClass" must either be null or a string..');
        }
        break;
      default:
        errors.add('Unexpected child "${kvp.key}" found under "flutter".');
        break;
    }
  }
}

const Set<int> _fontWeights = <int>{
  100, 200, 300, 400, 500, 600, 700, 800, 900,
};
///  Validates that the fonts are correct. Produces [errors] otherwise.
void _validateFonts(YamlList fonts, List<String> errors) {
  if (fonts == null) {
    return;
  }
  for (final YamlMap fontMap in fonts) {
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
            if (!_fontWeights.contains(kvp.value)) {
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
