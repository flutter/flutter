// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';


/// Generates the key mapping of GTK, based on the information in the key
/// data structure given to it.
class GtkCodeGenerator extends PlatformCodeGenerator {
  GtkCodeGenerator(PhysicalKeyData keyData, this.logicalData) : super(keyData);

  final LogicalKeyData logicalData;

  /// This generates the map of XKB scan codes to Flutter physical keys.
  String get xkbScanCodeMap {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.xKbScanCode != null) {
        result.writeln('  insert_record(table, ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)});  // ${entry.constantName}');
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of GTK keyval codes to Flutter logical keys.
  String get gtkKeyvalCodeMap {
    final StringBuffer result = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      zipStrict(entry.gtkValues, entry.gtkNames, (int value, String name) {
        result.writeln('  insert_record(table, ${toHex(value)}, ${toHex(entry.value, digits: 9)});  // $name');
      });
    }
    return result.toString().trimRight();
  }

  static String constructMapFromModToKeys(
      Map<String, List<String>> source,
      PhysicalKeyData physicalData,
      LogicalKeyData logicalData,
      String debugFunctionName,
  ) {
    final StringBuffer result = StringBuffer();
    source.forEach((String modifierBitName, List<String> keyNames) {
      final String firstLogicalName = keyNames[0];
      final List<String> physicalNames = keyNames.sublist(1);
      final int length = physicalNames.length;
      final LogicalKeyEntry firstLogical = logicalData.data[firstLogicalName];
      if (firstLogical == null) {
        print('Unrecognized first logical key $firstLogicalName specified for $debugFunctionName.');
        return;
      }
      result.writeln('''

  data = g_new(FlKeyEmbedderCheckedKey, 1);
  g_hash_table_insert(table, GUINT_TO_POINTER(GDK_${modifierBitName}_MASK), data);
  data->length = $length;
  data->first_logical_key = ${toHex(firstLogical.value, digits: 9)};  // ${firstLogical.constantName}
  physical_keys = g_new(uint64_t, $length);
  data->physical_keys = physical_keys;
  data->is_caps_lock = ${physicalNames.first == 'CapsLock' ? 'true' : 'false'};''');
      for (final String physicalName in physicalNames) {
        final PhysicalKeyEntry entry = physicalData.getEntryByName(physicalName);
        if (entry == null) {
          print('Unrecognized physical key $physicalName specified for $debugFunctionName.');
          return;
        }
        result.writeln('  *(physical_keys++) = ${toHex(entry.usbHidCode)};  // ${entry.name}');
      }
    });
    return result.toString().trimRight();
  }

  String get gtkModifierBitMap {
    final Map<String, List<String>> source = parseMapOfListOfString(File(
      path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'gtk_modifier_bit_mapping.json')
    ).readAsStringSync());
    return constructMapFromModToKeys(source, keyData, logicalData, 'gtkModifierBitMap');
  }

  String get gtkModeBitMap {
    final Map<String, List<String>> source = parseMapOfListOfString(File(
      path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'gtk_mode_bit_mapping.json')
    ).readAsStringSync());
    return constructMapFromModToKeys(source, keyData, logicalData, 'gtkModeBitMap');
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'gtk_key_mapping_cc.tmpl');

  @override
  String outputPath(String _) => path.join(flutterRoot.path, '..', path.join('engine', 'src', 'flutter', 'shell', 'platform', 'linux', 'key_mapping.cc'));

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'XKB_SCAN_CODE_MAP': xkbScanCodeMap,
      'GTK_KEYVAL_CODE_MAP': gtkKeyvalCodeMap,
      'GTK_MODIFIER_BIT_MAP': gtkModifierBitMap,
      'GTK_MODE_BIT_MAP': gtkModeBitMap,
    };
  }
}
