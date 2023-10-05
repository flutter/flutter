// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/native_assets.dart';
import 'package:flutter_tools/src/windows/native_assets.dart';
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
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
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
      await dryRunNativeAssetsWindows(
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
    await buildNativeAssetsWindows(
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
        TargetPlatform.windows_x64,
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
      () => dryRunNativeAssetsWindows(
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
    final Uri? nativeAssetsYaml = await dryRunNativeAssetsWindows(
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
              target: native_assets_cli.Target.windowsX64,
              path: AssetAbsolutePath(Uri.file('bar.dll')),
            ),
          ],
        ),
      ),
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
  });

  testUsingContext('build with assets but not enabled', overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.empty(),
  }, () async {
    final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    expect(
      () => buildNativeAssetsWindows(
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
    final (Uri? nativeAssetsYaml, _) = await buildNativeAssetsWindows(
      targetPlatform: TargetPlatform.windows_x64,
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
      projectUri.resolve('build/native_assets/windows/native_assets.yaml'),
    );
    expect(
      await fileSystem.file(nativeAssetsYaml).readAsString(),
      isNot(contains('package:bar/bar.dart')),
    );
    expect(
      environment.projectDir.childDirectory('build').childDirectory('native_assets').childDirectory('windows'),
      exists,
    );
  });

  for (final bool flutterTester in <bool>[false, true]) {
    String testName = '';
    if (flutterTester) {
      testName += ' flutter tester';
    }
    testUsingContext('build with assets$testName', overrides: <Type, Generator>{
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
      ProcessManager: () => FakeProcessManager.empty(),
    }, () async {
      final File packageConfig = environment.projectDir.childDirectory('.dart_tool').childFile('package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      final File dylibAfterCompiling = fileSystem.file('bar.dll');
      // The mock doesn't create the file, so create it here.
      await dylibAfterCompiling.create();
      final (Uri? nativeAssetsYaml, _) = await buildNativeAssetsWindows(
        targetPlatform: TargetPlatform.windows_x64,
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
                target: native_assets_cli.Target.windowsX64,
                path: AssetAbsolutePath(dylibAfterCompiling.uri),
              ),
            ],
          ),
        ),
      );
      expect(
        (globals.logger as BufferLogger).traceText,
        stringContainsInOrder(<String>[
          'Building native assets for windows_x64 debug.',
          'Building native assets for windows_x64 done.',
        ]),
      );
      expect(
        nativeAssetsYaml,
        projectUri.resolve('build/native_assets/windows/native_assets.yaml'),
      );
      expect(
        await fileSystem.file(nativeAssetsYaml).readAsString(),
        stringContainsInOrder(<String>[
          'package:bar/bar.dart',
          if (flutterTester)
            // Tests run on host system, so the have the full path on the system.
            '- ${projectUri.resolve('build/native_assets/windows/bar.dll').toFilePath()}'
          else
            // Apps are a bundle with the dylibs on their dlopen path.
            '- bar.dll',
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
      () => dryRunNativeAssetsWindows(
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
                target: native_assets_cli.Target.windowsX64,
                path: AssetAbsolutePath(Uri.file(OS.windows.staticlibFileName('bar'))),
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
            FakeCommand(
              command: <Pattern>[
                RegExp(r'(.*)vswhere.exe'),
                '-format',
                'json',
                '-products',
                '*',
                '-utf8',
                '-latest',
                '-version',
                '16',
                '-requires',
                'Microsoft.VisualStudio.Workload.NativeDesktop',
                'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
                'Microsoft.VisualStudio.Component.VC.CMake.Project',
              ],
              stdout: r'''
[
  {
    "instanceId": "491ec752",
    "installDate": "2023-04-21T08:17:11Z",
    "installationName": "VisualStudio/17.5.4+33530.505",
    "installationPath": "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community",
    "installationVersion": "17.5.33530.505",
    "productId": "Microsoft.VisualStudio.Product.Community",
    "productPath": "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\Common7\\IDE\\devenv.exe",
    "state": 4294967295,
    "isComplete": true,
    "isLaunchable": true,
    "isPrerelease": false,
    "isRebootRequired": false,
    "displayName": "Visual Studio Community 2022",
    "description": "Powerful IDE, free for students, open-source contributors, and individuals",
    "channelId": "VisualStudio.17.Release",
    "channelUri": "https://aka.ms/vs/17/release/channel",
    "enginePath": "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\resources\\app\\ServiceHub\\Services\\Microsoft.VisualStudio.Setup.Service",
    "installedChannelId": "VisualStudio.17.Release",
    "installedChannelUri": "https://aka.ms/vs/17/release/channel",
    "releaseNotes": "https://docs.microsoft.com/en-us/visualstudio/releases/2022/release-notes-v17.5#17.5.4",
    "thirdPartyNotices": "https://go.microsoft.com/fwlink/?LinkId=661288",
    "updateDate": "2023-04-21T08:17:11.2249473Z",
    "catalog": {
      "buildBranch": "d17.5",
      "buildVersion": "17.5.33530.505",
      "id": "VisualStudio/17.5.4+33530.505",
      "localBuild": "build-lab",
      "manifestName": "VisualStudio",
      "manifestType": "installer",
      "productDisplayVersion": "17.5.4",
      "productLine": "Dev17",
      "productLineVersion": "2022",
      "productMilestone": "RTW",
      "productMilestoneIsPreRelease": "False",
      "productName": "Visual Studio",
      "productPatchVersion": "4",
      "productPreReleaseMilestoneSuffix": "1.0",
      "productSemanticVersion": "17.5.4+33530.505",
      "requiredEngineVersion": "3.5.2150.18781"
    },
    "properties": {
      "campaignId": "2060:abb99c5d1ecc4013acf2e1814b10b690",
      "channelManifestId": "VisualStudio.17.Release/17.5.4+33530.505",
      "nickname": "",
      "setupEngineFilePath": "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\setup.exe"
    }
  }
]
''', // Newline at the end of the string.
            )
          ],
        ),
    FileSystem: () => fileSystem,
  }, () async {
    if (!const LocalPlatform().isWindows) {
      return;
    }

    final Directory msvcBinDir =
        fileSystem.directory(r'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.35.32215\bin\Hostx64\x64');
    await msvcBinDir.create(recursive: true);

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
    expect(result.cc?.toFilePath(), msvcBinDir.childFile('cl.exe').uri.toFilePath());
    expect(result.ar?.toFilePath(), msvcBinDir.childFile('lib.exe').uri.toFilePath());
    expect(result.ld?.toFilePath(), msvcBinDir.childFile('link.exe').uri.toFilePath());
    expect(result.envScript, isNotNull);
    expect(result.envScriptArgs, isNotNull);
  });
}
