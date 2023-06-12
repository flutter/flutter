// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ConsoleUtils {
  /// Make [contents] bold when printed to the terminal.
  ///
  /// This is a no-op on Windows.
  static String bold(String contents) {
    return '\u001b[1m$contents\u001b[0m';
  }
}
