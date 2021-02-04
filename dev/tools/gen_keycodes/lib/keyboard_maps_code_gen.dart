// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'logical_key_data.dart';
import 'physical_key_data.dart';
import 'utils.dart';

class _OutputLines<T extends Comparable<Object>> {
  final Map<T, String> lines = <T, String>{};

  void add(T code, String line) {
    lines[code] = line;
  }

  String sortedJoin() {
    return (lines.entries.toList()
      ..sort((MapEntry<T, String> a, MapEntry<T, String> b) => a.key.compareTo(b.key)))
      .map((MapEntry<T, String> entry) => entry.value)
      .join('\n');
  }
}

/// Generates the keyboard_maps.dart files, based on the information in the key
/// data structure given to it.
class KeyboardMapsCodeGenerator extends BaseCodeGenerator {
  KeyboardMapsCodeGenerator(PhysicalKeyData keyData, this.logicalData) : super(keyData);

  final LogicalKeyData logicalData;

  List<PhysicalKeyEntry> get numpadKeyData {
    return keyData.data.where((PhysicalKeyEntry entry) {
      return entry.constantName.startsWith('numpad') && entry.keyLabel != null;
    }).toList();
  }

  List<PhysicalKeyEntry> get functionKeyData {
    final RegExp functionKeyRe = RegExp(r'^f[0-9]+$');
    return keyData.data.where((PhysicalKeyEntry entry) {
      return functionKeyRe.hasMatch(entry.constantName);
    }).toList();
  }

  List<LogicalKeyEntry> get numpadLogicalKeyData {
    return logicalData.data.values.where((LogicalKeyEntry entry) {
      return entry.constantName.startsWith('numpad') && entry.keyLabel != null;
    }).toList();
  }

  List<LogicalKeyEntry> get functionLogicalKeyData {
    final RegExp functionKeyRe = RegExp(r'^f[0-9]+$');
    return logicalData.data.values.where((LogicalKeyEntry entry) {
      return functionKeyRe.hasMatch(entry.constantName);
    }).toList();
  }

