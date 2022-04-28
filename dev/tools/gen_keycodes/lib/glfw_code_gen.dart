// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';


/// Generates the key mapping of GLFW, based on the information in the key
/// data structure given to it.
class GlfwCodeGenerator extends PlatformCodeGenerator {
  GlfwCodeGenerator(KeyData keyData) : super(keyData);

  /// This generates the map of GLFW number pad key codes to logical keys.
  String get _glfwNumpadMap {
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
  String get _glfwKeyCodeMap {
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

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'keyboard_map_glfw_cc.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'GLFW_KEY_CODE_MAP': _glfwKeyCodeMap,
      'GLFW_NUMPAD_MAP': _glfwNumpadMap,
    };
  }
}
