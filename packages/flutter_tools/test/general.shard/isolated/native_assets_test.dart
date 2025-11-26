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
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
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
      );
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
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
      );
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
      );
      expect(
        await fileSystem.file(nonFlutterTesterAssetUri).readAsString(),
        isNot(contains('package:bar/bar.dart')),
      );
      expect(
        environment.projectDir
            .childDirectory('build')
            .childDirectory('native_assets')
            .childDirectory('windows'),
        exists,
      );
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
      );
      expect(
        result.codeAssets.map((FlutterCodeAsset c) => c.codeAsset.file!.toString()).toList()
          ..sort(),
        <String>[directSoFile.uri.toString(), linkedSoFile.uri.toString()],
      );
    },
  );

  testUsingContext(
    'unit tests does not require compiler toolchain',
    overrides: <Type, Generator>{
      ProcessManager: () {
        const Platform platform = LocalPlatform();
        return FakeProcessManager.list([
          if (platform.isMacOS)
            for (final binary in <String>['clang', 'ar', 'ld'])
              FakeCommand(
                command: <Pattern>['xcrun', '--find', binary],
                exitCode: 1,
                stderr: 'not found',
              ),
          if (platform.isLinux)
            const FakeCommand(
              command: <Pattern>['which', 'clang++'],
              exitCode: 1,
              stderr: 'not found',
            ),
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
      );

      expect(target.didSetCCompilerConfig, isTrue);
    },
  );
}

class _SetCCompilerConfigTarget extends FakeFlutterNativeAssetsBuildRunner {
  _SetCCompilerConfigTarget({super.buildResult, super.packagesWithNativeAssetsResult});

  var didSetCCompilerConfig = false;

  @override
  Future<void> setCCompilerConfig(CodeAssetTarget target) async {
    await target.setCCompilerConfig();
    didSetCCompilerConfig = true;
  }
}
