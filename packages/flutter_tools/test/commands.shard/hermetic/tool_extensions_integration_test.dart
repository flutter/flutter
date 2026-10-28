// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/experimental/project_extension_finder.dart';
import 'package:flutter_tools/src/experimental/templates.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_features.dart';
import 'package:flutter_tools/src/flutter_features_config.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Tool Extensions Integration - Disabled', () {
    testUsingContext(
      'ExtensionManager.ensureInitialized() is a no-op when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );

        await manager.ensureInitialized();
        expect(manager.connections, isEmpty);
        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'ConfigCommand does not output Extension Settings when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final configCommand = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: FakeToolContext(logger: testLogger),
          featureFlags: featureFlags,
          extensionManager: manager,
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--list']);
        expect(testLogger.statusText, isNot(contains('Extension Settings:')));

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'Doctor.diagnose does not execute extension validators when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final doctor = Doctor(logger: testLogger, clock: const SystemClock());

        await doctor.diagnose(extensionManager: manager);
        expect(testLogger.statusText, isNot(contains('Linux Custom Extension Prototype')));

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );
  });

  group('Tool Extensions Integration - Enabled', () {
    testUsingContext(
      'ExtensionManager.ensureInitialized() initializes connections when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );

        await manager.ensureInitialized();
        expect(manager.connections, isNotEmpty);
        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ConfigCommand outputs Extension Settings when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final configCommand = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: FakeToolContext(logger: testLogger),
          featureFlags: featureFlags,
          extensionManager: manager,
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--list']);
        expect(testLogger.statusText, contains('Extension Settings:'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'Doctor.diagnose executes extension validators when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final doctor = Doctor(logger: testLogger, clock: const SystemClock());

        await doctor.diagnose(extensionManager: manager);
        expect(testLogger.statusText, contains('[✓] Linux Custom Extension Prototype'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );
  });

  group('Tool Extensions Safe Mode & Custom Platforms', () {
    testWithoutContext('FLUTTER_NO_EXTENSIONS=1 overrides FLUTTER_TOOL_EXTENSIONS=true', () {
      final logger = BufferLogger.test();
      final platform = FakePlatform(
        environment: const <String, String>{
          'FLUTTER_TOOL_EXTENSIONS': 'true',
          'FLUTTER_NO_EXTENSIONS': '1',
        },
      );
      final config = Config.test(logger: logger);
      config.setValue('enable-tool-extensions', true);

      final flags = FlutterFeatureFlags(
        flutterVersion: FakeFlutterVersion(),
        featuresConfig: FlutterFeaturesConfig(
          globalConfig: config,
          platform: platform,
          projectManifest: null,
        ),
        platform: platform,
      );

      expect(flags.isToolExtensionsEnabled, isFalse);
    });

    testWithoutContext(
      'ConfigCommand skips extension settings when --no-extensions is passed',
      () async {
        const args = <String>['--no-extensions', 'config', '--list'];
        final logger = BufferLogger.test();
        final platform = FakePlatform(
          environment: const <String, String>{'FLUTTER_TOOL_EXTENSIONS': 'true'},
        );
        final featureFlags = FlutterFeatureFlags(
          flutterVersion: FakeFlutterVersion(),
          featuresConfig: FlutterFeaturesConfig(
            globalConfig: Config.test(logger: logger),
            platform: platform,
            projectManifest: null,
          ),
          platform: platform,
        );
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final toolContext = FakeToolContext(logger: logger);
        final configCommand = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: toolContext,
          featureFlags: featureFlags,
          extensionManager: manager,
        );
        final runner = FlutterCommandRunner(
          toolContext: toolContext,
          featureFlags: featureFlags,
          extensionManager: manager,
        )..addCommand(configCommand);

        await runner.run(args);
        expect(logger.statusText, isNot(contains('Extension Settings:')));
        expect(manager.connections, isEmpty);

        await manager.dispose();
      },
    );

    testWithoutContext(
      'disables ExtensionDevices discovery when --no-extensions is passed',
      () async {
        final logger = BufferLogger.test();
        final platform = FakePlatform(
          environment: const <String, String>{'FLUTTER_TOOL_EXTENSIONS': 'true'},
        );
        final featureFlags = FlutterFeatureFlags(
          flutterVersion: FakeFlutterVersion(),
          featuresConfig: FlutterFeaturesConfig(
            globalConfig: Config.test(logger: logger),
            platform: platform,
            projectManifest: null,
          ),
          platform: platform,
        );
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final toolContext = FakeToolContext(logger: logger);
        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );
        final discovery = ExtensionDevices(
          extensionBuildManager: buildManager,
          extensionManager: manager,
          fileSystem: toolContext.fs,
          logger: logger,
        );
        final probeCommand = _ExtensionDevicesProbeCommand(
          toolContext: toolContext,
          discovery: discovery,
        );
        final runner = FlutterCommandRunner(
          toolContext: toolContext,
          featureFlags: featureFlags,
          extensionManager: manager,
        )..addCommand(probeCommand);

        await runner.run(const <String>['--no-extensions', 'probe-devices']);
        expect(probeCommand.discoveredDevices, isEmpty);
        expect(manager.connections, isEmpty);

        await manager.dispose();
      },
    );

    testWithoutContext(
      'ExtensionTemplateManager discovers custom platforms and resolves package: template paths',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory projectDir = fs.directory('/workspace/app')..createSync(recursive: true);
        fs.currentDirectory = projectDir;

        projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: app
dev_dependencies:
  flutter_tools_extension_linux_prototype:
    path: ../flutter_tools_extension_linux_prototype
''');

        final Directory extDir = fs.directory('/workspace/flutter_tools_extension_linux_prototype')
          ..createSync(recursive: true);
        extDir.childFile('extension/flutter_tools/config.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: flutter_tools_extension_linux_prototype
host_platforms:
  - linux
services:
  - template
templates:
  - custom-linux-app
target_platforms:
  - custom_linux
''');
        extDir.childFile('bin/flutter_tools_extension_linux_prototype.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void main() {}');
        final Directory templateSourceDir = extDir.childDirectory('lib/templates/custom-linux-app')
          ..createSync(recursive: true);
        templateSourceDir
            .childFile('.custom_device_extension_info.copy.tmpl')
            .writeAsStringSync('Verified\n');

        projectDir.childFile('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'configVersion': 2,
              'packages': <Map<String, Object?>>[
                <String, Object?>{'name': 'app', 'rootUri': '../', 'packageUri': 'lib/'},
                <String, Object?>{
                  'name': 'flutter_tools_extension_linux_prototype',
                  'rootUri': '../../flutter_tools_extension_linux_prototype',
                  'packageUri': 'lib/',
                },
              ],
            }),
          );

        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          extensionFinder: ProjectExtensionFinder(fileSystem: fs, logger: logger),
          featureFlags: featureFlags,
        );
        final templateManager = ExtensionTemplateManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          fileSystem: fs,
          logger: logger,
        );

        final Set<String> customPlatforms = await templateManager.getCustomPlatforms(
          projectDir: projectDir,
        );
        expect(customPlatforms, contains('custom_linux'));

        final Directory resolvedDir = templateManager.resolveTemplateDirectory(
          'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
        );
        expect(resolvedDir.path, templateSourceDir.path);
        expect(resolvedDir.existsSync(), isTrue);

        expect(
          () => templateManager.resolveTemplateDirectory(
            'package:flutter_tools_extension_linux_prototype/../outside',
          ),
          throwsArgumentError,
        );

        await manager.dispose();
      },
    );
  });
}

final class _ExtensionDevicesProbeCommand extends FlutterCommand {
  _ExtensionDevicesProbeCommand({required super.toolContext, required this.discovery});

  final ExtensionDevices discovery;
  List<Device> discoveredDevices = const <Device>[];

  @override
  String get name => 'probe-devices';

  @override
  String get description => 'Probes ExtensionDevices during command execution.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    discoveredDevices = await discovery.devices();
    return FlutterCommandResult.success();
  }
}
