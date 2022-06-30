// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';
import 'package:flutter_tools/src/project_validator_result.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  late FileSystem fileSystem;

  group('PubDependenciesProjectValidator', () {

    setUp(() {
      fileSystem = globals.localFileSystem;
    });

    testWithoutContext('success ', () async {
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
      const String expected = 'All dependencies are hosted';
      expect(result.length, 1);
      expect(result[0].value, expected);
      expect(result[0].status, StatusProjectValidator.success);
    });

    testWithoutContext('error ', () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['dart', 'pub', 'deps', '--json'],
          stdout: 'stdout command fail',
        ),
      ]);
      final PubDependenciesProjectValidator validator = PubDependenciesProjectValidator(processManager);

      final List<ProjectValidatorResult> result = await validator.start(
          FlutterProject.fromDirectoryTest(fileSystem.currentDirectory)
      );
      const String expected = 'stdout command fail';
      expect(result.length, 1);
      expect(result[0].value, expected);
      expect(result[0].status, StatusProjectValidator.error);
    });

    testWithoutContext('warning ', () async {
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
      expect(result[0].status, StatusProjectValidator.warning);
    });
  });
}
