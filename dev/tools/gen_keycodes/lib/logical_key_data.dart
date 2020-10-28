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
    String gtkKeyCodeHeader,
    String gtkNameMap,
  )   : assert(chromiumKeys != null),
        assert(gtkKeyCodeHeader != null),
        assert(gtkNameMap != null) {
    data = _readHidEntries(chromiumKeys);
    _nameToGtkKeyCode = _readGtkKeyCodes(gtkKeyCodeHeader);
    // Cast GTK dom map
    final Map<String, List<dynamic>> dynamicGtkNames = (json.decode(gtkNameMap) as Map<String, dynamic>).cast<String, List<dynamic>>();
    _nameToGtkName = dynamicGtkNames.map<String, List<String>>((String key, List<dynamic> value) {
      return MapEntry<String, List<String>>(key, value.cast<String>());
    });
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
    for (final LogicalKeyEntry entry in data) {
      // GTK key names
      entry.gtkNames = _nameToGtkName[entry.constantName]?.cast<String>();
      if (entry.gtkNames != null && entry.gtkNames.isNotEmpty) {
        for (final String gtkName in entry.gtkNames) {
          if (_nameToGtkKeyCode[gtkName] != null) {
            entry.gtkValues ??= <int>[];
            entry.gtkValues.add(_nameToGtkKeyCode[gtkName]);
          }
        }
      }
    }

    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final LogicalKeyEntry entry in data) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }

  /// The list of keys.
  List<LogicalKeyEntry> data;

  /// The mapping from the Flutter name (e.g. "eject") to the GTK name (e.g.
  /// "GDK_KEY_Eject").
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, List<String>> _nameToGtkName;

  /// The mapping from GTK name (e.g. "GTK_KEY_comma") to the integer key code
  /// (logical meaning) of the key.
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, int> _nameToGtkKeyCode;

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
        final String name = match.group(1).replaceAll(RegExp('[^A-Za-z0-9]'), '');
        final int value = getHex(match.group(3));
        final LogicalKeyEntry newEntry = LogicalKeyEntry(
          value: value,
          commentName: LogicalKeyEntry.computeCommentName(name),
          constantName: LogicalKeyEntry.computeConstantName(name),
          webNames: [name],
          webValues: [value],
        );
        entries.add(newEntry);
      }
      return match.group(0);
    });
    return entries;
  }

  /// Parses entries from GTK's gdkkeysyms.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GDK_KEY_space 0x020
  Map<String, int> _readGtkKeyCodes(String headerFile) {
    final RegExp definedCodes = RegExp(r'#define GDK_KEY_([a-zA-Z0-9_]+)\s*0x([0-9a-f]+),?');
    final Map<String, int> replaced = <String, int>{};
    for (final Match match in definedCodes.allMatches(headerFile)) {
      replaced[match.group(1)] = int.parse(match.group(2), radix: 16);
    }
    return replaced;
  }
}

/// A single entry in the key data structure.
///
/// Can be read from JSON with the [LogicalKeyEntry.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class LogicalKeyEntry {
  /// Creates a single key entry from available data.
  LogicalKeyEntry({
    @required this.value,
    @required this.constantName,
    @required this.commentName,
    this.webNames,
    this.webValues,
    this.gtkNames,
    this.gtkValues,
  })  : assert(constantName != null),
        assert(commentName != null),
        assert(value != null);

  /// Populates the key from a JSON map.
  factory LogicalKeyEntry.fromJsonMapEntry(String name, Map<String, dynamic> map) {
    return LogicalKeyEntry(
      value: map['value'] as int,
      constantName: map['constant'] as String,
      commentName: map['english'] as String,
      webNames: (map['names']['web'] as List<dynamic>)?.cast<String>(),
      webValues: (map['values']['web'] as List<dynamic>)?.cast<int>(),
      gtkNames: (map['names']['gtk'] as List<dynamic>)?.cast<String>(),
      gtkValues: (map['values']['gtk'] as List<dynamic>)?.cast<int>(),
    );
  }

  final int value;

  final String constantName;

  /// The name of the key suitable for placing in comments.
  final String commentName;

  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  List<String> webNames;

  /// The value of the key.
  List<int> webValues;

  /// The list of names that GTK gives to this key (symbol names minus the
  /// prefix).
  List<String> gtkNames;

  /// The list of GTK key codes matching this key, created by looking up the
  /// Linux name in the GTK data, and substituting the GTK key code
  /// value.
  List<int> gtkValues;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'constant': constantName,
      'english': commentName,
      'value': value,
      'names': <String, dynamic>{
        'web': webNames,
        'gtk': gtkNames,
      },
      'values': <String, List<int>>{
        'web': webValues,
        'gtk': gtkValues,
      },
    };
  }

  @override
  String toString() {
    return """'$constantName': (name: "$commentName", value: ${toHex(value)}) """;
  }

  static String _computeConstantNameBase(String name) {
    final String result = name
      .replaceAll('PinP', 'PInP');
      // .replaceAllMapped(RegExp('([A-Z])([A-Z]+)([A-Z0-9]|\$)'),
      //   (Match match) => '${match.group(1)}${match.group(2).toLowerCase()}${match.group(3)}');
    return result;
  }

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_keys.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  static String computeConstantName(String name) {
    String result = upperCamelToLowerCamel(_computeConstantNameBase(name));
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  }

  /// Takes the [constantName] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  static String computeCommentName(String name) {
    String upperCamel = lowerCamelToUpperCamel(_computeConstantNameBase(name));
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
}
