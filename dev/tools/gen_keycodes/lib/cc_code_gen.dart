// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:gen_keycodes/key_data.dart';
import 'package:gen_keycodes/utils.dart';

/// Generates the keyboard_keys.dart and keyboard_maps.dart files, based on the
/// information in the key data structure given to it.
class CcCodeGenerator {
  CcCodeGenerator(this.keyData);

  /// Given an [input] string, wraps the text at 80 characters and prepends each
  /// line with the [prefix] string. Use for generated comments.
  String wrapString(String input, {String prefix = '  // '}) {
    final int wrapWidth = 80 - prefix.length;
    final StringBuffer result = StringBuffer();
    final List<String> words = input.split(RegExp(r'\s+'));
    String currentLine = words.removeAt(0);
    for (final String word in words) {
      if ((currentLine.length + word.length) < wrapWidth) {
        currentLine += ' $word';
      } else {
        result.writeln('$prefix$currentLine');
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      result.writeln('$prefix$currentLine');
    }
    return result.toString();
  }

  List<Key> get numpadKeyData {
    return keyData.data.where((Key entry) {
      return entry.constantName.startsWith('numpad') && entry.keyLabel != null;
    }).toList();
  }

  List<Key> get functionKeyData {
    final RegExp functionKeyRe = RegExp(r'^f[0-9]+$');
    return keyData.data.where((Key entry) {
      return functionKeyRe.hasMatch(entry.constantName);
    }).toList();
  }

  /// This generates the map of Flutter key codes to logical keys.
  String get predefinedKeyCodeMap {
    final StringBuffer keyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      keyCodeMap.writeln('    ${toHex(entry.flutterId, digits: 10)}: ${entry.constantName},');
    }
    for (final String entry in Key.synonyms.keys) {
      // Use the first item in the synonyms as a template for the ID to use.
      // It won't end up being the same value because it'll be in the pseudo-key
      // plane.
      final Key primaryKey = keyData.data.firstWhere((Key item) {
        return item.name == Key.synonyms[entry][0];
      }, orElse: () => null);
      assert(primaryKey != null);
      keyCodeMap.writeln('    ${toHex(Key.synonymPlane | primaryKey.flutterId, digits: 10)}: $entry,');
    }
    return keyCodeMap.toString().trimRight();
  }

