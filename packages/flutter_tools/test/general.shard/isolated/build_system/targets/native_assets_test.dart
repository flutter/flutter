// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    as native_assets_cli;
import 'package:package_config/package_config.dart' show Package;

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../../../../src/fakes.dart';
import '../../fake_native_assets_build_runner.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment iosEnvironment;
  late Environment androidEnvironment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late Logger logger;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    iosEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
        kIosArchs: 'arm64',
        kSdkRoot: 'path/to/iPhoneOS.sdk',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    androidEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android),
        kAndroidArchs: AndroidArch.arm64_v8a.platformName,
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    iosEnvironment.buildDir.createSync(recursive: true);
    androidEnvironment.buildDir.createSync(recursive: true);
  });

  testWithoutContext('NativeAssets throws error if missing target platform', () async {
    iosEnvironment.defines.remove(kTargetPlatform);
    expect(const NativeAssets().build(iosEnvironment), throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('NativeAssets defaults to ios archs if missing', () async {
    await createPackageConfig(iosEnvironment);

    iosEnvironment.defines.remove(kIosArchs);

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
    await NativeAssets(buildRunner: buildRunner).build(iosEnvironment);

    final File nativeAssetsYaml =
        iosEnvironment.buildDir.childFile('native_assets.yaml');

    final File depsFile = iosEnvironment.buildDir.childFile('native_assets.d');
    expect(depsFile, exists);
    expect(nativeAssetsYaml, exists);
  });

  testUsingContext('NativeAssets throws error if missing sdk root', overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
  },  () async {
    await createPackageConfig(iosEnvironment);

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <Package>[
        Package('foo', iosEnvironment.projectDir.uri),
      ]);

    iosEnvironment.defines.remove(kSdkRoot);
    expect(NativeAssets(buildRunner: buildRunner).build(iosEnvironment), throwsA(isA<MissingDefineException>()));
  });

  // The NativeAssets Target should _always_ be creating a yaml an d file.
  // The caching logic depends on this.
  for (final bool isNativeAssetsEnabled in <bool>[true, false]) {
    final String postFix = isNativeAssetsEnabled ? 'enabled' : 'disabled';
    testUsingContext(
      'Successful native_assets.yaml and native_assets.d creation with feature $postFix',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        FeatureFlags: () => TestFeatureFlags(
          isNativeAssetsEnabled: isNativeAssetsEnabled,
        ),
      },
      () async {
        await createPackageConfig(iosEnvironment);

        final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
        await NativeAssets(buildRunner: buildRunner).build(iosEnvironment);

        expect(iosEnvironment.buildDir.childFile('native_assets.d'), exists);
        expect(iosEnvironment.buildDir.childFile('native_assets.yaml'), exists);
      },
    );
  }

  testUsingContext(
    'NativeAssets with an asset',
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(
        <FakeCommand>[
          // Create the framework dylib.
          const FakeCommand(
            command: <Pattern>[
              'lipo',
              '-create',
              '-output',
              '/build/native_assets/ios/foo.framework/foo',
              'foo.framework/foo',
            ],
          ),
          // Lookup the original install names of the dylib.
          // There can be different install names for different architectures.
          FakeCommand(
            command: const <Pattern>[
              'otool',
              '-D',
              '/build/native_assets/ios/foo.framework/foo',
            ],
            stdout: <String>[
              '/build/native_assets/ios/foo.framework/foo (architecture x86_64):',
              '@rpath/libfoo.dylib',
              '/build/native_assets/ios/foo.framework/foo (architecture arm64):',
              '@rpath/libfoo.dylib',
            ].join('\n'),
          ),
          // Change the instal name of the binary itself and of its dependencies.
          // We pass the old to new install name mappings of all native assets dylibs,
          // even for the dylib that is being updated, since the `-change` option
          // is ignored if the dylib does not depend on the target dylib.
          const FakeCommand(
            command: <Pattern>[
              'install_name_tool',
              '-id',
              '@rpath/foo.framework/foo',
              '-change',
              '@rpath/libfoo.dylib',
              '@rpath/foo.framework/foo',
              '/build/native_assets/ios/foo.framework/foo',
            ],
          ),
          // Only after all changes to the dylib have been made do we sign it.
          const FakeCommand(
            command: <Pattern>[
              'codesign',
              '--force',
              '--sign',
              '-',
              '--timestamp=none',
              '/build/native_assets/ios/foo.framework',
            ],
          ),
        ],
      ),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
    },
    () async {
      await createPackageConfig(iosEnvironment);

      final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[Package('foo', iosEnvironment.buildDir.uri)],
        buildResult: FakeFlutterNativeAssetsBuilderResult(
          assets: <native_assets_cli.AssetImpl>[
            native_assets_cli.NativeCodeAssetImpl(
              id: 'package:foo/foo.dart',
              linkMode: native_assets_cli.DynamicLoadingBundledImpl(),
              os: native_assets_cli.OSImpl.iOS,
              architecture: native_assets_cli.ArchitectureImpl.arm64,
              file: Uri.file('foo.framework/foo'),
            ),
          ],
          dependencies: <Uri>[
            Uri.file('src/foo.c'),
          ],
        ),
      );
      await NativeAssets(buildRunner: buildRunner).build(iosEnvironment);

      final File nativeAssetsYaml = iosEnvironment.buildDir.childFile('native_assets.yaml');
      final File depsFile = iosEnvironment.buildDir.childFile('native_assets.d');
      expect(depsFile, exists);
      // We don't care about the specific format, but it should contain the
      // yaml as the file depending on the source files that went in to the
      // build.
      expect(
        depsFile.readAsStringSync(),
        stringContainsInOrder(<String>[
          nativeAssetsYaml.path,
          ':',
          'src/foo.c',
        ]),
      );
      expect(nativeAssetsYaml, exists);
      // We don't care about the specific format, but it should contain the
      // asset id and the path to the dylib.
      expect(
        nativeAssetsYaml.readAsStringSync(),
        stringContainsInOrder(<String>[
          'package:foo/foo.dart',
          'foo.framework',
        ]),
      );
    },
  );

  for (final bool hasAssets in <bool>[true, false]) {
    final String withOrWithout = hasAssets ? 'with' : 'without';
    testUsingContext(
      'flutter build $withOrWithout native assets',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        FeatureFlags: () => TestFeatureFlags(
              isNativeAssetsEnabled: true,
            ),
      },
      () async {
        await createPackageConfig(androidEnvironment);
        await fileSystem.file('libfoo.so').create();

        final FakeFlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('foo', androidEnvironment.buildDir.uri)
          ],
          buildResult: FakeFlutterNativeAssetsBuilderResult(
            assets: <native_assets_cli.AssetImpl>[
              if (hasAssets)
                native_assets_cli.NativeCodeAssetImpl(
                  id: 'package:foo/foo.dart',
                  linkMode: native_assets_cli.DynamicLoadingBundledImpl(),
                  os: native_assets_cli.OSImpl.android,
                  architecture: native_assets_cli.ArchitectureImpl.arm64,
                  file: Uri.file('libfoo.so'),
                ),
            ],
            dependencies: <Uri>[
              Uri.file('src/foo.c'),
            ],
          ),
        );
        await NativeAssets(buildRunner: buildRunner).build(androidEnvironment);
        expect(
          buildRunner.lastBuildMode,
          native_assets_cli.BuildModeImpl.release,
        );
      },
    );
  }
}

Future<void> createPackageConfig(Environment iosEnvironment) async {
  final File packageConfig = iosEnvironment.projectDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  await packageConfig.parent.create();
  await packageConfig.create();
}
