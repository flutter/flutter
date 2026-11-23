// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/experimental/config.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

final class _SecondaryConfigurationExtension extends ConfigurationExtension {
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

final class _FailingConfigurationExtension extends ConfigurationExtension {
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
  _FakeExtensionConnection({this.response, this.extensionName = 'fake_ext'});

  final Object? response;

  @override
  final String extensionName;

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async => response;
}

void _secondaryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_SecondaryConfigurationExtension()]);
}

final class _DomainErrorConfigurationExtension extends ConfigurationExtension {
  @override
  String get title => 'Custom Config';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    throw const ToolExtensionException('Config failed with actionable user error.');
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    throw const ToolExtensionException('Config options failed with actionable user error.');
  }
}

void _domainErrorConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _DomainErrorConfigurationExtension(),
  ], extensionName: 'custom_config_ext');
}

final class _HostConfigQueryExtension extends ConfigurationExtension {
  @override
  String get title => 'Host Query Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(
        name: 'enable-host-query',
        help: 'Enable host query feature.',
        environmentOverride: 'FLUTTER_HOST_QUERY_FLAG',
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: 'host-query-sdk',
        help: 'SDK path.',
        aliases: <String>['legacy-host-query-sdk'],
        environmentOverride: 'FLUTTER_HOST_QUERY_SDK',
      ),
      ConfigOption(name: 'host-query-unset', help: 'Unset option.'),
    ];
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    final Map<String, ExtensionRpcHandler> handlers = await super.initialize();
    return <String, ExtensionRpcHandler>{
      ...handlers,
      'readResolvedConfig': (Map<String, Object?> _) => getConfigurationValues(),
    };
  }
}

void _hostConfigQueryEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _HostConfigQueryExtension(),
  ], extensionName: 'host_query_ext');
}