  /// This generates the map of GLFW number pad key codes to logical keys.
  String get glfwNumpadMap {
    final StringBuffer glfwNumpadMap = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.glfwKeyCodes != null) {
        for (final int code in entry.glfwKeyCodes.cast<int>()) {
          glfwNumpadMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return glfwNumpadMap.toString().trimRight();
  }

  /// This generates the map of GLFW key codes to logical keys.
  String get glfwKeyCodeMap {
    final StringBuffer glfwKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.glfwKeyCodes != null) {
        for (final int code in entry.glfwKeyCodes.cast<int>()) {
          glfwKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return glfwKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of XKB scan codes to USB HID codes.
  String get xkbScanCodeMap {
    final StringBuffer xkbScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.xKbScanCode != null) {
        xkbScanCodeMap.writeln('  { ${toHex(entry.xKbScanCode)}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return xkbScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Android key codes to logical keys.
  String get androidKeyCodeMap {
    final StringBuffer androidKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.androidKeyCodes != null) {
        for (final int code in entry.androidKeyCodes.cast<int>()) {
          androidKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return androidKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Android number pad key codes to logical keys.
  String get androidNumpadMap {
    final StringBuffer androidKeyCodeMap = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.androidKeyCodes != null) {
        for (final int code in entry.androidKeyCodes.cast<int>()) {
          androidKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return androidKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Android scan codes to physical keys.
  String get androidScanCodeMap {
    final StringBuffer androidScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.androidScanCodes != null) {
        for (final int code in entry.androidScanCodes.cast<int>()) {
          androidScanCodeMap.writeln('  { $code, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
        }
      }
    }
    return androidScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Windows scan codes to physical keys.
  String get windowsScanCodeMap {
    final StringBuffer windowsScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.windowsScanCode != null) {
        windowsScanCodeMap.writeln('  { ${entry.windowsScanCode}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return windowsScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Windows number pad key codes to logical keys.
  String get windowsNumpadMap {
    final StringBuffer windowsNumPadMap = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.windowsScanCode != null) {
        windowsNumPadMap.writeln('  { ${toHex(entry.windowsScanCode)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return windowsNumPadMap.toString().trimRight();
  }

  /// This generates the map of Android key codes to logical keys.
  String get windowsKeyCodeMap {
    final StringBuffer windowsKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.windowsKeyCodes != null) {
        for (final int code in entry.windowsKeyCodes.cast<int>()) {
          windowsKeyCodeMap.writeln('  { $code, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
        }
      }
    }
    return windowsKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of macOS key codes to physical keys.
  String get macOsScanCodeMap {
    final StringBuffer macOsScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.macOsScanCode != null) {
        macOsScanCodeMap.writeln('  { ${toHex(entry.macOsScanCode)}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return macOsScanCodeMap.toString().trimRight();
  }

  /// This generates the map of macOS number pad key codes to logical keys.
  String get macOsNumpadMap {
    final StringBuffer macOsNumPadMap = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.macOsScanCode != null) {
        macOsNumPadMap.writeln('  { ${toHex(entry.macOsScanCode)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return macOsNumPadMap.toString().trimRight();
  }

  String get macOsFunctionKeyMap {
    final StringBuffer macOsFunctionKeyMap = StringBuffer();
    for (final Key entry in functionKeyData) {
      if (entry.macOsScanCode != null) {
        macOsFunctionKeyMap.writeln('  { ${toHex(entry.macOsScanCode)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return macOsFunctionKeyMap.toString().trimRight();
  }

  /// This generates the map of Fuchsia key codes to logical keys.
  String get fuchsiaKeyCodeMap {
    final StringBuffer fuchsiaKeyCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaKeyCodeMap.writeln('  { ${toHex(entry.flutterId)}, ${toHex(entry.flutterId, digits: 10)} },    // ${entry.constantName}');
      }
    }
    return fuchsiaKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Fuchsia USB HID codes to physical keys.
  String get fuchsiaHidCodeMap {
    final StringBuffer fuchsiaScanCodeMap = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaScanCodeMap.writeln(' { ${toHex(entry.usbHidCode)}, ${toHex(entry.usbHidCode)} },    // ${entry.constantName}');
      }
    }
    return fuchsiaScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to logical keys.
  String get webLogicalKeyMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.flutterId, digits: 10)},    // ${entry.constantName}");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical keys.
  String get webPhysicalKeyMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.usbHidCode)},    // ${entry.constantName}");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web number pad codes to logical keys.
  String get webNumpadMap {
    final StringBuffer result = StringBuffer();
    for (final Key entry in numpadKeyData) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': ${toHex(entry.flutterId, digits: 10)},    // ${entry.constantName}");
      }
    }
    return result.toString().trimRight();
  }

  /// Substitutes the various platform specific maps into the template file for
  /// keyboard_maps.dart.
  String generateKeyboardMaps(String platform) {
    // There is no macOS keycode map since macOS uses keycode to represent a physical key.
    // The LogicalKeyboardKey is generated by raw_keyboard_macos.dart from the unmodified characters
    // from NSEvent.
    final Map<String, String> mappings = <String, String>{
      'ANDROID_SCAN_CODE_MAP': androidScanCodeMap,
      'ANDROID_KEY_CODE_MAP': androidKeyCodeMap,
      'ANDROID_NUMPAD_MAP': androidNumpadMap,
      'FUCHSIA_SCAN_CODE_MAP': fuchsiaHidCodeMap,
      'FUCHSIA_KEY_CODE_MAP': fuchsiaKeyCodeMap,
      'MACOS_SCAN_CODE_MAP': macOsScanCodeMap,
      'MACOS_NUMPAD_MAP': macOsNumpadMap,
      'MACOS_FUNCTION_KEY_MAP': macOsFunctionKeyMap,
      'GLFW_KEY_CODE_MAP': glfwKeyCodeMap,
      'GLFW_NUMPAD_MAP': glfwNumpadMap,
      'XKB_SCAN_CODE_MAP': xkbScanCodeMap,
      'WEB_LOGICAL_KEY_MAP': webLogicalKeyMap,
      'WEB_PHYSICAL_KEY_MAP': webPhysicalKeyMap,
      'WEB_NUMPAD_MAP': webNumpadMap,
      'WINDOWS_SCAN_CODE_MAP': windowsScanCodeMap,
      'WINDOWS_NUMPAD_MAP': windowsNumpadMap,
      'WINDOWS_KEY_CODE_MAP': windowsKeyCodeMap,
    };

    final String template = File(path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_${platform}_cc.tmpl')).readAsStringSync();
    return _injectDictionary(template, mappings);
  }

  /// The database of keys loaded from disk.
  final KeyData keyData;

  static String _injectDictionary(String template, Map<String, String> dictionary) {
    String result = template;
    for (final String key in dictionary.keys) {
      result = result.replaceAll('@@@$key@@@', dictionary[key]);
    }
    return result;
  }
}
