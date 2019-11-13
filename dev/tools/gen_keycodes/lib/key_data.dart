// Copyright 2019 The Chromium Authors. All rights reserved.
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
/// [KeyData.fromJson] constructor and [toJson] method, respectively.
class KeyData {
  /// Parses the input data given in from the various data source files,
  /// populating the data structure.
  ///
  /// None of the parameters may be null.
  KeyData(
    String chromiumHidCodes,
    String androidKeyboardLayout,
    String androidKeyCodeHeader,
    String androidNameMap,
    String glfwKeyCodeHeader,
    String glfwNameMap,
  )   : assert(chromiumHidCodes != null),
        assert(androidKeyboardLayout != null),
        assert(androidKeyCodeHeader != null),
        assert(androidNameMap != null),
        assert(glfwKeyCodeHeader != null),
        assert(glfwNameMap != null) {
    _nameToAndroidScanCodes = _readAndroidScanCodes(androidKeyboardLayout);
    _nameToAndroidKeyCode = _readAndroidKeyCodes(androidKeyCodeHeader);
    _nameToGlfwKeyCode = _readGlfwKeyCodes(glfwKeyCodeHeader);
    // Cast Android dom map
    final Map<String, List<dynamic>> dynamicAndroidNames = json.decode(androidNameMap).cast<String, List<dynamic>>();
    _nameToAndroidName = dynamicAndroidNames.map<String, List<String>>((String key, List<dynamic> value) {
      return MapEntry<String, List<String>>(key, value.cast<String>());
    });
    // Cast GLFW dom map
    final Map<String, List<dynamic>> dynamicGlfwNames = json.decode(glfwNameMap).cast<String, List<dynamic>>();
    _nameToGlfwName = dynamicGlfwNames.map<String, List<String>>((String key, List<dynamic> value) {
      return MapEntry<String, List<String>>(key, value.cast<String>());
    });
    data = _readHidEntries(chromiumHidCodes);
  }

  /// Parses the given JSON data and populates the data structure from it.
  KeyData.fromJson(Map<String, dynamic> contentMap) {
    data = <Key>[
      for (String key in contentMap.keys) Key.fromJsonMapEntry(key, contentMap[key]),
    ];
  }

  /// Converts the data structure into a JSON structure that can be parsed by
  /// [KeyData.fromJson].
  Map<String, dynamic> toJson() {
    for (Key entry in data) {
      // Android Key names
      entry.androidKeyNames = _nameToAndroidName[entry.constantName]?.cast<String>();
      if (entry.androidKeyNames != null && entry.androidKeyNames.isNotEmpty) {
        for (String androidKeyName in entry.androidKeyNames) {
          if (_nameToAndroidKeyCode[androidKeyName] != null) {
            entry.androidKeyCodes ??= <int>[];
            entry.androidKeyCodes.add(_nameToAndroidKeyCode[androidKeyName]);
          }
          if (_nameToAndroidScanCodes[androidKeyName] != null && _nameToAndroidScanCodes[androidKeyName].isNotEmpty) {
            entry.androidScanCodes ??= <int>[];
            entry.androidScanCodes.addAll(_nameToAndroidScanCodes[androidKeyName]);
          }
        }
      }

      // GLFW key names
      entry.glfwKeyNames = _nameToGlfwName[entry.constantName]?.cast<String>();
      if (entry.glfwKeyNames != null && entry.glfwKeyNames.isNotEmpty) {
        for (String glfwKeyName in entry.glfwKeyNames) {
          if (_nameToGlfwKeyCode[glfwKeyName] != null) {
            entry.glfwKeyCodes ??= <int>[];
            entry.glfwKeyCodes.add(_nameToGlfwKeyCode[glfwKeyName]);
          }
        }
      }
    }

    final Map<String, dynamic> outputMap = <String, dynamic>{};
    for (Key entry in data) {
      outputMap[entry.constantName] = entry.toJson();
    }
    return outputMap;
  }

  /// The list of keys.
  List<Key> data;

  /// The mapping from the Flutter name (e.g. "eject") to the Android name (e.g.
  /// "MEDIA_EJECT").
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, List<String>> _nameToAndroidName;