void main() {
  group('ExtensionConfiguration Host Integration', () {
    testWithoutContext(
      'ExtensionConfiguration fetches feature flags and config options from single extension',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          toolContext: FakeToolContext(logger: logger),
        );
        addTearDown(manager.dispose);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final config = ExtensionConfiguration(
          extensions: manager.configurationExtensions,
          logger: logger,
        );

        final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
        expect(groups, hasLength(1));
        expect(groups.first.title, 'Linux Custom Extension Prototype');
        expect(groups.first.extensionName, 'flutter_tools_extension_linux_prototype');
        expect(
          groups.first.displayTitle,
          'Linux Custom Extension Prototype (package:flutter_tools_extension_linux_prototype)',
        );
        expect(groups.first.featureFlags.single.name, 'enable-linux-custom-prototype');
        expect(groups.first.featureFlags.single.enabledByDefault, isTrue);
        expect(groups.first.configOptions.single.name, 'linux-gtk-version');
        expect(groups.first.configOptions.single.value, '3');
      },
    );

    testWithoutContext(
      'ExtensionConfiguration aggregates and sorts settings lexicographically across extensions',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          toolContext: FakeToolContext(logger: logger),
        );
        addTearDown(manager.dispose);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final config = ExtensionConfiguration(
          extensions: <ConfigurationExtension>[
            _SecondaryConfigurationExtension(),
            ...manager.configurationExtensions,
          ],
          logger: logger,
        );

        final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
        expect(groups, hasLength(2));
        expect(groups[0].title, 'Secondary Configuration Extension');
        expect(groups[1].title, 'Linux Custom Extension Prototype');
      },
    );

    testWithoutContext('ExtensionConfiguration handles failing extensions gracefully without failing other extensions', () async {
      final logger = BufferLogger.test();
      final config = ExtensionConfiguration(
        extensions: <ConfigurationExtension>[
          _FailingConfigurationExtension(),
          _SecondaryConfigurationExtension(),
        ],
        logger: logger,
      );

      final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
      expect(groups, hasLength(1));
      expect(groups.first.title, 'Secondary Configuration Extension');
    });

    testWithoutContext(
      'ConfigurationExtensionClient warns on invalid and malformed RPC payloads',
      () async {
        final logger = BufferLogger.test();
        final invalidTypeClient = ConfigurationExtensionClient(
          _FakeExtensionConnection(response: 'not-a-list', extensionName: 'bad_ext'),
          logger: logger,
        );
        expect(await invalidTypeClient.getFeatureFlags(), isEmpty);
        expect(logger.warningText, contains('Extension "bad_ext" returned an invalid'));

        logger.clear();
        final malformedElementClient = ConfigurationExtensionClient(
          _FakeExtensionConnection(
            response: const <Object?>[
              <String, Object?>{'help': 'missing name'},
            ],
            extensionName: 'malformed_ext',
          ),
          logger: logger,
        );
        expect(await malformedElementClient.getConfigurations(), isEmpty);
        expect(logger.warningText, contains('Extension "malformed_ext" returned malformed'));
      },
    );

    testWithoutContext('ExtensionConfiguration logs warning with extension name and skips extension on ToolExtensionException', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(logger: logger),
      );
      addTearDown(manager.dispose);
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[
          _domainErrorConfigEntryPoint,
          _secondaryExtensionEntryPoint,
        ],
      );

      final config = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );

      final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
      expect(groups, hasLength(1));
      expect(groups.single.title, 'Secondary Configuration Extension');
      expect(
        logger.warningText,
        contains('Extension "custom_config_ext": Config failed with actionable user error.'),
      );
    });

    testWithoutContext('lookupSettingValue, setSettingValue, removeSettingValue, and inactiveSavedExtensionSettings manage nested extensions map', () {
      final fs = MemoryFileSystem.test();
      final config = Config.test(directory: fs.directory('/'));

      config.setValue('legacy-sdk', '/legacy/sdk');
      expect(
        ExtensionConfiguration.lookupSettingValue(
          config,
          'sdk-path',
          extensionName: 'ext_a',
          aliases: const <String>['legacy-sdk'],
        ),
        '/legacy/sdk',
      );

      ExtensionConfiguration.setSettingValue(
        config,
        'sdk-path',
        '/new/sdk',
        extensionName: 'ext_a',
        aliases: const <String>['legacy-sdk'],
      );
      expect(config.containsKey('legacy-sdk'), isFalse);
      expect(
        ExtensionConfiguration.lookupSettingValue(config, 'sdk-path', extensionName: 'ext_a'),
        '/new/sdk',
      );

      ExtensionConfiguration.setSettingValue(config, 'b-key', '2', extensionName: 'ext_b');
      ExtensionConfiguration.setSettingValue(config, 'a-key', '1', extensionName: 'ext_b');
      final Map<String, Map<String, Object?>> inactive =
          ExtensionConfiguration.inactiveSavedExtensionSettings(
            config,
            activeExtensionNames: const <String>{'ext_a'},
          );
      expect(inactive.keys.toList(), const <String>['ext_b']);
      expect(inactive['ext_b']!.keys.toList(), const <String>['a-key', 'b-key']);

      ExtensionConfiguration.removeSettingValue(config, 'sdk-path', extensionName: 'ext_a');
      ExtensionConfiguration.removeSettingValue(config, 'a-key', extensionName: 'ext_b');
      ExtensionConfiguration.removeSettingValue(config, 'b-key', extensionName: 'ext_b');
      expect(config.containsKey(ExtensionConfiguration.extensionsSettingsKey), isFalse);
    });

    testWithoutContext('resolveFeatureFlagValue and resolveConfigOptionValue honor environmentOverride, persisted settings, aliases, and defaults', () {
      final fs = MemoryFileSystem.test();
      final config = Config.test(directory: fs.directory('/'));
      const flag = FeatureFlag(
        name: 'enable-custom',
        help: 'Enable custom.',
        environmentOverride: 'FLUTTER_ENABLE_CUSTOM',
      );
      const option = ConfigOption(
        name: 'custom-sdk',
        help: 'SDK path.',
        aliases: <String>['legacy-sdk'],
        environmentOverride: 'FLUTTER_CUSTOM_SDK',
        value: '/default/sdk',
      );

      expect(
        ExtensionConfiguration.resolveFeatureFlagValue(
          config,
          flag,
          environment: const <String, String>{},
          extensionName: 'ext_a',
        ),
        isFalse,
      );
      expect(
        ExtensionConfiguration.resolveConfigOptionValue(
          config,
          option,
          environment: const <String, String>{},
          extensionName: 'ext_a',
        ),
        '/default/sdk',
      );

      config.setValue('legacy-sdk', '/legacy/sdk');
      ExtensionConfiguration.setSettingValue(config, 'enable-custom', true, extensionName: 'ext_a');
      expect(
        ExtensionConfiguration.resolveFeatureFlagValue(
          config,
          flag,
          environment: const <String, String>{},
          extensionName: 'ext_a',
        ),
        isTrue,
      );
      expect(
        ExtensionConfiguration.resolveConfigOptionValue(
          config,
          option,
          environment: const <String, String>{},
          extensionName: 'ext_a',
        ),
        '/legacy/sdk',
      );

      expect(
        ExtensionConfiguration.resolveFeatureFlagValue(
          config,
          flag,
          environment: const <String, String>{'FLUTTER_ENABLE_CUSTOM': 'false'},
          extensionName: 'ext_a',
        ),
        isFalse,
      );
      expect(
        ExtensionConfiguration.resolveConfigOptionValue(
          config,
          option,
          environment: const <String, String>{'FLUTTER_CUSTOM_SDK': '/env/sdk'},
          extensionName: 'ext_a',
        ),
        '/env/sdk',
      );
    });

    testWithoutContext('ToolExtensionService.getConfigurationValues queries host-resolved extension settings over RPC', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      hostConfig.setValue('legacy-host-query-sdk', '/legacy/sdk');
      ExtensionConfiguration.setSettingValue(
        hostConfig,
        'enable-host-query',
        true,
        extensionName: 'host_query_ext',
      );
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        entryPoints: const <ExtensionEntryPoint>[_hostConfigQueryEntryPoint],
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(
          config: hostConfig,
          logger: logger,
          platform: FakePlatform(
            environment: const <String, String>{'FLUTTER_HOST_QUERY_SDK': '/env/sdk'},
          ),
        ),
      );
      addTearDown(manager.dispose);
      await manager.ensureInitialized();

      final Object? resolved = await manager.connections.single.sendRequest(
        'config.readResolvedConfig',
      );
      expect(resolved, const <String, Object?>{
        'enable-host-query': true,
        'host-query-sdk': '/env/sdk',
      });
    });
  });

  group('ExtensionTerminalPrompter', () {
    testWithoutContext(
      'handlePromptForOption handles selection, default, quit, empty options, and invalid params',
      () async {
        final logger = BufferLogger.test();
        final terminal = _FakePromptTerminal(lines: <String?>['invalid', '2', '', 'q']);
        final prompter = ExtensionTerminalPrompter(
          toolContext: FakeToolContext(logger: logger, terminal: terminal),
        );

        expect(
          await prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Pick one',
            ToolExtensionService.promptOptionsParam: <String>['First', 'Second'],
            ToolExtensionService.promptDefaultChoiceIndexParam: 0,
          }),
          const <String, Object?>{ToolExtensionService.promptSelectedIndexKey: 1},
        );
        expect(
          await prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Pick default',
            ToolExtensionService.promptOptionsParam: <String>['First', 'Second'],
            ToolExtensionService.promptDefaultChoiceIndexParam: 0,
          }),
          const <String, Object?>{ToolExtensionService.promptSelectedIndexKey: 0},
        );
        expect(
          await prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Quit',
            ToolExtensionService.promptOptionsParam: <String>['First'],
          }),
          const <String, Object?>{ToolExtensionService.promptSelectedIndexKey: null},
        );
        expect(
          await prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Empty',
            ToolExtensionService.promptOptionsParam: <String>[],
          }),
          const <String, Object?>{ToolExtensionService.promptSelectedIndexKey: null},
        );

        await expectLater(
          prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Bad default',
            ToolExtensionService.promptOptionsParam: <String>['Only'],
            ToolExtensionService.promptDefaultChoiceIndexParam: 2,
          }),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
        await expectLater(
          prompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Missing options',
          }),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
      },
    );

    testWithoutContext(
      'handlePromptForInput handles input, default, EOF, echoMode restoration, and invalid params',
      () async {
        final logger = BufferLogger.test();
        final terminal = _FakePromptTerminal(lines: <String?>['secret-token', '', null]);
        final stdin = _FakeEchoStdin();
        final prompter = ExtensionTerminalPrompter(
          toolContext: FakeToolContext(
            logger: logger,
            stdio: _FakeEchoStdio(stdin),
            terminal: terminal,
          ),
        );

        expect(
          await prompter.handlePromptForInput(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Token',
            ToolExtensionService.promptEchoParam: false,
          }),
          const <String, Object?>{ToolExtensionService.promptValueKey: 'secret-token'},
        );
        expect(stdin.echoModeHistory, const <bool>[false, true]);
        expect(stdin.echoMode, isTrue);

        expect(
          await prompter.handlePromptForInput(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Path',
            ToolExtensionService.promptDefaultValueParam: '/default',
          }),
          const <String, Object?>{ToolExtensionService.promptValueKey: '/default'},
        );
        expect(
          await prompter.handlePromptForInput(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'EOF',
          }),
          const <String, Object?>{ToolExtensionService.promptValueKey: null},
        );
        await expectLater(
          prompter.handlePromptForInput(const <String, Object?>{
            ToolExtensionService.promptEchoParam: 'not-a-bool',
          }),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
      },
    );

    testWithoutContext(
      'fails fast with ToolExtensionException in --machine mode or non-interactive terminal',
      () async {
        final nonTtyPrompter = ExtensionTerminalPrompter(
          toolContext: FakeToolContext(
            terminal: _FakePromptTerminal(lines: <String?>[], stdinHasTerminal: false),
          ),
        );
        await expectLater(
          nonTtyPrompter.handlePromptForInput(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Enter value',
          }),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('non-interactive terminal'),
            ),
          ),
        );

        final machinePrompter = ExtensionTerminalPrompter(
          toolContext: FakeToolContext(terminal: _FakePromptTerminal(lines: <String?>[])),
        )..enableMachineMode();
        await expectLater(
          machinePrompter.handlePromptForOption(const <String, Object?>{
            ToolExtensionService.promptMessageParam: 'Pick',
            ToolExtensionService.promptOptionsParam: <String>['A'],
          }),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('--machine'),
            ),
          ),
        );
      },
    );
  });

  group('ConfigAction Host & RPC Validation', () {
    testWithoutContext('collectActionSettings scopes to ConfigOptions and settingsKeys and runConfigAction validates returned keys', () async {
      final fs = MemoryFileSystem.test();
      final config = Config.test(directory: fs.directory('/'));
      ExtensionConfiguration.setSettingValue(config, 'enable-flag', true, extensionName: 'act');
      ExtensionConfiguration.setSettingValue(config, 'sdk-dir', '/sdk', extensionName: 'act');
      ExtensionConfiguration.setSettingValue(config, 'cert-id', 'c1', extensionName: 'act');

      final ext = _TinyActionExtension();
      const option = ConfigOption(name: 'sdk-dir', help: 'SDK dir');
      const validAction = ConfigAction(
        name: 'update',
        help: 'Update',
        settingsKeys: <String>['cert-id'],
      );
      const invalidAction = ConfigAction(
        name: 'bad',
        help: 'Bad',
        settingsKeys: <String>['cert-id'],
      );

      final Map<String, String?> collected = ExtensionConfiguration.collectActionSettings(
        config,
        configActions: const <ConfigAction>[validAction],
        configOptions: const <ConfigOption>[option],
        extensionName: 'act',
      );
      expect(collected, const <String, String?>{'sdk-dir': '/sdk', 'cert-id': 'c1'});

      final group = ExtensionSettingsGroup(
        configActions: const <ConfigAction>[validAction, invalidAction],
        configOptions: const <ConfigOption>[option],
        extension: ext,
        extensionName: 'act',
        featureFlags: const <FeatureFlag>[],
        title: 'Tiny',
      );
      expect(group.actionOnlySettingsKeys, const <String>['cert-id']);

      expect(
        await ExtensionConfiguration.runConfigAction(
          action: validAction,
          currentSettings: collected,
          group: group,
        ),
        const <String, String?>{'sdk-dir': '/new-sdk', 'cert-id': 'c2'},
      );
      await expectLater(
        ExtensionConfiguration.runConfigAction(
          action: invalidAction,
          currentSettings: collected,
          group: group,
        ),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            contains('undeclared setting key "rogue-key"'),
          ),
        ),
      );
    });

    testWithoutContext(
      'ConfigurationExtension.runConfigAction RPC rejects invalid params',
      () async {
        final ext = _TinyActionExtension();
        final Map<String, ExtensionRpcHandler> handlers = await ext.initialize();
        final ExtensionRpcHandler handler = handlers['runConfigAction']!;
        final Matcher throwsInvalidParams = throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        );

        await expectLater(() => handler(const <String, Object?>{}), throwsInvalidParams);
        await expectLater(
          () => handler(const <String, Object?>{
            ConfigurationExtension.actionNameParam: 'update',
            ConfigurationExtension.currentSettingsParam: 'not-a-map',
          }),
          throwsInvalidParams,
        );
        await expectLater(
          () => handler(const <String, Object?>{
            ConfigurationExtension.actionNameParam: 'update',
            ConfigurationExtension.currentSettingsParam: <String, Object?>{'cert-id': 42},
          }),
          throwsInvalidParams,
        );
      },
    );
  });
}

