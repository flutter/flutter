// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'common.dart';

void main() {
  const ProcessManager processManager = LocalProcessManager();

  group('run.dart script', () {
    Future<ProcessResult> runScript(List<String> testNames,
        [List<String> otherArgs = const <String>[]]) async {
      final String dart = path.absolute(
          path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
      final ProcessResult scriptProcess = processManager.runSync(<String>[
        dart,
        'bin/run.dart',
        ...otherArgs,
        for (final String testName in testNames) ...<String>['-t', testName],
      ]);
      return scriptProcess;
    }

    Future<void> expectScriptResult(
        List<String> testNames,
        int expectedExitCode,
        {String deviceId}
      ) async {
      final ProcessResult result = await runScript(testNames, <String>[
        if (deviceId != null) ...<String>['-d', deviceId],
      ]);
      expect(result.exitCode, expectedExitCode,
          reason:
              '[ stderr from test process ]\n\n${result.stderr}\n\n[ end of stderr ]'
              '\n\n[ stdout from test process ]\n\n${result.stdout}\n\n[ end of stdout ]');
    }

    test('exits with code 0 when succeeds', () async {
      await expectScriptResult(<String>['smoke_test_success'], 0);
    });

    test('accepts file paths', () async {
      await expectScriptResult(
          <String>['bin/tasks/smoke_test_success.dart'], 0);
    });

    test('rejects invalid file paths', () async {
      await expectScriptResult(<String>['lib/framework/adb.dart'], 1);
    });

    test('exits with code 1 when task throws', () async {
      await expectScriptResult(<String>['smoke_test_throws'], 1);
    });

    test('exits with code 1 when fails', () async {
      await expectScriptResult(<String>['smoke_test_failure'], 1);
    });

    test('exits with code 1 when fails to connect', () async {
      await expectScriptResult(<String>['smoke_test_setup_failure'], 1);
    }, skip: true); // https://github.com/flutter/flutter/issues/53707

    test('exits with code 1 when results are mixed', () async {
      await expectScriptResult(
        <String>[
          'smoke_test_failure',
          'smoke_test_success',
        ],
        1,
      );
    });

    test('exits with code 0 when provided a valid device ID', () async {
      await expectScriptResult(<String>['smoke_test_device'], 0,
        deviceId: 'FAKE');
    });

    test('exits with code 1 when provided a bad device ID', () async {
      await expectScriptResult(<String>['smoke_test_device'], 1,
        deviceId: 'THIS_IS_NOT_VALID');
    });


    test('runs A/B test', () async {
      final ProcessResult result = await runScript(
        <String>['smoke_test_success'],
        <String>['--ab=2', '--local-engine=host_debug_unopt'],
      );
      expect(result.exitCode, 0);

      String sectionHeader = !Platform.isWindows
          ? '═════════════════════════╡ ••• A/B results so far ••• ╞═════════════════════════'
          : 'A/B results so far';
      expect(
        result.stdout,
        contains(
          '$sectionHeader\n'
          '\n'
          'Score\tAverage A (noise)\tAverage B (noise)\tSpeed-up\n'
          'metric1\t42.00 (0.00%)\t42.00 (0.00%)\t1.00x\t\n'
          'metric2\t123.00 (0.00%)\t123.00 (0.00%)\t1.00x\t\n',
        ),
      );

      sectionHeader = !Platform.isWindows
          ? '════════════════════════════╡ ••• Raw results ••• ╞═════════════════════════════'
          : 'Raw results';
      expect(
        result.stdout,
        contains(
          '$sectionHeader\n'
          '\n'
          'metric1:\n'
          '  A:\t42.00\t42.00\t\n'
          '  B:\t42.00\t42.00\t\n'
          'metric2:\n'
          '  A:\t123.00\t123.00\t\n'
          '  B:\t123.00\t123.00\t\n',
        ),
      );

      sectionHeader = !Platform.isWindows
          ? '═════════════════════════╡ ••• Final A/B results ••• ╞══════════════════════════'
          : 'Final A/B results';
      expect(
        result.stdout,
        contains(
          '$sectionHeader\n'
          '\n'
          'Score\tAverage A (noise)\tAverage B (noise)\tSpeed-up\n'
          'metric1\t42.00 (0.00%)\t42.00 (0.00%)\t1.00x\t\n'
          'metric2\t123.00 (0.00%)\t123.00 (0.00%)\t1.00x\t\n',
        ),
      );
    });
  });
}
