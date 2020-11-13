// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

import 'package:gen_keycodes/utils.dart';

const int kNumpadPlane = 0x00200000000;
const int kLeftModifierPlane = 0x00300000000;
const int kRightModifierPlane = 0x00400000000;

class _ModifierPair {
  const _ModifierPair(this.left, this.right);

  final String left;
  final String right;
}

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
    _readPrintables(data);
    _readHidEntries(data, chromiumKeys);
    // Cast GTK dom map
    final Map<String, List<dynamic>> dynamicGtkNames = (json.decode(gtkNameMap) as Map<String, dynamic>).cast<String, List<dynamic>>();
    final Map<String, List<String>> nameToGtkName = dynamicGtkNames.map<String, List<String>>((String key, List<dynamic> value) {
      return MapEntry<String, List<String>>(key, value.cast<String>());
    });
    _readGtkKeyCodes(data, gtkKeyCodeHeader, nameToGtkName);
    // Sort entries by value
    final List<MapEntry<String, LogicalKeyEntry>> sortedEntries = data.entries.toList()..sort(
      (MapEntry<String, LogicalKeyEntry> a, MapEntry<String, LogicalKeyEntry> b) => a.value.value.compareTo(b.value.value)
    );
    data
      ..clear()
      ..addEntries(sortedEntries);
  }

  /// Parses the given JSON data and populates the data structure from it.
  LogicalKeyData.fromJson(Map<String, dynamic> contentMap) {
    data.addEntries(contentMap.values.map((dynamic value) {
      final LogicalKeyEntry entry = LogicalKeyEntry.fromJsonMapEntry(value as Map<String, dynamic>);
      return MapEntry<String, LogicalKeyEntry>(entry.constantName, entry);
    }));
  }

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [LogicalKeyData.fromJson].
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final LogicalKeyEntry entry in data.values) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }

  /// Keys mapped from their constant names.
  final Map<String, LogicalKeyEntry> data = <String, LogicalKeyEntry>{};

  Map<String, LogicalKeyEntry> _readPrintables(Map<String, LogicalKeyEntry> data) {
    final Map<String, String> unusedNumpad = Map<String, String>.from(printableToNumpads);

    printable.forEach((String name, String char) {

      // If it has a numpad counterpart, also add the numpad key.
      if (printableToNumpads.containsKey(char)) {
        final String numpadName = printableToNumpads[char];
        data[LogicalKeyEntry.computeConstantName(numpadName)] = LogicalKeyEntry(
          value: char.codeUnitAt(0) + kNumpadPlane,
          commentName: LogicalKeyEntry.computeCommentName(numpadName),
          constantName: LogicalKeyEntry.computeConstantName(numpadName),
        );
        unusedNumpad.remove(char);
      }

      data[LogicalKeyEntry.computeConstantName(name)] = LogicalKeyEntry(
        value: char.codeUnitAt(0),
        commentName: LogicalKeyEntry.computeCommentName(name),
        constantName: LogicalKeyEntry.computeConstantName(name),
      );
    });

    unusedNumpad.forEach((String key, String value) {
      print('Unuadded numpad key $value');
    });
  }

  /// Parses entries from Chromium's key mapping header file.
  ///
  /// Lines in this file look like this (without the ///):
  ///                Key        Enum       Value
  /// DOM_KEY_MAP("Accel",      ACCEL,    0x0101),
  ///
  /// The UNI lines are ignored. Their entries have been included in the
  /// printable file.
  void _readHidEntries(Map<String, LogicalKeyEntry> data, String input) {
    final List<LogicalKeyEntry> entries = <LogicalKeyEntry>[];
    final RegExp domKeyRegExp = RegExp(
        r'DOM_KEY_(?:MAP)\s*\(\s*"([^\s]+?)",\s*([^\s]+?),\s*0x([a-fA-F0-9]+)\s*\)',
        multiLine: true);
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    input.replaceAllMapped(domKeyRegExp, (Match match) {
      if (match == null) {
        return match.group(0);
      }
      final String name = match.group(1).replaceAll(RegExp('[^A-Za-z0-9]'), '');
      final int value = getHex(match.group(3));
      // If it's a modifier key, add left and right keys instead.
      if (webModifiers.containsKey(name)) {
        final _ModifierPair pair = webModifiers[name];
        data[LogicalKeyEntry.computeConstantName(pair.left)] = LogicalKeyEntry(
          value: value + kLeftModifierPlane,
          commentName: LogicalKeyEntry.computeCommentName(pair.left),
          constantName: LogicalKeyEntry.computeConstantName(pair.left),
        );
        data[LogicalKeyEntry.computeConstantName(pair.right)] = LogicalKeyEntry(
          value: value + kRightModifierPlane,
          commentName: LogicalKeyEntry.computeCommentName(pair.right),
          constantName: LogicalKeyEntry.computeConstantName(pair.right),
        );
        return match.group(0);
      }

      final LogicalKeyEntry entry = data.putIfAbsent(LogicalKeyEntry.computeConstantName(name), () => LogicalKeyEntry(
        value: value,
        commentName: LogicalKeyEntry.computeCommentName(name),
        constantName: LogicalKeyEntry.computeConstantName(name),
      ));
      entry
        ..webNames.add(name)
        ..webValues.add(value);
      return match.group(0);
    });
  }

  /// Parses entries from GTK's gdkkeysyms.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GDK_KEY_space 0x020
  void _readGtkKeyCodes(Map<String, LogicalKeyEntry> data, String headerFile, Map<String, List<String>> nameToGtkName) {
    final RegExp definedCodes = RegExp(r'#define GDK_KEY_([a-zA-Z0-9_]+)\s*0x([0-9a-f]+),?');
    final Map<String, String> gtkNameToFlutterName = <String, String>{};
    nameToGtkName.forEach((String flutterName, List<String> gtkNames) {
      for (String gtkName in gtkNames) {
        if (gtkNameToFlutterName.containsKey(gtkName)) {
          print('Duplicate GTK logical name $gtkName');
          continue;
        }
        gtkNameToFlutterName[gtkName] = flutterName;
      }
    });

    final Map<String, int> replaced = <String, int>{};
    headerFile.replaceAllMapped(definedCodes, (Match match) {
      if (match != null) {
        final String gtkName = match.group(1);
        final String name = gtkNameToFlutterName[gtkName];
        final int value = int.parse(match.group(2), radix: 16);
        if (name == null)
          return match.group(0);

        final LogicalKeyEntry entry = data[name];
        if (entry == null) {
          print('Invalid logical entry by name $name');
          return match.group(0);
        }
        entry
          ..gtkNames.add(gtkName)
          ..gtkValues.add(value);
      }
      return match.group(0);
    });
  }

  /// Returns the static map of printable representations.
  static Map<String, String> get printable {
    if (_printable == null) {
      final String printableKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'printable_logical.json',)).readAsStringSync();
      final Map<String, dynamic> printable = json.decode(printableKeys) as Map<String, dynamic>;
      _printable = printable.cast<String, String>();
    }
    return _printable;
  }
  static Map<String, String> _printable;

  // Map Web key to the pair of key names
  static Map<String, _ModifierPair> get webModifiers {
    return _webModifiers ??= () {
      final String rawJson = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'web_modifiers.json',)).readAsStringSync();
      return (json.decode(rawJson) as Map<String, dynamic>).map((String key, dynamic value) {
        final List<dynamic> pair = value as List<dynamic>;
        return MapEntry<String, _ModifierPair>(key, _ModifierPair(pair[0] as String, pair[1] as String));
      });
    }();
  }
  static Map<String, _ModifierPair> _webModifiers;

  // Map printable to corresponding numpad key name
  static Map<String, String> get printableToNumpads {
    return _printableToNumpads ??= () {
      final String rawJson = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'printable_to_numpads.json',)).readAsStringSync();
      return (json.decode(rawJson) as Map<String, dynamic>).map((String key, dynamic value) {
        return MapEntry<String, String>(key, value as String);
      });
    }();
  }
  static Map<String, String> _printableToNumpads;
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
    List<String> webNames,
    List<int> webValues,
    List<String> gtkNames,
    List<int> gtkValues,
  })  : assert(constantName != null),
        assert(commentName != null),
        assert(value != null),
        this.webNames = webNames ?? <String>[],
        this.webValues = webValues ?? <int>[],
        this.gtkNames = gtkNames ?? <String>[],
        this.gtkValues = gtkValues ?? <int>[];

  /// Populates the key from a JSON map.
  factory LogicalKeyEntry.fromJsonMapEntry(Map<String, dynamic> map) {
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
  final List<String> webNames;

  /// The value of the key.
  final List<int> webValues;

  /// The list of names that GTK gives to this key (symbol names minus the
  /// prefix).
  final List<String> gtkNames;

  /// The list of GTK key codes matching this key, created by looking up the
  /// Linux name in the GTK data, and substituting the GTK key code
  /// value.
  final List<int> gtkValues;

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
