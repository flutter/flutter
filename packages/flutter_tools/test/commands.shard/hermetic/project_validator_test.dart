// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/validate_project.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';
import 'package:flutter_tools/src/project_validator_result.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

class ProjectValidatorDummy extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async{
    return <ProjectValidatorResult>[
      const ProjectValidatorResult(name: 'pass', value: 'value', status: StatusProjectValidator.success),
      const ProjectValidatorResult(name: 'fail', value: 'my error', status: StatusProjectValidator.error),
      const ProjectValidatorResult(name: 'pass two', value: 'pass', warning: 'my warning', status: StatusProjectValidator.warning),
    ];
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }
}

class ProjectValidatorCrash extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async{
    throw Exception('my exception');
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }
}

void main() {
  final BufferLogger loggerTest = BufferLogger.test();
  FileSystem fileSystem;

  group('analyze project command', () {
    setUpAll(() {
      fileSystem = MemoryFileSystem.test();
    });
    testUsingContext('success, error and warning', () async {
      final ValidateProjectCommand command = ValidateProjectCommand(
          fileSystem: fileSystem,
          logger: loggerTest,
          allProjectValidators: [ProjectValidatorDummy()]
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['validate-project']);

      const String expected = '\n'
          '┌──────────────────────────────────────────┐\n'
          '│ [✓] pass: value                          │\n'
          '│ [✗] Error: my error                      │\n'
          '│ [!] pass two: pass (warning: my warning) │\n'
          '│                                          │\n'
          '└──────────────────────────────────────────┘\n''';

      expect(loggerTest.statusText, contains(expected));
    });

    testUsingContext('crash', () async {

      final ValidateProjectCommand command = ValidateProjectCommand(
          fileSystem: fileSystem,
          logger: loggerTest,
          allProjectValidators: [ProjectValidatorCrash()]
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['validate-project']);

      const String expected = '[☠] Exception: my exception: #0      ProjectValidatorCrash.start';

      expect(loggerTest.statusText, contains(expected));
    });
  });
}
