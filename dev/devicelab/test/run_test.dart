// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/utils.dart' show rm;
import 'package:path/path.dart' as path;
import 'package:process/process.dart';


void main() {
  const ProcessManager processManager = LocalProcessManager();
  final String dart = path.absolute(
    path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));

  group('run.dart script', () {
    // The tasks here refer to files in ../bin/tasks/*.dart

    Future<ProcessResult> runScript(List<String> taskNames,
        [List<String> otherArgs = const <String>[]]) async {
      final ProcessResult scriptProcess = processManager.runSync(<String>[
        dart,
        'bin/run.dart',
        '--no-terminate-stray-dart-processes',
        ...otherArgs,
        for (final String testName in taskNames) ...<String>['-t', testName],
      ]);
      return scriptProcess;
    }

    Future<void> expectScriptResult(
        List<String> taskNames,
        int expectedExitCode,
        {String? deviceId}
      ) async {
      final ProcessResult result = await runScript(taskNames, <String>[
        if (deviceId != null) ...<String>['-d', deviceId],
      ]);
      expect(
        result.exitCode,
        expectedExitCode,
        reason:
          '[ stderr from test process ]\n'
          '\n'
          '${result.stderr}\n'
          '\n'
          '[ end of stderr ]\n'
          '\n'
          '[ stdout from test process ]\n'
          '\n'
          '${result.stdout}\n'
          '\n'
          '[ end of stdout ]',
      );
    }

    test('exits with code 0 when succeeds', () async {
      await expectScriptResult(<String>['smoke_test_success'], 0);
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

    test('prints a message after a few seconds when failing to connect (this test takes >10s)', () async {
      final Process process = await processManager.start(<String>[
        dart,
        'bin/run.dart',
        '--no-terminate-stray-dart-processes',
        '-t', 'smoke_test_setup_failure',
      ]);
      await process.stdout.transform(utf8.decoder).where(
        (String line) => line.contains('VM service still not ready. It is possible the target has failed')
      ).first;
      expect(process.kill(), isTrue);
    });

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
      final Directory tempDirectory = Directory.systemTemp.createTempSync('flutter_devicelab_ab_test.');
      final File abResultsFile = File(path.join(tempDirectory.path, 'test_results.json'));

      expect(abResultsFile.existsSync(), isFalse);

      final ProcessResult result = await runScript(
        <String>['smoke_test_success'],
        <String>['--ab=2', '--local-engine=host_debug_unopt', '--local-engine-host=host_debug_unopt', '--ab-result-file', abResultsFile.path],
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

      expect(abResultsFile.existsSync(), isTrue);
      rm(tempDirectory, recursive: true);
    });

    test('fails to upload results to Cocoon if flags given', () async {
      // CocoonClient will fail to find test-file, and will not send any http requests.
      final ProcessResult result = await runScript(
        <String>['smoke_test_success'],
        <String>['--service-account-file=test-file', '--task-key=task123'],
      );
      expect(result.exitCode, 1);
    });
  });
}
