// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/android/native_assets.dart';
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

  testUsingContext('dry run with no package config', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    expect(
      await dryRunNativeAssetsAndroid(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeNativeAssetsBuildRunner(
          hasPackageConfigResult: false,
        ),
      ),
      null,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('build with no package config', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    await buildNativeAssetsAndroid(
      androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
      targetAndroidNdkApi: 21,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      yamlParentDirectory: environment.buildDir.uri,
      buildRunner: FakeNativeAssetsBuildRunner(
        hasPackageConfigResult: false,
      ),
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('dry run with assets but not enabled', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => dryRunNativeAssetsAndroid(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
        ),
      ),
      throwsToolExit(
        message: 'Package(s) bar require the native assets feature to be enabled. '
            'Enable using `flutter config --enable-native-assets`.',
      ),
    );
  });

  testUsingContext('dry run with assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <Package>[
        Package('bar', projectUri),
      ],
      buildDryRunResult: FakeNativeAssetsBuilderResult(
        assets: <AssetImpl>[
          NativeCodeAssetImpl(
            id: 'package:bar/bar.dart',
            linkMode: DynamicLoadingBundledImpl(),
            os: OSImpl.macOS,
            architecture: ArchitectureImpl.arm64,
            file: Uri.file('libbar.so'),
          ),
          NativeCodeAssetImpl(
            id: 'package:bar/bar.dart',
            linkMode: DynamicLoadingBundledImpl(),
            os: OSImpl.macOS,
            architecture: ArchitectureImpl.x64,
            file: Uri.file('libbar.so'),
          ),
        ],
      ),
    );
    final Uri? nativeAssetsYaml = await dryRunNativeAssetsAndroid(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      stringContainsInOrder(<String>[
        'Dry running native assets for android.',
        'Dry running native assets for android done.',
      ]),
    );
    expect(
      nativeAssetsYaml,
      projectUri.resolve('build/native_assets/android/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      contains('package:bar/bar.dart'),
    );
    expect(buildRunner.buildDryRunInvocations, 1);
    expect(buildRunner.linkDryRunInvocations, 1);
  });

  testUsingContext('build with assets but not enabled', () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsAndroid(
        androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
        targetAndroidNdkApi: 21,
        projectUri: projectUri,
        buildMode: BuildMode.debug,
        fileSystem: fileSystem,
        yamlParentDirectory: environment.buildDir.uri,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
        ),
      ),
      throwsToolExit(
        message: 'Package(s) bar require the native assets feature to be enabled. '
            'Enable using `flutter config --enable-native-assets`.',
      ),
    );
  });

  testUsingContext('build no assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    await buildNativeAssetsAndroid(
      androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
      targetAndroidNdkApi: 21,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      yamlParentDirectory: environment.buildDir.uri,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
      ),
    );
    expect(
      environment.buildDir.childFile('native_assets.yaml'),
      exists,
    );
  });

  testUsingContext('build with assets',
      skip: const LocalPlatform().isWindows, // [intended] Backslashes in commands, but we will never run these commands on Windows.
      overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    final File dylibAfterCompiling = fileSystem.file('libbar.so');
    // The mock doesn't create the file, so create it here.
    await dylibAfterCompiling.create();
    final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <Package>[
        Package('bar', projectUri),
      ],
      buildResult: FakeNativeAssetsBuilderResult(
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
    await buildNativeAssetsAndroid(
      androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
      targetAndroidNdkApi: 21,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      yamlParentDirectory: environment.buildDir.uri,
      buildRunner: buildRunner,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      stringContainsInOrder(<String>[
        'Building native assets for [android_arm64] debug.',
        'Building native assets for [android_arm64] done.',
      ]),
    );
    expect(
      environment.buildDir.childFile('native_assets.yaml'),
      exists,
    );
    expect(buildRunner.buildInvocations, 1);
    expect(buildRunner.linkInvocations, 1);
  });

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
    await packageConfig.create(recursive: true);
    await buildNativeAssetsAndroid(
      androidArchs: <AndroidArch>[AndroidArch.x86_64],
      targetAndroidNdkApi: 21,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
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
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsAndroid(
        androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
        targetAndroidNdkApi: 21,
        projectUri: projectUri,
        buildMode: BuildMode.debug,
        fileSystem: fileSystem,
        yamlParentDirectory: environment.buildDir.uri,
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

  testUsingContext('Native assets dry run error', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    for (final String hook in <String>['Building', 'Linking']) {
      expect(
        () => dryRunNativeAssetsAndroid(
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <Package>[
              Package('bar', projectUri),
            ],
            buildDryRunResult: FakeNativeAssetsBuilderResult(
              success: hook != 'Building',
            ),
            linkDryRunResult: FakeNativeAssetsBuilderResult(
              success: hook != 'Linking',
            ),
          ),
        ),
        throwsToolExit(
          message:
              '$hook (dry run) native assets failed. See the logs for more details.',
        ),
      );
    }
  });

  testUsingContext('Native assets build error', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    for (final String hook in <String>['Building', 'Linking']) {
      expect(
        () => buildNativeAssetsAndroid(
          androidArchs: <AndroidArch>[AndroidArch.arm64_v8a],
          targetAndroidNdkApi: 21,
          projectUri: projectUri,
          buildMode: BuildMode.debug,
          fileSystem: fileSystem,
          yamlParentDirectory: environment.buildDir.uri,
          buildRunner: FakeNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <Package>[
              Package('bar', projectUri),
            ],
            buildResult: FakeNativeAssetsBuilderResult(
              success: hook != 'Building',
            ),
            linkResult: FakeNativeAssetsBuilderResult(
              success: hook != 'Linking',
            ),
          ),
        ),
        throwsToolExit(
          message:
              '$hook native assets failed. See the logs for more details.',
        ),
      );
    }
  });
}

class _BuildRunnerWithoutNdk extends FakeNativeAssetsBuildRunner {
  _BuildRunnerWithoutNdk({
    super.packagesWithNativeAssetsResult = const <Package>[],
  });

  @override
  Future<CCompilerConfigImpl> get ndkCCompilerConfigImpl async =>
      throwToolExit('Android NDK Clang could not be found.');
}
