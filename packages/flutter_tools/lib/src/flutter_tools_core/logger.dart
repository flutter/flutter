// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A simple logging interface shared between host and extensions.
abstract class Logger {
  /// Print informational messages.
  void info(String message);

  /// Print warnings.
  void warning(String message);

  /// Print errors.
  void error(String message);
}
