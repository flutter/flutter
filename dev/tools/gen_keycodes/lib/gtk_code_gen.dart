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
  GtkCodeGenerator(PhysicalKeyData keyData, LogicalKeyData logicalData)
    : super(keyData, logicalData);

  /// This generates the map of XKB scan codes to Flutter physical keys.
  String get xkbScanCodeMap {
    final OutputLines<int> lines = OutputLines<int>('GTK scancode map');
    for (final PhysicalKeyEntry entry in keyData.data.values) {
      if (entry.xKbScanCode != null) {
        lines.add(entry.xKbScanCode!, '  insert_record(table, ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)});  // ${entry.constantName}');
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of GTK keyval codes to Flutter logical keys.
  String get gtkKeyvalCodeMap {
    final OutputLines<int> lines = OutputLines<int>('GTK keyval map');
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      zipStrict(entry.gtkValues, entry.gtkNames, (int value, String name) {
        lines.add(value, '  insert_record(table, ${toHex(value)}, ${toHex(entry.value, digits: 11)});  // $name');
      });
    }
    return lines.sortedJoin().trimRight();
  }

  static String constructMapFromModToKeys(
      Map<String, List<String>> source,
      PhysicalKeyData physicalData,
      LogicalKeyData logicalData,
      String debugFunctionName,
  ) {
    final StringBuffer result = StringBuffer();
    source.forEach((String modifierBitName, List<String> keyNames) {
      if (keyNames.length != 2 && keyNames.length != 3) {
        print('Unexpected keyName length ${keyNames.length}.');
        return;
      }
      final String primaryLogicalName = keyNames[0];
      final String primaryPhysicalName = keyNames[1];
      final String? secondaryPhysicalName = keyNames.length == 3 ? keyNames[2] : null;
      final LogicalKeyEntry? primaryLogical = logicalData.data[primaryLogicalName];
      if (primaryLogical == null) {
        print('Unrecognized primary logical key $primaryLogicalName specified for $debugFunctionName.');
        return;
      }
      final PhysicalKeyEntry? primaryPhysical = physicalData.data[primaryPhysicalName];
      if (primaryPhysical == null) {
        print('Unrecognized primary physical key $primaryPhysicalName specified for $debugFunctionName.');
        return;
      }
      final PhysicalKeyEntry? secondaryPhysical = secondaryPhysicalName == null ? null : physicalData.data[secondaryPhysicalName];
      if (secondaryPhysical == null && secondaryPhysicalName != null) {
        print('Unrecognized secondary physical key $secondaryPhysicalName specified for $debugFunctionName.');
        return;
      }
      final String pad = secondaryPhysical == null ? '' : ' ';
      result.writeln('''

  data = g_new(FlKeyEmbedderCheckedKey, 1);
  g_hash_table_insert(table, GUINT_TO_POINTER(GDK_${modifierBitName}_MASK), data);
  data->primary_logical_key = ${toHex(primaryLogical.value, digits: 11)};$pad  // ${primaryLogical.constantName}
  data->primary_physical_key = ${toHex(primaryPhysical.usbHidCode, digits: 9)};$pad   // ${primaryPhysical.constantName}''');
      if (secondaryPhysical != null) {
        result.writeln('''
  data->secondary_physical_key = ${toHex(secondaryPhysical.usbHidCode, digits: 9)};  // ${secondaryPhysical.constantName}''');
      }
      result.writeln('''
  data->is_caps_lock = ${primaryPhysicalName == 'CapsLock' ? 'true' : 'false'};''');
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
  String outputPath(String platform) => path.join(flutterRoot.path, '..', path.join('engine', 'src', 'flutter', 'shell', 'platform', 'linux', 'key_mapping.cc'));

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
