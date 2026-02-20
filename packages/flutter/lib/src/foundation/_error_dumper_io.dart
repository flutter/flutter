// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'print.dart';

/// Dumps error messages to the console.
class ErrorToConsoleDumper {
  /// Dumps the given error [message] to the console.
  static void dump(String message) => debugPrint(message);

  /// Adds a listener that captures error messages being dumped on the web.
  static void addWebDumpListener(void Function(String message) listener) {}

  /// Clears all listeners that capture error messages being dumped on the web.
  static void clearWebDumpListeners() {}
}
