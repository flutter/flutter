// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:gen_keycodes/utils.dart';

/// The data structure used to manage keyboard key entries.
///
/// The main constructor parses the given input data into the data structure.
///
/// The data structure can be also loaded and saved to JSON, with the
/// [PhysicalKeyData.fromJson] constructor and [toJson] method, respectively.
class PhysicalKeyData {
  factory PhysicalKeyData(
    String chromiumHidCodes,
    String androidKeyboardLayout,
    String androidNameMap,
    String glfwHeaderFile,
    String glfwNameMap,
  ) {
    final Map<String, List<int>> nameToAndroidScanCodes = _readAndroidScanCodes(
      androidKeyboardLayout,
      androidNameMap,
    );
    final Map<String, List<int>> nameToGlfwKeyCodes = _readGlfwKeyCodes(glfwHeaderFile, glfwNameMap);
    // final Map<String, int> nameToGlfwKeyCode = _readGlfwKeyCodes(glfwKeyCodeHeader);
    // // Cast Android dom map
    // final Map<String, List<String>> nameToAndroidNames = (json.decode(androidNameMap) as Map<String, dynamic>)
    //   .cast<String, List<dynamic>>()
    //   .map<String, List<String>>((String key, List<dynamic> value) {
    //     return MapEntry<String, List<String>>(key, value.cast<String>());
    //   });
    // // Cast GLFW dom map
    // final Map<String, List<dynamic>> nameToGlfwNames = (json.decode(glfwNameMap) as Map<String, dynamic>)
    //   .cast<String, List<dynamic>>()
    //   .map<String, List<String>>((String key, List<dynamic> value) {
    //     return MapEntry<String, List<String>>(key, value.cast<String>());
    //   });
    final Map<String, PhysicalKeyEntry> data = _readHidEntries(chromiumHidCodes,
      nameToAndroidScanCodes,
      nameToGlfwKeyCodes,
    );
    final List<MapEntry<String, PhysicalKeyEntry>> sortedEntries = data.entries.toList()..sort(
      (MapEntry<String, PhysicalKeyEntry> a, MapEntry<String, PhysicalKeyEntry> b) => a.value.usbHidCode.compareTo(b.value.usbHidCode)
    );
    data
      ..clear()
      ..addEntries(sortedEntries);
    return PhysicalKeyData._(data);
  }

  /// Parses the given JSON data and populates the data structure from it.
  factory PhysicalKeyData.fromJson(Map<String, dynamic> contentMap) {
    final Map<String, PhysicalKeyEntry> data = <String, PhysicalKeyEntry>{};
    for (final MapEntry<String, dynamic> jsonEntry in contentMap.entries) {
      final PhysicalKeyEntry entry = PhysicalKeyEntry.fromJsonMapEntry(jsonEntry.value as Map<String, dynamic>);
      data[entry.name] = entry;
    }
    return PhysicalKeyData._(data);
  }

  PhysicalKeyData._(this._dataByName);

