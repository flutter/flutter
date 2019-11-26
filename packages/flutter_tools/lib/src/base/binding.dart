// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'logger.dart';
import 'platform.dart';
import 'terminal.dart';

/// The base binding which provides shared dependencies for the rest of the
/// tool.
mixin BindingBase {
  /// Retreive the current [BindingBase] instance.
  ///
  /// This will be null if it was never initialized.
  static BindingBase instance;

  /// Whether the tool is being run in verbose mode.
  bool get verbose;

  /// The platform the tool is running under.
  Platform get platform => const LocalPlatform();

  @mustCallSuper
  void initializeBinding() {
    instance = this;
  }

  // Logging APIs

  /// The output preferences for the arg results and logger.
  OutputPreferences get outputPreferences => OutputPreferences();

  /// The logger instance.
  Logger get logger => _logger ??= _createLogger();
  Logger _logger;
  Logger _createLogger() {
    Logger logger = platform.isWindows ? WindowsStdoutLogger() : StdoutLogger();
    if (verbose) {
      logger = VerboseLogger(logger, createStopwatch());
    }
    return logger;
  }

  // Time APIs

  /// Create a new [Stopwatch] instance.
  Stopwatch createStopwatch() {
    return Stopwatch();
  }
}
