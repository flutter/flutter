// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_devicelab/framework/runner.dart';

import 'common.dart';

void main() {
  final Map<String, String> isolateParams = <String, String>{
    'runFlutterConfig': 'false',
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
      expect(printLog[0], 'Test passed on first attempt.');
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
      expect(printLog[0], 'Consistently failed across all 3 executions.');
      expect(printLog[1], 'flaky: false');
    });
  });
}
