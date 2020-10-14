// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'physical_key_data.dart';
import 'logical_key_data.dart';
import 'utils.dart';

/// Given an [input] string, wraps the text at 80 characters and prepends each
/// line with the [prefix] string. Use for generated comments.
String _wrapString(String input) {
  return wrapString(input, prefix: '  /// ');
}

class _ExplicitKeySpecification {
  const _ExplicitKeySpecification(this.code, this.name, [this.constantName]);

  final int code;
  final String name;
  final String constantName;
}

/// Generates the keyboard_keys.dart based on the information in the key data
/// structure given to it.
class KeyboardKeysCodeGenerator extends BaseCodeGenerator {
  KeyboardKeysCodeGenerator(PhysicalKeyData physicalData, this.logicalData) : super(physicalData);

  final LogicalKeyData logicalData;
  PhysicalKeyData get physicalData => keyData;

  /// Gets the generated definitions of PhysicalKeyboardKeys.
  String get _physicalDefinitions {
    final StringBuffer definitions = StringBuffer();
    for (final PhysicalKeyEntry entry in physicalData.data) {
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

  static List<LogicalKeyEntry> _alnumLogicalKeys() {
    final List<_ExplicitKeySpecification> keys = <_ExplicitKeySpecification>[]
      ..addAll(List<_ExplicitKeySpecification>.generate(26, (int i) {
        final int code = i + 'a'.codeUnits[0];
        final String char = String.fromCharCode(code);
        return _ExplicitKeySpecification(code, 'lowercase${char.toUpperCase()}', 'lower${char.toUpperCase()}');
      }))
      ..addAll(List<_ExplicitKeySpecification>.generate(26, (int i) {
        final int code = i + 'A'.codeUnits[0];
        final String char = String.fromCharCode(code);
        return _ExplicitKeySpecification(code, 'uppercase$char', 'upper$char');
      }))
      ..addAll(List<_ExplicitKeySpecification>.generate(10, (int i) {
        final int code = i + '0'.codeUnits[0];
        final String char = String.fromCharCode(code);
        return _ExplicitKeySpecification(code, 'digit$char');
      }))
      ..add(_ExplicitKeySpecification(' '.codeUnits[0], 'space'));

    return keys.map((_ExplicitKeySpecification key) {
      final LogicalKeyEntry result = LogicalKeyEntry(name: key.name, value: key.code);
      if (key.constantName != null)
        result.constantName = key.constantName;
      return result;
    }).toList();
  }

  /// Gets the generated definitions of LogicalKeyboardKeys.
  String get _logicalDefinitions {
    String escapeLabel(String label) => label.contains("'") ? 'r"$label"' : "r'$label'";
    final StringBuffer definitions = StringBuffer();
    void printKey(int flutterId, String constantName, String commentName) {
      final String firstComment = _wrapString('Represents the logical "$commentName" key on the keyboard.');
      final String otherComments = _wrapString('See the function [RawKeyEvent.logicalKey] for more information.');
      definitions.write('''

$firstComment  ///
$otherComments  static const LogicalKeyboardKey $constantName = LogicalKeyboardKey(${toHex(flutterId, digits: 11)}, debugName: kReleaseMode ? null : '$commentName');
''');
    }

    for (final LogicalKeyEntry entry in _alnumLogicalKeys()..addAll(logicalData.data)) {
      printKey(
        entry.flutterId,
        entry.constantName,
        entry.commentName,
      );
    }
    // for (final String name in PhysicalKeyEntry.synonyms.keys) {
    //   // Use the first item in the synonyms as a template for the ID to use.
    //   // It won't end up being the same value because it'll be in the pseudo-key
    //   // plane.
    //   final PhysicalKeyEntry entry = physicalData.data.firstWhere((PhysicalKeyEntry item) => item.name == PhysicalKeyEntry.synonyms[name][0]);
    //   final Set<String> unionNames = PhysicalKeyEntry.synonyms[name].map<String>((dynamic name) {
    //     return upperCamelToLowerCamel(name as String);
    //   }).toSet();
    //   printKey(PhysicalKeyEntry.synonymPlane | entry.flutterId, entry.keyLabel, name, PhysicalKeyEntry.getCommentName(name),
    //       otherComments: _wrapString('This key represents the union of the keys '
    //           '$unionNames when comparing keys. This key will never be generated '
    //           'directly, its main use is in defining key maps.'));
    // }
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
    for (final PhysicalKeyEntry entry in physicalData.data) {
      scanCodeMap.writeln('    ${toHex(entry.usbHidCode)}: ${entry.constantName},');
    }
    return scanCodeMap.toString().trimRight();
  }

  /// This generates the map of Flutter key codes to logical keys.
  String get _predefinedKeyCodeMap {
    final StringBuffer keyCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in _alnumLogicalKeys()..addAll(logicalData.data)) {
      keyCodeMap.writeln('    ${toHex(entry.flutterId, digits: 10)}: ${entry.constantName},');
    }
    // for (final String entry in PhysicalKeyEntry.synonyms.keys) {
    //   // Use the first item in the synonyms as a template for the ID to use.
    //   // It won't end up being the same value because it'll be in the pseudo-key
    //   // plane.
    //   final PhysicalKeyEntry primaryKey = physicalData.data.firstWhere((PhysicalKeyEntry item) {
    //     return item.name == PhysicalKeyEntry.synonyms[entry][0];
    //   }, orElse: () => null);
    //   assert(primaryKey != null);
    //   keyCodeMap.writeln('    ${toHex(PhysicalKeyEntry.synonymPlane | primaryKey.flutterId, digits: 10)}: $entry,');
    // }
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
