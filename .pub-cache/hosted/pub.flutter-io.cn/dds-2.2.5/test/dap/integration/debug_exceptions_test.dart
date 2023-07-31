// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  group('debug mode', () {
    late DapTestSession dap;
    setUp(() async {
      dap = await DapTestSession.setUp();
    });
    tearDown(() => dap.tearDown());

    test('does not pause on exceptions if mode not set', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleThrowingProgram);

      // Run the app and expect it to complete (it should not pause).
      final outputEvents = await client.collectOutput(file: testFile);

      // Expect error info printed to stderr.
      final output = outputEvents
          .where((e) => e.category == 'stderr')
          .map((e) => e.output)
          .join();
      expectLinesStartWith(output, [
        'Unhandled exception:',
        'error',
      ]);
    });

    test('pauses on uncaught exceptions when mode=Unhandled', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleThrowingProgram);

      // Run and expect to pause on an exception.
      await client.pauseOnException(
        testFile,
        exceptionPauseMode: 'Unhandled',
      );
    });

    test('does not pauses on caught exceptions when mode=Unhandled', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleCaughtErrorProgram);

      // Run the app and expect it to complete (it should not pause).
      final outputEvents = await client.collectOutput(file: testFile);

      // Expect error info printed to stderr.
      final output = outputEvents
          .where((e) => e.category == 'stdout')
          .map((e) => e.output)
          .join();
      expectLines(output, ['Caught!']);
    });

    test('pauses on caught exceptions when mode=All', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleCaughtErrorProgram);

      // Run and expect to pause on an exception.
      await client.pauseOnException(
        testFile,
        exceptionPauseMode: 'All',
      );
    });

    test('parses line/column information from stack traces', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleThrowingProgram);
      final exceptionLine = lineWith(testFile, 'throw');
      final outputEvents = await client.collectOutput(file: testFile);

      // Find the output event for the top of the printed stack trace.
      // It should look something like:
      // #0      main (file:///var/folders/[...]/app3JZLvu/test_file.dart:2:5)
      final mainStackFrameEvent = outputEvents
          .firstWhere((event) => event.output.startsWith('#0      main'));

      // Expect that there is metadata attached that matches the file/location we
      // expect.
      expect(mainStackFrameEvent.source?.path, testFile.path);
      expect(mainStackFrameEvent.line, exceptionLine);
      expect(mainStackFrameEvent.column, 5);
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
