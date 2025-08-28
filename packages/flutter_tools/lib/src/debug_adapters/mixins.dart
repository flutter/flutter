// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/io.dart';

/// A mixin for tracking additional PIDs that can be shut down at the end of a debug session.
///
/// Adapted from package:dds/src/dap/adapters/mixins.dart to use Flutter's
/// dart:io wrappers.
mixin PidTracker {
  /// Process IDs to terminate during shutdown.
  ///
  /// This may be populated with pids from the VM Service to ensure we clean up
  /// properly where signals may not be passed through the shell to the
  /// underlying VM process.
  /// https://github.com/Dart-Code/Dart-Code/issues/907
  final pidsToTerminate = <int>{};

  /// Terminates all processes with the PIDs registered in [pidsToTerminate].
  void terminatePids(ProcessSignal signal) {
    pidsToTerminate.forEach(signal.send);
  }
}