class _FakePromptTerminal extends Fake implements AnsiTerminal {
  _FakePromptTerminal({required List<String?> lines, this.stdinHasTerminal = true})
    : _lines = Queue<String?>.of(lines);

  final Queue<String?> _lines;

  @override
  final bool stdinHasTerminal;

  @override
  bool usesTerminalUi = false;

  @override
  Future<String> readLine() async {
    if (_lines.isEmpty) {
      throw StateError('No element');
    }
    final String? next = _lines.removeFirst();
    if (next == null) {
      throw StateError('No element');
    }
    return next;
  }
}

class _FakeEchoStdin extends Fake implements Stdin {
  var _echoMode = true;
  final echoModeHistory = <bool>[];

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool value) {
    _echoMode = value;
    echoModeHistory.add(value);
  }
}

class _FakeEchoStdio extends FakeStdio {
  _FakeEchoStdio(this._stdin);

  final _FakeEchoStdin _stdin;

  @override
  Stream<List<int>> get stdin => _stdin;
}

final class _TinyActionExtension extends ConfigurationExtension {
  @override
  String get title => 'Tiny';

  @override
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    return switch (name) {
      'update' => const <String, String?>{'sdk-dir': '/new-sdk', 'cert-id': 'c2'},
      'bad' => const <String, String?>{'rogue-key': 'bad'},
      _ => throw ToolExtensionException('Unknown action: $name'),
    };
  }
}
