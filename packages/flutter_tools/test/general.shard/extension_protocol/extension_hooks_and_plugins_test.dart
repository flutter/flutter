// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:code_assets/code_assets.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_info.dart' hide BuildMode;
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/dart_plugin_registrant.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/throwing_pub.dart';
import '../isolated/fake_native_assets_build_runner.dart';

final class _PluginCapturingBuildService extends BuildService {
  _PluginCapturingBuildService(this._pluginsPort);

  final SendPort _pluginsPort;

  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return <ExtensionBuildTarget>[
      ExtensionBuildTarget(
        description: 'Custom package build target.',
        name: 'custom-pkg',
        nativeAssetsConfig: ExtensionNativeAssetsConfig(
          targetArchitecture: 'arm64',
          targetOs: 'custom_os',
          cCompilerConfig: ExtensionCCompilerConfig(
            ar: Uri.file('/opt/custom-sdk/llvm/bin/llvm-ar'),
            cc: Uri.file('/opt/custom-sdk/llvm/bin/clang'),
            ld: Uri.file('/opt/custom-sdk/llvm/bin/ld.lld'),
          ),
        ),
        pluginPlatformKey: 'custom_os',
      ),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
    List<ExtensionPlugin> plugins = const <ExtensionPlugin>[],
  }) async {
    _pluginsPort.send(plugins);
    return const ExtensionBuildResult(success: true);
  }
}

void _pluginCapturingExtensionEntryPoint(SendPort sendPort, SendPort pluginsPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_PluginCapturingBuildService(pluginsPort)],
    supportedPlatforms: const <String>{'linux'},
  );
}

ExtensionEntryPoint _createPluginCapturingEntryPoint(SendPort pluginsPort) {
  return (SendPort sendPort) => _pluginCapturingExtensionEntryPoint(sendPort, pluginsPort);
}

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
  custom_platform_b:
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

      expect(plugin.platforms.containsKey('custom_platform_b'), isFalse);
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

    testWithoutContext('resolvePluginImplementationsForPlatform and resolveExtensionPluginsForPlatform resolve custom platform plugins without affecting built-in resolution', () {
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

      final allPlugins = <Plugin>[appFacingPlugin, customImplPlugin, unrelatedAndroidPlugin];

      // Standard built-in resolution ignores custom_embedder unless requested.
      final List<PluginInterfaceResolution> builtInResolutions = resolvePlatformImplementation(
        allPlugins,
        selectDartPluginsOnly: false,
      );
      expect(
        builtInResolutions.map((PluginInterfaceResolution r) => r.platform),
        equals(<String>['android']),
      );

      final List<ExtensionPlugin> resolvedExtensionPlugins = resolveExtensionPluginsForPlatform(
        allPlugins,
        'custom_embedder',
        quiet: true,
      );
      expect(
        resolvedExtensionPlugins,
        equals(<ExtensionPlugin>[
          ExtensionPlugin(
            name: 'url_launcher_custom',
            path: Uri.directory('/pub/url_launcher_custom'),
            configuration: const <String, Object?>{'pluginClass': 'UrlLauncherCustomPlugin'},
          ),
        ]),
      );
    });

    testWithoutContext(
      'Plugin.fromYaml rejects invalid custom platform keys and specifications',
      () {
        expect(
          () => Plugin.fromYaml(
            'my_plugin',
            '/packages/my_plugin',
            loadYaml('''
platforms:
  bad-key:
    pluginClass: GoodClass
''') as YamlMap,
            null,
            const <String>[],
            fileSystem: fileSystem,
            isDevDependency: false,
          ),
          throwsToolExit(message: 'Invalid "bad-key" plugin specification.'),
        );

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
      },
    );

    testUsingContext(
      'DartPluginRegistrantTarget supports custom platform plugins when extension defines are set',
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
            kTargetPlatform: 'custom-arm64',
            kExtensionTargetOs: 'custom_os',
            kExtensionPluginPlatformKey: 'custom_os',
            kTargetFile: projectDir.childDirectory('lib').childFile('main.dart').absolute.path,
          },
          generateDartPluginRegistry: true,
        );

        expect(await const DartPluginRegistrantTarget().canSkip(environment), isFalse);

        writePackageConfigFiles(
          directory: projectDir,
          mainLibName: 'my_app',
          packages: <String, String>{
            'path_provider_custom_a': '/path_provider_custom_a',
            'path_provider_custom_b': '/path_provider_custom_b',
          },
          languageVersions: <String, String>{'my_app': '3.7'},
        );

        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
  path_provider_custom_a: 1.0.0
  path_provider_custom_b: 1.0.0
''');
        projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);

        fileSystem.directory('/path_provider_custom_a').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: path_provider_custom_a
flutter:
  plugin:
    implements: path_provider
    platforms:
      custom_os:
        dartPluginClass: PathProviderCustomA
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
''');
        fileSystem.directory('/path_provider_custom_b').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: path_provider_custom_b
