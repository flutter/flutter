// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.test_environment;

import 'dart:async';

import 'configuration.dart';
import 'group_context.dart';
import 'internal_test_case.dart';

/// The default unittest environment.
final _defaultEnvironment = new TestEnvironment();

/// The current unittest environment.
TestEnvironment get environment {
  var environment = Zone.current[#unittest.environment];
  return environment == null ? _defaultEnvironment : environment;
}

// The current environment's configuration.
Configuration get config => environment.config;

/// Encapsulates the state of the test environment.
///
/// This is used by the [withTestEnvironment] method to support multiple
/// invocations of the unittest library within the same application
/// instance.
class TestEnvironment {
  /// The environment's configuration.
  Configuration config;

  /// The top-level group context.
  ///
  /// We use a 'dummy' context for the top level to eliminate null checks when
  /// querying the context. This allows us to easily support top-level
  /// [setUp]/[tearDown] functions as well.
  final rootContext = new GroupContext.root();

  /// The current group context.
  GroupContext currentContext;

  /// The [currentTestCaseIndex] represents the index of the currently running
  /// test case.
  ///
  /// If this is -1 it implies the test system is not running.
  /// It will be set to [number of test cases] as a short-lived state flagging
  /// that the last test has completed.
  int currentTestCaseIndex = -1;

  /// The [initialized] variable specifies whether the framework
  /// has been initialized.
  bool initialized = false;

  /// The time since we last gave asynchronous code a chance to be scheduled.
  int lastBreath = new DateTime.now().millisecondsSinceEpoch;

  /// The number of [solo_group]s deep we are currently.
  int soloNestingLevel = 0;

  /// Whether we've seen a [solo_test].
  bool soloTestSeen = false;

  /// The list of test cases to run.
  final testCases = new List<InternalTestCase>();

  /// The error message that is printed in the test summary.
  String uncaughtErrorMessage;

  TestEnvironment() {
    currentContext = rootContext;
  }
}
