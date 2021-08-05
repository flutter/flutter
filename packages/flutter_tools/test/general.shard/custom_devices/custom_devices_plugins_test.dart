// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/custom_devices/custom_device.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/custom_devices_common.dart';
import '../../src/fakes.dart';

void main() {
  group('custom devices plugins', () {
    BufferLogger logger;
    MemoryFileSystem fileSystem;
    Directory directory;
    CustomDevicesConfig config;

    void writeAndLoadConfig(dynamic json) {
      writeCustomDevicesConfigFile(
        directory,
        json: json
      );

      config = CustomDevicesConfig.test(
        fileSystem: fileSystem,
        directory: directory,
        logger: logger,
      );
    }

    List<Directory> createFakePlugins(List<String> pluginNamesOrPaths) {
      const String pluginYamlTemplate = '''
  flutter:
    plugin:
      platforms:
        x-testembedder: {}
  ''';

      final List<Directory> directories = <Directory>[];
      final Directory fakePubCache = fileSystem.systemTempDirectory.childDirectory('cache');
      final File packagesFile = fileSystem.currentDirectory.childFile('.packages')
        ..createSync(recursive: true);
      for (final String nameOrPath in pluginNamesOrPaths) {
        final String name = fileSystem.path.basename(nameOrPath);
        final Directory pluginDirectory = (nameOrPath == name)
            ? fakePubCache.childDirectory(name)
            : fileSystem.directory(nameOrPath);
        packagesFile.writeAsStringSync(
            '$name:file://${pluginDirectory.childFile('lib').uri}\n',
            mode: FileMode.writeOnlyAppend);
        pluginDirectory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(pluginYamlTemplate.replaceAll('PLUGIN_CLASS', sentenceCase(camelCase(name))));
        pluginDirectory.childDirectory('x-testembedder').createSync(recursive: true);

        directories.add(pluginDirectory);
      }
      return directories;
    }

    setUp(() {
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
      directory = fileSystem.directory('custom_devices_config');

      fileSystem.currentDirectory.childFile('.packages').createSync(recursive: true);
    });

    testUsingContext(
      "building project with plugin support fails if native project directory doesn't exist",
      () async {
        writeAndLoadConfig(const <dynamic>[testConfigPluginsJson]);

        final CustomDevice device = CustomDevice(
          config: config.devices.single,
          logger: logger,
          processManager: FakeProcessManager.empty()
        );

        await expectLater(
          device.startApp(
            FakeLinuxApp(),
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
            bundleBuilder: FakeBundleBuilder()
          ),
          throwsToolExit(message: 'No testembedder project configured. See (...) to learn about adding custom embedder support to a project.'),
        );
      },
      overrides: <Type, dynamic Function()>{
        FileSystem: () => fileSystem,
        ProcessManager: () { assert(false); },
        CustomDevicesConfig: () => config,
        FeatureFlags: () => TestFeatureFlags(areCustomDevicesEnabled: true)
      },
    );

    testUsingContext(
      'building project with plugins invokes the correct commands',
      () async {
        bool postBuildHasRun = false;

        createFakePlugins(const <String>[
          'ctestplugin',
          'atestplugin',
          'btestplugin',
        ]);
        writeAndLoadConfig(const <dynamic>[testConfigPluginsJson]);

        // create the directory where our native project resides
        fileSystem.directory('x-testembedder').createSync();

        final CustomDevice device = CustomDevice(
          config: config.devices.single,
          logger: logger,
          processManager: FakeProcessManager.list(
            <FakeCommand>[
              FakeCommand(
                command: const <String>['testconfigurenativeproject', 'debug', 'atestplugin;btestplugin;ctestplugin', '/build/flutter_assets'],
                workingDirectory: fileSystem.currentDirectory.childDirectory('x-testembedder').path,
              ),
              FakeCommand(
                command: const <String>['testbuildnativeproject', 'debug', 'atestplugin;btestplugin;ctestplugin', '/build/flutter_assets'],
                workingDirectory: fileSystem.currentDirectory.childDirectory('x-testembedder').path,
              ),
              FakeCommand(
                command: const <String>['testpostbuild'],
                exitCode: -1, // stop the building / starting of the app here
                onRun: () => postBuildHasRun = true,
              ),
            ],
          ),
        );

        expect(
          await device.startApp(
            FakeLinuxApp(),
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
            bundleBuilder: FakeBundleBuilder()
          ),
          allOf(isA<LaunchResult>(), (LaunchResult r) => r.started == false)
        );
        expect(postBuildHasRun, true);
      },
      overrides: <Type, dynamic Function()>{
        FileSystem: () => fileSystem,
        ProcessManager: () { assert(false); },
        CustomDevicesConfig: () => config,
        FeatureFlags: () => TestFeatureFlags(areCustomDevicesEnabled: true)
      },
    );

    testUsingContext(
      'building project with plugins fails and prints output if configureNativeProject commands fails',
      () async {
        writeAndLoadConfig(const <dynamic>[testConfigPluginsJson]);
        fileSystem.directory('x-testembedder').createSync();

        final CustomDevice device = CustomDevice(
          config: config.devices.single,
          logger: logger,
          processManager: FakeProcessManager.list(
            <FakeCommand>[
              FakeCommand(
                command: const <String>['testconfigurenativeproject', 'debug', '', '/build/flutter_assets'],
                workingDirectory: fileSystem.currentDirectory.childDirectory('x-testembedder').path,
                exitCode: -1,
                stderr: 'some error'
              )
            ],
          ),
        );

        expect(
          await device.startApp(
            FakeLinuxApp(),
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
            bundleBuilder: FakeBundleBuilder()
          ),
          allOf(isA<LaunchResult>(), (LaunchResult r) => r.started == false)
        );
        expect(logger.errorText, contains('some error'));
      },
      overrides: <Type, dynamic Function()>{
        FileSystem: () => fileSystem,
        ProcessManager: () { assert(false); },
        CustomDevicesConfig: () => config,
        FeatureFlags: () => TestFeatureFlags(areCustomDevicesEnabled: true)
      },
    );

    testUsingContext(
      'building project with plugins fails and prints output if buildNativeProject commands fails',
      () async {
        writeAndLoadConfig(const <dynamic>[testConfigPluginsJson]);
        fileSystem.directory('x-testembedder').createSync();

        final CustomDevice device = CustomDevice(
          config: config.devices.single,
          logger: logger,
          processManager: FakeProcessManager.list(
            <FakeCommand>[
              FakeCommand(
                command: const <String>['testconfigurenativeproject', 'debug', '', '/build/flutter_assets'],
                workingDirectory: fileSystem.currentDirectory.childDirectory('x-testembedder').path,
              ),
              FakeCommand(
                command: const <String>['testbuildnativeproject', 'debug', '', '/build/flutter_assets'],
                workingDirectory: fileSystem.currentDirectory.childDirectory('x-testembedder').path,
                exitCode: -1,
                stderr: 'some error'
              ),
            ],
          ),
        );

        expect(
          await device.startApp(
            FakeLinuxApp(),
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
            bundleBuilder: FakeBundleBuilder()
          ),
          allOf(isA<LaunchResult>(), (LaunchResult r) => r.started == false)
        );
        expect(logger.errorText, contains('some error'));
      },
      overrides: <Type, dynamic Function()>{
        FileSystem: () => fileSystem,
        ProcessManager: () { assert(false); },
        CustomDevicesConfig: () => config,
        FeatureFlags: () => TestFeatureFlags(areCustomDevicesEnabled: true)
      },
    );
  });
}

