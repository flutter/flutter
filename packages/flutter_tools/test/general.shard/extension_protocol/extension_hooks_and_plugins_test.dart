// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/dart_plugin_registrant.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/throwing_pub.dart';
import '../isolated/fake_native_assets_build_runner.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late Artifacts artifacts;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    artifacts = Artifacts.test(fileSystem: fileSystem);
  });

  group('CustomPlatformPlugin and resolvePluginImplementationsForPlatform', () {
    testWithoutContext('parses non-built-in platform keys into CustomPlatformPlugin', () {
      final pluginYaml = loadYaml('''
platforms:
  custom_embedder:
    pluginClass: CustomEmbedderPlugin
    ffiPlugin: true
    dartPluginClass: CustomEmbedderDartPlugin
    nested:
      flag: true
      items:
        - a
        - b
  custom_federated:
    default_package: my_plugin_custom_federated
''') as YamlMap;

      final plugin = Plugin.fromYaml(
        'my_plugin',
        '/packages/my_plugin',
        pluginYaml,
        null,
        const <String>[],
        fileSystem: fileSystem,
        isDevDependency: false,
      );

      final PluginPlatform? platformPlugin = plugin.platforms['custom_embedder'];
      expect(platformPlugin, isA<CustomPlatformPlugin>());
      final customPlugin = platformPlugin! as CustomPlatformPlugin;
      expect(customPlugin.name, 'my_plugin');
      expect(customPlugin.platformKey, 'custom_embedder');
      expect(customPlugin.hasMethodChannel(), isTrue);
      expect(customPlugin.hasFfi(), isTrue);
      expect(customPlugin.hasDart(), isTrue);
      expect(customPlugin.configuration['pluginClass'], 'CustomEmbedderPlugin');
      expect(
        customPlugin.configuration['nested'],
        equals(<String, Object?>{
          'flag': true,
          'items': <Object?>['a', 'b'],
        }),
      );
      expect(plugin.defaultPackagePlatforms['custom_federated'], 'my_plugin_custom_federated');
      expect(
        plugin.pluginDartClassPlatforms['custom_embedder']?.dartClass,
        'CustomEmbedderDartPlugin',
      );
    });

    testWithoutContext(
      'resolvePluginImplementationsForPlatform resolves federated and custom platform plugins',
      () {
        final appFacingPlugin = Plugin.fromYaml(
          'url_launcher',
          '/pub/url_launcher',
          loadYaml('''
platforms:
  custom_embedder:
    default_package: url_launcher_custom
''') as YamlMap,
          null,
          const <String>['url_launcher_custom'],
          appDependencies: const <String>{'url_launcher'},
          fileSystem: fileSystem,
          isDevDependency: false,
        );

        final customImplPlugin = Plugin.fromYaml(
          'url_launcher_custom',
          '/pub/url_launcher_custom',
          loadYaml('''
implements: url_launcher
platforms:
  custom_embedder:
    pluginClass: UrlLauncherCustomPlugin
''') as YamlMap,
          null,
          const <String>[],
          appDependencies: const <String>{'url_launcher'},
          fileSystem: fileSystem,
          isDevDependency: false,
        );

        final unrelatedAndroidPlugin = Plugin.fromYaml(
          'android_only',
          '/pub/android_only',
          loadYaml('''
platforms:
  android:
    package: com.example.android
    pluginClass: AndroidOnlyPlugin
''') as YamlMap,
          null,
          const <String>[],
          appDependencies: const <String>{'android_only'},
          fileSystem: fileSystem,
          isDevDependency: false,
        );

        final List<Plugin> resolved = resolvePluginImplementationsForPlatform(
          <Plugin>[appFacingPlugin, customImplPlugin, unrelatedAndroidPlugin],
          'custom_embedder',
          quiet: true,
        );

        expect(resolved.map((Plugin p) => p.name), equals(<String>['url_launcher_custom']));
      },
    );

    testWithoutContext('Plugin.fromYaml rejects invalid custom platform specifications', () {
      expect(
        () => Plugin.fromYaml(
          'my_plugin',
          '/packages/my_plugin',
          loadYaml('''
platforms:
  custom_embedder:
    pluginClass: Bad;Class
''') as YamlMap,
          null,
          const <String>[],
          fileSystem: fileSystem,
          isDevDependency: false,
        ),
        throwsToolExit(message: 'Invalid "custom_embedder" plugin specification.'),
      );

      expect(
        () => Plugin.fromYaml(
          'my_plugin',
          '/packages/my_plugin',
          loadYaml('''
platforms:
  custom_embedder:
    pluginClass: GoodClass
    dartFileName: src/custom.dart
''') as YamlMap,
          null,
          const <String>[],
          fileSystem: fileSystem,
          isDevDependency: false,
        ),
        throwsToolExit(
          message: '"dartFileName" cannot be specified without "dartPluginClass" in custom_embedder platform of plugin "my_plugin"',
        ),
      );
    });

    testUsingContext(
      'DartPluginRegistrantTarget supports custom platform plugins (such as ohos and webos)',
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        Pub: ThrowingPub.new,
      },
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        final environment = Environment.test(
          fileSystem.currentDirectory,
          projectDir: projectDir,
          artifacts: artifacts,
          fileSystem: fileSystem,
          logger: logger,
          processManager: FakeProcessManager.any(),
          defines: <String, String>{
            kTargetPlatform: 'ohos-arm64',
            kTargetFile: projectDir.childDirectory('lib').childFile('main.dart').absolute.path,
          },
          generateDartPluginRegistry: true,
        );

        expect(await const DartPluginRegistrantTarget().canSkip(environment), isFalse);

        writePackageConfigFiles(
          directory: projectDir,
          mainLibName: 'my_app',
          packages: <String, String>{
            'path_provider_ohos': '/path_provider_ohos',
            'path_provider_webos': '/path_provider_webos',
          },
          languageVersions: <String, String>{'my_app': '3.7'},
        );

        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
  path_provider_ohos: 1.0.0
  path_provider_webos: 1.0.0
''');
        projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);

        fileSystem.directory('/path_provider_ohos').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: path_provider_ohos
flutter:
  plugin:
    implements: path_provider
    platforms:
      ohos:
        dartPluginClass: PathProviderOhos
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
''');
        fileSystem.directory('/path_provider_webos').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: path_provider_webos
flutter:
  plugin:
    implements: path_provider
    platforms:
      webos:
        dartPluginClass: PathProviderWebos
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
''');

        final FlutterProject testProject = FlutterProject.fromDirectoryTest(projectDir, logger);
        await DartPluginRegistrantTarget.test(testProject).build(environment);

        final File generatedMain = projectDir
            .childDirectory('.dart_tool')
            .childDirectory('flutter_build')
            .childFile('dart_plugin_registrant.dart');
        expect(generatedMain, exists);
        final String registrantContent = generatedMain.readAsStringSync();
        expect(registrantContent, contains("Platform.operatingSystem == 'ohos'"));
        expect(registrantContent, contains('path_provider_ohos.PathProviderOhos.registerWith()'));
        expect(registrantContent, contains("Platform.operatingSystem == 'webos'"));
        expect(registrantContent, contains('path_provider_webos.PathProviderWebos.registerWith()'));
      },
    );
  });

  group('ExtensionNativeAssetsConfig and custom-target Dart hooks interop', () {
    testWithoutContext('AssetBuildTarget.targetsFor resolves OS, Architecture, and CCompilerConfig for custom targetPlatform', () async {
      final defines = <String, String>{
        kBuildMode: BuildMode.debug.cliName,
        kTargetPlatform: 'custom-embedder-riscv64',
        kExtensionTargetOs: 'linux',
        kExtensionTargetArch: 'riscv64',
        kExtensionCCompilerCc: '/toolchain/bin/riscv64-linux-gnu-gcc',
        kExtensionCCompilerAr: '/toolchain/bin/riscv64-linux-gnu-ar',
        kExtensionCCompilerLd: '/toolchain/bin/riscv64-linux-gnu-ld',
      };

      final List<AssetBuildTarget> targets = AssetBuildTarget.targetsFor(
        buildDirectory: fileSystem.directory('/project/build'),
        buildMode: BuildMode.debug,
        environmentDefines: defines,
        fileSystem: fileSystem,
        supportedAssetTypes: <SupportedAssetTypes>[
          SupportedAssetTypes.codeAssets,
          SupportedAssetTypes.dataAssets,
        ],
        targetPlatform: TargetPlatform.unsupported,
      );

      expect(targets, hasLength(1));
      final AssetBuildTarget assetTarget = targets.single;
      expect(assetTarget, isA<LinuxAssetTarget>());
      final linuxTarget = assetTarget as LinuxAssetTarget;
      expect(linuxTarget.os, OS.linux);
      expect(linuxTarget.architecture, Architecture.riscv64);
      await linuxTarget.setCCompilerConfig();
      expect(
        linuxTarget.cCompilerConfigSync?.compiler,
        Uri.file('/toolchain/bin/riscv64-linux-gnu-gcc'),
      );
      expect(
        linuxTarget.cCompilerConfigSync?.archiver,
        Uri.file('/toolchain/bin/riscv64-linux-gnu-ar'),
      );
      expect(
        linuxTarget.cCompilerConfigSync?.linker,
        Uri.file('/toolchain/bin/riscv64-linux-gnu-ld'),
      );
    });

    testUsingContext(
      'BuildHooks, LinkHooks, and InstallCodeAssets execute with custom extension targetPlatform',
      overrides: <Type, Generator>{
        FeatureFlags: () =>
            TestFeatureFlags(isNativeAssetsEnabled: true, isDartDataAssetsEnabled: true),
      },
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        writePackageConfigFiles(directory: projectDir, mainLibName: 'my_app');

        final environment = Environment.test(
          projectDir,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.release.cliName,
            kTargetPlatform: 'custom-embedder-arm64',
            kExtensionTargetOs: 'linux',
            kExtensionTargetArch: 'arm64',
            kExtensionCCompilerCc: '/usr/bin/aarch64-linux-gnu-gcc',
            kExtensionCCompilerAr: '/usr/bin/aarch64-linux-gnu-ar',
            kExtensionCCompilerLd: '/usr/bin/aarch64-linux-gnu-ld',
          },
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: FakeProcessManager.empty(),
        );
        environment.buildDir.createSync(recursive: true);

        final buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['my_app'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              CodeAsset(
                package: 'my_app',
                name: 'my_native_lib.dart',
                linkMode: DynamicLoadingBundled(),
                file: environment.buildDir.childFile('libmy_native_lib.so').uri,
              ),
            ],
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
        );
        environment.buildDir.childFile('libmy_native_lib.so').writeAsStringSync('elf');

        await BuildHooks(buildRunner: buildRunner).build(environment);
        await LinkHooks(buildRunner: buildRunner).build(environment);
        await const InstallCodeAssets().build(environment);

        expect(buildRunner.buildInvocations, 1);
        expect(buildRunner.linkInvocations, 1);
        expect(environment.buildDir.childFile(BuildHooks.depFilename), exists);
        expect(environment.buildDir.childFile(LinkHooks.depFilename), exists);
        expect(environment.buildDir.childFile(InstallCodeAssets.depFilename), exists);
        final File manifestFile = environment.buildDir.childFile(
          InstallCodeAssets.nativeAssetsFilename,
        );
        expect(manifestFile, exists);
        expect(manifestFile.readAsStringSync(), contains('my_native_lib.dart'));
      },
    );

    testWithoutContext('LinuxAssetTarget.setCCompilerConfig falls back to clang on PATH when CMakeCache.txt is missing', () async {
      fileSystem.directory('/usr/bin').createSync(recursive: true);
      fileSystem.file('/usr/bin/clang++').createSync();
      fileSystem.file('/usr/bin/clang').createSync();
      fileSystem.file('/usr/bin/llvm-ar').createSync();
      fileSystem.file('/usr/bin/ld.lld').createSync();

      final Directory missingCmakeDir = fileSystem.directory('/project/build/linux/x64/debug');
      final target = LinuxAssetTarget(
        architecture: Architecture.x64,
        cmakeBuildDirectory: missingCmakeDir,
        fileSystem: fileSystem,
        supportedAssetTypes: <SupportedAssetTypes>[SupportedAssetTypes.codeAssets],
      );

      await target.setCCompilerConfig();

      expect(target.cCompilerConfigSync, isNotNull);
      expect(target.cCompilerConfigSync!.compiler, Uri.file('/usr/bin/clang'));
      expect(target.cCompilerConfigSync!.archiver, Uri.file('/usr/bin/llvm-ar'));
      expect(target.cCompilerConfigSync!.linker, Uri.file('/usr/bin/ld.lld'));
    });

    testWithoutContext(
      'CopyAssets includes NativeAssetsManifest.json and tolerates custom kTargetPlatform',
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: test_app
environment:
  sdk: ^3.7.0
''');
        writePackageConfigFiles(directory: projectDir, mainLibName: 'test_app');
        final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(projectDir, logger);

        final environment = Environment.test(
          projectDir,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.debug.cliName,
            kTargetPlatform: 'custom-embedder-arm64',
          },
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: FakeProcessManager.any(),
        );
        environment.buildDir.createSync(recursive: true);
        environment.buildDir
            .childFile(InstallCodeAssets.nativeAssetsFilename)
            .writeAsStringSync('{"format-version":[1,0,0],"native-assets":{}}');

        await CopyAssets(flutterProject: flutterProject).build(environment);

        final File bundledManifest = environment.buildDir
            .childDirectory('flutter_assets')
            .childFile('NativeAssetsManifest.json');
        expect(bundledManifest, exists);
        expect(bundledManifest.readAsStringSync(), '{"format-version":[1,0,0],"native-assets":{}}');
      },
    );

    testWithoutContext(
      'KernelSnapshot resolves targetOS from kExtensionTargetOs for custom kTargetPlatform',
      () async {
        const boundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
        final processManager = FakeProcessManager.empty();
        final environment = Environment.test(
          fileSystem.currentDirectory,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.profile.cliName,
            kTargetPlatform: 'custom-embedder-arm64',
            kExtensionTargetOs: 'windows',
          },
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: processManager,
        );
        environment.buildDir.createSync(recursive: true);
        final String build = environment.buildDir.path;
        final String flutterPatchedSdkPath = artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: TargetPlatform.windows_x64,
          mode: BuildMode.profile,
        );
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
              artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
              '--sdk-root',
              '$flutterPatchedSdkPath/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              ...buildModeOptions(BuildMode.profile, <String>[]),
              '--track-creation-locations',
              '--aot',
              '--tfa',
              '--target-os',
              'windows',
              '--packages',
              '/.dart_tool/package_config.json',
              '--output-dill',
              '$build/app.dill',
              '--depfile',
              '$build/kernel_snapshot_program.d',
              '--verbosity=error',
              '--recorded-uses=$build/recorded_uses.json',
              'file:///lib/main.dart',
            ],
            stdout: 'result $boundaryKey\n$boundaryKey\n$boundaryKey $build/app.dill 0\n',
            onRun: (_) {
              fileSystem.file('$build/recorded_uses.json').createSync();
            },
          ),
        );

        await const KernelSnapshot().build(environment);

        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'AssetBuildTarget.targetsFor supports custom OS identifiers (such as ohos and webos)',
      () async {
        fileSystem.directory('/opt/ohos-sdk/llvm/bin').createSync(recursive: true);
        fileSystem.file('/opt/ohos-sdk/llvm/bin/clang').createSync();
        fileSystem.file('/opt/ohos-sdk/llvm/bin/llvm-ar').createSync();
        fileSystem.file('/opt/ohos-sdk/llvm/bin/ld.lld').createSync();

        final List<AssetBuildTarget> ohosTargets = AssetBuildTarget.targetsFor(
          buildDirectory: fileSystem.directory('/project/build'),
          buildMode: BuildMode.debug,
          environmentDefines: <String, String>{
            kBuildMode: BuildMode.debug.cliName,
            kTargetPlatform: 'ohos-arm64',
            kExtensionTargetOs: 'ohos',
            kExtensionTargetArch: 'arm64',
            kExtensionCCompilerCc: '/opt/ohos-sdk/llvm/bin/clang',
          },
          fileSystem: fileSystem,
          supportedAssetTypes: <SupportedAssetTypes>[
            SupportedAssetTypes.codeAssets,
            SupportedAssetTypes.dataAssets,
          ],
          targetPlatform: TargetPlatform.unsupported,
        );

        expect(ohosTargets, hasLength(1));
        final AssetBuildTarget ohosTarget = ohosTargets.single;
        expect(ohosTarget, isA<CustomCodeAssetTarget>());
        final customTarget = ohosTarget as CustomCodeAssetTarget;
        expect(customTarget.os, OS.fromString('ohos'));
        expect(customTarget.os.name, 'ohos');
        expect(customTarget.architecture, Architecture.arm64);
        await customTarget.setCCompilerConfig();
        expect(
          customTarget.cCompilerConfigSync?.compiler,
          Uri.file('/opt/ohos-sdk/llvm/bin/clang'),
        );
        expect(
          customTarget.cCompilerConfigSync?.archiver,
          Uri.file('/opt/ohos-sdk/llvm/bin/llvm-ar'),
        );
        expect(customTarget.cCompilerConfigSync?.linker, Uri.file('/opt/ohos-sdk/llvm/bin/ld.lld'));

        // Also resolves custom OS and architecture directly from kTargetPlatform
        // when kExtensionTargetOs and kExtensionTargetArch are omitted.
        final List<AssetBuildTarget> inferredWebosTargets = AssetBuildTarget.targetsFor(
          buildDirectory: fileSystem.directory('/project/build'),
          buildMode: BuildMode.release,
          environmentDefines: <String, String>{
            kBuildMode: BuildMode.release.cliName,
            kTargetPlatform: 'webos-arm64',
          },
          fileSystem: fileSystem,
          supportedAssetTypes: <SupportedAssetTypes>[SupportedAssetTypes.codeAssets],
          targetPlatform: TargetPlatform.unsupported,
        );
        expect(inferredWebosTargets, hasLength(1));
        final inferredTarget = inferredWebosTargets.single as CustomCodeAssetTarget;
        expect(inferredTarget.os.name, 'webos');
        expect(inferredTarget.architecture, Architecture.arm64);
      },
    );

    testUsingContext(
      'BuildHooks, LinkHooks, and InstallCodeAssets bundle code assets for custom OS (ohos)',
      overrides: <Type, Generator>{
        FeatureFlags: () =>
            TestFeatureFlags(isNativeAssetsEnabled: true, isDartDataAssetsEnabled: true),
      },
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        writePackageConfigFiles(directory: projectDir, mainLibName: 'my_app');

        final environment = Environment.test(
          projectDir,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.release.cliName,
            kTargetPlatform: 'ohos-arm64',
            kExtensionTargetOs: 'ohos',
            kExtensionTargetArch: 'arm64',
            kExtensionCCompilerCc: '/opt/ohos-sdk/llvm/bin/clang',
            kExtensionCCompilerAr: '/opt/ohos-sdk/llvm/bin/llvm-ar',
            kExtensionCCompilerLd: '/opt/ohos-sdk/llvm/bin/ld.lld',
          },
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: FakeProcessManager.empty(),
        );
        environment.buildDir.createSync(recursive: true);

        final buildRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['my_app'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              CodeAsset(
                package: 'my_app',
                name: 'ohos_ffi.dart',
                linkMode: DynamicLoadingBundled(),
                file: environment.buildDir.childFile('libohos_ffi.so').uri,
              ),
            ],
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
        );
        environment.buildDir.childFile('libohos_ffi.so').writeAsStringSync('elf');

        await BuildHooks(buildRunner: buildRunner).build(environment);
        await LinkHooks(buildRunner: buildRunner).build(environment);
        await const InstallCodeAssets().build(environment);

        expect(
          environment.outputDir
              .childDirectory('native_assets')
              .childDirectory('ohos')
              .childFile('libohos_ffi.so'),
          exists,
        );
        final File manifestFile = environment.buildDir.childFile(
          InstallCodeAssets.nativeAssetsFilename,
        );
        expect(manifestFile, exists);
        expect(manifestFile.readAsStringSync(), contains('ohos_ffi.dart'));
      },
    );

    testWithoutContext(
      'KernelSnapshot omits --target-os for custom OS platforms (such as ohos)',
      () async {
        const boundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
        final processManager = FakeProcessManager.empty();
        final environment = Environment.test(
          fileSystem.currentDirectory,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.profile.cliName,
            kTargetPlatform: 'ohos-arm64',
            kExtensionTargetOs: 'ohos',
          },
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: processManager,
        );
        environment.buildDir.createSync(recursive: true);
        final String build = environment.buildDir.path;
        final String flutterPatchedSdkPath = artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: TargetPlatform.linux_x64,
          mode: BuildMode.profile,
        );
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
              artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
              '--sdk-root',
              '$flutterPatchedSdkPath/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              ...buildModeOptions(BuildMode.profile, <String>[]),
              '--track-creation-locations',
              '--aot',
              '--tfa',
              '--packages',
              '/.dart_tool/package_config.json',
              '--output-dill',
              '$build/app.dill',
              '--depfile',
              '$build/kernel_snapshot_program.d',
              '--verbosity=error',
              '--recorded-uses=$build/recorded_uses.json',
              'file:///lib/main.dart',
            ],
            stdout: 'result $boundaryKey\n$boundaryKey\n$boundaryKey $build/app.dill 0\n',
            onRun: (_) {
              fileSystem.file('$build/recorded_uses.json').createSync();
            },
          ),
        );

        await const KernelSnapshot().build(environment);

        expect(processManager, hasNoRemainingExpectations);
      },
    );
  });
}
