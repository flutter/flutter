// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/native_assets.dart';
import 'package:flutter_tools/src/native_assets.dart';
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode, Target;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;
import 'package:package_config/package_config_types.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
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
      await dryRunNativeAssetsMacOS(
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
    await buildNativeAssetsMacOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      buildRunner: FakeNativeAssetsBuildRunner(
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
    await dryRunNativeAssetsMultipeOSes(
      projectUri: projectUri,
      fileSystem: fileSystem,
      targetPlatforms: <TargetPlatform>[
        TargetPlatform.darwin,
        TargetPlatform.ios,
      ],
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
      () => dryRunNativeAssetsMacOS(
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
    final Uri? nativeAssetsYaml = await dryRunNativeAssetsMacOS(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
        dryRunResult: FakeNativeAssetsBuilderResult(
          assets: <Asset>[
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSArm64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSX64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
          ],
        ),
      ),
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      stringContainsInOrder(<String>[
        'Dry running native assets for macos.',
        'Dry running native assets for macos done.',
      ]),
    );
    expect(
      nativeAssetsYaml,
      projectUri.resolve('build/native_assets/macos/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      contains('package:bar/bar.dart'),
    );
  });

  testUsingContext('build with assets but not enabled', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsMacOS(
        darwinArchs: <DarwinArch>[DarwinArch.arm64],
        projectUri: projectUri,
        buildMode: BuildMode.debug,
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

  testUsingContext('build no assets', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    final (Uri? nativeAssetsYaml, _) = await buildNativeAssetsMacOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      projectUri: projectUri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
      buildRunner: FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', projectUri),
        ],
      ),
    );
    expect(
      nativeAssetsYaml,
      projectUri.resolve('build/native_assets/macos/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      isNot(contains('package:bar/bar.dart')),
    );
  });

  for (final bool flutterTester in <bool>[false, true]) {
    String testName = '';
    if (flutterTester) {
      testName += ' flutter tester';
    }
    testUsingContext('build with assets$testName', overrides: <Type, Generator>{
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
      ProcessManager: () => FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <Pattern>[
              'lipo',
              '-create',
              '-output',
              '/build/native_assets/macos/bar.dylib',
              'bar.dylib',
            ],
          ),
          const FakeCommand(
            command: <Pattern>[
              'install_name_tool',
              '-id',
              '@executable_path/Frameworks/bar.dylib',
              '/build/native_assets/macos/bar.dylib',
            ],
          ),
          const FakeCommand(
            command: <Pattern>[
              'codesign',
              '--force',
              '--sign',
              '-',
              '--timestamp=none',
              '/build/native_assets/macos/bar.dylib',
            ],
          ),
        ],
      ),
    }, () async {
      if (const LocalPlatform().isWindows) {
        return; // Backslashes in commands, but we will never run these commands on Windows.
      }
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      final (Uri? nativeAssetsYaml, _) = await buildNativeAssetsMacOS(
        darwinArchs: <DarwinArch>[DarwinArch.arm64],
        projectUri: projectUri,
        buildMode: BuildMode.debug,
        fileSystem: fileSystem,
        flutterTester: flutterTester,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          buildResult: FakeNativeAssetsBuilderResult(
            assets: <Asset>[
              Asset(
                id: 'package:bar/bar.dart',
                linkMode: LinkMode.dynamic,
                target: native_assets_cli.Target.macOSArm64,
                path: AssetAbsolutePath(Uri.file('bar.dylib')),
              ),
            ],
          ),
        ),
      );
      expect(
        (globals.logger as BufferLogger).traceText,
        stringContainsInOrder(<String>[
          'Building native assets for [macos_arm64] debug.',
          'Building native assets for [macos_arm64] done.',
        ]),
      );
      expect(
        nativeAssetsYaml,
        projectUri.resolve('build/native_assets/macos/native_assets.yaml'),
      );
      expect(
        await fileSystem.file(nativeAssetsYaml).readAsString(),
        stringContainsInOrder(<String>[
          'package:bar/bar.dart',
          if (flutterTester)
            // Tests run on host system, so the have the full path on the system.
            '- ${projectUri.resolve('build/native_assets/macos/bar.dylib').toFilePath()}'
          else
            // Apps are a bundle with the dylibs on their dlopen path.
            '- bar.dylib',
        ]),
      );
    });
  }

  testUsingContext('static libs not supported', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => dryRunNativeAssetsMacOS(
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          dryRunResult: FakeNativeAssetsBuilderResult(
            assets: <Asset>[
              Asset(
                id: 'package:bar/bar.dart',
                linkMode: LinkMode.static,
                target: native_assets_cli.Target.macOSArm64,
                path: AssetAbsolutePath(Uri.file('bar.a')),
              ),
              Asset(
                id: 'package:bar/bar.dart',
                linkMode: LinkMode.static,
                target: native_assets_cli.Target.macOSX64,
                path: AssetAbsolutePath(Uri.file('bar.a')),
              ),
            ],
          ),
        ),
      ),
      throwsToolExit(
        message: 'Native asset(s) package:bar/bar.dart have their link mode set to '
            'static, but this is not yet supported. '
            'For more info see https://github.com/dart-lang/sdk/issues/49418.',
      ),
    );
  });

  // This logic is mocked in the other tests to avoid having test order
  // randomization causing issues with what processes are invoked.
  // Exercise the parsing of the process output in this separate test.
  testUsingContext('NativeAssetsBuildRunnerImpl.cCompilerConfig', overrides: <Type, Generator>{
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
    if (!const LocalPlatform().isMacOS) {
      return;
    }

    final File packagesFile = fileSystem
        .directory(projectUri)
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    await packagesFile.parent.create();
    await packagesFile.create();
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packagesFile,
      logger: environment.logger,
    );
    final NativeAssetsBuildRunner runner = NativeAssetsBuildRunnerImpl(
      projectUri,
      packageConfig,
      fileSystem,
      logger,
    );
    final CCompilerConfig result = await runner.cCompilerConfig;
    expect(
      result.cc,
      Uri.file(
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang',
      ),
    );
  });
}
