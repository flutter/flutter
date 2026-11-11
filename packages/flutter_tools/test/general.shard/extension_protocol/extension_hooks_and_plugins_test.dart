// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:code_assets/code_assets.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart' hide BuildMode;
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/dart_plugin_registrant.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide Category;
import 'package:flutter_tools_core/flutter_tools_core.dart' as core show Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';
import '../isolated/fake_native_assets_build_runner.dart';

final class _ThrowingNativeAssetsBuildTarget extends BuildTarget {
  const _ThrowingNativeAssetsBuildTarget()
    : super(
        description: 'Build target that fails to resolve native assets config.',
        outputDir: '{OUTPUT_DIR}/failing_hooks',
        targetPlatform: 'custom-arm64',
      );

  @override
  String get name => 'failing-hooks-target';

  @override
  Future<ExtensionNativeAssetsConfig?> resolveNativeAssetsConfig(
    ExtensionBuildContext context,
  ) async {
    throw StateError('Toolchain lookup failed');
  }

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return const ExtensionBuildResult(success: true);
  }
}

final class _ThrowingNativeAssetsBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_ThrowingNativeAssetsBuildTarget()];
}

void _throwingNativeAssetsExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_ThrowingNativeAssetsBuildService()],
    extensionName: 'failing_hooks_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _PluginCapturingBuildTarget extends BuildTarget {
  const _PluginCapturingBuildTarget(this._pluginsPort)
    : super(
        description: 'Custom package build target.',
        outputDir: '{OUTPUT_DIR}/custom_pkg',
        targetPlatform: 'custom-arm64',
      );

  final SendPort _pluginsPort;

  @override
  String get name => 'custom-pkg';

  @override
  String? get pluginPlatformKey => 'custom_os';

  @override
  Future<ExtensionNativeAssetsConfig?> resolveNativeAssetsConfig(
    ExtensionBuildContext context,
  ) async {
    _pluginsPort.send(context.plugins);
    return ExtensionNativeAssetsConfig(
      targetArchitecture: 'arm64',
      targetOs: 'custom_os',
      cCompilerConfig: ExtensionCCompilerConfig(
        ar: Uri.parse('file:///opt/custom-sdk/llvm/bin/llvm-ar'),
        cc: Uri.parse('file:///opt/custom-sdk/llvm/bin/clang'),
        ld: Uri.parse('file:///opt/custom-sdk/llvm/bin/ld.lld'),
      ),
    );
  }

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    _pluginsPort.send(context.plugins);
    return ExtensionBuildResult(
      success: true,
      executableUri: Uri.parse('file:///tmp/custom_pkg/app'),
    );
  }
}

final class _DefaultHooksBuildTarget extends BuildTarget {
  const _DefaultHooksBuildTarget()
    : super(
        description: 'Custom build target using default resolveNativeAssetsConfig => null.',
        outputDir: '{OUTPUT_DIR}/custom_hookless',
        targetPlatform: 'custom-hookless-arm64',
      );

  @override
  String get name => 'custom-hookless';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return const ExtensionBuildResult(success: true);
  }
}

final class _DefaultHooksBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_DefaultHooksBuildTarget()];
}

void _defaultHooksExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_DefaultHooksBuildService()],
    extensionName: 'default_hooks_extension',
    supportedPlatforms: const <String>{'linux'},
  );
}

final class _PluginCapturingAssembleTarget extends AssembleTarget {
  const _PluginCapturingAssembleTarget(this._pluginsPort)
    : super(
        description: 'Custom assemble target that captures plugins.',
        targetPlatform: 'custom-arm64',
      );

  final SendPort _pluginsPort;

  @override
  String get name => 'custom-pkg-assemble';

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    _pluginsPort.send(context.plugins);
    return const ExtensionBuildResult(success: true);
  }
}

final class _PluginCapturingBuildService extends BuildService {
  _PluginCapturingBuildService(this._pluginsPort);

  final SendPort _pluginsPort;

  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[_PluginCapturingBuildTarget(_pluginsPort)];

