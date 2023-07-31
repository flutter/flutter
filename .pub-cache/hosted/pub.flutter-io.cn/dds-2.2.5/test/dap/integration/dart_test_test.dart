// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp(additionalArgs: ['--test']);
    await dap.addPackageDependency(dap.testAppDir, 'test');
  });
  tearDown(() => dap.tearDown());

  group('dart test', () {
    /// A helper that verifies a full set of expected test results for the
    /// [simpleTestProgram] script.
    void expectStandardSimpleTestResults(TestEvents events) {
      // Check we received all expected test events passed through from
      // package:test.
      final eventNames =
          events.testNotifications.map((e) => e['type']).toList();

      // start/done should always be first/last.
      expect(eventNames.first, equals('start'));
      expect(eventNames.last, equals('done'));

      // allSuites should have occurred after start.
      expect(
        eventNames,
        containsAllInOrder(['start', 'allSuites']),
      );

      // Expect two tests, with the failing one emitting an error.
      expect(
        eventNames,
        containsAllInOrder([
          'testStart',
          'testDone',
          'testStart',
          'error',
          'testDone',
        ]),
      );
    }

    test('can run without debugging', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        launch: () => client.launch(
          testFile.path,
          noDebug: true,
          cwd: dap.testAppDir.path,
          args: ['--chain-stack-traces'], // to suppress warnings in the output
        ),
      );

      // Check the printed output shows that the run finished, and it's exit
      // code (which is 1 due to the failing test).
      final output = outputEvents.output.map((e) => e.output).join();
      expectLines(output, simpleTestProgramExpectedOutput);

      expectStandardSimpleTestResults(outputEvents);
    });

    test('can run a single test', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        launch: () => client.launch(
          testFile.path,
          noDebug: true,
          cwd: dap.testAppDir.path,
          // It's up to the calling IDE to pass the correct args for 'dart test'
          // if it wants to run a subset of tests.
          args: [
            '--plain-name',
            'passing test',
          ],
        ),
      );

      final testsNames = outputEvents.testNotifications
          .where((e) => e['type'] == 'testStart')
          .map((e) => (e['test'] as Map<String, Object?>)['name'])
          .toList();

      expect(testsNames, contains('group 1 passing test'));
      expect(testsNames, isNot(contains('group 1 failing test')));
    });

    test('can hit and resume from a breakpoint', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        // When launching, hit a breakpoint and resume.
        start: () => client.hitBreakpoint(
          testFile,
          breakpointLine,
          cwd: dap.testAppDir.path,
          args: ['--chain-stack-traces'], // to suppress warnings in the output
        ).then((stop) => client.continue_(stop.threadId!)),
      );

      // Check the usual output and test events to ensure breaking/resuming did
      // not affect the results.
      final output = outputEvents.output
          .map((e) => e.output)
          .skipWhile(dapVmServiceBannerPattern.hasMatch)
          .join();
      expectLines(output, simpleTestProgramExpectedOutput);
      expectStandardSimpleTestResults(outputEvents);
    });

    test('rejects attaching', () async {
      final client = dap.client;

      final outputEvents = await client.collectTestOutput(
        launch: () => client.attach(
          vmServiceUri: 'ws://bogus.local/',
          autoResume: false,
        ),
      );

      final output = outputEvents.output.map((e) => e.output).join();
      expectLines(output, [
        'Attach is not supported for test runs',
        'Exited.',
      ]);
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
