// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:path/path.dart' as p;
import 'package:test_api/backend.dart'; //ignore: deprecated_member_use
import 'package:test_api/src/backend/declarer.dart'; //ignore: implementation_imports
import 'package:test_api/src/backend/group.dart'; //ignore: implementation_imports
import 'package:test_api/src/backend/group_entry.dart'; //ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/test.dart'; //ignore: implementation_imports

import 'runner/configuration.dart';
import 'runner/engine.dart';
import 'runner/plugin/environment.dart';
import 'runner/reporter.dart';
import 'runner/reporter/expanded.dart';
import 'runner/runner_suite.dart';
import 'runner/suite.dart';
import 'util/os.dart';
import 'util/print_sink.dart';

/// Runs all unskipped test cases declared in [testMain].
///
/// Test suite level metadata defined in annotations is not read. No filtering
/// is applied except for the filtering defined by `solo` or `skip` arguments to
/// `group` and `test`. Returns [true] if all tests passed.
Future<bool> directRunTests(FutureOr<void> Function() testMain,
        {Reporter Function(Engine)? reporterFactory,
        // TODO: Change the default https://github.com/dart-lang/test/issues/1571
        bool allowDuplicateTestNames = true}) =>
    _directRunTests(testMain,
        reporterFactory: reporterFactory,
        allowDuplicateTestNames: allowDuplicateTestNames);

/// Runs a single test declared in [testMain] matched by it's full test name.
///
/// There must be exactly one test defined with the name [fullTestName]. Note
/// that not all tests and groups are checked, so a test case that is not be
/// intended to be run (due to a `solo` on a different test) may still be run
/// with this API. Only the test names returned by [enumerateTestCases] should
/// be used to prevent running skipped tests.
///
/// Return [true] if the test passes.
///
/// If there are no tests matching [fullTestName] a [MissingTestException] is
/// thrown. If there is more than one test with the name [fullTestName] they
/// will both be run, then a [DuplicateTestnameException] will be thrown.
Future<bool> directRunSingleTest(
        FutureOr<void> Function() testMain, String fullTestName,
        {Reporter Function(Engine)? reporterFactory}) =>
    _directRunTests(testMain,
        reporterFactory: reporterFactory,
        fullTestName: fullTestName,
        allowDuplicateTestNames: false);

Future<bool> _directRunTests(FutureOr<void> Function() testMain,
    {Reporter Function(Engine)? reporterFactory,
    String? fullTestName,
    required bool allowDuplicateTestNames}) async {
  reporterFactory ??= (engine) => ExpandedReporter.watch(engine, PrintSink(),
      color: Configuration.empty.color, printPath: false, printPlatform: false);
  final declarer = Declarer(
      fullTestName: fullTestName,
      allowDuplicateTestNames: allowDuplicateTestNames);
  await declarer.declare(testMain);

  final suite = RunnerSuite(const PluginEnvironment(), SuiteConfiguration.empty,
      declarer.build(), SuitePlatform(Runtime.vm, os: currentOSGuess),
      path: p.prettyUri(Uri.base));

  final engine = Engine()
    ..suiteSink.add(suite)
    ..suiteSink.close();

  reporterFactory(engine);

  final success = await runZoned(() => Invoker.guard(engine.run),
          zoneValues: {#test.declarer: declarer}) ??
      false;

  if (fullTestName != null) {
    final testCount = engine.liveTests.length;
    if (testCount == 0) {
      throw MissingTestException(fullTestName);
    }
  }
  return success;
}

/// Runs [testMain] and returns the names of all declared tests.
///
/// Test names declared must be unique. If any test repeats the full name,
/// including group prefixes, of a prior test a [DuplicateTestNameException]
/// will be thrown.
///
/// Skipped tests are ignored.
Future<Set<String>> enumerateTestCases(
    FutureOr<void> Function() testMain) async {
  final declarer = Declarer();
  await declarer.declare(testMain);

  final toVisit = Queue<GroupEntry>.of([declarer.build()]);
  final unskippedTestNames = <String>{};
  while (toVisit.isNotEmpty) {
    final current = toVisit.removeLast();
    if (current is Group) {
      toVisit.addAll(current.entries.reversed);
    } else if (current is Test) {
      if (current.metadata.skip) continue;
      unskippedTestNames.add(current.name);
    } else {
      throw StateError('Unhandled Group Entry: ${current.runtimeType}');
    }
  }
  return unskippedTestNames;
}

/// An exception thrown when a specific test was requested by name that does not
/// exist.
class MissingTestException implements Exception {
  final String name;
  MissingTestException(this.name);

  @override
  String toString() =>
      'A test with the name "$name" was not declared in the test suite.';
}
