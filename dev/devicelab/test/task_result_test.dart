// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/task_result.dart';

import 'common.dart';

void main() {
  group('TaskResult fromJson', () {
    test('succeeded', () {
      final expectedJson = <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'i': 5, 'j': 10, 'not_a_metric': 'something'},
        'benchmarkScoreKeys': <String>['i', 'j'],
        'detailFiles': <String>[],
      };
      final result = TaskResult.fromJson(expectedJson);
      expect(result.toJson(), expectedJson);
    });

    test('succeeded with empty data', () {
      final result = TaskResult.fromJson(<String, dynamic>{'success': true});
      final expectedJson = <String, dynamic>{
        'success': true,
        'data': null,
        'benchmarkScoreKeys': <String>[],
        'detailFiles': <String>[],
      };
      expect(result.toJson(), expectedJson);
    });

    test('failed', () {
      final expectedJson = <String, dynamic>{'success': false, 'reason': 'failure message'};
      final result = TaskResult.fromJson(expectedJson);
      expect(result.toJson(), expectedJson);
    });
  });

  group('TaskResult.merge', () {
    test('namespaces data and score keys by task name', () {
      final merged = TaskResult.merge(<String, TaskResult>{
        'a_perf': TaskResult.success(
          <String, dynamic>{'frame_time': 1.0, 'extra': 'x'},
          benchmarkScoreKeys: <String>['frame_time'],
          detailFiles: <String>['a.trace'],
        ),
        'b_perf': TaskResult.success(
          <String, dynamic>{'frame_time': 2.0},
          benchmarkScoreKeys: <String>['frame_time'],
        ),
      });
      expect(merged.succeeded, isTrue);
      expect(merged.data, <String, dynamic>{
        'a_perf/frame_time': 1.0,
        'a_perf/extra': 'x',
        'b_perf/frame_time': 2.0,
      });
      expect(merged.benchmarkScoreKeys, <String>['a_perf/frame_time', 'b_perf/frame_time']);
      expect(merged.detailFiles, <String>['a.trace']);
    });

    test('rejects a failed result', () {
      expect(
        () => TaskResult.merge(<String, TaskResult>{'a_perf': TaskResult.failure('boom')}),
        throwsArgumentError,
      );
    });
  });
}
