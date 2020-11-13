// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'physical_key_data.dart';
import 'logical_key_data.dart';
import 'utils.dart';

/// Generates the key mapping of Web, based on the information in the key
/// data structure given to it.
class WebCodeGenerator extends PlatformCodeGenerator {
  WebCodeGenerator(PhysicalKeyData keyData, this.logicalData) : super(keyData);

  final LogicalKeyData logicalData;

  /// This generates the map of Web KeyboardEvent codes to logical key ids.
  String get _webLogicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      zipStrict(entry.webValues, entry.webNames, (int value, String name) {
        result.writeln("  '${name}': ${toHex(value, digits: 10)},");
      });
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical key USB HID codes.
  String get _webPhysicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.usbHidCode)},");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web number pad codes to logical key ids.
  String get _webLogicalLocationMap {
    final Map<String, dynamic> source = json.decode(File(
      path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'web_logical_location_mapping.json')
    ).readAsStringSync()) as Map<String, dynamic>;
    final StringBuffer result = StringBuffer();
    source.forEach((String webKey, dynamic dynamicValue) {
      final String valuesString = (dynamicValue as List<dynamic>).map((dynamic value) {
        if (value != null && logicalData.data[value] == null) {
          print('Error during web location map: $value is not a valid logical key.');
          return null;
        }
        return value == null ? 'null' : '${toHex(logicalData.data[value].value, digits: 10)}';
      }).join(", ");
      result.writeln("  '$webKey': <int?>[$valuesString],");
    });
    return result.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_web.tmpl');

  @override
  String outputPath(String platform) => path.join(flutterRoot.path, '..', 'engine', 'src', 'flutter', path.join('lib', 'web_ui', 'lib', 'src', 'engine', 'keycodes', 'keyboard_map_web.dart'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'WEB_LOGICAL_KEY_CODE_MAP': _webLogicalKeyCodeMap,
      'WEB_PHYSICAL_KEY_CODE_MAP': _webPhysicalKeyCodeMap,
      'WEB_LOGICAL_LOCATION_MAP': _webLogicalLocationMap,
    };
  }
}
