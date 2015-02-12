// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.configuration;

import 'simple_configuration.dart';
import 'test_case.dart';

/// Describes the interface used by the unit test system for communicating the
/// results of a test run.
abstract class Configuration {
  /// Creates an instance of [SimpleConfiguration].
  factory Configuration() => new SimpleConfiguration();

  /// Creates an [Configuration] instances that does nothing.
  ///
  /// For use by subclasses which wish to implement only a subset of features.
  Configuration.blank();

  /// If `true`, tests are started automatically once they're finished being defined.
  ///
  /// Otherwise, [runTests] must be called explicitly after tests are set up.
  final autoStart = true;

  /// How long a [TestCase] can run before it is considered an error.
  /// A [timeout] value of [:null:] means that the limit is infinite.
  Duration timeout = const Duration(minutes: 2);

  /// Called as soon as the unittest framework becomes initialized.
  ///
  /// This is done even before tests are added to the test framework. It might
  /// be used to determine/debug errors that occur before the test harness
  /// starts executing. It is also used to tell the vm or browser that tests are
  /// going to be run asynchronously and that the process should wait until they
  /// are done.
  void onInit() {}

  /// Called as soon as the unittest framework starts running.
  void onStart() {}

  /// Called when each test starts. Useful to show intermediate progress on
  /// a test suite.
  void onTestStart(TestCase testCase) {}

  /// Called when each test is first completed. Useful to show intermediate
  /// progress on a test suite.
  void onTestResult(TestCase testCase) {}

  /// Called when an already completed test changes state. For example: a test
  /// that was marked as passing may later be marked as being in error because
  /// it still had callbacks being invoked.
  void onTestResultChanged(TestCase testCase) {}

  /// Handles the logging of messages by a test case.
  void onLogMessage(TestCase testCase, String message) {}

  /// Called when the unittest framework is done running. [success] indicates
  /// whether all tests passed successfully.
  void onDone(bool success) {}

  /// Called with the result of all test cases. Browser tests commonly override
  /// this to reformat the output.
  ///
  /// When [uncaughtError] is not null, it contains an error that occured outside
  /// of tests (e.g. setting up the test).
  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {}
}
