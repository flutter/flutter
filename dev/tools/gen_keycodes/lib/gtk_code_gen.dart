// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';


/// Generates the key mapping of GTK, based on the information in the key
/// data structure given to it.
class GtkCodeGenerator extends PlatformCodeGenerator {
  GtkCodeGenerator(KeyData keyData) : super(keyData);

  /// This generates the map of XKB scan codes to USB HID codes.
  String get xkbScanCodeMap {
    final StringBuffer xkbScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.xKbScanCode != null) {
        xkbScanCodeMap.writeln('  { ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return xkbScanCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_linux_cc.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'XKB_SCAN_CODE_MAP': xkbScanCodeMap,
    };
  }
}