flutter:
  plugin:
    implements: path_provider
    platforms:
      custom_platform_b:
        dartPluginClass: PathProviderCustomB
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
        const customPlatformCheck =
            "const String.fromEnvironment('$kFlutterCustomPlatformDartDefine') == 'custom_os'";
        expect(registrantContent, contains(customPlatformCheck));
        expect(
          registrantContent,
          contains('path_provider_custom_a.PathProviderCustomA.registerWith()'),
        );
        expect(registrantContent, contains('return;'));
        expect(registrantContent, isNot(contains('PathProviderCustomB')));
        expect(
          registrantContent.indexOf(customPlatformCheck),
          lessThan(registrantContent.indexOf('if (Platform.isAndroid)')),
        );
      },
    );

    testWithoutContext('ExtensionBuildManager resolves plugins for pluginPlatformKey and maps nativeAssetsConfig to defines', () async {
      final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
      writePackageConfigFiles(
        directory: projectDir,
        mainLibName: 'my_app',
        packages: <String, String>{
          'camera_custom': '/camera_custom',
          'url_launcher_linux': '/url_launcher_linux',
        },
      );
      projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
  camera_custom: 1.0.0
  url_launcher_linux: 1.0.0
''');
      fileSystem.directory('/camera_custom').childFile('pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
name: camera_custom
flutter:
  plugin:
    platforms:
      custom_os:
        pluginClass: CameraCustomPlugin
        archivePath: pkg/camera.pkg
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
''');
      fileSystem.directory('/url_launcher_linux').childFile('pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
name: url_launcher_linux
flutter:
  plugin:
    platforms:
      linux:
        pluginClass: UrlLauncherPlugin
environment:
  sdk: ^3.7.0-0
  flutter: ">=1.20.0"
''');

      final pluginsPort = ReceivePort();
      addTearDown(pluginsPort.close);
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final extensionManager = ExtensionManager(
        entryPoints: <ExtensionEntryPoint>[_createPluginCapturingEntryPoint(pluginsPort.sendPort)],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(extensionManager.dispose);
      final buildManager = ExtensionBuildManager(
        extensionManager: extensionManager,
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        logger: logger,
      );

      final List<ExtensionBuildTarget> targets = await buildManager.getBuildTargets();
      expect(targets, hasLength(1));
      expect(
        buildManager.environmentDefinesForTarget('custom-pkg'),
        equals(<String, String>{
          kExtensionTargetOs: 'custom_os',
          kExtensionTargetArch: 'arm64',
          kExtensionCCompilerCc: '/opt/custom-sdk/llvm/bin/clang',
          kExtensionCCompilerAr: '/opt/custom-sdk/llvm/bin/llvm-ar',
          kExtensionCCompilerLd: '/opt/custom-sdk/llvm/bin/ld.lld',
          kExtensionPluginPlatformKey: 'custom_os',
        }),
      );

      final ExtensionBuildResult result = await buildManager.build(
        buildMode: BuildMode.release,
        mainPath: 'lib/main.dart',
        projectRoot: projectDir.uri,
        targetName: 'custom-pkg',
      );
      expect(result.success, isTrue);
      expect(
        await pluginsPort.first,
        equals(<ExtensionPlugin>[
          ExtensionPlugin(
            name: 'camera_custom',
            path: Uri.directory('/camera_custom'),
            configuration: const <String, Object?>{
              'pluginClass': 'CameraCustomPlugin',
              'archivePath': 'pkg/camera.pkg',
            },
          ),
        ]),
      );
    });
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
      expect(assetTarget, isA<CustomCodeAssetTarget>());
      final customTarget = assetTarget as CustomCodeAssetTarget;
      expect(customTarget.os, OS.linux);
      expect(customTarget.architecture, Architecture.riscv64);
      await customTarget.setCCompilerConfig();
      expect(
        customTarget.cCompilerConfigSync?.compiler,
        Uri.file('/toolchain/bin/riscv64-linux-gnu-gcc'),
      );
      expect(
        customTarget.cCompilerConfigSync?.archiver,
        Uri.file('/toolchain/bin/riscv64-linux-gnu-ar'),
      );
      expect(
        customTarget.cCompilerConfigSync?.linker,
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

    testUsingContext(
      'CopyAssets includes NativeAssetsManifest.json when present',
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
      () async {
        final Directory projectDir = fileSystem.currentDirectory;
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: test_app
environment:
  sdk: ^3.7.0
''');
        writePackageConfigFiles(directory: projectDir, mainLibName: 'test_app');

        final environment = Environment.test(
          projectDir,
          artifacts: artifacts,
          defines: <String, String>{
            kBuildMode: BuildMode.debug.cliName,
            kTargetPlatform: 'custom-embedder-arm64',
            kExtensionTargetOs: 'linux',
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

        await const CopyAssets().build(environment);

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
            kExtensionPluginPlatformKey: 'custom_embedder',
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
              '-DFLUTTER_CUSTOM_PLATFORM=custom_embedder',
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

    testWithoutContext('AssetBuildTarget.targetsFor supports custom OS identifiers', () async {
      fileSystem.directory('/opt/custom-sdk/llvm/bin').createSync(recursive: true);
      fileSystem.file('/opt/custom-sdk/llvm/bin/clang').createSync();
      fileSystem.file('/opt/custom-sdk/llvm/bin/llvm-ar').createSync();
      fileSystem.file('/opt/custom-sdk/llvm/bin/ld.lld').createSync();

      final List<AssetBuildTarget> customTargets = AssetBuildTarget.targetsFor(
        buildDirectory: fileSystem.directory('/project/build'),
        buildMode: BuildMode.debug,
        environmentDefines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
          kTargetPlatform: 'custom-arm64',
          kExtensionTargetOs: 'custom_os',
          kExtensionTargetArch: 'arm64',
          kExtensionCCompilerCc: '/opt/custom-sdk/llvm/bin/clang',
        },
        fileSystem: fileSystem,
        supportedAssetTypes: <SupportedAssetTypes>[
          SupportedAssetTypes.codeAssets,
          SupportedAssetTypes.dataAssets,
        ],
        targetPlatform: TargetPlatform.unsupported,
      );

      expect(customTargets, hasLength(1));
      final AssetBuildTarget target = customTargets.single;
      expect(target, isA<CustomCodeAssetTarget>());
      final customTarget = target as CustomCodeAssetTarget;
      expect(customTarget.os, OS.fromString('custom_os'));
      expect(customTarget.os.name, 'custom_os');
      expect(customTarget.architecture, Architecture.arm64);
      await customTarget.setCCompilerConfig();
      expect(
        customTarget.cCompilerConfigSync?.compiler,
        Uri.file('/opt/custom-sdk/llvm/bin/clang'),
      );
      expect(
        customTarget.cCompilerConfigSync?.archiver,
        Uri.file('/opt/custom-sdk/llvm/bin/llvm-ar'),
      );
      expect(customTarget.cCompilerConfigSync?.linker, Uri.file('/opt/custom-sdk/llvm/bin/ld.lld'));
    });

    testWithoutContext('unknown kTargetPlatform without kExtensionTargetOs throws in KernelSnapshot, DartPluginRegistrantTarget, and BuildHooks', () async {
      final environment = Environment.test(
        fileSystem.currentDirectory,
        artifacts: artifacts,
        defines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
          kTargetPlatform: 'linux-x46',
        },
        fileSystem: fileSystem,
        inputs: <String, String>{},
        logger: logger,
        processManager: FakeProcessManager.empty(),
        generateDartPluginRegistry: true,
      );

      await expectLater(() => const KernelSnapshot().build(environment), throwsA(isA<Exception>()));
      await expectLater(
        () => const DartPluginRegistrantTarget().canSkip(environment),
        throwsA(isA<Exception>()),
      );
      await expectLater(() => const BuildHooks().build(environment), throwsA(isA<Exception>()));
    });

    testUsingContext(
      'BuildHooks, LinkHooks, and InstallCodeAssets bundle code assets for custom OS',
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
            kTargetPlatform: 'custom-arm64',
            kExtensionTargetOs: 'custom_os',
            kExtensionTargetArch: 'arm64',
            kExtensionCCompilerCc: '/opt/custom-sdk/llvm/bin/clang',
            kExtensionCCompilerAr: '/opt/custom-sdk/llvm/bin/llvm-ar',
            kExtensionCCompilerLd: '/opt/custom-sdk/llvm/bin/ld.lld',
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
                name: 'custom_ffi.dart',
                linkMode: DynamicLoadingBundled(),
                file: environment.buildDir.childFile('libcustom_ffi.so').uri,
              ),
            ],
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
        );
        environment.buildDir.childFile('libcustom_ffi.so').writeAsStringSync('elf');

        await BuildHooks(buildRunner: buildRunner).build(environment);
        await LinkHooks(buildRunner: buildRunner).build(environment);
        await const InstallCodeAssets().build(environment);

        expect(
          environment.outputDir
              .childDirectory('native_assets')
              .childDirectory('custom_os')
              .childFile('libcustom_ffi.so'),
          exists,
        );
        final File manifestFile = environment.buildDir.childFile(
          InstallCodeAssets.nativeAssetsFilename,
        );
        expect(manifestFile, exists);
        expect(manifestFile.readAsStringSync(), contains('custom_ffi.dart'));
      },
    );

    testWithoutContext('KernelSnapshot omits --target-os for custom OS platforms', () async {
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
          kTargetPlatform: 'custom-arm64',
          kExtensionTargetOs: 'custom_os',
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
            '-DFLUTTER_CUSTOM_PLATFORM=custom_os',
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
    });
  });
}
