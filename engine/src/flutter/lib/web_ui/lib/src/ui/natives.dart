// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of ui;

/// Prints a warning to the browser's debug console.
void _debugPrintWarning(String warning) {
    if (engine.assertionsEnabled) {
      // Use a lower log level message to reduce noise in release mode.
      html.window.console.debug(warning);
      return;
    }
    html.window.console.warn(warning);
}

List<int> saveCompilationTrace() {
  if (engine.assertionsEnabled) {
    throw UnimplementedError('saveCompilationTrace is not implemented on the web.');
  }
  throw UnimplementedError();
}
