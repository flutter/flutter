// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';

/// Generates the key mapping for Web, based on the information in the key
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
    final OutputLines<String> lines = OutputLines<String>('Web logical map');
    for (final LogicalKeyEntry entry in logicalData.entries) {
      for (final String name in entry.webNames) {
        lines.add(name, "  '$name': ${toHex(entry.value, digits: 11)},");
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical key USB HID codes.
  String get _webPhysicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.entries) {
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
      final String valuesString = locations.map((String? value) {
        return value == null ? 'null' : toHex(logicalData.entryByName(value).value, digits: 10);
      }).join(', ');
      result.writeln("  '$webKey': <int?>[$valuesString],");
    });
    return result.toString().trimRight();
  }
  final Map<String, List<String?>> _logicalLocationMap;

  @override
  String get templatePath => path.join(dataRoot, 'web_key_map_dart.tmpl');

  @override
  String outputPath(String platform) => path.join(PlatformCodeGenerator.engineRoot,
      'lib', 'web_ui', 'lib', 'src', 'engine', 'key_map.dart');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'WEB_LOGICAL_KEY_CODE_MAP': _webLogicalKeyCodeMap,
      'WEB_PHYSICAL_KEY_CODE_MAP': _webPhysicalKeyCodeMap,
      'WEB_LOGICAL_LOCATION_MAP': _webLogicalLocationMap,
    };
  }
}
