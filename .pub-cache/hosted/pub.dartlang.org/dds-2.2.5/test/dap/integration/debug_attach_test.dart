// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
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

    test('can attach to a simple script using vmServiceUri', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final args = ['one', 'two'];
      final proc = await startDartProcessPaused(
        testFile.path,
        args,
        cwd: dap.testAppDir.path,
      );
      final vmServiceUri = await waitForStdoutVmServiceBanner(proc);

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.attach(
          vmServiceUri: vmServiceUri.toString(),
          autoResume: true,
          cwd: dap.testAppDir.path,
        ),
      );

      // Expect a "console" output event that prints the URI of the VM Service
      // the debugger connects to.
      final vmConnection = outputEvents.first;
      expect(vmConnection.output,
          startsWith('Connecting to VM Service at ws://127.0.0.1:'));
      expect(vmConnection.category, equals('console'));

      // Expect the normal applications output.
      final output = outputEvents
          .skip(1)
          .map((e) => e.output)
          // The stdout also contains the Observatory+DevTools banners.
          .where(
            (line) =>
                !line.startsWith('The Dart VM service is listening on') &&
                !line.startsWith(
                    'The Dart DevTools debugger and profiler is available at'),
          )
          .join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    });

    test('can attach to a simple script using vmServiceInfoFile', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Spawn the program using --write-service-info which we'll pass the path
      // of directly to the DAP to read.
      final vmServiceInfoFilePath = path.join(
        dap.testAppDir.path,
        'vmServiceInfo.json',
      );
      await startDartProcessPaused(
        testFile.path,
        ['one', 'two'],
        cwd: dap.testAppDir.path,
        vmArgs: ['--write-service-info=${Uri.file(vmServiceInfoFilePath)}'],
      );
      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.attach(
          vmServiceInfoFile: vmServiceInfoFilePath,
          autoResume: true,
          cwd: dap.testAppDir.path,
        ),
      );

      // Expect a "console" output event that prints the URI of the VM Service
      // the debugger connects to.
      final vmConnection = outputEvents.first;
      expect(
        vmConnection.output,
        startsWith('Connecting to VM Service at ws://127.0.0.1:'),
      );
      expect(vmConnection.category, equals('console'));

      // Expect the normal applications output.
      final output = outputEvents
          .skip(1)
          .map((e) => e.output)
          // The stdout also contains the Observatory+DevTools banners.
          .where(
            (line) =>
                !line.startsWith('The Dart VM service is listening on') &&
                !line.startsWith(
                    'The Dart DevTools debugger and profiler is available at'),
          )
          .join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    });

    test('removes breakpoints/pause and resumes on detach', () async {
      final testFile = dap.createTestFile(simpleBreakpointAndThrowProgram);

      final proc = await startDartProcessPaused(
        testFile.path,
        [],
        cwd: dap.testAppDir.path,
      );
      final vmServiceUri = await waitForStdoutVmServiceBanner(proc);

      // Attach to the paused script without resuming and wait for the startup
      // pause event.
      await Future.wait([
        dap.client.expectStop('entry'),
        dap.client.start(
          launch: () => dap.client.attach(
            vmServiceUri: vmServiceUri.toString(),
            autoResume: false,
            cwd: dap.testAppDir.path,
          ),
        ),
      ]);

      // Set a breakpoint that we expect not to be hit, as detach should disable
      // it and resume.
      final breakpointLine = lineWith(testFile, breakpointMarker);
      await dap.client.setBreakpoint(testFile, breakpointLine);

      // Detach using terminateRequest. Despite the name, terminateRequest is
      // the request for a graceful detach (and disconnectRequest is the
      // forceful shutdown).
      await dap.client.terminate();

      // Expect the process terminates (and hasn't got stuck on the breakpoint
      // or exception).
      await proc.exitCode;
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
