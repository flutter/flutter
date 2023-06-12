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
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode', () {
    test('sends dart.log events when sendLogsToClient=true', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final logOutputs = dap.client
          .events('dart.log')
          .map((event) => event.body as Map<String, Object?>)
          .map((body) => body['message'] as String);

      await Future.wait([
        expectLater(
          logOutputs,
          // Check for a known VM Service packet.
          emitsThrough(
            contains('"method":"streamListen","params":{"streamId":"Debug"}'),
          ),
        ),
        dap.client.start(
          file: testFile,
          launch: () => dap.client.launch(
            testFile.path,
            sendLogsToClient: true,
          ),
        ),
      ]);
      await dap.client.terminate();
    });

    test('prints messages from dart:developer log()', () async {
      final testFile = dap.createTestFile(r'''
import 'dart:developer';

void main(List<String> args) async {
  log('this is a test\nacross two lines');
  log('this is a test', name: 'foo');
}
    ''');

      var outputEvents = await dap.client.collectOutput(file: testFile);

      // Skip the first line because it's the VM Service connection info.
      final output = outputEvents.skip(1).map((e) => e.output).join();
      expectLines(output, [
        '[log] this is a test',
        '      across two lines',
        '[foo] this is a test',
        '',
        'Exited.',
      ]);
    });

    test('prints long messages from dart:developer log()', () async {
      // Make a long message that's more than 255 chars (where the VM truncates
      // log strings by default).
      final longMessage = 'this is a test' * 20;
      final testFile = dap.createTestFile('''
import 'dart:developer';

void main(List<String> args) async {
  log('$longMessage');
  // Prevent us exiting before the async log messages may have completed.
  // The test will terminate the script early once the expectations are met.
  await Future.delayed(const Duration(seconds: 30));
}
    ''');
      final expectedLogMessage = '[log] $longMessage\n';

      final consoleOutputs = dap.client.outputEvents
          .where((event) => event.category == 'console')
          .map((event) => event.output);

      await Future.wait([
        expectLater(consoleOutputs, emitsThrough(expectedLogMessage)),
        dap.client.start(file: testFile),
      ]);
      await dap.client.terminate();
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
