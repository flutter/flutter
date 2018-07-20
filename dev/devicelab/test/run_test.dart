// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:test/test.dart';

void main() {
  const ProcessManager processManager = const LocalProcessManager();

  group('run.dart script', () {
    Future<int> runScript(List<String> testNames) async {
      final List<String> options = <String>['bin/run.dart'];
      for (String testName in testNames) {
        options..addAll(<String>['-t', testName]);
      }
      final String dart = path.absolute(path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
      final ProcessResult scriptProcess = processManager.runSync(
        <String>[dart]..addAll(options)
      );
      return scriptProcess.exitCode;
    }

    test('exits with code 0 when succeeds', () async {
      expect(await runScript(<String>['smoke_test_success']), 0);
    });

    test('accepts file paths', () async {
      expect(await runScript(<String>['bin/tasks/smoke_test_success.dart']), 0);
    });

    test('rejects invalid file paths', () async {
      expect(await runScript(<String>['lib/framework/adb.dart']), 1);
    });

    test('exits with code 1 when task throws', () async {
      expect(await runScript(<String>['smoke_test_throws']), 1);
    });

    test('exits with code 1 when fails', () async {
      expect(await runScript(<String>['smoke_test_failure']), 1);
    });

    test('exits with code 1 when fails to connect', () async {
      expect(await runScript(<String>['smoke_test_setup_failure']), 1);
    }, skip: true); // https://github.com/flutter/flutter/issues/5901

    test('exits with code 1 when results are mixed', () async {
      expect(
        await runScript(<String>[
          'smoke_test_failure',
          'smoke_test_success',
        ]),
        1,
      );
    });
  });
}
