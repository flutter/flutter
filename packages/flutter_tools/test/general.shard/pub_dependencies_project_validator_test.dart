// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';
import 'package:flutter_tools/src/project_validator_result.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  late FileSystem fileSystem;

  group('PubDependenciesProjectValidator', () {

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext('success when all dependencies are hosted', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['dart', 'pub', 'deps', '--json'],
          stdout: '{"packages": [{"dependencies": ["abc"], "source": "hosted"}]}',
        ),
      ]);
      final PubDependenciesProjectValidator validator = PubDependenciesProjectValidator(processManager);

      final List<ProjectValidatorResult> result = await validator.start(
        FlutterProject.fromDirectoryTest(fileSystem.currentDirectory)
      );
      const String expected = 'All pub dependencies are hosted on https://pub.dartlang.org';
      expect(result.length, 1);
      expect(result[0].value, expected);
      expect(result[0].status, StatusProjectValidator.info);
    });

    testWithoutContext('error when command dart pub deps fails', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['dart', 'pub', 'deps', '--json'],
          stderr: 'command fail',
        ),
      ]);
      final PubDependenciesProjectValidator validator = PubDependenciesProjectValidator(processManager);

      final List<ProjectValidatorResult> result = await validator.start(
          FlutterProject.fromDirectoryTest(fileSystem.currentDirectory)
      );
      const String expected = 'command fail';
      expect(result.length, 1);
      expect(result[0].value, expected);
      expect(result[0].status, StatusProjectValidator.error);
    });

    testWithoutContext('info on dependencies not hosted', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['dart', 'pub', 'deps', '--json'],
          stdout: '{"packages": [{"dependencies": ["dep1", "dep2"], "source": "other"}]}',
        ),
      ]);
      final PubDependenciesProjectValidator validator = PubDependenciesProjectValidator(processManager);

      final List<ProjectValidatorResult> result = await validator.start(
          FlutterProject.fromDirectoryTest(fileSystem.currentDirectory)
      );
      const String expected = 'dep1, dep2 are not hosted';
      expect(result.length, 1);
      expect(result[0].value, expected);
      expect(result[0].status, StatusProjectValidator.info);
    });
  });
}
