// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_devicelab/framework/runner.dart';

import 'common.dart';

void main() {
  final Map<String, String> isolateParams = <String, String>{
    'runFlutterConfig': 'false',
    'runProcessCleanup': 'false',
    'timeoutInMinutes': '1',
  };
  List<String> printLog;
  void print(String s) => printLog.add(s);

  group('run.dart script', () {
    test('Reruns - Test passes the first time.', () async {
      printLog = <String>[];
      await runTasks(
        <String>['smoke_test_success'],
        isolateParams: isolateParams,
        print: print,
        logs: printLog,
      );
      expect(printLog.length, 2);
      expect(printLog[0], 'Total 1 executions: 1 success');
      expect(printLog[1], 'flaky: false');
    });

    test('Reruns - Test fails all reruns.', () async {
      printLog = <String>[];
      await runTasks(
        <String>['smoke_test_failure'],
        isolateParams: isolateParams,
        print: print,
        logs: printLog,
      );
      expect(printLog.length, 2);
      expect(printLog[0], 'Total 3 executions: 0 success');
      expect(printLog[1], 'flaky: false');
    });
  });
}