  Iterable<PhysicalKeyEntry> get data => _dataByName.values;
  /// Keys mapped from their constant names.
  final Map<String, PhysicalKeyEntry> _dataByName;

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [PhysicalKeyData.fromJson].
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (final PhysicalKeyEntry entry in _dataByName.values) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }


  /// The list of keys.
  PhysicalKeyEntry? getEntryByName(String name) {
    return _dataByName[name];
  }

  /// Parses entries from Androids Generic.kl scan code data file.
  ///
  /// Lines in this file look like this (without the ///):
  /// key 100   ALT_RIGHT
  /// # key 101 "KEY_LINEFEED"
  ///
  /// We parse the commented out lines as well as the non-commented lines, so so
  /// that we can get names for all of the available scan codes, not just ones
  /// defined for the generic profile.
  ///
  /// Also, note that some keys (notably MEDIA_EJECT) can be mapped to more than
  /// one scan code, so the mapping can't just be 1:1, it has to be 1:many.
  static Map<String, List<int>> _readAndroidScanCodes(String keyboardLayout, String nameMap) {
    final RegExp keyEntry = RegExp(r'#?\s*key\s+([0-9]+)\s*"?(?:KEY_)?([0-9A-Z_]+|\(undefined\))"?\s*(FUNCTION)?');
    final Map<String, List<int>> androidNameToScanCodes = <String, List<int>>{};
    for (final Match match in keyEntry.allMatches(keyboardLayout)) {
      if (match.group(3) == 'FUNCTION') {
        // Skip odd duplicate Android FUNCTION keys (F1-F12 are already defined).
        continue;
      }
      final String name = match.group(2)!;
      if (name == '(undefined)') {
        // Skip undefined scan codes.
        continue;
      }
      final String androidName = match.group(2)!;
      androidNameToScanCodes.putIfAbsent(androidName, () => <int>[])
        .add(int.parse(match.group(1)!));
    }

    // Cast Android dom map
    final Map<String, List<String>> nameToAndroidNames = (json.decode(nameMap) as Map<String, dynamic>)
      .cast<String, List<dynamic>>()
      .map<String, List<String>>((String key, List<dynamic> value) {
        return MapEntry<String, List<String>>(key, value.cast<String>());
      });

    final Map<String, List<int>> result = nameToAndroidNames.map((String name, List<String> androidNames) {
      final Set<int> scanCodes = <int>{};
      for (final String androidName in androidNames) {
        scanCodes.addAll(androidNameToScanCodes[androidName] ?? <int>[]);
      }
      return MapEntry<String, List<int>>(name, scanCodes.toList()..sort());
    });

    return result;
  }

  /// Parses entries from GLFW's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GLFW_KEY_SPACE              32,
  // static Map<String, int> _readGlfwKeyCodes(String headerFile) {
  //   // Only get the KEY definitions, ignore the rest (mouse, joystick, etc).
  //   final RegExp definedCodes = RegExp(r'define GLFW_KEY_([A-Z0-9_]+)\s*([A-Z0-9_]+),?');
  //   final Map<String, dynamic> replaced = <String, dynamic>{};
  //   for (final Match match in definedCodes.allMatches(headerFile)) {
  //     replaced[match.group(1)!] = int.tryParse(match.group(2)!) ?? match.group(2)!.replaceAll('GLFW_KEY_', '');
  //   }
  //   final Map<String, int> result = <String, int>{};
  //   replaced.forEach((String key, dynamic value) {
  //     // Some definition values point to other definitions (e.g #define GLFW_KEY_LAST GLFW_KEY_MENU).
  //     if (value is String) {
  //       result[key] = replaced[value] as int;
  //     } else {
  //       result[key] = value as int;
  //     }
  //   });
  //   return result;
  // }

  /// Parses entries from GLFW's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GLFW_KEY_SPACE              32,
  static Map<String, List<int>> _readGlfwKeyCodes(String headerFile, String nameMap) {
    // Only get the KEY definitions, ignore the rest (mouse, joystick, etc).
    final RegExp definedCodes = RegExp(r'define GLFW_KEY_([A-Z0-9_]+)\s*([A-Z0-9_]+),?');
    final Map<String, dynamic> replaced = <String, dynamic>{};
    for (final Match match in definedCodes.allMatches(headerFile)) {
      replaced[match.group(1)!] = int.tryParse(match.group(2)!) ?? match.group(2)!.replaceAll('GLFW_KEY_', '');
    }
    final Map<String, int> glfwNameToKeyCode = <String, int>{};
    replaced.forEach((String key, dynamic value) {
      // Some definition values point to other definitions (e.g #define GLFW_KEY_LAST GLFW_KEY_MENU).
      if (value is String) {
        glfwNameToKeyCode[key] = replaced[value] as int;
      } else {
        glfwNameToKeyCode[key] = value as int;
      }
    });

    final Map<String, List<String>> nameToGlfwNames = (json.decode(nameMap) as Map<String, dynamic>)
      .cast<String, List<dynamic>>()
      .map<String, List<String>>((String key, List<dynamic> value) {
        return MapEntry<String, List<String>>(key, value.cast<String>());
      });

    final Map<String, List<int>> result = nameToGlfwNames.map((String name, List<String> glfwNames) {
      final Set<int> keyCodes = <int>{};
      for (final String glfwName in glfwNames) {
        if (glfwNameToKeyCode[glfwName] != null)
          keyCodes.add(glfwNameToKeyCode[glfwName]!);
      }
      return MapEntry<String, List<int>>(name, keyCodes.toList()..sort());
    });

    return result;
  }

  /// Parses entries from Chromium's HID code mapping header file.
  ///
  /// Lines in this file look like this (without the ///):
  ///            USB       evdev   XKB     Win     Mac     Code     Enum
  /// DOM_CODE(0x000010, 0x0000, 0x0000, 0x0000, 0xffff, "Hyper", HYPER),
  static Map<String, PhysicalKeyEntry> _readHidEntries(
    String input,
    Map<String, List<int>> nameToAndroidScanCodes,
    Map<String, List<int>> nameToGlfwKeyCodes,
  ) {
    final Map<int, PhysicalKeyEntry> entries = <int, PhysicalKeyEntry>{};
    final RegExp usbMapRegExp = RegExp(
        r'DOM_CODE\s*\(\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),'
        r'\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),\s*"?([^\s]+?)"?,\s*([^\s]+?)\s*\)',
        multiLine: true);
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    for (final Match match in usbMapRegExp.allMatches(input)) {
      final int usbHidCode = getHex(match.group(1)!);
      final int macScanCode = getHex(match.group(5)!);
      final int linuxScanCode = getHex(match.group(2)!);
      final int xKbScanCode = getHex(match.group(3)!);
      final int windowsScanCode = getHex(match.group(4)!);
      // The input data has a typo...
      final String chromiumName = shoutingToLowerCamel(match.group(7)!).replaceAll('Minimium', 'Minimum');
      if (match.group(6) == 'NULL')
        continue;
      final String name = chromiumName == 'none' ? 'None' : match.group(6)!;
      final PhysicalKeyEntry newEntry = PhysicalKeyEntry(
        usbHidCode: usbHidCode,
        androidScanCodes: nameToAndroidScanCodes[name] ?? <int>[],
        glfwKeyCodes: nameToGlfwKeyCodes[name] ?? <int>[],
        linuxScanCode: linuxScanCode == 0 ? null : linuxScanCode,
        xKbScanCode: xKbScanCode == 0 ? null : xKbScanCode,
        windowsScanCode: windowsScanCode == 0 ? null : windowsScanCode,
        macOsScanCode: macScanCode == 0xffff ? null : macScanCode,
        iosScanCode: (usbHidCode & 0x070000) == 0x070000 ? (usbHidCode ^ 0x070000) : null,
        name: name,
        chromiumName: chromiumName,
      );
      if (newEntry.name == 'IntlHash') {
        // Skip key that is not actually generated by any keyboard.
        continue;
      }
      // Remove duplicates: last one wins, so that supplemental codes
      // override.
      if (entries.containsKey(newEntry.usbHidCode)) {
        print('Duplicate usbHidCode ${newEntry.usbHidCode} of key ${newEntry.name} '
          'conflicts with existing ${entries[newEntry.usbHidCode]!.name}. Keeping the new one.');
      }
      entries[newEntry.usbHidCode] = newEntry;
    }
    return entries.map((int code, PhysicalKeyEntry entry) =>
        MapEntry<String, PhysicalKeyEntry>(entry.name, entry));
  }
}

