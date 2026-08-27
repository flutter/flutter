// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/experimental/config.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';

class _SecondaryConfigurationExtension extends ConfigurationExtension {
  @override
  String get title => 'Secondary Configuration Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(name: 'enable-secondary-feature', help: 'Enable secondary feature flag'),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: 'secondary-config-key',
        help: 'Secondary configuration setting option',
        value: 'custom-value',
      ),
    ];
  }
}

class _FailingConfigurationExtension extends ConfigurationExtension {
  @override
  String get title => 'Failing Configuration Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    throw Exception('Simulated feature flags error');
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    throw Exception('Simulated config options error');
  }
}

class _FakeExtensionConnection extends Fake implements ExtensionConnection {
  _FakeExtensionConnection({this.response});

  final Object? response;

  @override
  Future<Object?> sendRequest(
    String method, [
    Object? params,
    Duration timeout = const Duration(seconds: 5),
  ]) async => response;
}

void _secondaryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_SecondaryConfigurationExtension()]);
}

void main() {
  group('ExtensionConfiguration Host Integration', () {
    testUsingContext(
      'ExtensionConfiguration fetches feature flags and config options from single extension',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(hostPlatform: HostPlatform.linux_x64, logger: logger);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final config = ExtensionConfiguration(
          extensions: manager.configurationExtensions,
          logger: logger,
        );

        final List<FeatureFlag> flags = await config.fetchFeatureFlags();
        expect(flags, hasLength(1));
        expect(flags.first.name, 'enable-linux-custom-prototype');
        expect(flags.first.enabledByDefault, isTrue);

        final List<ConfigOption> options = await config.fetchConfigurations();
        expect(options, hasLength(1));
        expect(options.first.name, 'linux-gtk-version');
        expect(options.first.value, '3');

        final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
        expect(groups, hasLength(1));
        expect(groups.first.title, 'Linux Custom Extension Prototype');
        expect(groups.first.featureFlags.first.name, 'enable-linux-custom-prototype');
        expect(groups.first.configOptions.first.name, 'linux-gtk-version');

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionConfiguration aggregates feature flags and config options across multiple extensions',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(hostPlatform: HostPlatform.linux_x64, logger: logger);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final config = ExtensionConfiguration(
          extensions: <ConfigurationExtension>[
            ...manager.configurationExtensions,
            _SecondaryConfigurationExtension(),
          ],
          logger: logger,
        );

        final List<FeatureFlag> flags = await config.fetchFeatureFlags();
        expect(flags, hasLength(2));
        expect(flags.map((e) => e.name), <String>[
          'enable-linux-custom-prototype',
          'enable-secondary-feature',
        ]);

        final List<ConfigOption> options = await config.fetchConfigurations();
        expect(options, hasLength(2));
        expect(options.map((e) => e.name), <String>['linux-gtk-version', 'secondary-config-key']);

        final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
        expect(groups, hasLength(2));
        expect(groups[0].title, 'Linux Custom Extension Prototype');
        expect(groups[1].title, 'Secondary Configuration Extension');

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ConfigCommand settingsText incorporates extension flags and options grouped by extension title',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(hostPlatform: HostPlatform.linux_x64, logger: logger);
        await manager.initialize(
          entryPoints: <ExtensionEntryPoint>[
            linuxExtensionEntryPoint,
            _secondaryExtensionEntryPoint,
          ],
        );

        final command = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: FakeToolContext(logger: logger),
          extensionManager: manager,
        );

        final String settingsOutput = await command.settingsText;
        expect(settingsOutput, contains('Extension Settings:'));
        expect(settingsOutput, contains('  Linux Custom Extension Prototype:'));
        expect(settingsOutput, contains('    enable-linux-custom-prototype: true'));
        expect(settingsOutput, contains('    linux-gtk-version: 3'));
        expect(settingsOutput, contains('  Secondary Configuration Extension:'));
        expect(settingsOutput, contains('    enable-secondary-feature: false'));
        expect(settingsOutput, contains('    secondary-config-key: custom-value'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ExtensionConfiguration handles failing extensions gracefully without failing other extensions',
      () async {
        final logger = BufferLogger.test();
        final config = ExtensionConfiguration(
          extensions: <ConfigurationExtension>[
            _FailingConfigurationExtension(),
            _SecondaryConfigurationExtension(),
          ],
          logger: logger,
        );

        final List<FeatureFlag> flags = await config.fetchFeatureFlags();
        expect(flags, hasLength(1));
        expect(flags.first.name, 'enable-secondary-feature');

        final List<ConfigOption> options = await config.fetchConfigurations();
        expect(options, hasLength(1));
        expect(options.first.name, 'secondary-config-key');

        final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
        expect(groups, hasLength(1));
        expect(groups.first.title, 'Secondary Configuration Extension');
      },
    );

    testUsingContext(
      'ConfigurationExtensionClient handles null and invalid responses gracefully',
      () async {
        final logger = BufferLogger.test();
        final clientWithNull = ConfigurationExtensionClient(
          _FakeExtensionConnection(),
          logger: logger,
        );

        expect(await clientWithNull.fetchTitle(), 'Tool Extension Configuration');
        expect(await clientWithNull.getFeatureFlags(), isEmpty);
        expect(await clientWithNull.getConfigurations(), isEmpty);

        final clientWithInvalid = ConfigurationExtensionClient(
          _FakeExtensionConnection(response: 'not-a-list'),
          logger: logger,
        );

        expect(await clientWithInvalid.getFeatureFlags(), isEmpty);
        expect(await clientWithInvalid.getConfigurations(), isEmpty);
      },
    );
  });
}
