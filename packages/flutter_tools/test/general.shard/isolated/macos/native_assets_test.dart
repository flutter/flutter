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
import 'package:flutter_tools/src/isolated/native_assets/macos/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide Target;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    as native_assets_cli;
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
    await dryRunNativeAssetsMultipleOSes(
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
            file: Uri.file('libbar.dylib'),
          ),
          NativeCodeAssetImpl(
            id: 'package:bar/bar.dart',
            linkMode: DynamicLoadingBundledImpl(),
            os: OSImpl.macOS,
            architecture: ArchitectureImpl.x64,
            file: Uri.file('libbar.dylib'),
          ),
        ],
      ),
    );
    final Uri? nativeAssetsYaml = await dryRunNativeAssetsMacOS(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
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
    final String nativeAssetsYamlContents =
        await fileSystem.file(nativeAssetsYaml).readAsString();
    expect(
      nativeAssetsYamlContents,
      contains('package:bar/bar.dart'),
    );
    expect(buildRunner.buildDryRunInvocations, 1);
    expect(buildRunner.linkDryRunInvocations, 0);
    // Check that the framework uri is identical for both archs.
    final String pathSeparator = const LocalPlatform().pathSeparator;
    expect(
      nativeAssetsYamlContents,
      stringContainsInOrder(
        <String>[
          'bar.framework${pathSeparator}bar',
          'bar.framework${pathSeparator}bar',
        ],
      ),
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
    final String dylibPathBar;
    final String signPathBar;
    final String dylibPathBuz;
    final String signPathBuz;

    if (flutterTester) {
      // Just the dylib.
      dylibPathBar = '/build/native_assets/macos/libbar.dylib';
      signPathBar = '/build/native_assets/macos/libbar.dylib';
      dylibPathBuz = '/build/native_assets/macos/libbuz.dylib';
      signPathBuz = '/build/native_assets/macos/libbuz.dylib';
    } else {
      // Packaged in framework.
      dylibPathBar = '/build/native_assets/macos/bar.framework/Versions/A/bar';
      signPathBar = '/build/native_assets/macos/bar.framework';
      dylibPathBuz = '/build/native_assets/macos/buz.framework/Versions/A/buz';
      signPathBuz = '/build/native_assets/macos/buz.framework';
    }
    for (final BuildMode buildMode in <BuildMode>[
      BuildMode.debug,
      BuildMode.release,
    ]) {
      testUsingContext('build with assets $buildMode$testName', overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
        ProcessManager: () => FakeProcessManager.list(
          <FakeCommand>[
            if (flutterTester) ...<FakeCommand>[
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBar,
                  'arm64/libbar.dylib',
                  'x64/libbar.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'otool',
                  '-D',
                  dylibPathBar,
                ],
                stdout: <String>[
                  '$dylibPathBar (architecture x86_64):',
                  '@rpath/libbar.dylib',
                  '$dylibPathBar (architecture arm64):',
                  '@rpath/libbar.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBuz,
                  'arm64/libbuz.dylib',
                  'x64/libbuz.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'otool',
                  '-D',
                  dylibPathBuz,
                ],
                stdout: <String>[
                  '$dylibPathBuz (architecture x86_64):',
                  '@rpath/libbuz.dylib',
                  '$dylibPathBuz (architecture arm64):',
                  '@rpath/libbuz.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  dylibPathBar,
                  '-change',
                  '@rpath/libbar.dylib',
                  dylibPathBar,
                  '-change',
                  '@rpath/libbuz.dylib',
                  dylibPathBuz,
                  dylibPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'codesign',
                  '--force',
                  '--sign',
                  '-',
                  if (buildMode == BuildMode.debug)
                    '--timestamp=none',
                  signPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  dylibPathBuz,
                  '-change',
                  '@rpath/libbar.dylib',
                 dylibPathBar,
                  '-change',
                  '@rpath/libbuz.dylib',
                  signPathBuz,
                  signPathBuz,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'codesign',
                  '--force',
                  '--sign',
                  '-',
                  if (buildMode == BuildMode.debug)
                    '--timestamp=none',
                  signPathBuz,
                ],
              ),
            ] else ...<FakeCommand>[
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBar,
                  'arm64/libbar.dylib',
                  'x64/libbar.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'otool',
                  '-D',
                  dylibPathBar,
                ],
                stdout: <String>[
                  '$dylibPathBar (architecture x86_64):',
                  '@rpath/libbar.dylib',
                  '$dylibPathBar (architecture arm64):',
                  '@rpath/libbar.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBuz,
                  'arm64/libbuz.dylib',
                  'x64/libbuz.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'otool',
                  '-D',
                  dylibPathBuz,
                ],
                stdout: <String>[
                  '$dylibPathBuz (architecture x86_64):',
                  '@rpath/libbuz.dylib',
                  '$dylibPathBuz (architecture arm64):',
                  '@rpath/libbuz.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbar.dylib',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbuz.dylib',
                  '@rpath/buz.framework/buz',
                  dylibPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  '@rpath/buz.framework/buz',
                  '-change',
                  '@rpath/libbar.dylib',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbuz.dylib',
                  '@rpath/buz.framework/buz',
                  dylibPathBuz,
                ],
              ),
            ],
          ],
        ),
      }, () async {
        if (const LocalPlatform().isWindows) {
          return; // Backslashes in commands, but we will never run these commands on Windows.
        }
        final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
        await packageConfig.parent.create();
        await packageConfig.create();
        final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          onBuild: (native_assets_cli.Target target) =>
              FakeNativeAssetsBuilderResult(
                assets: <AssetImpl>[
                  NativeCodeAssetImpl(
                    id: 'package:bar/bar.dart',
                    linkMode: DynamicLoadingBundledImpl(),
                    os: target.os,
                    architecture: target.architecture,
                    file: Uri.file('${target.architecture}/libbar.dylib'),
                  ),
                  NativeCodeAssetImpl(
                    id: 'package:buz/buz.dart',
                    linkMode: DynamicLoadingBundledImpl(),
                    os: target.os,
                    architecture: target.architecture,
                    file: Uri.file('${target.architecture}/libbuz.dylib'),
                  ),
                ],
              ),
        );
        final (Uri? nativeAssetsYaml, _) = await buildNativeAssetsMacOS(
          darwinArchs: <DarwinArch>[DarwinArch.arm64, DarwinArch.x86_64],
          projectUri: projectUri,
          buildMode: buildMode,
          fileSystem: fileSystem,
          flutterTester: flutterTester,
          buildRunner: buildRunner,
        );
        expect(
          (globals.logger as BufferLogger).traceText,
          stringContainsInOrder(<String>[
            'Building native assets for [macos_arm64, macos_x64] $buildMode.',
            'Building native assets for [macos_arm64, macos_x64] done.',
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
              '- ${projectUri.resolve('build/native_assets/macos/libbar.dylib').toFilePath()}'
            else
              // Apps are a bundle with the dylibs on their dlopen path.
              '- bar.framework/bar',
          ]),
        );
        expect(
          await fileSystem.file(nativeAssetsYaml).readAsString(),
          stringContainsInOrder(<String>[
            'package:buz/buz.dart',
            if (flutterTester)
              // Tests run on host system, so the have the full path on the system.
              '- ${projectUri.resolve('build/native_assets/macos/libbuz.dylib').toFilePath()}'
            else
              // Apps are a bundle with the dylibs on their dlopen path.
              '- buz.framework/buz',
          ]),
        );
        // Multi arch.
        expect(buildRunner.buildInvocations, 2);
        expect(
          buildRunner.linkInvocations,
          buildMode == BuildMode.release ? 2 : 0,
        );
      });
    }
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
          buildDryRunResult: FakeNativeAssetsBuilderResult(
            assets: <AssetImpl>[
              NativeCodeAssetImpl(
                id: 'package:bar/bar.dart',
                linkMode: StaticLinkingImpl(),
                os: OSImpl.macOS,
                architecture: ArchitectureImpl.arm64,
                file: Uri.file('bar.a'),
              ),
              NativeCodeAssetImpl(
                id: 'package:bar/bar.dart',
                linkMode: StaticLinkingImpl(),
                os: OSImpl.macOS,
                architecture: ArchitectureImpl.x64,
                file: Uri.file('bar.a'),
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



  testUsingContext('Native assets dry run error', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig =
        environment.projectDir.childFile('.dart_tool/package_config.json');
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
          buildDryRunResult: const FakeNativeAssetsBuilderResult(
            success: false,
          ),
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
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsMacOS(
        darwinArchs: <DarwinArch>[DarwinArch.arm64],
        projectUri: projectUri,
        buildMode: BuildMode.debug,
        fileSystem: fileSystem,
        yamlParentDirectory: environment.buildDir.uri,
        buildRunner: FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          buildResult: const FakeNativeAssetsBuilderResult(
            success: false,
          ),
        ),
      ),
      throwsToolExit(
        message:
            'Building native assets failed. See the logs for more details.',
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

    final File packageConfigFile = fileSystem
        .directory(projectUri)
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    await packageConfigFile.parent.create();
    await packageConfigFile.create();
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: environment.logger,
    );
    final NativeAssetsBuildRunner runner = NativeAssetsBuildRunnerImpl(
      projectUri,
      packageConfigFile.path,
      packageConfig,
      fileSystem,
      logger,
    );
    final CCompilerConfigImpl result = await runner.cCompilerConfig;
    expect(
      result.compiler,
      Uri.file(
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang',
      ),
    );
  });
}
