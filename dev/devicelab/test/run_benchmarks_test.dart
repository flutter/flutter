// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import 'common.dart';

void main() {
  TaskFunction succeed(List<String> log, String name, double value) => () async {
    log.add(name);
    return TaskResult.success(<String, dynamic>{'t': value}, benchmarkScoreKeys: <String>['t']);
  };

  test('runBenchmarks runs in order and merges results', () async {
    final log = <String>[];
    final TaskResult result = await runBenchmarks(<String, TaskFunction>{
      'a': succeed(log, 'a', 1),
      'b': succeed(log, 'b', 2),
    })();
    expect(log, <String>['a', 'b']);
    expect(result.succeeded, isTrue);
    expect(result.data, <String, dynamic>{'a/t': 1.0, 'b/t': 2.0});
    expect(result.benchmarkScoreKeys, <String>['a/t', 'b/t']);
  });

  test('runBenchmarks runs every benchmark and reports all failures', () async {
    final log = <String>[];
    final TaskResult result = await runBenchmarks(<String, TaskFunction>{
      'a': succeed(log, 'a', 1),
      'b': () async {
        log.add('b');
        return TaskResult.failure('boom');
      },
      'c': succeed(log, 'c', 3),
      'd': () async {
        log.add('d');
        return TaskResult.failure('bang');
      },
    })();
    expect(log, <String>['a', 'b', 'c', 'd']);
    expect(result.failed, isTrue);
    expect(result.message, 'b: boom\nd: bang');
  });
}
