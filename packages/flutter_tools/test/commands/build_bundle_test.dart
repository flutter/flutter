// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  Cache.disableLocking();

  group('getUsage', () {
    Directory tempDir;
    MockBundleBuilder mockBundleBuilder;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');

      mockBundleBuilder = MockBundleBuilder();
      when(
        mockBundleBuilder.build(
          platform: anyNamed('platform'),
          buildMode: anyNamed('buildMode'),
          mainPath: anyNamed('mainPath'),
          manifestPath: anyNamed('manifestPath'),
          applicationKernelFilePath: anyNamed('applicationKernelFilePath'),
          depfilePath: anyNamed('depfilePath'),
          privateKeyPath: anyNamed('privateKeyPath'),
          assetDirPath: anyNamed('assetDirPath'),
          packagesPath: anyNamed('packagesPath'),
          precompiledSnapshot: anyNamed('precompiledSnapshot'),
          reportLicensedPackages: anyNamed('reportLicensedPackages'),
          trackWidgetCreation: anyNamed('trackWidgetCreation'),
          extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
          extraGenSnapshotOptions: anyNamed('extraGenSnapshotOptions'),
          fileSystemRoots: anyNamed('fileSystemRoots'),
          fileSystemScheme: anyNamed('fileSystemScheme'),
        ),
      ).thenAnswer((_) => Future<void>.value());
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    Future<BuildBundleCommand> runCommandIn(String projectPath, { List<String> arguments }) async {
      final BuildBundleCommand command = BuildBundleCommand(bundleBuilder: mockBundleBuilder);
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'bundle',
        ...?arguments,
        '--target=$projectPath/lib/main.dart',
      ]);
      return command;
    }

    testUsingContext('indicate that project is a module', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildBundleCommand command = await runCommandIn(projectPath);

      expect(await command.usageValues,
          containsPair(kCommandBuildBundleIsModule, 'true'));
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate that project is not a module', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildBundleCommand command = await runCommandIn(projectPath);

      expect(await command.usageValues,
          containsPair(kCommandBuildBundleIsModule, 'false'));
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate the target platform', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildBundleCommand command = await runCommandIn(projectPath);

      expect(await command.usageValues,
          containsPair(kCommandBuildBundleTargetPlatform, 'android-arm'));
    }, timeout: allowForCreateFlutterProject);
  });
}

class MockBundleBuilder extends Mock implements BundleBuilder {}
