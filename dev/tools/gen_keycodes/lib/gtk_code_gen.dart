// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'physical_key_data.dart';
import 'logical_key_data.dart';
import 'utils.dart';


/// Generates the key mapping of GTK, based on the information in the key
/// data structure given to it.
class GtkCodeGenerator extends PlatformCodeGenerator {
  GtkCodeGenerator(PhysicalKeyData keyData, this.logicalData) : super(keyData);

  final LogicalKeyData logicalData;

  /// This generates the map of XKB scan codes to Flutter physical keys.
  String get xkbScanCodeMap {
    final StringBuffer xkbScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.xKbScanCode != null) {
        xkbScanCodeMap.writeln('  insert_record(table, ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)});    // ${entry.constantName}');
      }
    }
    return xkbScanCodeMap.toString().trimRight();
  }

  /// This generates the map of GTK keyval codes to Flutter logical keys.
  String get gtkKeyvalCodeMap {
    final StringBuffer gtkKeyvalCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data) {
      if (entry.gtkValues != null && entry.gtkNames != null) {
        if (entry.gtkValues.length != entry.gtkNames.length) {
          print('Mismatched keycodes ${entry.gtkValues} to names ${entry.gtkNames}');
          continue;
        }
        for (int i = 0; i < entry.gtkValues.length; i += 1) {
          gtkKeyvalCodeMap.writeln('  insert_record(table, ${toHex(entry.gtkValues[i])}, ${entry.value});    // ${entry.gtkNames[i]}');
        }
      }
    }
    return gtkKeyvalCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_linux_cc.tmpl');

  @override
  String outputPath(String _) => path.join(flutterRoot.path, '..', path.join('engine', 'src', 'flutter', 'shell', 'platform', 'linux', 'keyboard_map.cc'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'XKB_SCAN_CODE_MAP': xkbScanCodeMap,
      'GTK_KEYVAL_CODE_MAP': gtkKeyvalCodeMap,
    };
  }
}
