// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.test_case;

import '../unittest.dart';

/// An individual unit test.
abstract class TestCase {
  /// A unique numeric identifier for this test case.
  int get id;

  /// A description of what the test is specifying.
  String get description;

  /// The error or failure message for the tests.
  ///
  /// Initially an empty string.
  String get message;

  /// The result of the test case.
  ///
  /// If the test case has is completed, this will be one of [PASS], [FAIL], or
  /// [ERROR]. Otherwise, it will be `null`.
  String get result;

  /// Returns whether this test case passed.
  bool get passed;

  /// The stack trace for the error that caused this test case to fail, or
  /// `null` if it succeeded.
  StackTrace get stackTrace;

  /// The name of the group within which this test is running.
  String get currentGroup;

  /// The time the test case started running.
  ///
  /// `null` if the test hasn't yet begun running.
  DateTime get startTime;

  /// The amount of time the test case took.
  ///
  /// `null` if the test hasn't finished running.
  Duration get runningTime;

  /// Whether this test is enabled.
  ///
  /// Disabled tests won't be run.
  bool get enabled;

  /// Whether this test case has finished running.
  bool get isComplete => !enabled || result != null;
}
