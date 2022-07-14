// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';


/// Generates the key mapping for Android, based on the information in the key
/// data structure given to it.
class AndroidCodeGenerator extends PlatformCodeGenerator {
  AndroidCodeGenerator(super.physicalData, super.logicalData);

  /// This generates the map of Android key codes to logical keys.
  String get _androidKeyCodeMap {
    final StringBuffer androidKeyCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.entries) {
      for (final int code in entry.androidValues) {
        androidKeyCodeMap.writeln('          put(${toHex(code, digits: 10)}L, ${toHex(entry.value, digits: 10)}L); // ${entry.constantName}');
      }
    }
    return androidKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Android scan codes to physical keys.
  String get _androidScanCodeMap {
    final StringBuffer androidScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.entries) {
      if (entry.androidScanCodes != null) {
        for (final int code in entry.androidScanCodes.cast<int>()) {
          androidScanCodeMap.writeln('          put(${toHex(code, digits: 10)}L, ${toHex(entry.usbHidCode, digits: 10)}L); // ${entry.constantName}');
        }
      }
    }
    return androidScanCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(dataRoot, 'android_keyboard_map_java.tmpl');

  @override
  String outputPath(String platform) => path.join(PlatformCodeGenerator.engineRoot, 'shell', 'platform',
      path.join('android', 'io', 'flutter', 'embedding', 'android', 'KeyboardMap.java'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'ANDROID_SCAN_CODE_MAP': _androidScanCodeMap,
      'ANDROID_KEY_CODE_MAP': _androidKeyCodeMap,
    };
  }
}
