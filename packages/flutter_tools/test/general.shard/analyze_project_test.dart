// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/analyze_project.dart';

import '../src/common.dart';

void main() {
  group('ProjectValidatorResult', () {
    late ProjectValidatorResult result;

    setUp(() {
      result = ProjectValidatorResult('name');
    });

    testWithoutContext('fail toString', () {
      expect(
        () => result.toString(),
        throwsToolExit(message: 'ProjectValidatorResult status not ready')
      );
      expect(result.currentStatus(), Status.notReady);
    });

    testWithoutContext('success status', () {
      result.setSuccess('value');
      expect(result.toString(), 'name: value');
      expect(result.currentStatus(), Status.success);
    });

    testWithoutContext('success status with warning', () {
      result.setSuccess('value', warning: 'my warning');
      expect(result.toString(), 'name: value. Warning: my warning');
      expect(result.currentStatus(), Status.success);
    });

    testWithoutContext('error status', () {
      result.setError('my error');
      expect(result.toString(), 'Error: my error');
      expect(result.currentStatus(), Status.error);
    });
  });
}
