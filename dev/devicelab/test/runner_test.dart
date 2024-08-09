// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_devicelab/framework/runner.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  final Map<String, String> isolateParams = <String, String>{
    'runFlutterConfig': 'false',
    'timeoutInMinutes': '1',
  };

  group('run.dart script', () {
    test('Reruns - Test passes the first time.', () async {
      final List<String> printLog = <String>[];
      void print(String s) => printLog.add(s);
      await runTasks(
        <String>['smoke_test_success'],
        isolateParams: isolateParams,
        print: print,
        logs: printLog,
      );
      expect(printLog.length, 2);
      expect(printLog[0], 'Test passed on first attempt.');
      expect(printLog[1], 'flaky: false');
    });

    test('Reruns - Test fails all reruns.', () async {
      final List<String> printLog = <String>[];
      void print(String s) => printLog.add(s);
      await runTasks(
        <String>['smoke_test_failure'],
        isolateParams: isolateParams,
        print: print,
        logs: printLog,
      );
      expect(printLog.length, 2);
      expect(printLog[0], 'Consistently failed across all 3 executions.');
      expect(printLog[1], 'flaky: false');
    });

    test('Infra reruns - Infra flake not counted.', () async {
      final io.Directory tmpDir = io.Directory.systemTemp.createTempSync(
        'runner_test',
      );
      try {
        final io.File tmpFile = io.File(path.join(tmpDir.path, 'file'));
        final List<String> printLog = <String>[];
        void prnt(String s) => printLog.add(s);
        await runTasks(
          <String>['smoke_test_infra_failure'],
          isolateParams: isolateParams,
          print: prnt,
          logs: printLog,
          taskArgs: <String>[tmpFile.path],
        );
        expect(printLog, anyElement(contains(
          'The test failed due to a transient infrastructure issue',
        )));
        expect(printLog, anyElement(contains('Test passed on first attempt.')));
        expect(printLog, anyElement(contains('flaky: false')));
      } finally {
        try {
          tmpDir.deleteSync(recursive: true);
        } catch (_) {
          // Ignore failures to clean up the temporary directory.
        }
      }
    });
  });
}
