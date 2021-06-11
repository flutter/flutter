// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';


/// Generates the key mapping for GTK, based on the information in the key
/// data structure given to it.
class GtkCodeGenerator extends PlatformCodeGenerator {
  GtkCodeGenerator(
    PhysicalKeyData keyData,
    LogicalKeyData logicalData,
    String modifierBitMapping,
    String lockBitMapping,
  ) : _modifierBitMapping = parseMapOfListOfString(modifierBitMapping),
      _lockBitMapping = parseMapOfListOfString(lockBitMapping),
      super(keyData, logicalData);

  /// This generates the map of XKB scan codes to Flutter physical keys.
  String get _xkbScanCodeMap {
    final OutputLines<int> lines = OutputLines<int>('GTK scancode map');
    for (final PhysicalKeyEntry entry in keyData.entries) {
      if (entry.xKbScanCode != null) {
        lines.add(entry.xKbScanCode!, '  insert_record(table, ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)});  // ${entry.constantName}');
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of GTK keyval codes to Flutter logical keys.
  String get _gtkKeyvalCodeMap {
    final OutputLines<int> lines = OutputLines<int>('GTK keyval map');
    for (final LogicalKeyEntry entry in logicalData.entries) {
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
      assert(keyNames.length == 2 || keyNames.length == 3);
      final String primaryLogicalName = keyNames[0];
      final String primaryPhysicalName = keyNames[1];
      final String? secondaryPhysicalName = keyNames.length == 3 ? keyNames[2] : null;
      final LogicalKeyEntry primaryLogical = logicalData.entryByName(primaryLogicalName);
      final PhysicalKeyEntry primaryPhysical = physicalData.entryByName(primaryPhysicalName);
      final PhysicalKeyEntry? secondaryPhysical = secondaryPhysicalName == null ? null : physicalData.entryByName(secondaryPhysicalName);
      if (secondaryPhysical == null && secondaryPhysicalName != null) {
        print('Unrecognized secondary physical key $secondaryPhysicalName specified for $debugFunctionName.');
        return;
      }
      final String pad = secondaryPhysical == null ? '' : ' ';
      result.writeln('''

  data = g_new(FlKeyEmbedderCheckedKey, 1);
  g_hash_table_insert(table, GUINT_TO_POINTER(GDK_${modifierBitName}_MASK), data);
  data->is_caps_lock = ${primaryPhysicalName == 'CapsLock' ? 'true' : 'false'};
  data->primary_logical_key = ${toHex(primaryLogical.value, digits: 11)};$pad  // ${primaryLogical.constantName}
  data->primary_physical_key = ${toHex(primaryPhysical.usbHidCode, digits: 9)};$pad   // ${primaryPhysical.constantName}''');
      if (secondaryPhysical != null) {
        result.writeln('''
  data->secondary_physical_key = ${toHex(secondaryPhysical.usbHidCode, digits: 9)};  // ${secondaryPhysical.constantName}''');
      }
    });
    return result.toString().trimRight();
  }

  String get _gtkModifierBitMap {
    return constructMapFromModToKeys(_modifierBitMapping, keyData, logicalData, 'gtkModifierBitMap');
  }
  final Map<String, List<String>> _modifierBitMapping;

  String get _gtkModeBitMap {
    return constructMapFromModToKeys(_lockBitMapping, keyData, logicalData, 'gtkModeBitMap');
  }
  final Map<String, List<String>> _lockBitMapping;

  @override
  String get templatePath => path.join(dataRoot, 'gtk_key_mapping_cc.tmpl');

  @override
  String outputPath(String platform) => path.join(PlatformCodeGenerator.engineRoot,
      'shell', 'platform', 'linux', 'key_mapping.cc');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'XKB_SCAN_CODE_MAP': _xkbScanCodeMap,
      'GTK_KEYVAL_CODE_MAP': _gtkKeyvalCodeMap,
      'GTK_MODIFIER_BIT_MAP': _gtkModifierBitMap,
      'GTK_MODE_BIT_MAP': _gtkModeBitMap,
    };
  }
}
