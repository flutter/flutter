// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(dacoharkes): Remove this tag once the xcrun clang --version state doesn't leak.
@Tags(<String>['no-shuffle'])
library;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/native_assets.dart';
import 'package:flutter_tools/src/native_assets.dart';
import 'package:native_assets_cli/native_assets_cli.dart'
    hide BuildMode, Target;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;
import 'package:package_config/package_config_types.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

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

  testUsingContext('dry run with no package config',
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
      }, () async {
    expect(
      await dryRunNativeAssetsiOS(
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
    ProcessManager: () => FakeProcessManager.any(),
  }, () async {
    await buildNativeAssetsiOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      environmentType: EnvironmentType.simulator,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      writeYamlFileTo: environment.buildDir.uri,
      buildRunner: FakeNativeAssetsBuildRunner(
        hasPackageConfigResult: false,
      ),
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });


  testUsingContext('dry run with assets but not enabled',
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
      }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => dryRunNativeAssetsiOS(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
        ),
      ),
      throwsToolExit(
        message:
            'Package(s) bar require the native assets feature to be enabled. '
            'Enable using `flutter config --enable-native-assets`.',
      ),
    );
  });

  testUsingContext('dry run with assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.any(),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    final Uri? nativeAssetsYaml = await dryRunNativeAssetsiOS(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
        dryRunResult: <Asset>[
          Asset(
            name: 'package:bar/bar.dart',
            linkMode: LinkMode.dynamic,
            target: native_assets_cli.Target.macOSArm64,
            path: AssetAbsolutePath(Uri.file('bar.dylib')),
          ),
          Asset(
            name: 'package:bar/bar.dart',
            linkMode: LinkMode.dynamic,
            target: native_assets_cli.Target.macOSX64,
            path: AssetAbsolutePath(Uri.file('bar.dylib')),
          ),
        ],
      ),
    );
    expect(
      nativeAssetsYaml,
      projectUri.resolve('build/native_assets/ios/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      contains('package:bar/bar.dart'),
    );
  });

  testUsingContext('build with assets but not enabled', () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsiOS(
        darwinArchs: <DarwinArch>[DarwinArch.arm64],
        environmentType: EnvironmentType.simulator,
        projectUri: projectUri,
        buildMode: BuildMode.debug,
        fileSystem: fileSystem,
        writeYamlFileTo: environment.buildDir.uri,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
        ),
      ),
      throwsToolExit(
        message:
            'Package(s) bar require the native assets feature to be enabled. '
            'Enable using `flutter config --enable-native-assets`.',
      ),
    );
  });

  testUsingContext('build no assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.list(
          <FakeCommand>[
            const FakeCommand(
              command: <Pattern>['xcrun', 'clang', '--version'],
              stdout: '''
Apple clang version 14.0.0 (clang-1400.0.29.202)
Target: arm64-apple-darwin22.6.0
Thread model: posix
InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin''',
            )
          ],
        ),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    await buildNativeAssetsiOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      environmentType: EnvironmentType.simulator,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      writeYamlFileTo: environment.buildDir.uri,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
        buildResult: <Asset>[],
      ),
    );
  });

  testUsingContext('build with assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.any(),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    await buildNativeAssetsiOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      environmentType: EnvironmentType.simulator,
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      writeYamlFileTo: environment.buildDir.uri,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
        buildResult: <Asset>[
          Asset(
            name: 'package:bar/bar.dart',
            linkMode: LinkMode.dynamic,
            target: native_assets_cli.Target.macOSArm64,
            path: AssetAbsolutePath(Uri.file('bar.dylib')),
          ),
        ],
      ),
    );
  });
}