/// A single entry in the key data structure.
///
/// Can be read from JSON with the [PhysicalKeyEntry.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class PhysicalKeyEntry {
  /// Creates a single key entry from available data.
  ///
  /// The [usbHidCode] and [chromiumName] parameters must not be null.
  PhysicalKeyEntry({
    required this.usbHidCode,
    required this.name,
    required this.androidScanCodes,
    required this.linuxScanCode,
    required this.xKbScanCode,
    required this.windowsScanCode,
    required this.macOsScanCode,
    required this.iosScanCode,
    required this.chromiumName,
    required this.glfwKeyCodes,
  })  : assert(usbHidCode != null),
        assert(chromiumName != null);

  /// Populates the key from a JSON map.
  factory PhysicalKeyEntry.fromJsonMapEntry(Map<String, dynamic> map) {
    return PhysicalKeyEntry(
      name: map['names']['domkey'] as String,
      chromiumName: map['names']['chromium'] as String,
      usbHidCode: map['scanCodes']['usb'] as int,
      // androidKeyNames: (map['names']['android'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      androidScanCodes: (map['scanCodes']['android'] as List<dynamic>?)?.cast<int>() ?? <int>[],
      linuxScanCode: map['scanCodes']['linux'] as int,
      xKbScanCode: map['scanCodes']['xkb'] as int,
      windowsScanCode: map['scanCodes']['windows'] as int,
      macOsScanCode: map['scanCodes']['macos'] as int,
      iosScanCode: map['scanCodes']['ios'] as int,
      // glfwKeyNames: (map['names']['glfw'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      glfwKeyCodes: (map['keyCodes']['glfw'] as List<dynamic>?)?.cast<int>() ?? <int>[],
    );
  }

  /// The USB HID code of the key
  final int usbHidCode;

  /// The Linux scan code of the key, from Chromium's header file.
  final int? linuxScanCode;
  /// The XKb scan code of the key from Chromium's header file.
  final int? xKbScanCode;
  /// The Windows scan code of the key from Chromium's header file.
  final int? windowsScanCode;
  /// The macOS scan code of the key from Chromium's header file.
  final int? macOsScanCode;
  /// The iOS scan code of the key from UIKey's documentation (USB Hid table)
  final int? iosScanCode;
  /// The list of Android scan codes matching this key, created by looking up
  /// the Android name in the Chromium data, and substituting the Android scan
  /// code value.
  final List<int> androidScanCodes;
  /// The list of GLFW key codes matching this key, created by looking up the
  /// Linux name in the Chromium data, and substituting the GLFW key code
  /// value.
  final List<int> glfwKeyCodes;
  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  final String name;
  /// The Chromium symbol name for the key.
  final String chromiumName;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return removeEmptyValues(<String, dynamic>{
      'names': removeEmptyValues(<String, dynamic>{
        'domkey': name,
        // 'android': androidKeyNames,
        'english': commentName,
        'chromium': chromiumName,
        // 'glfw': glfwKeyNames,
      }),
      'scanCodes': removeEmptyValues(<String, dynamic>{
        'android': androidScanCodes,
        'usb': usbHidCode,
        'linux': linuxScanCode,
        'xkb': xKbScanCode,
        'windows': windowsScanCode,
        'macos': macOsScanCode,
        'ios': iosScanCode,
      }),
      'keyCodes': removeEmptyValues(<String, List<int>>{
        'glfw': glfwKeyCodes,
      }),
    });
  }

  /// Returns the printable representation of this key, if any.
  ///
  /// If there is no printable representation, returns null.
  String? get keyLabel => printable[constantName];

  int get flutterId {
    if (printable.containsKey(constantName) && !constantName.startsWith('numpad')) {
      return unicodePlane | ((keyLabel?.codeUnitAt(0) ?? 0) & valueMask);
    }
    return hidPlane | (usbHidCode & valueMask);
  }

  static String getCommentName(String constantName) {
    String upperCamel = lowerCamelToUpperCamel(constantName);
    upperCamel = upperCamel.replaceAllMapped(
      RegExp(r'(Digit|Numpad|Lang|Button|Left|Right)([0-9]+)'),
      (Match match) => '${match.group(1)} ${match.group(2)}',
    );
    return upperCamel.replaceAllMapped(RegExp(r'([A-Z])'), (Match match) => ' ${match.group(1)}').trim();
  }

  /// Gets the name of the key suitable for placing in comments.
  ///
  /// Takes the [constantName] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  String get commentName => getCommentName(constantName);

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_key.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  late final String constantName = ((){
    String result;
    if (name == null || name.isEmpty) {
      // If it doesn't have a DomKey name then use the Chromium symbol name.
      result = chromiumName;
    } else {
      result = upperCamelToLowerCamel(name);
    }
    if (kDartReservedWords.contains(result)) {
      return '${result}Key';
    }
    return result;
  })();

  @override
  String toString() {
    return """'$constantName': (name: "$name", usbHidCode: ${toHex(usbHidCode)}, """
        'linuxScanCode: ${toHex(linuxScanCode)}, xKbScanCode: ${toHex(xKbScanCode)}, '
        'windowsKeyCode: ${toHex(windowsScanCode)}, macOsScanCode: ${toHex(macOsScanCode)}, '
        'windowsScanCode: ${toHex(windowsScanCode)}, chromiumSymbolName: $chromiumName '
        'iOSScanCode: ${toHex(iosScanCode)})';
  }

  /// Returns the static map of printable representations.
  static late final Map<String, String> printable = ((){
    final String printableKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'printable.json',)).readAsStringSync();
    return (json.decode(printableKeys) as Map<String, dynamic>)
      .cast<String, String>();
  })();

  /// Returns the static map of synonym representations.
  ///
  /// These include synonyms for keys which don't have printable
  /// representations, and appear in more than one place on the keyboard (e.g.
  /// SHIFT, ALT, etc.).
  static late final Map<String, List<String>> synonyms = ((){
    final String synonymKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'synonyms.json',)).readAsStringSync();
    final Map<String, dynamic> dynamicSynonym = json.decode(synonymKeys) as Map<String, dynamic>;
    return dynamicSynonym.map((String name, dynamic values) {
      // The keygen and algorithm of macOS relies on synonyms being pairs.
      // See siblingKeyMap in macos_code_gen.dart.
      final List<String> names = (values as List<dynamic>).whereType<String>().toList();
      assert(names.length == 2);
      return MapEntry<String, List<String>>(name, names);
    });
  })();

  /// Mask for the 32-bit value portion of the code.
  static const int valueMask = 0x000FFFFFFFF;

  /// The code prefix for keys which have a Unicode representation.
  static const int unicodePlane = 0x00000000000;

  /// The code prefix for keys which do not have a Unicode representation, but
  /// do have a USB HID ID.
  static const int hidPlane = 0x00100000000;

  /// The code prefix for pseudo-keys which represent collections of key synonyms.
  static const int synonymPlane = 0x20000000000;
}
