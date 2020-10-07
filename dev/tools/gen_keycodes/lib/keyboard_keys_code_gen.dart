// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'physical_key_data.dart';
import 'utils.dart';

/// Given an [input] string, wraps the text at 80 characters and prepends each
/// line with the [prefix] string. Use for generated comments.
String _wrapString(String input) {
  return wrapString(input, prefix: '  /// ');
}

/// Generates the keyboard_keys.dart based on the information in the key data
/// structure given to it.
class KeyboardKeysCodeGenerator extends BaseCodeGenerator {
  KeyboardKeysCodeGenerator(PhysicalKeyData keyData) : super(keyData);

  /// Gets the generated definitions of PhysicalKeyboardKeys.
  String get _physicalDefinitions {
    final StringBuffer definitions = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      final String firstComment = _wrapString('Represents the location of the '
        '"${entry.commentName}" key on a generalized keyboard.');
      final String otherComments = _wrapString('See the function '
        '[RawKeyEvent.physicalKey] for more information.');
      definitions.write('''

$firstComment  ///
$otherComments  static const PhysicalKeyboardKey ${entry.constantName} = PhysicalKeyboardKey(${toHex(entry.usbHidCode, digits: 8)}, debugName: kReleaseMode ? null : '${entry.commentName}');
''');
    }
    return definitions.toString();
  }

  /// Gets the generated definitions of LogicalKeyboardKeys.
  String get _logicalDefinitions {
    String escapeLabel(String label) => label.contains("'") ? 'r"$label"' : "r'$label'";
    final StringBuffer definitions = StringBuffer();
    void printKey(int flutterId, String keyLabel, String constantName, String commentName, {String otherComments}) {
      final String firstComment = _wrapString('Represents the logical "$commentName" key on the keyboard.');
      otherComments ??= _wrapString('See the function [RawKeyEvent.logicalKey] for more information.');
      if (keyLabel == null) {
        definitions.write('''

$firstComment  ///
$otherComments  static const LogicalKeyboardKey $constantName = LogicalKeyboardKey(${toHex(flutterId, digits: 11)}, debugName: kReleaseMode ? null : '$commentName');
''');
      } else {
        definitions.write('''

$firstComment  ///
$otherComments  static const LogicalKeyboardKey $constantName = LogicalKeyboardKey(${toHex(flutterId, digits: 11)}, keyLabel: ${escapeLabel(keyLabel)}, debugName: kReleaseMode ? null : '$commentName');
''');
      }
    }

    for (final PhysicalKeyEntry entry in keyData.data) {
      printKey(
        entry.flutterId,
        entry.keyLabel,
        entry.constantName,
        entry.commentName,
      );
    }
    for (final String name in PhysicalKeyEntry.synonyms.keys) {
      // Use the first item in the synonyms as a template for the ID to use.
      // It won't end up being the same value because it'll be in the pseudo-key
      // plane.
      final PhysicalKeyEntry entry = keyData.data.firstWhere((PhysicalKeyEntry item) => item.name == PhysicalKeyEntry.synonyms[name][0]);
      final Set<String> unionNames = PhysicalKeyEntry.synonyms[name].map<String>((dynamic name) {
        return upperCamelToLowerCamel(name as String);
      }).toSet();
      printKey(PhysicalKeyEntry.synonymPlane | entry.flutterId, entry.keyLabel, name, PhysicalKeyEntry.getCommentName(name),
          otherComments: _wrapString('This key represents the union of the keys '
              '$unionNames when comparing keys. This key will never be generated '
              'directly, its main use is in defining key maps.'));
    }
    return definitions.toString();
  }

  String get _logicalSynonyms {
    final StringBuffer synonyms = StringBuffer();
    for (final String name in PhysicalKeyEntry.synonyms.keys) {
      for (final String synonym in PhysicalKeyEntry.synonyms[name].cast<String>()) {
        final String keyName = upperCamelToLowerCamel(synonym);
        synonyms.writeln('    $keyName: $name,');
      }
    }
    return synonyms.toString();
  }

  /// This generates the map of USB HID codes to physical keys.
  String get _predefinedHidCodeMap {
    final StringBuffer scanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      scanCodeMap.writeln('    ${toHex(entry.usbHidCode)}: ${entry.constantName},');
    }
    return scanCodeMap.toString().trimRight();
  }

  /// This generates the map of Flutter key codes to logical keys.
  String get _predefinedKeyCodeMap {
    final StringBuffer keyCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      keyCodeMap.writeln('    ${toHex(entry.flutterId, digits: 10)}: ${entry.constantName},');
    }
    for (final String entry in PhysicalKeyEntry.synonyms.keys) {
      // Use the first item in the synonyms as a template for the ID to use.
      // It won't end up being the same value because it'll be in the pseudo-key
      // plane.
      final PhysicalKeyEntry primaryKey = keyData.data.firstWhere((PhysicalKeyEntry item) {
        return item.name == PhysicalKeyEntry.synonyms[entry][0];
      }, orElse: () => null);
      assert(primaryKey != null);
      keyCodeMap.writeln('    ${toHex(PhysicalKeyEntry.synonymPlane | primaryKey.flutterId, digits: 10)}: $entry,');
    }
    return keyCodeMap.toString().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_key.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'PHYSICAL_KEY_MAP': _predefinedHidCodeMap,
      'LOGICAL_KEY_MAP': _predefinedKeyCodeMap,
      'LOGICAL_KEY_DEFINITIONS': _logicalDefinitions,
      'LOGICAL_KEY_SYNONYMS': _logicalSynonyms,
      'PHYSICAL_KEY_DEFINITIONS': _physicalDefinitions,
    };
  }
}
