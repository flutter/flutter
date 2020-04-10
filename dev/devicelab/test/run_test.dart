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
    Future<ProcessResult> runScript(List<String> testNames) async {
      final String dart = path.absolute(path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
      final ProcessResult scriptProcess = processManager.runSync(<String>[
        dart,
        'bin/run.dart',
        for (final String testName in testNames) ...<String>['-t', testName],
      ]);
      return scriptProcess;
    }

    Future<void> expectScriptResult(List<String> testNames, { bool expectSuccess }) async {
      final ProcessResult result = await runScript(testNames);
      expect(result.exitCode, expectSuccess ? 0 : isNot(equals(0)),
          reason: '[ stderr from test process ]\n\n${result.stderr}\n\n[ end of stderr ]'
          '\n\n[ stdout from test process ]\n\n${result.stdout}\n\n[ end of stdout ]');
    }

    test('exits with code 0 when succeeds', () async {
      await expectScriptResult(<String>['smoke_test_success'], expectSuccess: true);
    });

    test('accepts file paths', () async {
      await expectScriptResult(<String>['bin/tasks/smoke_test_success.dart'], expectSuccess: true);
    });

    test('rejects invalid file paths', () async {
      await expectScriptResult(<String>['lib/framework/adb.dart'], expectSuccess: false);
    });

    test('exits with code 1 when task throws', () async {
      await expectScriptResult(<String>['smoke_test_throws'], expectSuccess: false);
    });

    test('exits with code 1 when fails', () async {
      await expectScriptResult(<String>['smoke_test_failure'], expectSuccess: false);
    });

    test('exits with code 1 when fails to connect', () async {
      await expectScriptResult(<String>['smoke_test_setup_failure'], expectSuccess: false);
    });

    test('exits with code 1 when results are mixed', () async {
      await expectScriptResult(<String>[
          'smoke_test_failure',
          'smoke_test_success',
        ],
        expectSuccess: false,
      );
    });
  });
}