  /// This generates the map of GLFW number pad key codes to logical keys.
  String get glfwNumpadMap {
    final StringBuffer glfwNumpadMap = StringBuffer();
    for (final PhysicalKeyEntry entry in numpadKeyData) {
      if (entry.glfwKeyCodes != null) {
        for (final int code in entry.glfwKeyCodes.cast<int>()) {
          glfwNumpadMap.writeln('  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return glfwNumpadMap.toString().trimRight();
  }

  /// This generates the map of GLFW key codes to logical keys.
  String get glfwKeyCodeMap {
    final StringBuffer glfwKeyCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.glfwKeyCodes != null) {
        for (final int code in entry.glfwKeyCodes.cast<int>()) {
          glfwKeyCodeMap.writeln('  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return glfwKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of GTK number pad key codes to logical keys.
  String get gtkNumpadMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in numpadLogicalKeyData) {
      if (entry.gtkValues != null) {
        for (final int code in entry.gtkValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of GTK key codes to logical keys.
  String get gtkKeyCodeMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      if (entry.gtkValues != null) {
        for (final int code in entry.gtkValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of XKB USB HID codes to physical keys.
  String get xkbScanCodeMap {
    final StringBuffer xkbScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.xKbScanCode != null) {
        xkbScanCodeMap.writeln('  ${toHex(entry.xKbScanCode)}: PhysicalKeyboardKey.${entry.constantName},');
      }
    }
    return xkbScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Android key codes to logical keys.
  String get androidKeyCodeMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      if (entry.androidValues != null) {
        for (final int code in entry.androidValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of Android number pad key codes to logical keys.
  String get androidNumpadMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in numpadLogicalKeyData) {
      if (entry.androidValues != null) {
        for (final int code in entry.androidValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of Android scan codes to physical keys.
  String get androidScanCodeMap {
    final StringBuffer androidScanCodeMap = StringBuffer();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      if (entry.androidValues != null) {
        for (final int code in entry.androidValues) {
          androidScanCodeMap.writeln('  $code: PhysicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return androidScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Windows scan codes to physical keys.
  String get windowsScanCodeMap {
    final StringBuffer windowsScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.windowsScanCode != null) {
        windowsScanCodeMap.writeln('  ${toHex(entry.windowsScanCode)}: PhysicalKeyboardKey.${entry.constantName},');
      }
    }
    return windowsScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Windows number pad key codes to logical keys.
  String get windowsNumpadMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in numpadLogicalKeyData) {
      if (entry.windowsValues != null){
        for (final int code in entry.windowsValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of Windows key codes to logical keys.
  String get windowsKeyCodeMap {
    final _OutputLines<int> lines = _OutputLines<int>();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      if (entry.windowsValues != null) {
        for (final int code in entry.windowsValues) {
          lines.add(code, '  $code: LogicalKeyboardKey.${entry.constantName},');
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of macOS key codes to physical keys.
  String get macOsScanCodeMap {
    final StringBuffer macOsScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.macOsScanCode != null) {
        macOsScanCodeMap.writeln('  ${toHex(entry.macOsScanCode)}: PhysicalKeyboardKey.${entry.constantName},');
      }
    }
    return macOsScanCodeMap.toString().trimRight();
  }

  /// This generates the map of macOS number pad key codes to logical keys.
  String get macOsNumpadMap {
    final StringBuffer macOsNumPadMap = StringBuffer();
    for (final PhysicalKeyEntry entry in numpadKeyData) {
      if (entry.macOsScanCode != null) {
        macOsNumPadMap.writeln('  ${toHex(entry.macOsScanCode)}: LogicalKeyboardKey.${entry.constantName},');
      }
    }
    return macOsNumPadMap.toString().trimRight();
  }

  String get macOsFunctionKeyMap {
    final StringBuffer macOsFunctionKeyMap = StringBuffer();
    for (final PhysicalKeyEntry entry in functionKeyData) {
      if (entry.macOsScanCode != null) {
        macOsFunctionKeyMap.writeln('  ${toHex(entry.macOsScanCode)}: LogicalKeyboardKey.${entry.constantName},');
      }
    }
    return macOsFunctionKeyMap.toString().trimRight();
  }

  /// This generates the map of iOS key codes to physical keys.
  String get iosScanCodeMap {
    final StringBuffer iosScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.iosScanCode != null) {
        iosScanCodeMap.writeln('  ${toHex(entry.iosScanCode)}: PhysicalKeyboardKey.${entry.constantName},');
      }
    }
    return iosScanCodeMap.toString().trimRight();
  }

  /// This generates the map of iOS number pad key codes to logical keys.
  String get iosNumpadMap {
    final StringBuffer iosNumPadMap = StringBuffer();
    for (final PhysicalKeyEntry entry in numpadKeyData) {
      if (entry.iosScanCode != null) {
        iosNumPadMap.writeln('  ${toHex(entry.iosScanCode)}: LogicalKeyboardKey.${entry.constantName},');
      }
    }
    return iosNumPadMap.toString().trimRight();
  }

  /// This generates the map of Fuchsia key codes to logical keys.
  String get fuchsiaKeyCodeMap {
    final StringBuffer fuchsiaKeyCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaKeyCodeMap.writeln('  ${toHex(entry.flutterId)}: LogicalKeyboardKey.${entry.constantName},');
      }
    }
    return fuchsiaKeyCodeMap.toString().trimRight();
  }

  /// This generates the map of Fuchsia USB HID codes to physical keys.
  String get fuchsiaHidCodeMap {
    final StringBuffer fuchsiaScanCodeMap = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.usbHidCode != null) {
        fuchsiaScanCodeMap.writeln('  ${toHex(entry.usbHidCode)}: PhysicalKeyboardKey.${entry.constantName},');
      }
    }
    return fuchsiaScanCodeMap.toString().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to logical keys.
  String get webLogicalKeyMap {
    final _OutputLines<String> lines = _OutputLines<String>();
    for (final LogicalKeyEntry entry in logicalData.data.values) {
      if (entry.webNames != null) {
        for (final String name in entry.webNames) {
          lines.add(name, "  '$name': LogicalKeyboardKey.${entry.constantName},");
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  /// This generates the map of Web KeyboardEvent codes to physical keys.
  String get webPhysicalKeyMap {
    final StringBuffer result = StringBuffer();
    for (final PhysicalKeyEntry entry in keyData.data) {
      if (entry.name != null) {
        result.writeln("  '${entry.name}': PhysicalKeyboardKey.${entry.constantName},");
      }
    }
    return result.toString().trimRight();
  }

  /// This generates the map of Web number pad codes to logical keys.
  String get webNumpadMap {
    final _OutputLines<String> lines = _OutputLines<String>();
    for (final LogicalKeyEntry entry in numpadLogicalKeyData) {
      if (entry.webNames != null) {
        for (final String name in entry.webNames) {
          lines.add(name, "  '$name': LogicalKeyboardKey.${entry.constantName},");
        }
      }
    }
    return lines.sortedJoin().trimRight();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_maps.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'ANDROID_SCAN_CODE_MAP': androidScanCodeMap,
      'ANDROID_KEY_CODE_MAP': androidKeyCodeMap,
      'ANDROID_NUMPAD_MAP': androidNumpadMap,
      'FUCHSIA_SCAN_CODE_MAP': fuchsiaHidCodeMap,
      'FUCHSIA_KEY_CODE_MAP': fuchsiaKeyCodeMap,
      'MACOS_SCAN_CODE_MAP': macOsScanCodeMap,
      'MACOS_NUMPAD_MAP': macOsNumpadMap,
      'MACOS_FUNCTION_KEY_MAP': macOsFunctionKeyMap,
      'IOS_SCAN_CODE_MAP': iosScanCodeMap,
      'IOS_NUMPAD_MAP': iosNumpadMap,
      'GLFW_KEY_CODE_MAP': glfwKeyCodeMap,
      'GLFW_NUMPAD_MAP': glfwNumpadMap,
      'GTK_KEY_CODE_MAP': gtkKeyCodeMap,
      'GTK_NUMPAD_MAP': gtkNumpadMap,
      'XKB_SCAN_CODE_MAP': xkbScanCodeMap,
      'WEB_LOGICAL_KEY_MAP': webLogicalKeyMap,
      'WEB_PHYSICAL_KEY_MAP': webPhysicalKeyMap,
      'WEB_NUMPAD_MAP': webNumpadMap,
      'WINDOWS_LOGICAL_KEY_MAP': windowsKeyCodeMap,
      'WINDOWS_PHYSICAL_KEY_MAP': windowsScanCodeMap,
      'WINDOWS_NUMPAD_MAP': windowsNumpadMap,
    };
  }
}
