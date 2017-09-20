// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/globals.dart';
import 'package:json_schema/json_schema.dart';
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'cache.dart';

/// A wrapper around the `flutter` section in the  `pubspec.yaml` file.
class FlutterManifest {
  Map<String, dynamic> _descriptor;
  Map<String, dynamic> _flutterDescriptor;

  FlutterManifest._();

  String get appName => _descriptor['name'];

  bool get usesMaterialDesign {
    return _flutterDescriptor.containsKey('uses-material-design') &&
        _flutterDescriptor['uses-material-design'];
  }

  List<Map<String, dynamic>> get fontsDescriptor {
    if (!_flutterDescriptor.containsKey('fonts')) {
      return <Map<String, dynamic>>[];
    }
    return _flutterDescriptor['fonts'];
  }

  List<String> get assets {
    if (!_flutterDescriptor.containsKey('assets')) {
      return <String>[];
    }
    return _flutterDescriptor['assets'];
  }

  List<Font> _fonts;

  List<Font> get fonts {
    if (!_flutterDescriptor.containsKey('fonts')) {
      return <Font>[];
    }
    if (_fonts == null) {
      final List<Font> fonts = <Font>[];
      for (Map<String, dynamic> fontFamily in _flutterDescriptor['fonts']) {
        final List<Map<String, dynamic>> fontFiles = fontFamily['fonts'];
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
        for (Map<String, dynamic> fontFile in fontFiles) {
          final String asset = fontFile['asset'];
          if (asset == null) {
            printError('Warning: Missing asset in fonts for $familyName', emphasis: true);
            continue;
          }

          fontAssets.add(new FontAsset(
            asset,
            weight: fontFile['weight'],
            style: fontFile['style'],
          ));
        }
        if (fontAssets.isNotEmpty)
          fonts.add(new Font(fontFamily['family'], fontAssets));
      }

     _fonts = fonts;
    }

    return _fonts;
  }

  static Future<FlutterManifest> createManifestFromPath(String path) async {
    return  _createManifestFromYaml(_loadFlutterManifest(path));
  }

  static Future<FlutterManifest> createManifestFromString(String manifest) async {
    return _createManifestFromYaml(loadYaml(manifest));
  }

  static  Future<FlutterManifest> _createManifestFromYaml(Object yamlDocument) async {
    final FlutterManifest pubspec = new FlutterManifest._();
    if (yamlDocument == null || !await _validate(yamlDocument)) {
      return null;
    }
    pubspec._descriptor = yamlDocument;
    pubspec._flutterDescriptor =
        pubspec._descriptor['flutter'] ?? <String, dynamic>{};
    return pubspec;
  }
}

 class Font {
  final String familyName;
  final List<FontAsset> fontAssets;
  Font(
    this.familyName,
    this.fontAssets,
  ) {
    assert(familyName != null);
    assert(fontAssets != null);
    assert(fontAssets.isNotEmpty);
  }

  @override
  String toString() => 'Font (family: $familyName, assets: $fontAssets)';

  Map<String, dynamic> getDescriptor() {
   final List<Map<String, dynamic>> assets = <Map<String, dynamic>>[];
   for (FontAsset fontAsset in fontAssets) {
     assets.add(fontAsset.getDescriptor());
   }
   return <String, dynamic>{'fonts': assets, 'family': familyName};
  }
}

class FontAsset {
  final String asset;
  final int weight;
  final String style;

  FontAsset(this.asset, {this.weight, this.style});

  @override
  String toString() => 'FontAsset (asset: $asset, weight; $weight, style: $style )';

  Map<String, dynamic> getDescriptor() {
    final Map<String, dynamic> descriptor = <String,dynamic>{};
    if (weight != null) {
      descriptor['weight'] = weight;
    }
    if (style != null) {
      descriptor['style'] = style;
    }
    descriptor['asset'] = asset;
    return descriptor;
  }
}

dynamic _loadFlutterManifest(String manifestPath) {
  if (manifestPath == null || !fs.isFileSync(manifestPath))
    return null;
  final String manifestDescriptor = fs.file(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

Future<bool> _validate(Object manifest) async {
  final String schemaPath = fs.path.join(fs.path.absolute(Cache.flutterRoot),
      'packages', 'flutter_tools', 'schema', 'pubspec_yaml.json');
  final Schema schema =
      await Schema.createSchemaFromUrl(fs.path.toUri(schemaPath).toString());

  final Validator validator = new Validator(schema);
  if (validator.validate(manifest)) {
    return true;
  } else {
    printStatus('Error detected in pubspec.yaml:', emphasis: true);
    printError(validator.errors.join('\n'));
    return false;
  }
}