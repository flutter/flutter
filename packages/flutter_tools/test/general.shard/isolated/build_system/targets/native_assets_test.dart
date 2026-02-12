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
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../../../../src/fakes.dart';
import '../../../../src/package_config.dart';
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

  testWithoutContext('no dependency on KernelSnapshot', () async {
    const target = DartBuildForNative();
    expect(target.dependencies, isNot(isA<KernelSnapshot>()));
  });

  testWithoutContext('NativeAssets throws error if missing target platform', () async {
    iosEnvironment.defines.remove(kTargetPlatform);
    expect(
      const DartBuildForNative().build(iosEnvironment),
      throwsA(isA<MissingDefineException>()),
    );
  });

  testUsingContext('NativeAssets defaults to ios archs if missing', () async {
    writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

    iosEnvironment.defines.remove(kIosArchs);

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
    await DartBuildForNative(buildRunner: buildRunner).build(iosEnvironment);
    await const InstallCodeAssets().build(iosEnvironment);

    expect(iosEnvironment.buildDir.childFile(DartBuild.depFilename), exists);
    expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.depFilename), exists);
    expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.nativeAssetsFilename), exists);
  });

  testUsingContext(
    'NativeAssets throws error if missing sdk root',
    overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true)},
    () async {
      writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

      final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <String>['foo'],
      );

      iosEnvironment.defines.remove(kSdkRoot);
      expect(
        DartBuildForNative(buildRunner: buildRunner).build(iosEnvironment),
        throwsA(isA<MissingDefineException>()),
      );
    },
  );

  // The NativeAssets Target should _always_ be creating a yaml an d file.
  // The caching logic depends on this.
  for (final isNativeAssetsEnabled in <bool>[true, false]) {
    final postFix = isNativeAssetsEnabled ? 'enabled' : 'disabled';
    testUsingContext(
      'Successful native_assets.json and native_assets.d creation with feature $postFix',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: isNativeAssetsEnabled),
      },
      () async {
        writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

        final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
        await DartBuildForNative(buildRunner: buildRunner).build(iosEnvironment);
        await const InstallCodeAssets().build(iosEnvironment);

        expect(iosEnvironment.buildDir.childFile(DartBuild.depFilename), exists);
        expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.depFilename), exists);
        expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.nativeAssetsFilename), exists);
      },
    );
  }

  testUsingContext(
    'NativeAssets with an asset',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        // Create the framework dylib.
        FakeCommand(
          command: const <Pattern>[
            'xcrun',
            'lipo',
            '-create',
            '-output',
            '/native_assets/foo.framework/foo',
            'libfoo.dylib',
          ],
          onRun: (_) {
            iosEnvironment.fileSystem
                .file('/native_assets/foo.framework/foo')
                .createSync(recursive: true);
          },
        ),
        FakeCommand(
          command: const <Pattern>[
            'xcrun',
            'dsymutil',
            '/native_assets/foo.framework/foo',
            '-o',
            '/native_assets/foo.framework.dSYM',
          ],
          onRun: (_) {
            iosEnvironment.fileSystem
                .directory('/native_assets/foo.framework.dSYM')
                .createSync(recursive: true);
          },
        ),
        const FakeCommand(
          command: <Pattern>['xcrun', 'strip', '-x', '-S', '/native_assets/foo.framework/foo'],
        ),
        // Lookup the original install names of the dylib.
        // There can be different install names for different architectures.
        FakeCommand(
          command: const <Pattern>['xcrun', 'otool', '-D', '/native_assets/foo.framework/foo'],
          stdout: <String>[
            '/native_assets/foo.framework/foo (architecture x86_64):',
            '@rpath/libfoo.dylib',
            '/native_assets/foo.framework/foo (architecture arm64):',
            '@rpath/libfoo.dylib',
          ].join('\n'),
        ),
        // Change the install name of the binary itself and of its dependencies.
        // We pass the old to new install name mappings of all native assets dylibs,
        // even for the dylib that is being updated, since the `-change` option
        // is ignored if the dylib does not depend on the target dylib.
        const FakeCommand(
          command: <Pattern>[
            'xcrun',
            'install_name_tool',
            '-id',
            '@rpath/foo.framework/foo',
            '-change',
            '@rpath/libfoo.dylib',
            '@rpath/foo.framework/foo',
            '/native_assets/foo.framework/foo',
          ],
        ),
        // Only after all changes to the dylib have been made do we sign it.
        const FakeCommand(
          command: <Pattern>[
            'xcrun',
            'codesign',
            '--force',
            '--sign',
            '-',
            '--timestamp=none',
            '/native_assets/foo.framework',
          ],
        ),
      ]),
    },
    () async {
      writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

      final codeAssets = <CodeAsset>[
        CodeAsset(
          package: 'foo',
          name: 'foo.dart',
          linkMode: DynamicLoadingBundled(),
          file: Uri.file('libfoo.dylib'),
        ),
      ];
      final String libFooPath = iosEnvironment.fileSystem.file('libfoo.dylib').path;
      final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <String>['foo'],
        buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
          dependencies: <Uri>[Uri.file('src/foo.c')],
        ),
        onBuild: (input) {
          iosEnvironment.fileSystem.file(libFooPath).createSync(recursive: true);
          return FakeFlutterNativeAssetsBuilderResult.fromAssets(
            dependencies: <Uri>[Uri.file('src/foo.c')],
          );
        },
        linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
      );

      final File dartHookResultJsonFile = iosEnvironment.buildDir.childFile(
        DartBuild.dartHookResultFilename,
      );
      final dartBuildForNative = DartBuildForNative(buildRunner: buildRunner);
      await dartBuildForNative.build(iosEnvironment);
      const installCodeAssets = InstallCodeAssets();
      await installCodeAssets.build(iosEnvironment);

      // Verify DartBuildForNative dependencies.
      final List<String> buildInputs = _resolvedInputs(dartBuildForNative, iosEnvironment);
      final List<String> buildOutputs = _resolvedOutputs(dartBuildForNative, iosEnvironment);
      // Re-run if the C source changes.
      expect(buildInputs, contains(iosEnvironment.fileSystem.file('src/foo.c').path));
      // Re-created if the result JSON is deleted.
      expect(buildOutputs, contains(dartHookResultJsonFile.path));
      // Re-created if the dylib is deleted.
      expect(buildOutputs, contains(libFooPath));

      final File nativeAssetsYaml = iosEnvironment.buildDir.childFile(
        InstallCodeAssets.nativeAssetsFilename,
      );

      // Verify InstallCodeAssets dependencies.
      final List<String> installInputs = _resolvedInputs(installCodeAssets, iosEnvironment);
      final List<String> installOutputs = _resolvedOutputs(installCodeAssets, iosEnvironment);
      // Re-run if the dylib changes.
      expect(installInputs, contains(libFooPath));
      // Re-created if the final manifest is deleted.
      expect(installOutputs, contains(nativeAssetsYaml.path));
      // Re-created if deleted by Xcode "Product > Clean Build Folder...".
      expect(
        installOutputs,
        contains(
          iosEnvironment.outputDir
              .childDirectory('native_assets')
              .childFile('foo.framework/foo')
              .path,
        ),
      );

      expect(nativeAssetsYaml, exists);
    },
  );

  for (final hasAssets in <bool>[true, false]) {
    final withOrWithout = hasAssets ? 'with' : 'without';
    testUsingContext(
      'flutter build $withOrWithout native assets',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
      () async {
        writePackageConfigFiles(directory: androidEnvironment.projectDir, mainLibName: 'my_app');
        await fileSystem.file('libfoo.so').create();

        final codeAssets = <CodeAsset>[
          if (hasAssets)
            CodeAsset(
              package: 'foo',
              name: 'foo.dart',
              linkMode: DynamicLoadingBundled(),
              file: Uri.file('libfoo.so'),
            ),
        ];
        final buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['foo'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            dependencies: <Uri>[Uri.file('src/foo.c')],
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
        );
        await DartBuildForNative(buildRunner: buildRunner).build(androidEnvironment);
      },
    );
  }
}

List<String> _resolvedOutputs(Target target, Environment environment) {
  return target.resolveOutputs(environment).sources.map((File f) => f.path).toList();
}

List<String> _resolvedInputs(Target target, Environment environment) {
  return target.resolveInputs(environment).sources.map((File f) => f.path).toList();
}
