// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'constants.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';

/// Given an [input] string, wraps the text at 80 characters and prepends each
/// line with the [prefix] string. Use for generated comments.
String _wrapString(String input) {
  return wrapString(input, prefix: '  /// ');
}

class SynonymKeyInfo {
  SynonymKeyInfo(this.keys, this.name);

  final List<LogicalKeyEntry> keys;
  final String name;

  // Use the first item in the synonyms as a template for the ID to use.
  // It won't end up being the same value because it'll be in the pseudo-key
  // plane.
  LogicalKeyEntry get primaryKey => keys[0];
  int get value => (primaryKey.value & ~kVariationMask) + kSynonymPlane;
  String get constantName => upperCamelToLowerCamel(name);
}

/// Generates the keyboard_key.dart based on the information in the key data
/// structure given to it.
class KeyboardKeysCodeGenerator extends BaseCodeGenerator {
  KeyboardKeysCodeGenerator(PhysicalKeyData keyData, LogicalKeyData logicalData) : super(keyData, logicalData);

  /// Gets the generated definitions of PhysicalKeyboardKeys.
  String get _physicalDefinitions {
    final StringBuffer definitions = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.entries) {
      final String firstComment = _wrapString('Represents the location of the '
        '"${entry.commentName}" key on a generalized keyboard.');
      final String otherComments = _wrapString('See the function '
        '[KeyEvent.physical] for more information.');
      definitions.write('''

$firstComment  ///
$otherComments  static const PhysicalKeyboardKey ${entry.constantName} = PhysicalKeyboardKey(${toHex(entry.usbHidCode, digits: 8)});
''');
    }
    return definitions.toString();
  }

  String get _physicalDebugNames {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.entries) {
      result.write('''
      ${toHex(entry.usbHidCode, digits: 8)}: '${entry.commentName}',
''');
    }
    return result.toString();
  }

  /// Gets the generated definitions of LogicalKeyboardKeys.
  String get _logicalDefinitions {
    final StringBuffer definitions = StringBuffer();
    void printKey(int flutterId, String constantName, String commentName, {String? otherComments}) {
      final String firstComment = _wrapString('Represents the logical "$commentName" key on the keyboard.');
      otherComments ??= _wrapString('See the function [KeyEvent.logical] for more information.');
      definitions.write('''

$firstComment  ///
$otherComments  static const LogicalKeyboardKey $constantName = LogicalKeyboardKey(${toHex(flutterId, digits: 11)});
''');
    }

    for (final LogicalKeyEntry entry in logicalData.entries) {
      printKey(
        entry.value,
        entry.constantName,
        entry.commentName,
      );
    }
    for (final SynonymKeyInfo synonymInfo in synonyms) {
      // Use the first item in the synonyms as a template for the ID to use.
      // It won't end up being the same value because it'll be in the pseudo-key
      // plane.
      final Set<String> unionNames = synonymInfo.keys.map(
        (LogicalKeyEntry entry) => entry.constantName).toSet();
      printKey(synonymInfo.value, synonymInfo.constantName, PhysicalKeyEntry.getCommentName(synonymInfo.name),
          otherComments: _wrapString('This key represents the union of the keys '
              '$unionNames when comparing keys. This key will never be generated '
              'directly, its main use is in defining key maps.'));
    }
    return definitions.toString();
  }

  String get _logicalSynonyms {
    final StringBuffer result = StringBuffer();
    for (final SynonymKeyInfo synonymInfo in synonyms) {
      for (final LogicalKeyEntry key in synonymInfo.keys) {
        final String synonymName = upperCamelToLowerCamel(synonymInfo.name);
        result.writeln('    ${key.constantName}: $synonymName,');
      }
    }
    return result.toString();
  }

  String get _logicalKeyLabels {
    final StringBuffer result = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.entries) {
      result.write('''
    ${toHex(entry.value, digits: 11)}: '${entry.commentName}',
''');
    }
    for (final SynonymKeyInfo synonymInfo in synonyms) {
      result.write('''
    ${toHex(synonymInfo.value)}: '${synonymInfo.name}',
''');
    }
    return result.toString();
  }

  /// This generates the map of USB HID codes to physical keys.
  String get _predefinedHidCodeMap {
    final StringBuffer scanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.entries) {
      scanCodeMap.writeln('    ${toHex(entry.usbHidCode)}: ${entry.constantName},');
    }
    return scanCodeMap.toString().trimRight();
  }

  /// This generates the map of Flutter key codes to logical keys.
  String get _predefinedKeyCodeMap {
    final StringBuffer keyCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.entries) {
      keyCodeMap.writeln('    ${toHex(entry.value, digits: 11)}: ${entry.constantName},');
    }
    for (final SynonymKeyInfo synonymInfo in synonyms) {
      keyCodeMap.writeln('    ${toHex(synonymInfo.value, digits: 11)}: ${synonymInfo.constantName},');
    }
    return keyCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(dataRoot, 'keyboard_key.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'LOGICAL_KEY_MAP': _predefinedKeyCodeMap,
      'LOGICAL_KEY_DEFINITIONS': _logicalDefinitions,
      'LOGICAL_KEY_SYNONYMS': _logicalSynonyms,
      'LOGICAL_KEY_KEY_LABELS': _logicalKeyLabels,
      'PHYSICAL_KEY_MAP': _predefinedHidCodeMap,
      'PHYSICAL_KEY_DEFINITIONS': _physicalDefinitions,
      'PHYSICAL_KEY_DEBUG_NAMES': _physicalDebugNames,
    };
  }

  late final List<SynonymKeyInfo> synonyms = LogicalKeyData.synonyms.entries.map(
    (MapEntry<String, List<String>> synonymDefinition) {
      final List<LogicalKeyEntry> entries = synonymDefinition.value.map(
        (String name) => logicalData.entryByName(name)).toList();
      return SynonymKeyInfo(
        entries,
        synonymDefinition.key,
      );
    }
  ).toList();
}
