// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show exit;

import 'package:meta/meta.dart';

import 'process.dart';

/// Exits the process with the given [exitCode].
typedef ExitFunction = void Function(int exitCode);

const ExitFunction _defaultExitFunction = io.exit;

ExitFunction _exitFunction = _defaultExitFunction;

/// Exits the process.
///
/// Throws [AssertionError] if assertions are enabled and the dart:io exit
/// is still active when called. This may indicate exit was called in
/// a test without being configured correctly.
///
/// This is analogous to the `exit` function in `dart:io`, except that this
/// function may be set to a testing-friendly value by calling
/// [setExitFunctionForTests] (and then restored to its default implementation
/// with [restoreExitFunction]). The default implementation delegates to
/// `dart:io`.
ExitFunction get exit {
  assert(
    _exitFunction != io.exit || !_inUnitTest(),
    'io.exit was called with assertions active in a unit test',
  );
  return _exitFunction;
}

// Whether the tool is executing in a unit test.
bool _inUnitTest() {
  return Zone.current[#test.declarer] != null;
}

/// Sets the [exit] function to a function that throws an exception rather
/// than exiting the process; this is intended for testing purposes.
@visibleForTesting
void setExitFunctionForTests([ExitFunction? exitFunction]) {
  _exitFunction =
      exitFunction ??
      (int exitCode) {
        throw ProcessExit(exitCode, immediate: true);
      };
}

/// Restores the [exit] function to the `dart:io` implementation.
@visibleForTesting
void restoreExitFunction() {
  _exitFunction = _defaultExitFunction;
}
