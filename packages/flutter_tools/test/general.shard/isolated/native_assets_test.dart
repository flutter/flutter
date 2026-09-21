// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
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
import 'package:flutter_tools/src/isolated/native_assets/test/native_assets.dart';
import 'package:package_config/package_config_types.dart';
import 'package:test/fake.dart';

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

  group('findRunPackageName', () {
    testWithoutContext('prefers direct root URI match over manifestAppName', () {
      final FileSystem fs = MemoryFileSystem.test();
      final Uri projectUri = Uri.parse('file:///my_app/');
      final packageConfig = PackageConfig(<Package>[
        Package('aaa_first_dep', Uri.parse('file:///pub_cache/aaa_first_dep/')),
        Package('direct_pkg', projectUri),
        Package('manifest_pkg', Uri.parse('file:///other_dir/')),
      ]);

      expect(
        findRunPackageName(
          fileSystem: fs,
          manifestAppName: 'manifest_pkg',
          packageConfig: packageConfig,
          projectUri: projectUri,
        ),
        'direct_pkg',
      );
    });

    testWithoutContext('matches package root via canonicalized path when URIs differ', () {
      final FileSystem fs = MemoryFileSystem.test();
      final Directory realDir = fs.directory('/real_dir')..createSync(recursive: true);
      final Link symlink = fs.link('/symlink_dir')..createSync('/real_dir');
      final Directory symlinkDir = fs.directory(symlink.path);

      final packageConfig = PackageConfig(<Package>[
        Package('aaa_first_dep', Uri.parse('file:///pub_cache/aaa_first_dep/')),
        Package('symlink_pkg', realDir.uri),
        Package('manifest_pkg', Uri.parse('file:///manifest_dir/')),
      ]);

      expect(
        findRunPackageName(
          fileSystem: fs,
          manifestAppName: 'manifest_pkg',
          packageConfig: packageConfig,
          projectUri: symlinkDir.uri,
        ),
        'symlink_pkg',
      );
    });

    testWithoutContext('falls back to manifestAppName rather than first package in packageConfig '
        'when no package root matches projectUri', () {
      final FileSystem fs = MemoryFileSystem.test();
      final Uri projectUri = Uri.parse('file:///unmatched_app/');
      final packageConfig = PackageConfig(<Package>[
        Package('_fe_analyzer_shared', Uri.parse('file:///pub_cache/_fe_analyzer_shared/')),
        Package('args', Uri.parse('file:///pub_cache/args/')),
      ]);

      expect(
        findRunPackageName(
          fileSystem: fs,
          manifestAppName: 'my_app',
          packageConfig: packageConfig,
          projectUri: projectUri,
        ),
        'my_app',
      );
    });

    testWithoutContext('falls back to manifestAppName when packageConfig is empty', () {
      final FileSystem fs = MemoryFileSystem.test();
      expect(
        findRunPackageName(
          fileSystem: fs,
          manifestAppName: 'standalone_app',
          packageConfig: PackageConfig.empty,
          projectUri: Uri.parse('file:///standalone_app/'),
        ),
        'standalone_app',
      );
    });

    testWithoutContext(
      'returns null when no package root matches and manifestAppName is empty',
      () {
        final FileSystem fs = MemoryFileSystem.test();
        final packageConfig = PackageConfig(<Package>[
          Package('args', Uri.parse('file:///pub_cache/args/')),
        ]);

        expect(
          findRunPackageName(
            fileSystem: fs,
            manifestAppName: '',
            packageConfig: packageConfig,
            projectUri: Uri.parse('file:///empty_app/'),
          ),
          isNull,
        );
      },
    );

    testWithoutContext(
      'catches FileSystemException during symlink resolution and falls back cleanly',
      () {
        final FileSystem fs = _ThrowingResolveLinksFileSystem(MemoryFileSystem.test());
        final packageConfig = PackageConfig(<Package>[
          Package('other_pkg', Uri.parse('file:///other_dir/')),
        ]);

        expect(
          findRunPackageName(
            fileSystem: fs,
            manifestAppName: 'fallback_app',
            packageConfig: packageConfig,
            projectUri: Uri.parse('file:///broken_dir/'),
          ),
          'fallback_app',
        );
      },
    );
  });

  group('testCompilerBuildNativeAssets', () {
    testUsingContext(
      'falls back to manifest appName when package root does not match projectUri '
      '(regression test for https://github.com/flutter/flutter/issues/192933)',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
      () async {
        final Directory projectDir = fileSystem.directory('/my_app')..createSync(recursive: true);
        fileSystem.currentDirectory = projectDir;
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: '>=3.2.0 <4.0.0'
''');

        final File packageConfigFile = writePackageConfigFiles(
          directory: projectDir,
          mainLibName: 'other_pkg',
          mainLibRootUri: '../other_dir',
          packages: <String, String>{'my_app': '../different_dir'},
        );
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          packageConfigFile,
          logger: logger,
        );

        final buildInfo = BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          packageConfigPath: packageConfigFile.path,
          packageConfig: packageConfig,
        );

        final fakeRunner = FakeFlutterNativeAssetsBuildRunner();
        final Uri? result = await testCompilerBuildNativeAssets(buildInfo, buildRunner: fakeRunner);
        expect(result, isNotNull);
        expect(fileSystem.file(result).existsSync(), isTrue);
      },
    );

    testUsingContext(
      'logs warning and returns null gracefully when no package can be resolved',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
      () async {
        final Directory projectDir = fileSystem.directory('/empty_app')
          ..createSync(recursive: true);
        fileSystem.currentDirectory = projectDir;
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
environment:
  sdk: '>=3.2.0 <4.0.0'
''');

        final File packageConfigFile = projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion": 2, "packages": []}');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          packageConfigFile,
          logger: logger,
        );

        final buildInfo = BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          packageConfigPath: packageConfigFile.path,
          packageConfig: packageConfig,
        );

        final fakeRunner = FakeFlutterNativeAssetsBuildRunner();
        final Uri? result = await testCompilerBuildNativeAssets(buildInfo, buildRunner: fakeRunner);
        expect(result, isNull);
        expect(
          logger.warningText,
          contains('Could not determine run package name for native assets testing'),
        );
      },
    );
  });
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

class _ThrowingResolveLinksFileSystem extends ForwardingFileSystem {
  _ThrowingResolveLinksFileSystem(super.delegate);

  @override
  Directory directory(Object? path) => _ThrowingResolveLinksDirectory();
}

class _ThrowingResolveLinksDirectory extends Fake implements Directory {
  @override
  bool existsSync() => true;

  @override
  String resolveSymbolicLinksSync() {
    throw const FileSystemException('Cyclic link');
  }
}
