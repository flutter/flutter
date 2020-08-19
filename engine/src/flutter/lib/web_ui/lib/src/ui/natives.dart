// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
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
  static void _printString(String? s) {
    print(s);
  }

  static void _printDebugString(String? s) {
    html.window.console.error(s!);
  }
}

List<int> saveCompilationTrace() {
  throw UnimplementedError();
}
