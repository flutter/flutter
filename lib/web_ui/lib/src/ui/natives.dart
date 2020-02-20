// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of ui;

// Corelib 'print' implementation.
// ignore: unused_element
void _print(dynamic arg) {
  _Logger._printString(arg.toString());
}

void _printDebug(dynamic arg) {
  _Logger._printDebugString(arg.toString());
}

class _Logger {
  static void _printString(String s) {
    print(s);
  }
  static void _printDebugString(String s) {
    html.window.console.error(s);
  }
}

/// Returns runtime Dart compilation trace as a UTF-8 encoded memory buffer.
///
/// The buffer contains a list of symbols compiled by the Dart JIT at runtime up to the point
/// when this function was called. This list can be saved to a text file and passed to tools
/// such as `flutter build` or Dart `gen_snapshot` in order to precompile this code offline.
///
/// The list has one symbol per line of the following format: `<namespace>,<class>,<symbol>\n`.
/// Here are some examples:
///
/// ```
/// dart:core,Duration,get:inMilliseconds
/// package:flutter/src/widgets/binding.dart,::,runApp
/// file:///.../my_app.dart,::,main
/// ```
///
/// This function is only effective in debug and dynamic modes, and will throw in AOT mode.
List<int> saveCompilationTrace() {
  throw UnimplementedError();
}
