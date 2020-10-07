// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

import 'package:gen_keycodes/utils.dart';

/// The data structure used to manage keyboard key entries.
///
/// The main constructor parses the given input data into the data structure.
///
/// The data structure can be also loaded and saved to JSON, with the
/// [LogicalKeyData.fromJson] constructor and [toJson] method, respectively.
class LogicalKeyData {
  /// Parses the input data given in from the various data source files,
  /// populating the data structure.
  ///
  /// None of the parameters may be null.
  LogicalKeyData(
    String chromiumKeys,
  )   : assert(chromiumKeys != null) {
    data = _readHidEntries(chromiumKeys);
  }

  /// Parses the given JSON data and populates the data structure from it.
  LogicalKeyData.fromJson(Map<String, dynamic> contentMap) {
    data = <LogicalKeyEntry>[
      for (final String key in contentMap.keys) LogicalKeyEntry.fromJsonMapEntry(key, contentMap[key] as Map<String, dynamic>),
    ];
  }

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [LogicalKeyData.fromJson].
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final LogicalKeyEntry entry in data) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }

  /// The list of keys.
  List<LogicalKeyEntry> data;

  /// Parses entries from Chromium's key mapping header file.
  ///
  /// Lines in this file look like either of these (without the ///):
  ///                Key        Enum      Unicode code point
  /// DOM_KEY_UNI("Backspace", BACKSPACE, 0x0008),
  ///                Key        Enum       Value
  /// DOM_KEY_MAP("Accel",      ACCEL,    0x0101),
  List<LogicalKeyEntry> _readHidEntries(String input) {
    final List<LogicalKeyEntry> entries = <LogicalKeyEntry>[];
    final RegExp domKeyRegExp = RegExp(
        r'DOM_KEY_(?:UNI|MAP)\s*\(\s*"([^\s]+?)",\s*([^\s]+?),\s*0x([a-fA-F0-9]+)\s*\)',
        multiLine: true);
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    input.replaceAllMapped(domKeyRegExp, (Match match) {
      if (match != null) {
        final LogicalKeyEntry newEntry = LogicalKeyEntry(
          value: getHex(match.group(3)),
          name: match.group(1).replaceAll(RegExp('[^A-Za-z0-9]'), ''),
        );
        entries.add(newEntry);
      }
      return match.group(0);
    });
    return entries;
  }
}

/// A single entry in the key data structure.
///
/// Can be read from JSON with the [LogicalKeyEntry.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class LogicalKeyEntry {
  /// Creates a single key entry from available data.
  ///
  /// The [usbHidCode] and [chromiumName] parameters must not be null.
  LogicalKeyEntry({
    @required this.name,
    @required this.value,
  })  : assert(name != null),
        assert(value != null);

  /// Populates the key from a JSON map.
  factory LogicalKeyEntry.fromJsonMapEntry(String name, Map<String, dynamic> map) {
    return LogicalKeyEntry(
      name: map['name'] as String,
      value: map['value'] as int,
    );
  }

  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  String name;
  /// The value of the key.
  int value;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
    };
  }

  int get flutterId => value;

  static String getCommentName(String constantNameBase) {
    String upperCamel = lowerCamelToUpperCamel(constantNameBase);
    upperCamel = upperCamel.replaceAllMapped(RegExp(r'(Digit|Numpad|Lang|Button|Left|Right)([0-9]+)'), (Match match) => '${match.group(1)} ${match.group(2)}');
    return upperCamel
      // 'fooBar' => 'foo Bar', 'fooBAR' => 'foo BAR'
      .replaceAllMapped(RegExp(r'([^A-Z])([A-Z])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      // 'ABCDoo' => 'ABC Doo'
      .replaceAllMapped(RegExp(r'([A-Z])([A-Z])([a-z])'), (Match match) => '${match.group(1)} ${match.group(2)}${match.group(3)}')
      // 'AB1' => 'AB 1', 'F1' => 'F1'
      .replaceAllMapped(RegExp(r'([A-Z]{2,})([0-9])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      // 'Foo1' => 'Foo 1'
      .replaceAllMapped(RegExp(r'([a-z])([0-9])'), (Match match) => '${match.group(1)} ${match.group(2)}')
      .trim();
  }

  /// Gets the name of the key suitable for placing in comments.
  ///
  /// Takes the [constantName] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  String get commentName => getCommentName(constantNameBase);

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_keys.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  String get constantNameBase {
    final String result = name
      .replaceAll('PinP', 'PInP');
      // .replaceAllMapped(RegExp('([A-Z])([A-Z]+)([A-Z0-9]|\$)'),
      //   (Match match) => '${match.group(1)}${match.group(2).toLowerCase()}${match.group(3)}');
    return result;
  }

  String get constantName {
    String result = _constantName ?? upperCamelToLowerCamel(constantNameBase);
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  }
  String _constantName;
  set constantName(String value) => _constantName = value;

  @override
  String toString() {
    return """'$constantName': (name: "$name", value: ${toHex(value)})""";
  }
}
