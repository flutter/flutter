// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core logging interface for tool extensions.
///
/// This library defines a simple logging interface shared between the host
/// and extensions.
library flutter_tools_core.logger;

/// A simple logging interface shared between host and extensions.
///
/// This interface allows extensions to log messages (info, warning, error)
/// which are then forwarded to the host's logger.
abstract class Logger {
  /// Print informational messages.
  void info(String message);

  /// Print warnings.
  void warning(String message);

  /// Print errors.
  void error(String message);
}
