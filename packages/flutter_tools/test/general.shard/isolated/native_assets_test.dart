// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:code_assets/code_assets.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';
import 'package:hooks/hooks.dart';
import 'package:package_config/package_config_types.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import 'fake_native_assets_build_runner.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment environment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Uri projectUri;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
      projectDir: fileSystem.directory('/project'),
    );
    environment.buildDir.createSync(recursive: true);
    projectUri = environment.projectDir.uri;
  });

  testUsingContext(
    'Native assets: non-bundled libraries require no copying',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.json').uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, LinkMode linkMode, [Uri? file]) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      final environmentDefines = <String, String>{kBuildMode: BuildMode.release.cliName};
      final codeAssets = <CodeAsset>[
        makeCodeAsset('malloc', LookupInProcess()),
        makeCodeAsset('free', LookupInExecutable()),
        makeCodeAsset('draw', DynamicLoadingSystem(Uri.file('/usr/lib/skia.so'))),
      ];
      final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: projectUri.resolve('${getBuildDirectory()}/native_assets/test/'),
      );
      expect(testLogger.traceText, isNot(contains('Copying native assets to')));
    },
  );

  testUsingContext(
    'build with assets but not enabled',
    overrides: <Type, Generator>{
      // ignore: avoid_redundant_argument_values
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: false),
      ProcessManager: () => FakeProcessManager.empty(),
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          targetPlatform: TargetPlatform.windows_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Enable code assets using `flutter config --enable-native-assets`'),
      );
    },
  );

  testUsingContext(
    'build no assets',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir
          .childFile(InstallCodeAssets.nativeAssetsFilename)
          .uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final environmentDefines = <String, String>{kBuildMode: BuildMode.debug.cliName};
      final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      final Directory targetDirectory = environment.buildDir.childDirectory('native_assets');
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: targetDirectory.uri,
      );
      expect(
        await fileSystem.file(nonFlutterTesterAssetUri).readAsString(),
        isNot(contains('package:bar/bar.dart')),
      );
      expect(targetDirectory, exists);
    },
  );

  testUsingContext(
    'Native assets build error',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            buildResult: null,
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Building native assets failed. See the logs for more details.'),
      );
    },
  );

  testUsingContext(
    'Native assets: no duplicate assets with linking',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);
      final File linkableAFile = environment.projectDir.childFile('linkable.a');
      linkableAFile.writeAsBytesSync(<int>[]);
      final File linkedSoFile = environment.projectDir.childFile('linked.so');
      linkedSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, Uri file, LinkMode linkMode) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      final DartHooksResult result = await runFlutterSpecificHooks(
        environmentDefines: <String, String>{
          // Release mode means the dart build has linking enabled.
          kBuildMode: BuildMode.release.cliName,
        },
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
            ],
            codeAssetsForLinking: <String, List<CodeAsset>>{
              'package:bar': <CodeAsset>[
                makeCodeAsset('linkable', linkableAFile.uri, StaticLinking()),
              ],
            },
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              makeCodeAsset('linked', linkedSoFile.uri, DynamicLoadingBundled()),
            ],
          ),
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      expect(
        result.codeAssets.map((FlutterCodeAsset c) => c.codeAsset.file!.toString()).toList()
          ..sort(),
        <String>[directSoFile.uri.toString(), linkedSoFile.uri.toString()],
      );
    },
  );

  testUsingContext(
    'Native assets: unused code assets are tree-shaken during linking when not recorded as used',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir
          .childFile(InstallCodeAssets.nativeAssetsFilename)
          .uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final File unusedSoFile = environment.projectDir.childFile('unused.so');
      unusedSoFile.writeAsBytesSync(<int>[]);
      final File usedSoFile = environment.projectDir.childFile('used.so');
      usedSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, Uri file, LinkMode linkMode) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      final environmentDefines = <String, String>{kBuildMode: BuildMode.release.cliName};
      final DartHooksResult result = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssetsForLinking: <String, List<CodeAsset>>{
              'package:bar': <CodeAsset>[
                makeCodeAsset('unused', unusedSoFile.uri, DynamicLoadingBundled()),
                makeCodeAsset('used', usedSoFile.uri, DynamicLoadingBundled()),
              ],
            },
          ),
          // Link hook receives both assets, but tree-shakes 'unused' and only outputs 'used'.
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[makeCodeAsset('used', usedSoFile.uri, DynamicLoadingBundled())],
          ),
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );

      expect(
        result.codeAssets.map((FlutterCodeAsset c) => c.codeAsset.file!.toString()).toList(),
        <String>[usedSoFile.uri.toString()],
      );

      final List<File> installedFiles = await installCodeAssets(
        dartHookResult: result,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: projectUri.resolve('${getBuildDirectory()}/native_assets/linux/'),
      );

      // Verify installed files only contain native_assets.json and used.so, but not unused.so.
      expect(
        installedFiles.map(
          (File f) => f.path.split(RegExp(r'[/\\]')).lastWhere((String s) => s.isNotEmpty),
        ),
        unorderedEquals(<String>[InstallCodeAssets.nativeAssetsFilename, 'used.so']),
      );
      final File nativeAssetsJsonFile = fileSystem.file(nonFlutterTesterAssetUri);
      expect(nativeAssetsJsonFile, exists);
      final String jsonContent = nativeAssetsJsonFile.readAsStringSync();
      expect(jsonContent, contains('package:bar/used'));
      expect(jsonContent, isNot(contains('package:bar/unused')));
    },
  );

  testUsingContext(
    'Native assets: duplicate assets throws tool exit listing duplicate IDs',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, Uri file, LinkMode linkMode) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.release.cliName},
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
              codeAssets: <CodeAsset>[
                makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
                makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
              ],
            ),
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Found duplicates in the code assets: [package:bar/direct]'),
      );
    },
  );

  testUsingContext(
    'unit tests does not require compiler toolchain',
    overrides: <Type, Generator>{
      ProcessManager: () {
        const Platform platform = LocalPlatform();
        return FakeProcessManager.list([
          if (platform.isMacOS) ...[
            for (final binary in <String>['clang', 'ar', 'ld'])
              FakeCommand(
                command: <Pattern>['xcrun', '--find', binary],
                exitCode: 1,
                stderr: 'not found',
              ),
            for (final binary in <String>['clang', 'ar', 'ld'])
              FakeCommand(
                command: <Pattern>['xcrun', '--find', binary],
                exitCode: 1,
                stderr: 'not found',
              ),
          ],
          if (platform.isLinux) ...[
            const FakeCommand(
              command: <Pattern>['which', 'clang++'],
              exitCode: 1,
              stderr: 'not found',
            ),
            const FakeCommand(
              command: <Pattern>['which', 'clang++'],
              exitCode: 1,
              stderr: 'not found',
            ),
          ],
        ]);
      },
    },
    () async {
      // This calls setCCompilerConfig() on a test target, which must not throw despite the
      // toolchain not being available.
      const Platform platform = LocalPlatform();
      if (!platform.isLinux && !platform.isMacOS) {
        return false;
      }

      final target = _SetCCompilerConfigTarget(
        packagesWithNativeAssetsResult: <String>['bar'],
        buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
      );

      await runFlutterSpecificHooks(
        environmentDefines: {},
        targetPlatform: TargetPlatform.tester,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: target,
        buildCodeAssets: BuildCodeAssetsOptions(
          appBuildDirectory: fileSystem.directory(projectUri),
        ),
        buildDataAssets: true,
        recordedUsesFile: null,
      );

      expect(target.didSetCCompilerConfig, isTrue);
    },
  );

  testUsingContext(
    'linux build reads compilers from CMakeCache.txt',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      final target = _SetCCompilerConfigTarget(
        packagesWithNativeAssetsResult: <String>['bar'],
        buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
      );

      await fileSystem.directory('/usr/bin/').create(recursive: true);
      await fileSystem.file('/usr/bin/ld.ldd').create();
      await fileSystem.file('/usr/bin/llvm-ar').create();
      await fileSystem.file('/usr/bin/clang').create();
      await fileSystem.file('/usr/bin/clang++').create();

      final Directory project = fileSystem.directory(projectUri);
      await project.childDirectory('build/linux/arm64/release').create(recursive: true);
      await project.childFile('build/linux/arm64/release/CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=/usr/bin/clang++
CMAKE_AR:FILEPATH=/usr/bin/llvm-ar
CMAKE_LINKER:FILEPATH=/usr/bin/ld.ldd
''');

      await runFlutterSpecificHooks(
        environmentDefines: {kBuildMode: 'release'},
        targetPlatform: TargetPlatform.linux_arm64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: target,
        buildCodeAssets: BuildCodeAssetsOptions(appBuildDirectory: project.childDirectory('build')),
        buildDataAssets: false,
        recordedUsesFile: null,
      );

      expect(target.didSetCCompilerConfig, isTrue);
    },
  );

  testUsingContext(
    'installCodeAssets cleans up existing stale files in target directory without crashing '
    '(regression test for https://github.com/flutter/flutter/issues/190234)',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir
          .childFile(InstallCodeAssets.nativeAssetsFilename)
          .uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final environmentDefines = <String, String>{kBuildMode: BuildMode.debug.cliName};
      final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      final Directory targetDirectory = environment.buildDir.childDirectory('native_assets');
      await targetDirectory.create(recursive: true);
      final File staleFile = targetDirectory.childFile('stale.txt');
      staleFile.writeAsStringSync('stale');

      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: targetDirectory.uri,
      );
      expect(targetDirectory, exists);
      expect(staleFile, isNot(exists));
    },
  );

  testWithoutContext('FlutterNativeAssetsBuildRunnerImpl.build throws ToolExit on lock TimeoutException '
      '(regression test for https://github.com/flutter/flutter/issues/194568)', () async {
    final logger = BufferLogger.test();
    final lockTimeoutFileSystem = MemoryFileSystem.test(
      opHandle: (String context, FileSystemOp operation) {
        if (operation == FileSystemOp.exists && context.endsWith('build.dart')) {
          throw TimeoutException(
            'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock.',
            const Duration(minutes: 5),
          );
        }
      },
    );
    final Directory projectDir = lockTimeoutFileSystem.directory('/project')
      ..createSync(recursive: true);
    final File pubspecFile = projectDir.childFile('pubspec.yaml')
      ..writeAsStringSync('name: my_app\n');
    final File packageConfigFile = writePackageConfigFiles(
      directory: projectDir,
      mainLibName: 'my_app',
    );
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: logger,
    );
    final runner = FlutterNativeAssetsBuildRunnerImpl(
      packageConfigFile.path,
      packageConfig,
      lockTimeoutFileSystem,
      logger,
      FakePlatform(),
      'my_app',
      pubspecFile.path,
      includeDevDependencies: false,
    );

    await expectLater(
      runner.build(extensions: <ProtocolExtension>[], linkingEnabled: false),
      throwsToolExit(
        message:
            'Building native assets timed out waiting for a file lock: '
            'TimeoutException after 0:05:00.000000: '
            'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock.\n'
            'Ensure no other Flutter or Dart processes are stuck building native assets, '
            'or delete stale `.lock` files under `.dart_tool/hooks_runner/` and try again.',
      ),
    );
  });

  testWithoutContext('FlutterNativeAssetsBuildRunnerImpl.link throws ToolExit on lock TimeoutException '
      '(regression test for https://github.com/flutter/flutter/issues/194568)', () async {
    final logger = BufferLogger.test();
    final lockTimeoutFileSystem = MemoryFileSystem.test(
      opHandle: (String context, FileSystemOp operation) {
        if (operation == FileSystemOp.exists && context.endsWith('link.dart')) {
          throw TimeoutException(
            'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock.',
            const Duration(minutes: 5),
          );
        }
      },
    );
    final Directory projectDir = lockTimeoutFileSystem.directory('/project')
      ..createSync(recursive: true);
    final File pubspecFile = projectDir.childFile('pubspec.yaml')
      ..writeAsStringSync('name: my_app\n');
    final File packageConfigFile = writePackageConfigFiles(
      directory: projectDir,
      mainLibName: 'my_app',
    );
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: logger,
    );
    final runner = FlutterNativeAssetsBuildRunnerImpl(
      packageConfigFile.path,
      packageConfig,
      lockTimeoutFileSystem,
      logger,
      FakePlatform(),
      'my_app',
      pubspecFile.path,
      includeDevDependencies: false,
    );

    await expectLater(
      runner.link(
        extensions: <ProtocolExtension>[],
        buildResult: const FakeFlutterNativeAssetsBuilderResult(),
        recordedUsesFile: null,
      ),
      throwsToolExit(
        message:
            'Linking native assets timed out waiting for a file lock: '
            'TimeoutException after 0:05:00.000000: '
            'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock.\n'
            'Ensure no other Flutter or Dart processes are stuck building native assets, '
            'or delete stale `.lock` files under `.dart_tool/hooks_runner/` and try again.',
      ),
    );
  });

  testWithoutContext(
    'FlutterNativeAssetsBuildRunnerImpl.build throws ToolExit on FileSystemException '
    '(regression test for https://github.com/flutter/flutter/issues/194568)',
    () async {
      final logger = BufferLogger.test();
      final lockErrorFileSystem = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (operation == FileSystemOp.exists && context.endsWith('build.dart')) {
            throw const FileSystemException(
              'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock. '
                  'Move your project to a filesystem that supports file locking.',
              '/project/.dart_tool/hooks_runner/shared/my_app/.lock',
            );
          }
        },
      );
      final Directory projectDir = lockErrorFileSystem.directory('/project')
        ..createSync(recursive: true);
      final File pubspecFile = projectDir.childFile('pubspec.yaml')
        ..writeAsStringSync('name: my_app\n');
      final File packageConfigFile = writePackageConfigFiles(
        directory: projectDir,
        mainLibName: 'my_app',
      );
      final PackageConfig packageConfig = await loadPackageConfigWithLogging(
        packageConfigFile,
        logger: logger,
      );
      final runner = FlutterNativeAssetsBuildRunnerImpl(
        packageConfigFile.path,
        packageConfig,
        lockErrorFileSystem,
        logger,
        FakePlatform(),
        'my_app',
        pubspecFile.path,
        includeDevDependencies: false,
      );

      await expectLater(
        runner.build(extensions: <ProtocolExtension>[], linkingEnabled: false),
        throwsToolExit(
          message:
              'Failed to build native assets: '
              'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock. '
              'Move your project to a filesystem that supports file locking.',
        ),
      );
    },
  );

  testWithoutContext(
    'FlutterNativeAssetsBuildRunnerImpl.link throws ToolExit on FileSystemException '
    '(regression test for https://github.com/flutter/flutter/issues/194568)',
    () async {
      final logger = BufferLogger.test();
      final lockErrorFileSystem = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
          if (operation == FileSystemOp.exists && context.endsWith('link.dart')) {
            throw const FileSystemException(
              'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock. '
                  'Move your project to a filesystem that supports file locking.',
              '/project/.dart_tool/hooks_runner/shared/my_app/.lock',
            );
          }
        },
      );
      final Directory projectDir = lockErrorFileSystem.directory('/project')
        ..createSync(recursive: true);
      final File pubspecFile = projectDir.childFile('pubspec.yaml')
        ..writeAsStringSync('name: my_app\n');
      final File packageConfigFile = writePackageConfigFiles(
        directory: projectDir,
        mainLibName: 'my_app',
      );
      final PackageConfig packageConfig = await loadPackageConfigWithLogging(
        packageConfigFile,
        logger: logger,
      );
      final runner = FlutterNativeAssetsBuildRunnerImpl(
        packageConfigFile.path,
        packageConfig,
        lockErrorFileSystem,
        logger,
        FakePlatform(),
        'my_app',
        pubspecFile.path,
        includeDevDependencies: false,
      );

      await expectLater(
        runner.link(
          extensions: <ProtocolExtension>[],
          buildResult: const FakeFlutterNativeAssetsBuilderResult(),
          recordedUsesFile: null,
        ),
        throwsToolExit(
          message:
              'Failed to build native assets: '
              'Could not acquire the lock to /project/.dart_tool/hooks_runner/shared/my_app/.lock. '
              'Move your project to a filesystem that supports file locking.',
        ),
      );
    },
  );
}

class _SetCCompilerConfigTarget extends FakeFlutterNativeAssetsBuildRunner {
  _SetCCompilerConfigTarget({super.buildResult, super.packagesWithNativeAssetsResult});

  bool didSetCCompilerConfig = false;

  @override
  Future<void> setCCompilerConfig(CodeAssetTarget target) async {
    await target.setCCompilerConfig();
    didSetCCompilerConfig = true;
  }
}