  @override
  List<AssembleTarget> get assembleTargets => <AssembleTarget>[
    _PluginCapturingAssembleTarget(_pluginsPort),
  ];
}

final class _PluginCapturingDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: core.Category.desktop,
        id: 'custom-pkg-device',
        name: 'Custom Pkg Device',
        buildTarget: 'custom-pkg',
        ephemeral: false,
        targetPlatform: 'custom-arm64',
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => true;

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async => true;

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId}) async => true;
}

void _pluginCapturingExtensionEntryPoint(SendPort sendPort, SendPort pluginsPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[
      _PluginCapturingBuildService(pluginsPort),
      _PluginCapturingDeviceService(),
    ],
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
        extraPlatformKeys: const <String>{
          'custom_embedder',
          'custom_federated',
          'custom_platform_b',
        },
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
      expect(customPlugin.dartPluginClass, 'CustomEmbedderDartPlugin');
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

    testWithoutContext('Plugin.fromYaml ignores non-built-in platform stanzas by default when extraPlatformKeys is omitted', () {
      final pluginYaml = loadYaml('''
platforms:
  android:
    package: com.example.my_plugin
    pluginClass: MyAndroidPlugin
  bad-hyphen-key:
    pluginClass: Bad;Class
  empty_custom_map: {}
  scalar_custom_entry: 123
''') as YamlMap;

      final plugin = Plugin.fromYaml(
        'my_plugin',
        '/packages/my_plugin',
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
      );

      expect(plugin.platforms.keys, equals(<String>['android']));
      expect(plugin.defaultPackagePlatforms, isEmpty);
    });

    testWithoutContext('resolvePluginImplementationsForPlatform and resolveExtensionPluginsForPlatform resolve custom platform plugins without affecting built-in resolution', () {
      const extraKeys = <String>{'custom_embedder'};
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
        extraPlatformKeys: extraKeys,
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
        extraPlatformKeys: extraKeys,
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
        extraPlatformKeys: extraKeys,
        isDevDependency: false,
      );

      final allPlugins = <Plugin>[appFacingPlugin, customImplPlugin, unrelatedAndroidPlugin];

      // Standard built-in resolution ignores custom_embedder unless requested.
      final List<PluginInterfaceResolution> builtInResolutions = resolvePlatformImplementation(
        allPlugins,
        logger: logger,
        selectDartPluginsOnly: false,
      );
      expect(
        builtInResolutions.map((PluginInterfaceResolution r) => r.platform),
        equals(<String>['android']),
      );

      final List<ExtensionPlugin> resolvedExtensionPlugins = resolveExtensionPluginsForPlatform(
        allPlugins,
        'custom_embedder',
        fileSystem: fileSystem,
        logger: logger,
        quiet: true,
      );
      expect(
        resolvedExtensionPlugins,
        equals(<ExtensionPlugin>[
          ExtensionPlugin(
            name: 'url_launcher_custom',
            path: fileSystem.directory('/pub/url_launcher_custom').uri,
            configuration: const <String, Object?>{'pluginClass': 'UrlLauncherCustomPlugin'},
          ),
        ]),
      );

      final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final winPlugin = Plugin.fromYaml(
        'camera_custom',
        r'C:\pub-cache\camera_custom',
        loadYaml('''
platforms:
  custom_embedder:
    pluginClass: CameraCustomPlugin
''') as YamlMap,
        null,
        const <String>[],
        extraPlatformKeys: const <String>['custom_embedder'],
        isDevDependency: false,
      );
      expect(
        resolveExtensionPluginsForPlatform(
          <Plugin>[winPlugin],
          'custom_embedder',
          fileSystem: windowsFs,
          logger: logger,
        ),
        equals(<ExtensionPlugin>[
          ExtensionPlugin(
            name: 'camera_custom',
            path: Uri.parse('file:///C:/pub-cache/camera_custom/'),
            configuration: const <String, Object?>{'pluginClass': 'CameraCustomPlugin'},
          ),
        ]),
      );
    });

    testWithoutContext('Plugin.fromYaml rejects invalid custom platform keys and specifications when requested in extraPlatformKeys', () {
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
          extraPlatformKeys: const <String>{'bad-key'},
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
          extraPlatformKeys: const <String>{'custom_embedder'},
          isDevDependency: false,
        ),
        throwsToolExit(
          message:
              'Invalid "custom_embedder" plugin specification: '
              'the "pluginClass" field must be a valid identifier',
        ),
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
          extraPlatformKeys: const <String>{'custom_embedder'},
          isDevDependency: false,
        ),
        throwsToolExit(
          message: '"dartFileName" cannot be specified without "dartPluginClass" in custom_embedder platform of plugin "my_plugin"',
        ),
      );
    });

    testWithoutContext(
      'DartPluginRegistrantTarget supports custom platform plugins when extension defines are set',
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

    ({
      ExtensionBuildManager buildManager,
      List<ExtensionPlugin> expectedCustomPlugins,
      ExtensionManager extensionManager,
      FeatureFlags featureFlags,
      StreamIterator<Object?> pluginsEvents,
      Directory projectDir,
    })
    setUpCustomPluginProject() {
      final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
      fileSystem.directory('/flutter').createSync(recursive: true);
      fileSystem.currentDirectory = projectDir;
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
      projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
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
      final pluginsEvents = StreamIterator<Object?>(pluginsPort);
      addTearDown(pluginsEvents.cancel);
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
        projectFactory: FlutterProjectFactory(
          config: FakeConfig(),
          fileSystem: fileSystem,
          logger: logger,
        ),
      );

      final expectedCustomPlugins = <ExtensionPlugin>[
        ExtensionPlugin(
          name: 'camera_custom',
          path: fileSystem.directory('/camera_custom').uri,
          configuration: const <String, Object?>{
            'pluginClass': 'CameraCustomPlugin',
            'archivePath': 'pkg/camera.pkg',
          },
        ),
      ];

      return (
        buildManager: buildManager,
        expectedCustomPlugins: expectedCustomPlugins,
        extensionManager: extensionManager,
        featureFlags: featureFlags,
        pluginsEvents: pluginsEvents,
        projectDir: projectDir,
      );
    }

    testWithoutContext('ExtensionBuildManager.resolveNativeAssetsConfig resolves filtered plugins and environmentDefinesForTarget', () async {
      final (
        :ExtensionBuildManager buildManager,
        :List<ExtensionPlugin> expectedCustomPlugins,
        extensionManager: _,
        featureFlags: _,
        :StreamIterator<Object?> pluginsEvents,
        :Directory projectDir,
      ) = setUpCustomPluginProject();

      final ExtensionNativeAssetsConfig? resolvedConfig = await buildManager
          .resolveNativeAssetsConfig(
            buildMode: BuildMode.release,
            flutterRoot: fileSystem.directory('/flutter').uri,
            mainPath: 'lib/main.dart',
            outputDir: fileSystem.directory('/project/build/custom_pkg').uri,
            projectRoot: projectDir.uri,
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-pkg',
          );
      expect(resolvedConfig, isNotNull);
      expect(await pluginsEvents.moveNext(), isTrue);
      expect(pluginsEvents.current, equals(expectedCustomPlugins));

      expect(
        buildManager.environmentDefinesForTarget('custom-pkg', nativeAssetsConfig: resolvedConfig),
        equals(<String, String>{
          kExtensionTargetOs: 'custom_os',
          kExtensionTargetArch: 'arm64',
          kExtensionCCompilerCc: 'file:///opt/custom-sdk/llvm/bin/clang',
          kExtensionCCompilerAr: 'file:///opt/custom-sdk/llvm/bin/llvm-ar',
          kExtensionCCompilerLd: 'file:///opt/custom-sdk/llvm/bin/ld.lld',
          kExtensionPluginPlatformKey: 'custom_os',
        }),
      );
    });

    testWithoutContext(
      'ExtensionBuildManager logs conflicting federated custom platform plugin errors',
      () async {
        final (
          :ExtensionBuildManager buildManager,
          expectedCustomPlugins: _,
          extensionManager: _,
          featureFlags: _,
          pluginsEvents: _,
          :Directory projectDir,
        ) = setUpCustomPluginProject();

        final Directory cameraFrontend = fileSystem.directory('/camera')
          ..createSync(recursive: true);
        cameraFrontend.childFile('pubspec.yaml').writeAsStringSync('''
name: camera
environment:
  sdk: ^3.7.0-0
flutter:
  plugin:
    platforms:
      custom_os:
        default_package: camera_custom
''');
        final Directory cameraAlt = fileSystem.directory('/camera_custom_alt')
          ..createSync(recursive: true);
        cameraAlt.childFile('pubspec.yaml').writeAsStringSync('''
name: camera_custom_alt
environment:
  sdk: ^3.7.0-0
flutter:
  plugin:
    implements: camera
    platforms:
      custom_os:
        pluginClass: CameraCustomAltPlugin
''');
        fileSystem.file('/camera_custom/pubspec.yaml').writeAsStringSync('''
name: camera_custom
environment:
  sdk: ^3.7.0-0
flutter:
  plugin:
    implements: camera
    platforms:
      custom_os:
        pluginClass: CameraCustomPlugin
''');
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.7.0-0
dependencies:
  camera:
    path: /camera
  camera_custom:
    path: /camera_custom
  camera_custom_alt:
    path: /camera_custom_alt
flutter:
  uses-material-design: false
''');
        writePackageConfigFiles(
          directory: projectDir,
          mainLibName: 'my_app',
          packages: <String, String>{
            'camera': '/camera',
            'camera_custom': '/camera_custom',
            'camera_custom_alt': '/camera_custom_alt',
          },
        );

        await expectLater(
          buildManager.build(
            buildMode: BuildMode.release,
            flutterRoot: fileSystem.directory('/flutter').uri,
            mainPath: 'lib/main.dart',
            outputDir: fileSystem.directory('/project/build/custom_pkg').uri,
            projectRoot: projectDir.uri,
            resolvedArtifacts: const <String, String>{},
            targetName: 'custom-pkg',
          ),
          throwsToolExit(),
        );
        expect(logger.errorText, contains('camera_custom'));
        expect(logger.errorText, contains('camera_custom_alt'));
      },
    );

    testWithoutContext(
      'ExtensionBuildManager.resolveNativeAssetsConfig throws ToolExit when extension fails',
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        fileSystem.directory('/flutter').createSync(recursive: true);
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final extensionManager = ExtensionManager(
          entryPoints: <ExtensionEntryPoint>[_throwingNativeAssetsExtensionEntryPoint],
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
          projectFactory: FlutterProjectFactory(
            config: FakeConfig(),
            fileSystem: fileSystem,
            logger: logger,
          ),
        );

        await expectLater(
          buildManager.resolveNativeAssetsConfig(
            buildMode: BuildMode.release,
            flutterRoot: fileSystem.directory('/flutter').uri,
            mainPath: 'lib/main.dart',
            outputDir: fileSystem.directory('/project/build/failing_hooks').uri,
            projectRoot: projectDir.uri,
            resolvedArtifacts: const <String, String>{},
            targetName: 'failing-hooks-target',
          ),
          throwsToolExit(
            message: 'Failed to resolve native assets config from extension "failing_hooks_extension" for target "failing-hooks-target"',
          ),
        );
      },
    );

    testWithoutContext(
      'ExtensionBuildManager.build resolves and forwards filtered plugins for pluginPlatformKey',
      () async {
        final (
          :ExtensionBuildManager buildManager,
          :List<ExtensionPlugin> expectedCustomPlugins,
          extensionManager: _,
          featureFlags: _,
          :StreamIterator<Object?> pluginsEvents,
          :Directory projectDir,
        ) = setUpCustomPluginProject();

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: BuildMode.release,
          flutterRoot: fileSystem.directory('/flutter').uri,
          mainPath: 'lib/main.dart',
          outputDir: fileSystem.directory('/project/build/custom_pkg').uri,
          projectRoot: projectDir.uri,
          resolvedArtifacts: const <String, String>{},
          targetName: 'custom-pkg',
        );
        expect(result.success, isTrue);
        expect(await pluginsEvents.moveNext(), isTrue);
        expect(pluginsEvents.current, equals(expectedCustomPlugins));
      },
    );

    testWithoutContext(
      'ExtensionBuildSubCommand forwards filtered plugins to extension build target',
      () async {
        final (
          :ExtensionBuildManager buildManager,
          :List<ExtensionPlugin> expectedCustomPlugins,
          extensionManager: _,
          featureFlags: _,
          :StreamIterator<Object?> pluginsEvents,
          projectDir: _,
        ) = setUpCustomPluginProject();

        final List<ExtensionBuildTarget> targets = await buildManager.getBuildTargets();
        expect(targets, hasLength(1));

        final cache = FakeCache(fileSystem: fileSystem, flutterRoot: '/flutter');
        final subCommand = ExtensionBuildSubCommand(
          buildManager: buildManager,
          target: targets.single,
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            logger: logger,
            signals: FakeSignals(),
          ),
          verboseHelp: false,
        );
        final FlutterCommandResult subCommandResult = await subCommand.runCommand();
        expect(subCommandResult.exitStatus, ExitStatus.success);
        expect(await pluginsEvents.moveNext(), isTrue);
        expect(pluginsEvents.current, equals(expectedCustomPlugins));
      },
    );

    testWithoutContext(
      'ExtensionBackedDevice.startApp forwards filtered plugins to extension build target',
      () async {
        final (
          :ExtensionBuildManager buildManager,
          :List<ExtensionPlugin> expectedCustomPlugins,
          :ExtensionManager extensionManager,
          featureFlags: _,
          :StreamIterator<Object?> pluginsEvents,
          projectDir: _,
        ) = setUpCustomPluginProject();

        final discovery = ExtensionDevices(
          extensionBuildManager: buildManager,
          extensionManager: extensionManager,
          fileSystem: fileSystem,
          logger: logger,
        );
        final List<Device> devices = await discovery.devices();
        expect(devices, hasLength(1));
        final LaunchResult launchResult = await devices.single.startApp(
          null,
          mainPath: 'lib/main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        );
        expect(launchResult.started, isTrue);
        expect(await pluginsEvents.moveNext(), isTrue);
        expect(pluginsEvents.current, equals(expectedCustomPlugins));
      },
    );

    testWithoutContext('AssembleCommand resolves nativeAssetsConfig, environmentDefinesForTarget, and assemble target plugins for custom extension targetPlatform', () async {
      final (
        :ExtensionBuildManager buildManager,
        :List<ExtensionPlugin> expectedCustomPlugins,
        extensionManager: _,
        :FeatureFlags featureFlags,
        :StreamIterator<Object?> pluginsEvents,
        projectDir: _,
      ) = setUpCustomPluginProject();

      Environment? capturedEnvironment;
      final cache = FakeCache(fileSystem: fileSystem, flutterRoot: '/flutter');
      final assembleCommand = AssembleCommand(
        androidContext: FakeAndroidContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          capturedEnvironment = environment;
        }),
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(
          cache: cache,
          fs: fileSystem,
          logger: logger,
          signals: FakeSignals(),
        ),
        xcode: null,
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(assembleCommand);
      await commandRunner.run(<String>[
        'assemble',
        '--output=/project/build/custom_pkg',
        '-dTargetPlatform=custom-arm64',
        '-dBuildMode=release',
        'copy_assets',
      ]);

      expect(await pluginsEvents.moveNext(), isTrue);
      expect(pluginsEvents.current, equals(expectedCustomPlugins));
      expect(capturedEnvironment, isNotNull);
      expect(capturedEnvironment!.defines[kExtensionTargetOs], 'custom_os');
      expect(capturedEnvironment!.defines[kExtensionTargetArch], 'arm64');
      expect(
        capturedEnvironment!.defines[kExtensionCCompilerCc],
        'file:///opt/custom-sdk/llvm/bin/clang',
      );
      expect(
        capturedEnvironment!.defines[kExtensionCCompilerAr],
        'file:///opt/custom-sdk/llvm/bin/llvm-ar',
      );
      expect(
        capturedEnvironment!.defines[kExtensionCCompilerLd],
        'file:///opt/custom-sdk/llvm/bin/ld.lld',
      );
      expect(capturedEnvironment!.defines[kExtensionPluginPlatformKey], 'custom_os');

      final buildSystem = FlutterBuildSystem(
        fileSystem: fileSystem,
        logger: logger,
        platform: FakePlatform(),
      );
      final realAssembleCommand = AssembleCommand(
        androidContext: FakeAndroidContext(),
        buildSystem: buildSystem,
        extensionBuildManager: buildManager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(
          cache: cache,
          fs: fileSystem,
          logger: logger,
          signals: FakeSignals(),
        ),
        xcode: null,
      );
      final CommandRunner<void> realAssembleRunner = createTestCommandRunner(realAssembleCommand);
      await realAssembleRunner.run(<String>[
        'assemble',
        '--output=/project/build/custom_pkg_assemble',
        '-dTargetPlatform=custom-arm64',
        '-dBuildMode=release',
        'custom-pkg-assemble',
      ]);
      // First event is resolveNativeAssetsConfig, second is custom-pkg-assemble.build(context).
      expect(await pluginsEvents.moveNext(), isTrue);
      expect(pluginsEvents.current, equals(expectedCustomPlugins));
      expect(await pluginsEvents.moveNext(), isTrue);
      expect(pluginsEvents.current, equals(expectedCustomPlugins));
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
        androidSdkProvider: null,
        buildDirectory: fileSystem.directory('/project/build'),
        buildMode: BuildMode.debug,
        environmentDefines: defines,
        fileSystem: fileSystem,
        supportedAssetTypes: <SupportedAssetTypes>[
          SupportedAssetTypes.codeAssets,
          SupportedAssetTypes.dataAssets,
        ],
        targetPlatform: TargetPlatform.unsupported,
        visualStudio: null,
      );

      expect(targets, hasLength(1));
      final AssetBuildTarget assetTarget = targets.single;
      expect(assetTarget, isA<CustomCodeAssetTarget>());
      final customTarget = assetTarget as CustomCodeAssetTarget;
      expect(customTarget.os, OS.linux);
      expect(customTarget.architecture, Architecture.riscv64);
      await customTarget.setCCompilerConfig(
        processUtils: ProcessUtils(processManager: FakeProcessManager.empty(), logger: logger),
      );
      expect(
        customTarget.cCompilerConfigSync?.compiler,
        fileSystem.file('/toolchain/bin/riscv64-linux-gnu-gcc').uri,
      );
      expect(
        customTarget.cCompilerConfigSync?.archiver,
        fileSystem.file('/toolchain/bin/riscv64-linux-gnu-ar').uri,
      );
      expect(
        customTarget.cCompilerConfigSync?.linker,
        fileSystem.file('/toolchain/bin/riscv64-linux-gnu-ld').uri,
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

    testWithoutContext('CopyAssets includes NativeAssetsManifest.json when present', () async {
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
    });

    testWithoutContext(
      'KernelSnapshot resolves targetOS from kExtensionTargetOs for custom kTargetPlatform',
      () async {
        const boundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
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
              'package:my_app/main.dart',
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

    testWithoutContext('AssetBuildTarget.targetsFor and cCompilerConfigFromDefines validate compiler URIs and reject partial defines', () async {
      final List<AssetBuildTarget> customTargets = AssetBuildTarget.targetsFor(
        androidSdkProvider: null,
        buildDirectory: fileSystem.directory('/project/build'),
        buildMode: BuildMode.debug,
        environmentDefines: <String, String>{
          kBuildMode: BuildMode.debug.cliName,
          kTargetPlatform: 'custom-arm64',
          kExtensionTargetOs: 'custom_os',
          kExtensionTargetArch: 'arm64',
          kExtensionCCompilerCc: 'file:///opt/custom-sdk/llvm/bin/clang',
          kExtensionCCompilerAr: 'file:///opt/custom-sdk/llvm/bin/llvm-ar',
          kExtensionCCompilerLd: 'file:///opt/custom-sdk/llvm/bin/ld.lld',
        },
        fileSystem: fileSystem,
        supportedAssetTypes: <SupportedAssetTypes>[
          SupportedAssetTypes.codeAssets,
          SupportedAssetTypes.dataAssets,
        ],
        targetPlatform: TargetPlatform.unsupported,
        visualStudio: null,
      );

      expect(customTargets, hasLength(1));
      final AssetBuildTarget target = customTargets.single;
      expect(target, isA<CustomCodeAssetTarget>());
      final customTarget = target as CustomCodeAssetTarget;
      expect(customTarget.os, OS.fromString('custom_os'));
      expect(customTarget.os.name, 'custom_os');
      expect(customTarget.architecture, Architecture.arm64);
      await customTarget.setCCompilerConfig(
        processUtils: ProcessUtils(processManager: FakeProcessManager.empty(), logger: logger),
      );
      expect(
        customTarget.cCompilerConfigSync?.compiler,
        Uri.parse('file:///opt/custom-sdk/llvm/bin/clang'),
      );
      expect(
        customTarget.cCompilerConfigSync?.archiver,
        Uri.parse('file:///opt/custom-sdk/llvm/bin/llvm-ar'),
      );
      expect(
        customTarget.cCompilerConfigSync?.linker,
        Uri.parse('file:///opt/custom-sdk/llvm/bin/ld.lld'),
      );

      final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final CCompilerConfig? windowsCompiler = cCompilerConfigFromDefines(<String, String>{
        kExtensionCCompilerCc: r'C:\sdk\bin\clang.exe',
        kExtensionCCompilerAr: r'C:\sdk\bin\llvm-ar.exe',
        kExtensionCCompilerLd: r'C:\sdk\bin\lld-link.exe',
        kExtensionCCompilerEnvScript: r'C:\sdk\vcvarsall.bat',
        kExtensionCCompilerEnvScriptArgs: '["x64_arm64"]',
      }, fileSystem: windowsFs);
      expect(windowsCompiler?.compiler, Uri.parse('file:///C:/sdk/bin/clang.exe'));
      expect(windowsCompiler?.archiver, Uri.parse('file:///C:/sdk/bin/llvm-ar.exe'));
      expect(windowsCompiler?.linker, Uri.parse('file:///C:/sdk/bin/lld-link.exe'));
      expect(
        windowsCompiler?.windows.developerCommandPrompt?.script,
        Uri.parse('file:///C:/sdk/vcvarsall.bat'),
      );
      expect(
        windowsCompiler?.windows.developerCommandPrompt?.arguments,
        equals(<String>['x64_arm64']),
      );

      expect(
        () => cCompilerConfigFromDefines(<String, String>{
          kExtensionCCompilerCc: '/opt/custom-sdk/llvm/bin/clang',
        }, fileSystem: fileSystem),
        throwsToolExit(message: 'Partial C compiler configuration'),
      );
      expect(
        () => cCompilerConfigFromDefines(<String, String>{
          kExtensionCCompilerCc: '/opt/custom-sdk/llvm/bin/clang',
          kExtensionCCompilerAr: '/opt/custom-sdk/llvm/bin/llvm-ar',
          kExtensionCCompilerLd: '/opt/custom-sdk/llvm/bin/ld.lld',
          kExtensionCCompilerEnvScriptArgs: '["--arch"]',
        }, fileSystem: fileSystem),
        throwsToolExit(message: 'without "$kExtensionCCompilerEnvScript"'),
      );
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
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
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
            'package:my_app/main.dart',
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

    testUsingContext(
      'default resolveNativeAssetsConfig => null succeeds for hookless apps and throws actionable ToolExit when hooks are present',
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isNativeAssetsEnabled: true,
          isDartDataAssetsEnabled: true,
          isToolExtensionsEnabled: true,
        ),
      },
      () async {
        final Directory projectDir = fileSystem.directory('/project')..createSync(recursive: true);
        fileSystem.currentDirectory = projectDir;
        fileSystem.directory('/flutter').createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.7.0-0
flutter:
  uses-material-design: false
''');
        projectDir.childDirectory('lib').childFile('main.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}\n');
        writePackageConfigFiles(directory: projectDir, mainLibName: 'my_app');

        final featureFlags = TestFeatureFlags(
          isNativeAssetsEnabled: true,
          isDartDataAssetsEnabled: true,
          isToolExtensionsEnabled: true,
        );
        final extensionManager = ExtensionManager(
          entryPoints: <ExtensionEntryPoint>[_defaultHooksExtensionEntryPoint],
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
          projectFactory: FlutterProjectFactory(
            config: FakeConfig(),
            fileSystem: fileSystem,
            logger: logger,
          ),
        );

        Environment? capturedEnvironment;
        final cache = FakeCache(fileSystem: fileSystem, flutterRoot: '/flutter');
        final assembleCommand = AssembleCommand(
          androidContext: FakeAndroidContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            capturedEnvironment = environment;
          }),
          extensionBuildManager: buildManager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            cache: cache,
            fs: fileSystem,
            logger: logger,
            signals: FakeSignals(),
          ),
          xcode: null,
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(assembleCommand);
        await commandRunner.run(<String>[
          'assemble',
          '--output=/project/build/custom_hookless',
          '-dTargetPlatform=custom-hookless-arm64',
          '-dBuildMode=release',
          'copy_assets',
        ]);

        expect(capturedEnvironment, isNotNull);
        expect(capturedEnvironment!.defines[kExtensionCustomTargetPlatform], 'true');
        expect(capturedEnvironment!.defines.containsKey(kExtensionTargetOs), isFalse);

        const boundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';
        final processManager = FakeProcessManager.empty();
        final hooklessEnv = Environment.test(
          projectDir,
          artifacts: artifacts,
          defines: capturedEnvironment!.defines,
          fileSystem: fileSystem,
          inputs: <String, String>{},
          logger: logger,
          processManager: processManager,
          generateDartPluginRegistry: true,
        );
        hooklessEnv.buildDir.createSync(recursive: true);
        final String hooklessBuild = hooklessEnv.buildDir.path;
        final String flutterPatchedSdkPath = artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          mode: BuildMode.release,
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
              ...buildModeOptions(BuildMode.release, <String>[]),
              '--aot',
              '--tfa',
              '--packages',
              '/project/.dart_tool/package_config.json',
              '--output-dill',
              '$hooklessBuild/app.dill',
              '--depfile',
              '$hooklessBuild/kernel_snapshot_program.d',
              '--verbosity=error',
              '--recorded-uses=$hooklessBuild/recorded_uses.json',
              'package:my_app/main.dart',
            ],
            stdout: 'result $boundaryKey\n$boundaryKey\n$boundaryKey $hooklessBuild/app.dill 0\n',
            onRun: (_) {
              fileSystem
                  .file('$hooklessBuild/${KernelSnapshot.recordedUsesFileName}')
                  .writeAsStringSync(KernelSnapshot.recordedUsesEmptyContent);
            },
          ),
        );

        expect(await const DartPluginRegistrantTarget().canSkip(hooklessEnv), isFalse);
        await const KernelSnapshot().build(hooklessEnv);
        expect(processManager, hasNoRemainingExpectations);
        final emptyHookRunner = FakeFlutterNativeAssetsBuildRunner();
        await BuildHooks(buildRunner: emptyHookRunner).build(hooklessEnv);
        await LinkHooks(buildRunner: emptyHookRunner).build(hooklessEnv);
        await const InstallCodeAssets().build(hooklessEnv);
        expect(hooklessEnv.buildDir.childFile(InstallCodeAssets.nativeAssetsFilename), exists);

        final nonEmptyHookRunner = FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['my_app'],
        );
        await expectLater(
          () => BuildHooks(buildRunner: nonEmptyHookRunner).build(hooklessEnv),
          throwsToolExit(message: 'BuildTarget.resolveNativeAssetsConfig'),
        );
      },
    );
  });
}
