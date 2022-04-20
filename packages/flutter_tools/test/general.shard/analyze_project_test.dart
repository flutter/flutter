// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/analyze_project.dart';
import 'package:flutter_tools/src/analyze_project_validator.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';

class ProjectValidatorTaskImpl extends ProjectValidator {

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final ProjectValidatorResult error = ProjectValidatorResult(
      'result_1',
      'this is an error',
      StatusProjectValidator.error,
    );

    final ProjectValidatorResult success = ProjectValidatorResult(
      'result_2',
      'correct',
      StatusProjectValidator.success,
    );

    final ProjectValidatorResult warning = ProjectValidatorResult(
      'result_3',
      'this passed',
      StatusProjectValidator.success,
      warning: 'with a warning'
    );

    return <ProjectValidatorResult>[error, success, warning];
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }
}

void main() {
  group('ProjectValidatorResult', () {

    testWithoutContext('success status', () {
      final ProjectValidatorResult result = ProjectValidatorResult(
        'name',
        'value',
        StatusProjectValidator.success,
      );
      expect(result.toString(), 'name: value');
      expect(result.status, StatusProjectValidator.success);
    });

    testWithoutContext('success status with warning', () {
      final ProjectValidatorResult result = ProjectValidatorResult(
        'name',
        'value',
        StatusProjectValidator.success,
        warning: 'my warning'
      );
      expect(result.toString(), 'name: value. Warning: my warning');
      expect(result.status, StatusProjectValidator.success);
    });

    testWithoutContext('error status', () {
      final ProjectValidatorResult result = ProjectValidatorResult(
        'name',
        'my error',
        StatusProjectValidator.error,
      );
      expect(result.toString(), 'Error: my error');
      expect(result.status, StatusProjectValidator.error);
    });
  });

  group('ProjectValidatorTask', () {
    late ProjectValidatorTaskImpl task;

    setUp(() {
      task = ProjectValidatorTaskImpl();
    });

    testWithoutContext('error status', () async {
      MemoryFileSystem fs = MemoryFileSystem.test();
      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      final List<ProjectValidatorResult> results = await task.start(project);
      expect(results.length, 3);
      expect(results[0].toString(), 'Error: this is an error');
      expect(results[1].toString(), 'result_2: correct');
      expect(results[2].toString(), 'result_3: this passed. Warning: with a warning');
    });
  });
}