  /// The mapping from the Flutter name (e.g. "eject") to the GLFW name (e.g.
  /// "GLFW_MEDIA_EJECT").
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, List<String>> _nameToGlfwName;

  /// The mapping from the Android name (e.g. "MEDIA_EJECT") to the integer scan
  /// code (physical location) of the key.
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, List<int>> _nameToAndroidScanCodes;

  /// The mapping from Android name (e.g. "MEDIA_EJECT") to the integer key code
  /// (logical meaning) of the key.
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, int> _nameToAndroidKeyCode;

  /// The mapping from GLFW name (e.g. "GLFW_KEY_COMMA") to the integer key code
  /// (logical meaning) of the key.
  ///
  /// Only populated if data is parsed from the source files, not if parsed from
  /// JSON.
  Map<String, int> _nameToGlfwKeyCode;

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
  Map<String, List<int>> _readAndroidScanCodes(String keyboardLayout) {
    final RegExp keyEntry = RegExp(r'''#?\s*key\s+([0-9]+)\s*"?(?:KEY_)?([0-9A-Z_]+|\(undefined\))"?\s*(FUNCTION)?''');
    final Map<String, List<int>> result = <String, List<int>>{};
    keyboardLayout.replaceAllMapped(keyEntry, (Match match) {
      if (match.group(3) == 'FUNCTION') {
        // Skip odd duplicate Android FUNCTION keys (F1-F12 are already defined).
        return '';
      }
      final String name = match.group(2);
      if (name == '(undefined)') {
        // Skip undefined scan codes.
        return '';
      }
      final String androidName = match.group(2);
      result[androidName] ??= <int>[];
      result[androidName].add(int.parse(match.group(1)));
      return null;
    });

    return result;
  }

  /// Parses entries from Android's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Left Control modifier key. */
  ///  AKEYCODE_CTRL_LEFT       = 113,
  Map<String, int> _readAndroidKeyCodes(String headerFile) {
    final RegExp enumBlock = RegExp(r'enum\s*\{(.*)\};', multiLine: true);
    // Eliminate everything outside of the enum block.
    headerFile = headerFile.replaceAllMapped(enumBlock, (Match match) => match.group(1));
    final RegExp enumEntry = RegExp(r'''AKEYCODE_([A-Z0-9_]+)\s*=\s*([0-9]+),?''');
    final Map<String, int> result = <String, int>{};
    for (Match match in enumEntry.allMatches(headerFile)) {
      result[match.group(1)] = int.parse(match.group(2));
    }
    return result;
  }

