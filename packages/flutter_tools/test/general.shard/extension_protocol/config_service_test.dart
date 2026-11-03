// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/commands/config.dart';
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
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async => response;
}

void _secondaryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_SecondaryConfigurationExtension()]);
}

class _DomainErrorConfigurationExtension extends ConfigurationExtension {
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

class _InteractiveSigningConfigExtension extends ConfigurationExtension {
  static const String kEnableSigning = 'enable-custom-signing';
  static const String kCustomSdkPath = 'custom-sdk-path';
  static const String kLegacySdkPath = 'legacy-custom-sdk';
  static const String kSigningCert = 'custom-signing-cert';
  static const String kSigningPassphrase = 'custom-signing-passphrase';
  static const String kSelectSigningAction = 'select-custom-signing-settings';
  static const String kSelectManyAction = 'select-many-signing-settings';
  static const String kClearSigningAction = 'clear-custom-signing-settings';
  static const String kReadOwnedValuesAction = 'read-owned-config-values';
  static const String kUndeclaredKeyAction = 'undeclared-key-action';

  var _featureFlagsFetchCount = 0;

  @override
  String get title => 'Custom Signing Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    _featureFlagsFetchCount++;
    return const <FeatureFlag>[
      FeatureFlag(name: kEnableSigning, help: 'Enable custom signing workflows.'),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: kCustomSdkPath,
        help: 'Path to custom SDK.',
        aliases: <String>[kLegacySdkPath],
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: kSelectSigningAction,
        help: 'Select custom signing certificate and passphrase interactively.',
        aliases: <String>['select-custom-cert'],
        settingsKeys: <String>[kSigningCert, kSigningPassphrase],
      ),
      ConfigAction(
        name: kSelectManyAction,
        help: 'Select from more than 9 options interactively.',
        settingsKeys: <String>[kSigningCert],
      ),
      ConfigAction(
        name: kClearSigningAction,
        help: 'Clear saved custom signing settings.',
        settingsKeys: <String>[kSigningCert, kSigningPassphrase],
      ),
      ConfigAction(
        name: kReadOwnedValuesAction,
        help: 'Snapshot owned configuration values via extension.getConfigurationValues.',
        settingsKeys: <String>[kSigningCert],
      ),
      ConfigAction(
        name: kUndeclaredKeyAction,
        help: 'Action returning an undeclared setting key.',
        settingsKeys: <String>[kSigningCert],
      ),
    ];
  }

  @override
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    switch (name) {
      case kClearSigningAction:
        return const <String, String?>{kSigningCert: null, kSigningPassphrase: null};
      case kSelectSigningAction:
        final String? selectedCert = await promptForOption(
          message: 'Select a signing certificate',
          options: const <String, String>{
            'cert-alpha': 'Developer Alpha (TEAM1)',
            'cert-beta': 'Developer Beta (TEAM2)',
          },
          defaultOptionId: 'cert-alpha',
        );
        if (selectedCert == null) {
          return const <String, String?>{};
        }
        final String? passphrase = await promptForInput(
          message: 'Enter certificate passphrase',
          defaultValue: 'default-secret',
          echo: false,
        );
        return <String, String?>{kSigningCert: selectedCert, kSigningPassphrase: passphrase};
      case kSelectManyAction:
        final String? selectedCert = await promptForOption(
          message: 'Select a certificate from full list',
          options: <String, String>{for (var i = 1; i <= 10; i++) 'cert-$i': 'Certificate $i'},
          defaultOptionId: 'cert-1',
        );
        return <String, String?>{kSigningCert: selectedCert};
      case kReadOwnedValuesAction:
        final Map<String, Object?> ownedValues = await getConfigurationValues();
        final List<String> summary =
            ownedValues.entries
                .map(
                  (MapEntry<String, Object?> entry) =>
                      '${entry.key}=${entry.value}(${entry.value.runtimeType})',
                )
                .toList()
              ..sort();
        return <String, String?>{
          kSigningCert: 'fetches=$_featureFlagsFetchCount;${summary.join(',')}',
        };
      case kUndeclaredKeyAction:
        return const <String, String?>{'unowned-secret-key': 'bad'};
      default:
        throw ToolExtensionException('Unknown action: $name');
    }
  }
}

void _interactiveSigningEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _InteractiveSigningConfigExtension(),
  ], extensionName: 'custom_signing_ext');
}

class _SingleSubscriptionStdin extends Stream<List<int>> with Fake implements Stdin {
  _SingleSubscriptionStdin(List<String> chunks)
    : _stream = Stream<List<int>>.fromIterable(chunks.map(utf8.encode));

  final Stream<List<int>> _stream;
  var _echoMode = true;
  var _lineMode = true;
  final echoModeHistory = <bool>[];

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool value) {
    _echoMode = value;
    echoModeHistory.add(value);
  }

  @override
  bool get lineMode => _lineMode;

  @override
  set lineMode(bool value) {
    _lineMode = value;
  }

  @override
  bool get hasTerminal => true;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class _EchoTrackingStdio extends FakeStdio {
  _EchoTrackingStdio(this._fakeStdin);

  final _SingleSubscriptionStdin _fakeStdin;

  @override
  bool get stdinHasTerminal => true;

  @override
  Stream<List<int>> get stdin => _fakeStdin;
}

