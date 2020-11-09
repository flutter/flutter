// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';


/// Generates the key mapping of Web, based on the information in the key
/// data structure given to it.
class WebCodeGenerator extends PlatformCodeGenerator {
  WebCodeGenerator(KeyData keyData) : super(keyData);

  /// This generates the map of Web KeyboardEvent codes to logical key ids.
  String get _webLogicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.flutterId, digits: 10)},");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical key USB HID codes.
  String get _webPhysicalKeyCodeMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.usbHidCode)},");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web number pad codes to logical key ids.
  String get _webNumpadCodeMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.flutterId, digits: 10)},");
      }
    }
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
      'WEB_NUMPAD_CODE_MAP': _webNumpadCodeMap,
    };
  }
}
