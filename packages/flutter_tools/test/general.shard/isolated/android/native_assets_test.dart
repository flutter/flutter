// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart';
import 'package:package_config/package_config_types.dart';

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

  for (final BuildMode buildMode in <BuildMode>[
    BuildMode.debug,
    BuildMode.release,
  ]) {
    testUsingContext('build with assets $buildMode',
        skip: const LocalPlatform().isWindows, // [intended] Backslashes in commands, but we will never run these commands on Windows.
        overrides: <Type, Generator>{
          FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
          ProcessManager: () => FakeProcessManager.empty(),
        }, () async {
      final File packageConfig =
          environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
      await packageConfig.parent.create();
      await packageConfig.create();
      final File dylibAfterCompiling = fileSystem.file('libbar.so');
      // The mock doesn't create the file, so create it here.
      await dylibAfterCompiling.create();
      final FakeFlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
        buildResult: FakeFlutterNativeAssetsBuilderResult(
          assets: <AssetImpl>[
            NativeCodeAssetImpl(
              id: 'package:bar/bar.dart',
              linkMode: DynamicLoadingBundledImpl(),
              os: OSImpl.android,
              architecture: ArchitectureImpl.arm64,
              file: Uri.file('libbar.so'),
            ),
          ],
        ),
      );
      await runFlutterSpecificDartBuild(
        environmentDefines: <String, String>{
          kBuildMode: buildMode.cliName,
          kMinSdkVersion: minSdkVersion,
        },
        targetPlatform: TargetPlatform.android_arm64,
        projectUri: projectUri,
        nativeAssetsYamlUri: nonFlutterTesterAssetUri,
        fileSystem: fileSystem,
        buildRunner: buildRunner,
      );
      expect(
        (globals.logger as BufferLogger).traceText,
        stringContainsInOrder(<String>[
          'Building native assets for android_arm64 $buildMode.',
          'Building native assets for android_arm64 $buildMode done.',
        ]),
      );

      expect(
        environment.buildDir.childFile('native_assets.yaml'),
        exists,
      );
      expect(buildRunner.buildInvocations, 1);
      expect(
        buildRunner.linkInvocations,
        buildMode == BuildMode.release ? 1 : 0,
      );
    });
  }

  // Ensure no exceptions for a non installed NDK are thrown if no native
  // assets have to be build.
  testUsingContext(
      'does not throw if NDK not present but no native assets present',
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
        ProcessManager: () => FakeProcessManager.empty(),
      }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
    await packageConfig.create(recursive: true);
    await runFlutterSpecificDartBuild(
      environmentDefines: <String, String>{
        kBuildMode: BuildMode.debug.cliName,
        kMinSdkVersion: minSdkVersion,
      },
      targetPlatform: TargetPlatform.android_x64,
      nativeAssetsYamlUri: nonFlutterTesterAssetUri,
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: _BuildRunnerWithoutNdk(),
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      isNot(contains('Building native assets for ')),
    );
  });

  testUsingContext('throw if NDK not present and there are native assets',
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
      }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => runFlutterSpecificDartBuild(
        environmentDefines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
          kMinSdkVersion: minSdkVersion,
        },
        targetPlatform: TargetPlatform.android_arm64,
        projectUri: projectUri,
        nativeAssetsYamlUri: nonFlutterTesterAssetUri,
        fileSystem: fileSystem,
        buildRunner: _BuildRunnerWithoutNdk(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
        ),
      ),
      throwsToolExit(
        message: 'Android NDK Clang could not be found.',
      ),
    );
  });

}

class _BuildRunnerWithoutNdk extends FakeFlutterNativeAssetsBuildRunner {
  _BuildRunnerWithoutNdk({
    super.packagesWithNativeAssetsResult = const <Package>[],
  });

  @override
  Future<CCompilerConfigImpl> get ndkCCompilerConfigImpl async =>
      throwToolExit('Android NDK Clang could not be found.');
}
