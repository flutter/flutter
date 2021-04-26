// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';

/// Generates the key mapping of Web, based on the information in the key
/// data structure given to it.
class WebCodeGenerator extends PlatformCodeGenerator {
  WebCodeGenerator(
    PhysicalKeyData keyData,
    LogicalKeyData logicalData,
    String logicalLocationMap,
  ) : _logicalLocationMap = parseMapOfListOfNullableString(logicalLocationMap),
      super(keyData, logicalData);

  /// This generates the map of Web KeyboardEvent codes to logical key ids.
  String get _webLogicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      zipStrict(entry.webValues, entry.webNames, (int value, String name) {
        result.writeln("  '$name': ${toHex(value, digits: 10)},");
      });
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical key USB HID codes.
  String get _webPhysicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data.values) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.usbHidCode)},");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web number pad codes to logical key ids.
  String get _webLogicalLocationMap {
    final StringBuffer result = StringBuffer();
    _logicalLocationMap.forEach((String webKey, List<String?> locations) {
      final String valuesString = locations.map((dynamic value) {
        if (value != null && logicalData.data[value] == null) {
          print('Error during web location map: $value is not a valid logical key.');
          return null;
        }
        return value == null ? 'null' : toHex(logicalData.data[value]?.value, digits: 10);
      }).join(', ');
      result.writeln("  '$webKey': <int?>[$valuesString],");
    });
    return result.toString().trimRight();
  }
  final Map<String, List<String?>> _logicalLocationMap;

  @override
  String get templatePath => path.join(dataRoot, 'web_key_map_dart.tmpl');

  @override
  String outputPath(String platform) => path.join(flutterRoot.path, '..', 'engine', 'src', 'flutter', path.join('lib', 'web_ui', 'lib', 'src', 'engine', 'key_map.dart'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'WEB_LOGICAL_KEY_CODE_MAP': _webLogicalKeyCodeMap,
      'WEB_PHYSICAL_KEY_CODE_MAP': _webPhysicalKeyCodeMap,
      'WEB_LOGICAL_LOCATION_MAP': _webLogicalLocationMap,
    };
  }
}