class FakeLinuxApp extends Fake implements LinuxApp {
  @override
  String name = 'testapp';

  @override
  String executable(BuildMode buildMode) {
    switch (buildMode) {
      case BuildMode.debug:
        return 'debug/executable';
      case BuildMode.profile:
        return 'profile/executable';
      case BuildMode.release:
        return 'release/executable';
      default:
        throw StateError('Invalid mode: $buildMode');
    }
  }
}

class FakeBundleBuilder extends Fake implements BundleBuilder {
  FakeBundleBuilder([this.impl]);

  final BundleBuildFunction impl;

  @override
  Future<void> build({
    TargetPlatform platform,
    BuildInfo buildInfo,
    FlutterProject project,
    String mainPath,
    String manifestPath = defaultManifestPath,
    String applicationKernelFilePath,
    String depfilePath,
    String assetDirPath,
    @visibleForTesting BuildSystem buildSystem
  }) async {
    if (impl != null) {
      return impl(
        platform: platform,
        buildInfo: buildInfo,
        project: project,
        mainPath: mainPath,
        manifestPath: manifestPath,
        applicationKernelFilePath: applicationKernelFilePath,
        depfilePath: depfilePath,
        assetDirPath: assetDirPath,
        buildSystem: buildSystem
      );
    } else {
      return;
    }
  }
}
