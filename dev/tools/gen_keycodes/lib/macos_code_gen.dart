// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'mask_constants.dart';
import 'physical_key_data.dart';
import 'utils.dart';

// Map from keys of synonyms.json to macOS's modifier flag constants.
const Map<String, String> kSynonymToModifierFlag = {
  'shift': 'NSEventModifierFlagShift',
  'control': 'NSEventModifierFlagControl',
  'alt': 'NSEventModifierFlagOption',
  'meta': 'NSEventModifierFlagCommand',
};

// The name of keys that require special attention.
const List<String> kSpecialKeys = <String>['CapsLock'];

String _toConstantVariableName(String variableName) {
  return 'k${variableName[0].toUpperCase()}${variableName.substring(1)}';
}

/// Generates the key mapping of macOS, based on the information in the key
/// data structure given to it.
class MacOsCodeGenerator extends PlatformCodeGenerator {
  MacOsCodeGenerator(PhysicalKeyData keyData, this.logicalData, this.maskConstants) : super(keyData);

  final LogicalKeyData logicalData;

  final List<MaskConstant> maskConstants;

  /// This generates the map of macOS key codes to physical keys.
  String get _scanCodeMap {
    final StringBuffer scanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.macOsScanCode != null) {
        scanCodeMap.writeln('  @${toHex(entry.macOsScanCode)} : @${toHex(entry.usbHidCode)},    // ${entry.constantName}');
      }
    }
    return scanCodeMap.toString().trimRight();
  }

  String get _keyCodeToLogicalMap {
    final StringBuffer result = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      zipStrict(entry.macOsKeyCodeValues, entry.macOsKeyCodeNames, (int macOsValue, String macOsName) {
        result.writeln('  @${toHex(macOsValue)} : @${toHex(entry.value, digits: 10)},    // $macOsName');
      });
    }
    return result.toString().trimRight();
  }

  /// This generates the map of macOS number pad key codes to logical keys.
  // String get _numpadMap {
  //   final StringBuffer numPadMap = StringBuffer();
  //   for (final PhysicalKeyEntry entry in numpadKeyData) {
  //     if (entry.macOsScanCode != null) {
  //       numPadMap.writeln('  @${toHex(entry.macOsScanCode)} : @${toHex(entry.flutterId, digits: 10)},    // ${entry.constantName}');
  //     }
  //   }
  //   return numPadMap.toString().trimRight();
  // }

  // String get _functionKeyMap {
  //   final StringBuffer functionKeyMap = StringBuffer();
  //   for (final PhysicalKeyEntry entry in functionKeyData) {
  //     if (entry.macOsScanCode != null) {
  //       functionKeyMap.writeln('  @${toHex(entry.macOsScanCode)} : @${toHex(entry.flutterId, digits: 10)},    // ${entry.constantName}');
  //     }
  //   }
  //   return functionKeyMap.toString().trimRight();
  // }

  /// This generates the mask values for the part of a key code that defines its plane.
  String get _maskConstants {
    final StringBuffer buffer = StringBuffer();
    for (final MaskConstant constant in maskConstants) {
      buffer.writeln('/**');
      buffer.write(constant.description
        .map((String line) => wrapString(line, prefix: ' * '))
        .join(' *\n'));
      buffer.writeln(' */');
      buffer.writeln('const uint64_t ${_toConstantVariableName(constant.name)} = ${constant.value};');
      buffer.writeln('');
    }
    return buffer.toString().trimRight();
  }

  /// This generates a map between the physical code of sibling keys, such as
  /// left and right shift, including both directions.
  String get _siblingKeyMap {
    final StringBuffer siblingKeyMap = StringBuffer();
    PhysicalKeyEntry.synonyms.forEach((String name, List<String> keyNames) {
      assert(keyNames.length == 2);
      final int first = keyData.getEntryByName(keyNames[0]).macOsScanCode;
      final int second = keyData.getEntryByName(keyNames[1]).macOsScanCode;
      if (first == null || second == null) {
        print('Invalid sibling key: $name, $keyNames');
      }
      siblingKeyMap.writeln('  @${toHex(first)} : @${toHex(second)}, // $name');
      siblingKeyMap.writeln('  @${toHex(second)} : @${toHex(first)}, // $name');
    });
    return siblingKeyMap.toString().trimRight();
  }

  /// This generates a map from the physical code of a modifier key (each side)
  /// to the macOS constant flag.
  String get _keyToModifierFlagMap {
    final StringBuffer modifierKeyMap = StringBuffer();
    kSynonymToModifierFlag.forEach((String synonymName, String modifierFlag) {
      final List<String> keyNames = PhysicalKeyEntry.synonyms[synonymName];
      assert(keyNames.length == 2);
      modifierKeyMap.writeln('  @${toHex(keyData.getEntryByName(keyNames[0]).usbHidCode)} : @($modifierFlag),');
      modifierKeyMap.writeln('  @${toHex(keyData.getEntryByName(keyNames[1]).usbHidCode)} : @($modifierFlag),');
    });
    return modifierKeyMap.toString().trimRight();
  }

  /// This generates some keys that needs special attention.
  String get _specialKeyConstants {
    final StringBuffer specialKeyConstants = StringBuffer();
    for (final String keyName in kSpecialKeys) {
      specialKeyConstants.writeln('const uint64_t k${keyName}PhysicalKey = ${toHex(keyData.getEntryByName(keyName).usbHidCode)};');
    }
    return specialKeyConstants.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'macos_key_code_map_cc.tmpl');

  @override
  String outputPath(String platform) => path.join(flutterRoot.path, '..', 'engine', 'src', 'flutter', path.join('shell', 'platform', 'darwin', 'macos', 'framework', 'Source', 'KeyCodeMap.mm'));

  @override
  Map<String, String> mappings() {
    // There is no macOS keycode map since macOS uses keycode to represent a physical key.
    // The LogicalKeyboardKey is generated by raw_keyboard_macos.dart from the unmodified characters
    // from NSEvent.
    return <String, String>{
      'MACOS_SCAN_CODE_MAP': _scanCodeMap,
      'MACOS_KEYCODE_LOGICAL_MAP': _keyCodeToLogicalMap,
      'MASK_CONSTANTS': _maskConstants,
      'SIBLING_KEY_MAP': _siblingKeyMap,
      'MODIFIER_FLAG_MAP': _keyToModifierFlagMap,
      'SPECIAL_KEY_CONSTANTS': _specialKeyConstants,
    };
  }
}
