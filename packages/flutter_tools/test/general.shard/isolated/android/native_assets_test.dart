// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';
import '../fake_native_assets_build_runner.dart';

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

  for (final buildMode in <BuildMode>[BuildMode.debug, BuildMode.release]) {
    testUsingContext(
      'build with assets $buildMode',
      // [intended] Backslashes in commands, but we will never run these commands on Windows.
      skip: const LocalPlatform().isWindows,
      overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
      () async {
        final File packageConfig = environment.projectDir.childFile(
          '.dart_tool/package_config.json',
        );
        final Uri nonFlutterTesterAssetUri = environment.buildDir
            .childFile(InstallCodeAssets.nativeAssetsFilename)
            .uri;
        await packageConfig.parent.create();
        await packageConfig.create();
        final File dylibAfterCompiling = fileSystem.file('libbar.so');
        // The mock doesn't create the file, so create it here.
        await dylibAfterCompiling.create();

        final codeAssets = <CodeAsset>[
          CodeAsset(
            package: 'bar',
            name: 'bar.dart',
            linkMode: DynamicLoadingBundled(),
            file: Uri.file('libbar.so'),
          ),
        ];
        final buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
        );
        final environmentDefines = <String, String>{
          kBuildMode: buildMode.cliName,
          kMinSdkVersion: minSdkVersion,
        };
        final DartHooksResult result = await runFlutterSpecificHooks(
          environmentDefines: environmentDefines,
          targetPlatform: TargetPlatform.android_arm64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
        await installCodeAssets(
          dartHookResult: result,
          environmentDefines: environmentDefines,
          targetPlatform: TargetPlatform.android_arm64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          nativeAssetsFileUri: nonFlutterTesterAssetUri,
        );
        expect(
          (globals.logger as BufferLogger).traceText,
          stringContainsInOrder(<String>[
            'Building native assets for android_arm64.',
            'Building native assets for android_arm64 done.',
          ]),
        );

        expect(environment.buildDir.childFile('native_assets.json'), exists);
        expect(buildRunner.buildInvocations, 1);
        expect(buildRunner.linkInvocations, buildMode == BuildMode.release ? 1 : 0);
      },
    );
  }

  // Ensure no exceptions for a non installed NDK are thrown if no native
  // assets have to be build.
  testUsingContext(
    'does not throw if NDK not present but no native assets present',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.create(recursive: true);
      await runFlutterSpecificHooks(
        environmentDefines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
          kMinSdkVersion: minSdkVersion,
        },
        targetPlatform: TargetPlatform.android_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: _BuildRunnerWithoutNdk(),
      );
      expect(
        (globals.logger as BufferLogger).traceText,
        isNot(contains('Building native assets for ')),
      );
    },
  );

  testUsingContext(
    'throw if NDK not present and there are native assets',
    overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true)},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        await runFlutterSpecificHooks(
          environmentDefines: <String, String>{
            kBuildMode: BuildMode.debug.cliName,
            kMinSdkVersion: minSdkVersion,
          },
          targetPlatform: TargetPlatform.android_arm64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: _BuildRunnerWithoutNdk(packagesWithNativeAssetsResult: <String>['bar']),
        ),
        isA<DartHooksResult>(),
      );
    },
  );
}

class _BuildRunnerWithoutNdk extends FakeFlutterNativeAssetsBuildRunner {
  _BuildRunnerWithoutNdk({super.packagesWithNativeAssetsResult = const <String>[]});

  @override
  CCompilerConfig? get ndkCCompilerConfigResult => null;
}
