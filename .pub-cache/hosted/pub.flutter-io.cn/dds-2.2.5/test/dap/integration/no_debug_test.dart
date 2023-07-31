// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/src/dap/protocol_generated.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('noDebug mode', () {
    test('runs a simple script', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.launch(
          testFile.path,
          noDebug: true,
          args: ['one', 'two'],
        ),
      );

      final output = outputEvents.map((e) => e.output).join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    });

    test('runs a simple script using the runInTerminal request', () async {
      final testFile = dap.createTestFile(emptyProgram);

      // Set up a handler to handle the server calling the clients runInTerminal
      // request and capture the args.
      RunInTerminalRequestArguments? runInTerminalArgs;
      dap.client.handleRequest(
        'runInTerminal',
        (args) {
          runInTerminalArgs = RunInTerminalRequestArguments.fromJson(
            args as Map<String, Object?>,
          );
          return RunInTerminalResponseBody();
        },
      );

      // Run the script until we get a TerminatedEvent.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.initialize(supportsRunInTerminalRequest: true),
        dap.client.launch(
          testFile.path,
          noDebug: true,
          console: "terminal",
        ),
      ], eagerError: true);

      expect(runInTerminalArgs, isNotNull);
      expect(
        runInTerminalArgs!.args,
        containsAllInOrder([Platform.resolvedExecutable, testFile.path]),
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
