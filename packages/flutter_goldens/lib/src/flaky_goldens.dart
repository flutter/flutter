// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Allows flaky test handling for the Flutter framework.
///
/// Mixed in with the [FlutterGoldenFileComparator] and
/// [_FlutterWebGoldenComparator].
mixin FlakyGoldenMixin  {
  /// Whether this comparator allows flaky goldens.
  ///
  /// If set to true, concrete implementations of this class are expected to
  /// generate the golden and submit it for review, but not fail the test.
  bool _isFlakyModeEnabled = false;

  /// Puts this comparator into flaky comparison mode.
  ///
  /// After calling this method the next invocation of [compare] will allow
  /// incorrect golden to pass the check.
  ///
  /// Concrete implementations of [compare] must call [getAndResetFlakyMode] so
  /// that subsequent tests can run in non-flaky mode. If a subsequent test
  /// needs to run in a flaky mode, it must call this method again.
  void enableFlakyMode() {
    assert(
      !_isFlakyModeEnabled,
      'Test is already marked as flaky. Call `getAndResetFlakyMode` to reset the '
      'flag before calling this method again.',
    );
    _isFlakyModeEnabled = true;
  }

  /// Returns whether flaky comparison mode was enabled via [enableFlakyMode],
  /// and if it was, resets the comparator back to non-flaky mode.
  bool getAndResetFlakyMode() {
    if (!_isFlakyModeEnabled) {
      // Not in flaky mode. Nothing to do.
      return false;
    }

    // In flaky mode. Reset it and return true.
    _isFlakyModeEnabled = false;
    return true;
  }
}
