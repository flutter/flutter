// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'package:test/test.dart';

/// Asserts that `callback` throws an [AssertionError].
///
/// When running in a VM in which assertions are enabled, asserts that the
/// specified callback throws an [AssertionError]. When asserts are not
/// enabled, such as when running using a release-mode VM with default
/// settings, this acts as a no-op.
void expectAssertion(Function callback) {
  bool assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());
  if (assertsEnabled) {
    bool threw = false;
    try {
      callback();
    } catch (e) {
      expect(e is AssertionError, true);
      threw = true;
    }
    expect(threw, true);
  }
}

/// Asserts that `callback` throws an [ArgumentError].
void expectArgumentError(Function callback) {
  bool threw = false;
  try {
    callback();
  } catch (e) {
    expect(e is ArgumentError, true);
    threw = true;
  }
  expect(threw, true);
}

