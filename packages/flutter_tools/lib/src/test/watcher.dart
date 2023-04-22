// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'test_device.dart';

/// Callbacks for reporting progress while running tests.
abstract class TestWatcher {
  /// Called after the test device starts.
  ///
  /// If startPaused was true, the caller needs to resume in DevTools to
  /// start running the tests.
  void handleStartedDevice(final Uri? vmServiceUri) { }

  /// Called after the tests finish but before the test device exits.
  ///
  /// The test device won't exit until this method completes.
  /// Not called if the test device died.
  Future<void> handleFinishedTest(final TestDevice testDevice);

  /// Called when the test device crashed before it could be connected to the
  /// test harness.
  Future<void> handleTestCrashed(final TestDevice testDevice);

  /// Called if we timed out waiting for the test device to connect to test
  /// harness.
  Future<void> handleTestTimedOut(final TestDevice testDevice);
}
