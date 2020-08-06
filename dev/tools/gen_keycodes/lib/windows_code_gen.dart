// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';


/// Generates the key mapping of Windows, based on the information in the key
/// data structure given to it.
class WindowsCodeGenerator extends PlatformCodeGenerator {
  WindowsCodeGenerator(KeyData keyData) : super(keyData);

  /// This generates the map of Windows scan codes to physical keys.
  String get _windowsScanCodeMap {
    final StringBuffer windowsScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.windowsScanCode != null) {
        windowsScanCodeMap.writeln('  { ${entry.windowsScanCode}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return windowsScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Windows number pad key codes to logical keys.
  String get _windowsNumpadMap {
    final StringBuffer windowsNumPadMap = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.windowsScanCode != null) {
        windowsNumPadMap.writeln('  { ${toHex(entry.windowsScanCode)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return windowsNumPadMap.toString().trimRight();
  }

  /// This generates the map of Android key codes to logical keys.
  String get _windowsKeyCodeMap {
    final StringBuffer windowsKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.windowsKeyCodes != null) {
        for (final int code in entry.windowsKeyCodes.cast<int>()) {
          windowsKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return windowsKeyCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_windows_cc.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'WINDOWS_SCAN_CODE_MAP': _windowsScanCodeMap,
      'WINDOWS_NUMPAD_MAP': _windowsNumpadMap,
      'WINDOWS_KEY_CODE_MAP': _windowsKeyCodeMap,
    };
  }
}
