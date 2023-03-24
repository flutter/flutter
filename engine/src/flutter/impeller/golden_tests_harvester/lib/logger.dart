// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Logs messages to the appropriate console.
class Logger {
  Logger._();

  /// Singleton accessor for the [Logger].
  static Logger get instance {
    _instance ??= Logger._();
    return _instance!;
  }

  static Logger? _instance;

  /// Log [message] to the console.
  // ignore: avoid_print
  void log(String message) => print(message);
}
