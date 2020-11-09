// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';


/// Generates the key mapping of Fuchsia, based on the information in the key
/// data structure given to it.
class FuchsiaCodeGenerator extends PlatformCodeGenerator {
  FuchsiaCodeGenerator(KeyData keyData) : super(keyData);

  /// This generates the map of Fuchsia key codes to logical keys.
  String get _fuchsiaKeyCodeMap {
    final StringBuffer fuchsiaKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaKeyCodeMap.writeln('  { ${toHex(entry.flutterId)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return fuchsiaKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Fuchsia USB HID codes to physical keys.
  String get _fuchsiaHidCodeMap {
    final StringBuffer fuchsiaScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaScanCodeMap.writeln(' { ${toHex(entry.usbHidCode)}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return fuchsiaScanCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_fuchsia_cc.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'FUCHSIA_SCAN_CODE_MAP': _fuchsiaHidCodeMap,
      'FUCHSIA_KEY_CODE_MAP': _fuchsiaKeyCodeMap,
    };
  }
}