  /// Parses entries from GLFW's keycodes.h key code data file.
  ///
  /// Lines in this file look like this (without the ///):
  ///  /** Space key. */
  ///  #define GLFW_KEY_SPACE              32,
  Map<String, int> _readGlfwKeyCodes(String headerFile) {
    // Only get the KEY definitions, ignore the rest (mouse, joystick, etc).
    final RegExp enumEntry = RegExp(r'''define GLFW_KEY_([A-Z0-9_]+)\s*([A-Z0-9_]+),?''');
    final Map<String, dynamic> replaced = <String, dynamic>{};
    for (Match match in enumEntry.allMatches(headerFile)) {
      replaced[match.group(1)] = int.tryParse(match.group(2)) ?? match.group(2).replaceAll('GLFW_KEY_', '');
    }
    final Map<String, int> result = <String, int>{};
    replaced.forEach((String key, dynamic value) {
      // Some definition values point to other definitions (e.g #define GLFW_KEY_LAST GLFW_KEY_MENU).
      if (value is String) {
        result[key] = replaced[value];
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  /// Parses entries from Chromium's HID code mapping header file.
  ///
  /// Lines in this file look like this (without the ///):
  ///            USB       evdev   XKB     Win     Mac     Code     Enum
  /// USB_KEYMAP(0x000010, 0x0000, 0x0000, 0x0000, 0xffff, "Hyper", HYPER),
  List<Key> _readHidEntries(String input) {
    final List<Key> entries = <Key>[];
    final RegExp usbMapRegExp = RegExp(
        r'''USB_KEYMAP\s*\(\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),'''
        r'''\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),\s*0x([a-fA-F0-9]+),\s*"?([^\s]+?)"?,\s*([^\s]+?)\s*\)''',
        multiLine: true);
    final RegExp commentRegExp = RegExp(r'//.*$', multiLine: true);
    input = input.replaceAll(commentRegExp, '');
    input.replaceAllMapped(usbMapRegExp, (Match match) {
      if (match != null) {
        final int macScanCode = getHex(match.group(5));
        final int linuxScanCode = getHex(match.group(2));
        final int xKbScanCode = getHex(match.group(3));
        final int windowsScanCode = getHex(match.group(4));
        final Key newEntry = Key(
          usbHidCode: getHex(match.group(1)),
          linuxScanCode: linuxScanCode == 0 ? null : linuxScanCode,
          xKbScanCode: xKbScanCode == 0 ? null : xKbScanCode,
          windowsScanCode: windowsScanCode == 0 ? null : windowsScanCode,
          macOsScanCode: macScanCode == 0xffff ? null : macScanCode,
          name: match.group(6) == 'NULL' ? null : match.group(6),
          // The input data has a typo...
          chromiumName: shoutingToLowerCamel(match.group(7)).replaceAll('Minimium', 'Minimum'),
        );
        if (newEntry.chromiumName == 'none') {
          newEntry.name = 'None';
        }
        if (newEntry.name == 'IntlHash') {
          // Skip key that is not actually generated by any keyboard.
          return '';
        }
        // Remove duplicates: last one wins, so that supplemental codes
        // override.
        entries.removeWhere((Key entry) => entry.usbHidCode == newEntry.usbHidCode);
        entries.add(newEntry);
      }
      return match.group(0);
    });
    return entries;
  }
}

/// A single entry in the key data structure.
///
/// Can be read from JSON with the [Key.fromJsonMapEntry] constructor, or
/// written with the [toJson] method.
class Key {
  /// Creates a single key entry from available data.
  ///
  /// The [usbHidCode] and [chromiumName] parameters must not be null.
  Key({
    String enumName,
    this.name,
    @required this.usbHidCode,
    this.linuxScanCode,
    this.xKbScanCode,
    this.windowsScanCode,
    this.macOsScanCode,
    @required this.chromiumName,
    this.androidKeyNames,
    this.androidScanCodes,
    this.androidKeyCodes,
    this.glfwKeyNames,
    this.glfwKeyCodes,
  })  : assert(usbHidCode != null),
        assert(chromiumName != null),
        _constantName = enumName;

  /// Populates the key from a JSON map.
  factory Key.fromJsonMapEntry(String name, Map<String, dynamic> map) {
    return Key(
      enumName: name,
      name: map['names']['domkey'],
      chromiumName: map['names']['chromium'],
      usbHidCode: map['scanCodes']['usb'],
      androidKeyNames: map['names']['android']?.cast<String>(),
      androidScanCodes: map['scanCodes']['android']?.cast<int>(),
      androidKeyCodes: map['keyCodes']['android']?.cast<int>(),
      linuxScanCode: map['scanCodes']['linux'],
      xKbScanCode: map['scanCodes']['xkb'],
      windowsScanCode: map['scanCodes']['windows'],
      macOsScanCode: map['scanCodes']['macos'],
      glfwKeyNames: map['names']['glfw']?.cast<String>(),
      glfwKeyCodes: map['keyCodes']['glfw']?.cast<int>(),
    );
  }

  /// The USB HID code of the key
  int usbHidCode;

  /// The Linux scan code of the key, from Chromium's header file.
  int linuxScanCode;
  /// The XKb scan code of the key from Chromium's header file.
  int xKbScanCode;
  /// The Windows scan code of the key from Chromium's header file.
  int windowsScanCode;
  /// The macOS scan code of the key from Chromium's header file.
  int macOsScanCode;
  /// The name of the key, mostly derived from the DomKey name in Chromium,
  /// but where there was no DomKey representation, derived from the Chromium
  /// symbol name.
  String name;
  /// The Chromium symbol name for the key.
  String chromiumName;
  /// The list of names that Android gives to this key (symbol names minus the
  /// prefix).
  List<String> androidKeyNames;
  /// The list of Android key codes matching this key, created by looking up the
  /// Android name in the Chromium data, and substituting the Android key code
  /// value.
  List<int> androidKeyCodes;
  /// The list of Android scan codes matching this key, created by looking up
  /// the Android name in the Chromium data, and substituting the Android scan
  /// code value.
  List<int> androidScanCodes;

  /// The list of names that GFLW gives to this key (symbol names minus the
  /// prefix).
  List<String> glfwKeyNames;

  /// The list of GLFW key codes matching this key, created by looking up the
  /// Linux name in the Chromium data, and substituting the GLFW key code
  /// value.
  List<int> glfwKeyCodes;

  /// Creates a JSON map from the key data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'names': <String, dynamic>{
        'domkey': name,
        'android': androidKeyNames,
        'english': commentName,
        'chromium': chromiumName,
        'glfw': glfwKeyNames,
      },
      'scanCodes': <String, dynamic>{
        'android': androidScanCodes,
        'usb': usbHidCode,
        'linux': linuxScanCode,
        'xkb': xKbScanCode,
        'windows': windowsScanCode,
        'macos': macOsScanCode,
      },
      'keyCodes': <String, List<int>>{
        'android': androidKeyCodes,
        'glfw': glfwKeyCodes,
      },
    };
  }

  /// Returns the printable representation of this key, if any.
  ///
  /// If there is no printable representation, returns null.
  String get keyLabel => printable[constantName];

  int get flutterId {
    if (printable.containsKey(constantName) && !constantName.startsWith('numpad')) {
      return unicodePlane | (keyLabel.codeUnitAt(0) & valueMask);
    }
    return hidPlane | (usbHidCode & valueMask);
  }

  static String getCommentName(String constantName) {
    String upperCamel = lowerCamelToUpperCamel(constantName);
    upperCamel = upperCamel.replaceAllMapped(RegExp(r'(Digit|Numpad|Lang|Button|Left|Right)([0-9]+)'), (Match match) => '${match.group(1)} ${match.group(2)}');
    return upperCamel.replaceAllMapped(RegExp(r'([A-Z])'), (Match match) => ' ${match.group(1)}').trim();
  }

  /// Gets the name of the key suitable for placing in comments.
  ///
  /// Takes the [constantName] and converts it from lower camel case to capitalized
  /// separate words (e.g. "wakeUp" converts to "Wake Up").
  String get commentName => getCommentName(constantName);

  /// Gets the named used for the key constant in the definitions in
  /// keyboard_keys.dart.
  ///
  /// If set by the constructor, returns the name set, but otherwise constructs
  /// the name from the various different names available, making sure that the
  /// name isn't a Dart reserved word (if it is, then it adds the word "Key" to
  /// the end of the name).
  String get constantName {
    if (_constantName == null) {
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
      // Don't set enumName: we want it to regen each time if never set, but
      // to stay set if set by the JSON loading.
      return result;
    }
    return _constantName;
  }
  set constantName(String value) => _constantName = value;
  String _constantName;

  @override
  String toString() {
    return """'$constantName': (name: "$name", usbHidCode: ${toHex(usbHidCode)}, """
        '''linuxScanCode: ${toHex(linuxScanCode)}, xKbScanCode: ${toHex(xKbScanCode)}, '''
        '''windowsKeyCode: ${toHex(windowsScanCode)}, macOsScanCode: ${toHex(macOsScanCode)}, '''
        '''chromiumSymbolName: $chromiumName''';
  }

  /// Returns the static map of printable representations.
  static Map<String, String> get printable {
    if (_printable == null) {
      final String printableKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'printable.json',)).readAsStringSync();
      final Map<String, dynamic> printable = json.decode(printableKeys);
      _printable = printable.cast<String, String>();
    }
    return _printable;
  }
  static Map<String, String> _printable;

  /// Returns the static map of synonym representations.
  ///
  /// These include synonyms for keys which don't have printable
  /// representations, and appear in more than one place on the keyboard (e.g.
  /// SHIFT, ALT, etc.).
  static Map<String, List<dynamic>> get synonyms {
    if (_synonym == null) {
      final String synonymKeys = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'synonyms.json',)).readAsStringSync();
      final Map<String, dynamic> synonym = json.decode(synonymKeys);
      _synonym = synonym.cast<String, List<dynamic>>();
    }
    return _synonym;
  }
  static Map<String, List<dynamic>> _synonym;

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