void main() {
  group('ExtensionConfiguration Host Integration', () {
    testWithoutContext(
      'ExtensionConfiguration fetches feature flags and config options from single extension',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
        );
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
    );

    testWithoutContext('ExtensionConfiguration aggregates feature flags and config options across multiple extensions', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
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
    });

    testWithoutContext('ConfigCommand settingsText incorporates extension flags and options grouped by extension title', () async {
      final logger = BufferLogger.test();
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint, _secondaryExtensionEntryPoint],
      );

      final command = ConfigCommand(
        androidContext: FakeAndroidContext(),
        toolContext: FakeToolContext(logger: logger),
        featureFlags: featureFlags,
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
    });

    testWithoutContext('ExtensionConfiguration handles failing extensions gracefully without failing other extensions', () async {
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
    });

    testWithoutContext(
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

    testWithoutContext('ExtensionConfiguration logs warning with extension name and skips extension on ToolExtensionException', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
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

      final List<FeatureFlag> flags = await config.fetchFeatureFlags();
      expect(flags.map((FeatureFlag f) => f.name), const <String>['enable-secondary-feature']);
      expect(
        logger.warningText,
        contains('Extension "custom_config_ext": Config failed with actionable user error.'),
      );

      logger.clear();
      final List<ConfigOption> options = await config.fetchConfigurations();
      expect(options.map((ConfigOption o) => o.name), const <String>['secondary-config-key']);
      expect(
        logger.warningText,
        contains(
          'Extension "custom_config_ext": Config options failed with actionable user error.',
        ),
      );

      logger.clear();
      final List<ExtensionSettingsGroup> groups = await config.fetchExtensionSettings();
      expect(groups, hasLength(1));
      expect(groups.single.title, 'Secondary Configuration Extension');
      expect(
        logger.warningText,
        contains('Extension "custom_config_ext": Config failed with actionable user error.'),
      );
    });

    testWithoutContext('ToolExtensionService host RPC helpers throw StateError before peer attachment and FormatException on malformed responses', () async {
      final service = _SecondaryConfigurationExtension();

      await expectLater(
        service.getConfigurationValues(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('extension.getConfigurationValues'),
          ),
        ),
      );
      await expectLater(
        service.promptForOption(
          message: 'Select option',
          options: const <String, String>{'a': 'Option A'},
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('terminal.promptForOption'),
          ),
        ),
      );
      await expectLater(
        service.promptForInput(message: 'Enter text'),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('terminal.promptForInput'),
          ),
        ),
      );
    });

    testWithoutContext('extension.getConfigurationValues scopes returned keys to extension owned settings with native bool feature flags and zero re-entrant RPCs', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      hostConfig
        ..setValue('custom_signing_ext.enable-custom-signing', true)
        ..setValue('legacy-custom-sdk', '/opt/legacy-sdk')
        ..setValue('custom_signing_ext.custom-signing-cert', 'cert-alpha')
        ..setValue('other_ext.secret-key', 'should-not-leak')
        ..setValue('android-sdk', '/opt/android-sdk');

      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        config: hostConfig,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

      final extConfig = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );
      final List<ExtensionSettingsGroup> groups = await extConfig.fetchExtensionSettings();
      final ExtensionSettingsGroup group = groups.single;
      final ConfigAction readAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kReadOwnedValuesAction,
      );

      final Map<String, String?> updates = await extConfig.runConfigAction(
        extension: group.extension!,
        action: readAction,
        currentSettings: const <String, String?>{},
      );
      expect(
        updates[_InteractiveSigningConfigExtension.kSigningCert],
        'fetches=1;'
        'custom-sdk-path=/opt/legacy-sdk(String),'
        'custom-signing-cert=cert-alpha(String),'
        'enable-custom-signing=true(bool)',
      );

      // Prefixed setting takes precedence over unprefixed/alias fallback without re-querying getFeatureFlags().
      hostConfig.setValue('custom_signing_ext.custom-sdk-path', '/opt/scoped-sdk');
      final Map<String, String?> updated = await extConfig.runConfigAction(
        extension: group.extension!,
        action: readAction,
        currentSettings: const <String, String?>{},
      );
      expect(
        updated[_InteractiveSigningConfigExtension.kSigningCert],
        'fetches=1;'
        'custom-sdk-path=/opt/scoped-sdk(String),'
        'custom-signing-cert=cert-alpha(String),'
        'enable-custom-signing=true(bool)',
      );
    });

    testWithoutContext('terminal.promptForOption and terminal.promptForInput succeed on a single-subscription stdin stream with AnsiTerminal', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      final logger = BufferLogger.test();
      final fakeStdin = _SingleSubscriptionStdin(const <String>[
        '2',
        'super-secret-passphrase\n',
        'invalid\n',
        '99\n',
        'cert-2\n',
        '10\n',
      ]);
      final stdio = _EchoTrackingStdio(fakeStdin);
      final terminal = AnsiTerminal(stdio: stdio, platform: FakePlatform());

      final manager = ExtensionManager(
        config: hostConfig,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        stdio: stdio,
        terminal: terminal,
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

      final extConfig = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup group = (await extConfig.fetchExtensionSettings()).single;
      final ConfigAction selectAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kSelectSigningAction,
      );

      final Map<String, String?> updates = await extConfig.runConfigAction(
        extension: group.extension!,
        action: selectAction,
        currentSettings: const <String, String?>{},
      );

      expect(updates, const <String, String?>{
        _InteractiveSigningConfigExtension.kSigningCert: 'cert-beta',
        _InteractiveSigningConfigExtension.kSigningPassphrase: 'super-secret-passphrase',
      });
      expect(fakeStdin.echoModeHistory, containsAllInOrder(const <bool>[false, true]));
      expect(logger.statusText, contains('[1] Developer Alpha (TEAM1) (default)'));
      expect(logger.statusText, contains('[2] Developer Beta (TEAM2)'));
      expect(logger.statusText, contains('Select a signing certificate (or "q" to quit): '));
      expect(logger.statusText, contains('Enter certificate passphrase [default-secret]: '));

      // Also exercise > 9 options re-prompting on invalid input, out-of-range index, and raw key before accepting '10'.
      final ConfigAction selectManyAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kSelectManyAction,
      );
      final Map<String, String?> manyUpdates = await extConfig.runConfigAction(
        extension: group.extension!,
        action: selectManyAction,
        currentSettings: const <String, String?>{},
      );
      expect(manyUpdates, const <String, String?>{
        _InteractiveSigningConfigExtension.kSigningCert: 'cert-10',
      });
    });

    testWithoutContext('terminal.promptForOption and terminal.promptForInput fail with -32002 in non-TTY and --machine modes', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      final logger = BufferLogger.test();

      // 1. Non-TTY mode (Terminal.test() has stdinHasTerminal == false).
      final nonTtyManager = ExtensionManager(
        config: hostConfig,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        terminal: Terminal.test(),
      );
      addTearDown(nonTtyManager.dispose);
      await nonTtyManager.initialize(
        entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint],
      );

      final nonTtyConfig = ExtensionConfiguration(
        extensions: nonTtyManager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup nonTtyGroup =
          (await nonTtyConfig.fetchExtensionSettings()).single;
      final ConfigAction selectAction = nonTtyGroup.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kSelectSigningAction,
      );

      await expectLater(
        nonTtyConfig.runConfigAction(
          extension: nonTtyGroup.extension!,
          action: selectAction,
          currentSettings: const <String, String?>{},
        ),
        throwsA(
          isA<ToolExtensionException>()
              .having(
                (ToolExtensionException e) => e.code,
                'code',
                ToolExtensionException.nonInteractiveErrorCode,
              )
              .having(
                (ToolExtensionException e) => e.message,
                'message',
                contains('non-interactive terminal'),
              ),
        ),
      );

      // 2. --machine mode with an interactive terminal still fails with -32002.
      final machineStdio = _EchoTrackingStdio(_SingleSubscriptionStdin(const <String>['1']));
      final machineManager = ExtensionManager(
        config: hostConfig,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        stdio: machineStdio,
        terminal: AnsiTerminal(stdio: machineStdio, platform: FakePlatform()),
      )..enableMachineMode();
      addTearDown(machineManager.dispose);
      await machineManager.initialize(
        entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint],
      );

      final machineConfig = ExtensionConfiguration(
        extensions: machineManager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup machineGroup =
          (await machineConfig.fetchExtensionSettings()).single;

      await expectLater(
        machineConfig.runConfigAction(
          extension: machineGroup.extension!,
          action: selectAction,
          currentSettings: const <String, String?>{},
        ),
        throwsA(
          isA<ToolExtensionException>()
              .having(
                (ToolExtensionException e) => e.code,
                'code',
                ToolExtensionException.nonInteractiveErrorCode,
              )
              .having((ToolExtensionException e) => e.message, 'message', contains('"--machine"')),
        ),
      );
    });

    testWithoutContext('ExtensionConfiguration.runConfigAction rejects undeclared setting keys and invalid RPC params', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

      final extConfig = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup group = (await extConfig.fetchExtensionSettings()).single;
      final ConfigAction undeclaredAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kUndeclaredKeyAction,
      );

      await expectLater(
        extConfig.runConfigAction(
          extension: group.extension!,
          action: undeclaredAction,
          currentSettings: const <String, String?>{},
        ),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            contains('returned undeclared setting key "unowned-secret-key"'),
          ),
        ),
      );

      final ExtensionConnection connection = manager.connections.single;
      await expectLater(
        connection.sendRequest(
          ConfigurationExtension.runConfigActionMethod,
          params: const <String, Object?>{'name': ''},
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );
    });
  });
}
