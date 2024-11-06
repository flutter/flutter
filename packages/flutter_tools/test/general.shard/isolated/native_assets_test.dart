// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:native_assets_cli/code_assets_builder.dart' hide BuildMode;
import 'package:package_config/package_config_types.dart';

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

  testUsingContext('dry run with no package config', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    expect(
      await runFlutterSpecificDartDryRunOnPlatforms(
        projectUri: projectUri,
        fileSystem: fileSystem,
        targetPlatforms: <TargetPlatform>[TargetPlatform.windows_x64],
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
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
    final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
    await runFlutterSpecificDartBuild(
      environmentDefines: <String, String>{
        kBuildMode: BuildMode.debug.cliName,
      },
      targetPlatform: TargetPlatform.windows_x64,
      projectUri: projectUri,
      nativeAssetsYamlUri: nonFlutterTesterAssetUri,
      fileSystem: fileSystem,
      buildRunner: FakeFlutterNativeAssetsBuildRunner(
        hasPackageConfigResult: false,
      ),
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('dry run for multiple OSes with no package config', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    await runFlutterSpecificDartDryRunOnPlatforms(
      projectUri: projectUri,
      fileSystem: fileSystem,
      targetPlatforms: <TargetPlatform>[
        TargetPlatform.windows_x64,
        TargetPlatform.darwin,
        TargetPlatform.ios,
      ],
      buildRunner: FakeFlutterNativeAssetsBuildRunner(
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
      () => runFlutterSpecificDartDryRunOnPlatforms(
        projectUri: projectUri,
        fileSystem: fileSystem,
        targetPlatforms: <TargetPlatform>[TargetPlatform.windows_x64],
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
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
    final FakeFlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <Package>[
        Package('bar', projectUri),
      ],
      buildDryRunResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
        codeAssets: <CodeAsset>[
          CodeAsset(
            package: 'bar',
            name: 'bar.dart',
            linkMode: DynamicLoadingBundled(),
            os: OS.windows,
            file: Uri.file('bar.dll'),
          ),
        ],
      ),
    );
    final Uri? nativeAssetsYaml = await runFlutterSpecificDartDryRunOnPlatforms(
      projectUri: projectUri,
      fileSystem: fileSystem,
      targetPlatforms: <TargetPlatform>[TargetPlatform.windows_x64],
      buildRunner: buildRunner,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      stringContainsInOrder(<String>[
        'Dry running native assets for windows.',
        'Dry running native assets for windows done.',
      ]),
    );
    expect(
      nativeAssetsYaml,
      projectUri.resolve('build/native_assets/windows/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      contains('package:bar/bar.dart'),
    );
    expect(buildRunner.buildDryRunInvocations, 1);
  });

  testUsingContext('build with assets but not enabled', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => runFlutterSpecificDartBuild(
        environmentDefines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
        },
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        nativeAssetsYamlUri: nonFlutterTesterAssetUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
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
    final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.yaml').uri;
    await packageConfig.parent.create();
    await packageConfig.create();
    final (_, Uri nativeAssetsYaml) = await runFlutterSpecificDartBuild(
      environmentDefines: <String, String>{
        kBuildMode: BuildMode.debug.cliName,
      },
      targetPlatform: TargetPlatform.windows_x64,
      projectUri: projectUri,
      nativeAssetsYamlUri: nonFlutterTesterAssetUri,
      fileSystem: fileSystem,
      buildRunner: FakeFlutterNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
      ),
    );
    expect(nativeAssetsYaml, nonFlutterTesterAssetUri);
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      isNot(contains('package:bar/bar.dart')),
    );
    expect(
      environment.projectDir.childDirectory('build').childDirectory('native_assets').childDirectory('windows'),
      exists,
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
    expect(
      () => runFlutterSpecificDartDryRunOnPlatforms(
        projectUri: projectUri,
        fileSystem: fileSystem,
        targetPlatforms: <TargetPlatform>[TargetPlatform.windows_x64],
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          buildDryRunResult: null,
        ),
      ),
      throwsToolExit(
        message:
            'Building (dry run) native assets failed. See the logs for more details.',
      ),
    );
  });

  testUsingContext('Native assets build error', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
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
        },
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        nativeAssetsYamlUri: nonFlutterTesterAssetUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          buildResult: null,
        ),
      ),
      throwsToolExit(
        message:
            'Building native assets failed. See the logs for more details.',
      ),
    );
  });
}
