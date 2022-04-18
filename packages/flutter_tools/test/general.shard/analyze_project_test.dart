// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/analyze_project.dart';
import 'package:flutter_tools/src/analyze_project_validator.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';

class ProjectValidatorTaskImpl extends ProjectValidatorTask {

  @override
  List<ProjectValidatorResult> start(FlutterProject project) {
    final ProjectValidatorResult error = ProjectValidatorResult('result_1');
    error.setError('this is an error');
    final ProjectValidatorResult success = ProjectValidatorResult('result_2');
    success.setSuccess('correct');
    final ProjectValidatorResult warning = ProjectValidatorResult('result_3');
    warning.setSuccess('this passed', warning: 'with a warning');

    return [
      error,
      success,
      warning,
    ];
  }

  @override
  List<SupportedPlatform> get supportedPlatforms {
    return [
      SupportedPlatform.ios,
      SupportedPlatform.android,
    ];
  }
}

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

  group('ProjectValidatorTask', () {
    late ProjectValidatorTaskImpl task;

    setUp(() {
      task = ProjectValidatorTaskImpl();
    });

    testWithoutContext('error status', () {
      MemoryFileSystem fs = MemoryFileSystem.test();
      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      final List<ProjectValidatorResult> results = task.start(project);
      expect(results.length, 3);
      expect(results[0].toString(), 'Error: this is an error');
      expect(results[1].toString(), 'result_2: correct');
      expect(results[2].toString(), 'result_3: this passed. Warning: with a warning');
    });
  });
}
