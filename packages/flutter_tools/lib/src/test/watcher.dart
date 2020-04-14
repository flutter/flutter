// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import '../base/io.dart' show Process;

/// Callbacks for reporting progress while running tests.
abstract class TestWatcher {
  /// Called after a child process starts.
  ///
  /// If startPaused was true, the caller needs to resume in Observatory to
  /// start running the tests.
  void handleStartedProcess(ProcessEvent event) { }

  /// Called after the tests finish but before the process exits.
  ///
  /// The child process won't exit until this method completes.
  /// Not called if the process died.
  Future<void> handleFinishedTest(ProcessEvent event);

  /// Called when the test process crashed before connecting to test harness.
  Future<void> handleTestCrashed(ProcessEvent event);

  /// Called if we timed out waiting for the test process to connect to test
  /// harness.
  Future<void> handleTestTimedOut(ProcessEvent event);
}

/// Describes a child process started during testing.
class ProcessEvent {
  ProcessEvent(this.childIndex, this.process, [this.observatoryUri]);

  /// The index assigned when the child process was launched.
  ///
  /// Indexes are assigned consecutively starting from zero.
  /// When debugging, there should only be one child process so this will
  /// always be zero.
  final int childIndex;

  final Process process;

  /// The observatory URL or null if not debugging.
  final Uri observatoryUri;
}
