// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_bundle.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  Cache.disableLocking();
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

  testUsingContext('bundle getUsage indicate that project is a module', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect(await command.usageValues,
        containsPair(CustomDimensions.commandBuildBundleIsModule, 'true'));
  }, timeout: allowForCreateFlutterProject);

  testUsingContext('bundle getUsage indicate that project is not a module', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=app']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect(await command.usageValues,
        containsPair(CustomDimensions.commandBuildBundleIsModule, 'false'));
  }, timeout: allowForCreateFlutterProject);

  testUsingContext('bundle getUsage indicate the target platform', () async {
    final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=app']);

    final BuildBundleCommand command = await runCommandIn(projectPath);

    expect(await command.usageValues,
        containsPair(CustomDimensions.commandBuildBundleTargetPlatform, 'android-arm'));
  }, timeout: allowForCreateFlutterProject);

  testUsingContext('bundle fails to build for Windows if feature is disabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync(recursive: true);
    fs.file('.packages').createSync(recursive: true);
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=windows-x64',
    ]), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
  });

  testUsingContext('bundle fails to build for Linux if feature is disabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=linux-x64',
    ]), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  });

  testUsingContext('bundle fails to build for macOS if feature is disabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    expect(() => runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=darwin-x64',
    ]), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('bundle can build for Windows if feature is enabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=windows-x64',
    ]);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('bundle can build for Linux if feature is enabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=linux-x64',
    ]);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('bundle can build for macOS if feature is enabled', () async {
    fs.file('lib/main.dart').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final CommandRunner<void> runner = createTestCommandRunner(BuildBundleCommand()
        ..bundleBuilder = MockBundleBuilder());

    await runner.run(<String>[
      'bundle',
      '--no-pub',
      '--target-platform=darwin-x64',
    ]);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });
}

class MockBundleBuilder extends Mock implements BundleBuilder {}
