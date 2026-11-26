// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:data_assets/data_assets.dart';
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
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/web/compiler_config.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../../src/common.dart';
import '../../../../src/fake_process_manager.dart';
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
        kTargetPlatform: TargetPlatform.ios.getName(),
        kIosArchs: 'arm64',
        kSdkRoot: 'path/to/iPhoneOS.sdk',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(isNativeAssetsEnabled: true),
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    androidEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: TargetPlatform.android.getName(),
        kAndroidArchs: CpuArch.arm64.androidPlatformName,
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(isNativeAssetsEnabled: true),
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    iosEnvironment.buildDir.createSync(recursive: true);
    androidEnvironment.buildDir.createSync(recursive: true);
  });

  test('no dependency on KernelSnapshot', () async {
    const target = BuildHooks();
    expect(target.dependencies, isNot(isA<KernelSnapshot>()));
  });

  test('NativeAssets throws error if missing target platform', () async {
    iosEnvironment.defines.remove(kTargetPlatform);
    expect(const BuildHooks().build(iosEnvironment), throwsA(isA<MissingDefineException>()));
  });

  test('NativeAssets defaults to ios archs if missing', () async {
    writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

    iosEnvironment.defines.remove(kIosArchs);

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
    await BuildHooks(buildRunner: buildRunner).build(iosEnvironment);
    await const InstallCodeAssets().build(iosEnvironment);

    expect(iosEnvironment.buildDir.childFile(BuildHooks.depFilename), exists);
    expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.depFilename), exists);
    expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.nativeAssetsFilename), exists);
  });

  test('NativeAssets throws error if missing sdk root', () async {
    writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <String>['foo'],
    );

    final Environment env = iosEnvironment.copyWith(
      featureFlags: TestFeatureFlags(isNativeAssetsEnabled: true),
    );
    env.defines.remove(kSdkRoot);
    expect(BuildHooks(buildRunner: buildRunner).build(env), throwsA(isA<MissingDefineException>()));
  });

  test('NativeAssets throws error if sdk root is unrecognized iOS SDK', () async {
    writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

    final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
      packagesWithNativeAssetsResult: <String>['foo'],
    );

    final Environment env = iosEnvironment.copyWith(
      featureFlags: TestFeatureFlags(isNativeAssetsEnabled: true),
    );
    env.defines[kSdkRoot] = 'path/to/XROS1.0.sdk';
    expect(
      BuildHooks(buildRunner: buildRunner).build(env),
      throwsToolExit(
        message:
            'Unsupported iOS SDK root "path/to/XROS1.0.sdk". Expected an iPhoneOS or iPhoneSimulator SDK. '
            "Flutter only supports building the iOS Runner for iOS; check the target's Base SDK "
            '(SDKROOT) and Supported Destinations in Xcode.',
      ),
    );
  });

  // The NativeAssets Target should _always_ be creating a yaml an d file.
  // The caching logic depends on this.
  for (final isNativeAssetsEnabled in <bool>[true, false]) {
    final postFix = isNativeAssetsEnabled ? 'enabled' : 'disabled';
    test(
      'Successful native_assets.json and native_assets.d creation with feature $postFix',
      () async {
        writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

        final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner();
        final Environment env = iosEnvironment.copyWith(
          featureFlags: TestFeatureFlags(isNativeAssetsEnabled: isNativeAssetsEnabled),
        );
        await BuildHooks(buildRunner: buildRunner).build(env);
        await const InstallCodeAssets().build(env);

        expect(iosEnvironment.buildDir.childFile(BuildHooks.depFilename), exists);
        expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.depFilename), exists);
        expect(iosEnvironment.buildDir.childFile(InstallCodeAssets.nativeAssetsFilename), exists);
      },
    );
  }

  bool nativeAssetsLinkingEnabled(BuildMode buildMode) {
    switch (buildMode) {
      case BuildMode.debug:
        return false;
      case BuildMode.jitRelease:
      case BuildMode.profile:
      case BuildMode.release:
        return true;
    }
  }

  for (final buildMode in <BuildMode>[BuildMode.profile, BuildMode.debug]) {
    final bool linkingEnabled = nativeAssetsLinkingEnabled(buildMode);
    final testName = linkingEnabled ? 'enabled' : 'disabled';
    test(
      'NativeAssets depfile filtering avoids circular cycles in Xcode when link hooks are $testName',
      () async {
        writePackageConfigFiles(directory: iosEnvironment.projectDir, mainLibName: 'my_app');

        // Force environment to use specified build mode!
        iosEnvironment.defines[kBuildMode] = buildMode.cliName;

        final String sourceAssetPath = iosEnvironment.fileSystem
            .file('assets/translations/en.json')
            .path;
        iosEnvironment.fileSystem.file(sourceAssetPath).createSync(recursive: true);

        final FlutterNativeAssetsBuildRunner buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['foo'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            dependencies: <Uri>[Uri.file(sourceAssetPath)],
            dataAssets: <DataAsset>[
              DataAsset(file: Uri.file(sourceAssetPath), name: 'en.json', package: 'my_app'),
            ],
          ),
          linkResult: linkingEnabled
              ? FakeFlutterNativeAssetsBuilderResult.fromAssets(
                  dependencies: <Uri>[Uri.file(sourceAssetPath)],
                )
              : const FakeFlutterNativeAssetsBuilderResult(),
        );

        final Environment env = iosEnvironment.copyWith(
          featureFlags: TestFeatureFlags(
            isNativeAssetsEnabled: true,
            isDartDataAssetsEnabled: true,
          ),
        );
        final dartBuildForNative = BuildHooks(buildRunner: buildRunner);
        await dartBuildForNative.build(env);

        final dartLinkForNative = LinkHooks(buildRunner: buildRunner);
        await dartLinkForNative.build(env);

        final File depfileFile = iosEnvironment.buildDir.childFile(LinkHooks.depFilename);
        expect(depfileFile, exists);

        final String contents = depfileFile.readAsStringSync();
        final List<String> colonSeparated = contents.split(': ');
        expect(colonSeparated.length, 2);

        final List<String> linkOutputs = _resolvedOutputs(dartLinkForNative, iosEnvironment);
        // Verify that full source path resolved resolves to empty list after fix!
        expect(linkOutputs, isNot(contains(sourceAssetPath)));
      },
    );
  }

  test('NativeAssets with an asset', () async {
    processManager.addCommands(<FakeCommand>[
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
    ]);
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

    final File dartHookResultJsonFile = iosEnvironment.buildDir.childFile(LinkHooks.resultFilename);
    final Environment env = iosEnvironment.copyWith(
      featureFlags: TestFeatureFlags(isNativeAssetsEnabled: true),
    );
    final dartBuildForNative = BuildHooks(buildRunner: buildRunner);
    await dartBuildForNative.build(env);
    final dartLinkForNative = LinkHooks(buildRunner: buildRunner);
    await dartLinkForNative.build(env);
    const installCodeAssets = InstallCodeAssets();
    await installCodeAssets.build(env);

    // Verify BuildHooks dependencies.
    final List<String> buildInputs = _resolvedInputs(dartBuildForNative, env);
    final List<String> buildOutputs = _resolvedOutputs(dartBuildForNative, env);
    // Re-run if the C source changes.
    expect(buildInputs, contains(iosEnvironment.fileSystem.file('src/foo.c').path));
    // Re-created if the output JSON is deleted.
    expect(
      buildOutputs,
      contains(iosEnvironment.buildDir.childFile(BuildHooks.resultFilename).path),
    );

    // Verify LinkHooks dependencies.
    final List<String> linkOutputs = _resolvedOutputs(dartLinkForNative, env);
    // Re-created if the result JSON is deleted.
    expect(linkOutputs, contains(dartHookResultJsonFile.path));
    // Re-created if the dylib is deleted.
    expect(linkOutputs, contains(libFooPath));

    final File nativeAssetsYaml = iosEnvironment.buildDir.childFile(
      InstallCodeAssets.nativeAssetsFilename,
    );

    // Verify InstallCodeAssets dependencies.
    final List<String> installInputs = _resolvedInputs(installCodeAssets, env);
    final List<String> installOutputs = _resolvedOutputs(installCodeAssets, env);
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
    expect(processManager, hasNoRemainingExpectations);
  });

  for (final hasAssets in <bool>[true, false]) {
    final withOrWithout = hasAssets ? 'with' : 'without';
    test('flutter build $withOrWithout native assets', () async {
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
      await BuildHooks(buildRunner: buildRunner).build(androidEnvironment);
    });
  }

  test(
    'createFlutterNativeAssetsBuildRunner includes dev dependencies for release test targets',
    () async {
      writePackageConfigFiles(directory: androidEnvironment.projectDir, mainLibName: 'my_app');
      androidEnvironment.defines[kBuildMode] = BuildMode.release.cliName;

      androidEnvironment.defines[kTargetFile] = fileSystem.path.join('lib', 'main.dart');
      final FlutterNativeAssetsBuildRunner mainRunner = await createFlutterNativeAssetsBuildRunner(
        androidEnvironment,
      );
      expect((mainRunner as FlutterNativeAssetsBuildRunnerImpl).includeDevDependencies, isFalse);

      androidEnvironment.defines[kTargetFile] = fileSystem.path.join(
        'integration_test',
        'app_test.dart',
      );
      final FlutterNativeAssetsBuildRunner integrationTestRunner =
          await createFlutterNativeAssetsBuildRunner(androidEnvironment);
      expect(
        (integrationTestRunner as FlutterNativeAssetsBuildRunnerImpl).includeDevDependencies,
        isTrue,
      );

      androidEnvironment.defines[kTargetFile] = fileSystem.path.join('test_driver', 'app.dart');
      final FlutterNativeAssetsBuildRunner driverRunner =
          await createFlutterNativeAssetsBuildRunner(androidEnvironment);
      expect((driverRunner as FlutterNativeAssetsBuildRunnerImpl).includeDevDependencies, isTrue);

      androidEnvironment.defines[kTargetFile] = fileSystem.path.join('test', 'app_test.dart');
      final FlutterNativeAssetsBuildRunner testRunner = await createFlutterNativeAssetsBuildRunner(
        androidEnvironment,
      );
      expect((testRunner as FlutterNativeAssetsBuildRunnerImpl).includeDevDependencies, isTrue);
    },
  );

  test('Web LinkHooks tracks only active compileTargets recordedUsesFileNames and invalidates across compiler transitions', () async {
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    final webEnv = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{kBuildMode: BuildMode.release.cliName},
      artifacts: artifacts,
      featureFlags: TestFeatureFlags(isRecordUseEnabled: true),
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    webEnv.buildDir.createSync(recursive: true);
    final File wasmUses = webEnv.buildDir.childFile(LinkHooks.recordedUsesWasmFileName);
    final File jsUses = webEnv.buildDir.childFile(LinkHooks.recordedUsesJsFileName);

    expect(const LinkHooks().buildKey, isNull);

    // Required inputs are non-optional even before the compiler writes them.
    final LinkHooks wasmLinkHooks = WebReleaseBundle(
      const <WebCompilerConfig>[WasmCompilerConfig(), JsCompilerConfig()],
      const NoOpAnalytics(),
      engineRevision: 'rev',
    ).dependencies.whereType<LinkHooks>().single;
    expect(
      _resolvedInputs(wasmLinkHooks, webEnv),
      containsAll(<String>[wasmUses.path, jsUses.path]),
    );

    wasmUses.writeAsStringSync('{"wasm":true}');
    jsUses.writeAsStringSync('{"js":true}');
    expect(wasmLinkHooks.getRecordedUsesFile(webEnv, BuildMode.release)?.path, wasmUses.path);

    // Default JS build (dryRun: true) ignores stale recorded_uses_wasm.json.
    final LinkHooks dryRunLinkHooks = WebReleaseBundle(
      const <WebCompilerConfig>[JsCompilerConfig(), WasmCompilerConfig(dryRun: true)],
      const NoOpAnalytics(),
      engineRevision: 'rev',
    ).dependencies.whereType<LinkHooks>().single;
    expect(_resolvedInputs(dryRunLinkHooks, webEnv), contains(jsUses.path));
    expect(_resolvedInputs(dryRunLinkHooks, webEnv), isNot(contains(wasmUses.path)));
    expect(dryRunLinkHooks.getRecordedUsesFile(webEnv, BuildMode.release)?.path, jsUses.path);

    // --no-wasm-dry-run (Dart2WasmTarget omitted) also ignores stale recorded_uses_wasm.json.
    final LinkHooks jsOnlyLinkHooks = WebReleaseBundle(
      const <WebCompilerConfig>[JsCompilerConfig()],
      const NoOpAnalytics(),
      engineRevision: 'rev',
    ).dependencies.whereType<LinkHooks>().single;
    expect(_resolvedInputs(jsOnlyLinkHooks, webEnv), contains(jsUses.path));
    expect(_resolvedInputs(jsOnlyLinkHooks, webEnv), isNot(contains(wasmUses.path)));
    expect(jsOnlyLinkHooks.getRecordedUsesFile(webEnv, BuildMode.release)?.path, jsUses.path);

    // Verify FlutterBuildSystem invalidates link_hooks when dropping recorded_uses_wasm.json.
    final buildRunner = FakeFlutterNativeAssetsBuildRunner();
    final buildSystem = FlutterBuildSystem(
      fileSystem: fileSystem,
      logger: logger,
      platform: webEnv.platform,
    );
    await BuildHooks(platform: HookPlatform.web, buildRunner: buildRunner).build(webEnv);

    final BuildResult wasmBuild = await buildSystem.build(
      LinkHooks(
        platform: HookPlatform.web,
        recordedUsesFileNames: wasmLinkHooks.recordedUsesFileNames,
        buildRunner: buildRunner,
      ),
      webEnv,
    );
    expect(wasmBuild.success, isTrue);
    expect(wasmBuild.performance['link_hooks']!.skipped, isFalse);

    final BuildResult jsTransitionBuild = await buildSystem.build(
      LinkHooks(
        platform: HookPlatform.web,
        recordedUsesFileNames: dryRunLinkHooks.recordedUsesFileNames,
        buildRunner: buildRunner,
      ),
      webEnv,
    );
    expect(jsTransitionBuild.success, isTrue);
    expect(jsTransitionBuild.performance['link_hooks']!.skipped, isFalse);

    final BuildResult jsRepeatBuild = await buildSystem.build(
      LinkHooks(
        platform: HookPlatform.web,
        recordedUsesFileNames: dryRunLinkHooks.recordedUsesFileNames,
        buildRunner: buildRunner,
      ),
      webEnv,
    );
    expect(jsRepeatBuild.success, isTrue);
    expect(jsRepeatBuild.performance['link_hooks']!.skipped, isTrue);
  });
}

List<String> _resolvedOutputs(Target target, Environment environment) {
  return target.resolveOutputs(environment).sources.map((File f) => f.path).toList();
}

List<String> _resolvedInputs(Target target, Environment environment) {
  return target.resolveInputs(environment).sources.map((File f) => f.path).toList();
}
