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
}
