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
  _FakeExtensionConnection({this.response});

  final Object? response;

  @override
  String get extensionName => 'fake_ext';

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async => response;
}

void _secondaryExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _SecondaryConfigurationExtension(),
  ], extensionName: 'secondary_config_ext');
}

final class _InteractiveSigningConfigExtension extends ConfigurationExtension {
  static const String kEnableSigning = 'enable-custom-signing';
  static const String kEnableSigningEnv = 'FLUTTER_CUSTOM_SIGNING';
  static const String kCustomSdkPath = 'custom-sdk-path';
  static const String kCustomSdkEnv = 'FLUTTER_CUSTOM_SDK_PATH';
  static const String kLegacySdkPath = 'legacy-custom-sdk';
  static const String kSigningCert = 'custom-signing-cert';
  static const String kSigningPassphrase = 'custom-signing-passphrase';
  static const String kSelectSigningAction = 'select-custom-signing-settings';
  static const String kClearSigningAction = 'clear-custom-signing-settings';
  static const String kReadOwnedValuesAction = 'read-owned-config-values';
  static const String kUpdateDeclaredOptionAction = 'update-declared-option-action';
  static const String kUndeclaredKeyAction = 'undeclared-key-action';

  var _featureFlagsFetchCount = 0;

  @override
  String get title => 'Custom Signing Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    _featureFlagsFetchCount++;
    return const <FeatureFlag>[
      FeatureFlag(
        name: kEnableSigning,
        help: 'Enable custom signing workflows.',
        environmentOverride: kEnableSigningEnv,
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: kCustomSdkPath,
        help: 'Path to custom SDK.',
        aliases: <String>[kLegacySdkPath],
        environmentOverride: kCustomSdkEnv,
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
        name: kUpdateDeclaredOptionAction,
        help: 'Action updating a declared ConfigOption key without repeating it in settingsKeys.',
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
        const certIds = <String>['cert-alpha', 'cert-beta'];
        const certLabels = <String>['Developer Alpha (TEAM1)', 'Developer Beta (TEAM2)'];
        final int? selectedIndex = await promptForOption(
          message: 'Select a signing certificate',
          options: certLabels,
          defaultChoiceIndex: 0,
        );
        if (selectedIndex == null) {
          return const <String, String?>{};
        }
        final String? passphrase = await promptForInput(
          message: 'Enter certificate passphrase',
          defaultValue: 'default-secret',
          echo: false,
        );
        return <String, String?>{
          kSigningCert: certIds[selectedIndex],
          kSigningPassphrase: passphrase,
        };
      case kReadOwnedValuesAction:
        final Map<String, Object?> ownedValues = await getConfigurationValues();
        final summary = <String>[
          for (final MapEntry(:String key, :Object? value) in ownedValues.entries)
            '$key=$value(${value.runtimeType})',
        ]..sort();
        return <String, String?>{
          kSigningCert: 'fetches=$_featureFlagsFetchCount;${summary.join(',')}',
        };
      case kUpdateDeclaredOptionAction:
        return const <String, String?>{
          kCustomSdkPath: '/opt/action-updated-sdk',
          kSigningCert: 'cert-alpha',
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
        toolContext: FakeToolContext(logger: logger),
      );
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[_secondaryExtensionEntryPoint, linuxExtensionEntryPoint],
      );

      final config = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
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
        toolContext: FakeToolContext(logger: logger),
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
      expect(
        settingsOutput,
        contains(
          '  Linux Custom Extension Prototype (package:flutter_tools_extension_linux_prototype):',
        ),
      );
      expect(settingsOutput, contains('    enable-linux-custom-prototype: true'));
      expect(settingsOutput, contains('    linux-gtk-version: 3'));
      expect(
        settingsOutput,
        contains('  Secondary Configuration Extension (package:secondary_config_ext):'),
      );
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
        expect(await clientWithNull.getConfigActions(), isEmpty);

        final clientWithInvalid = ConfigurationExtensionClient(
          _FakeExtensionConnection(response: 'not-a-list'),
          logger: logger,
        );

        expect(await clientWithInvalid.getFeatureFlags(), isEmpty);
        expect(await clientWithInvalid.getConfigurations(), isEmpty);
        expect(await clientWithInvalid.getConfigActions(), isEmpty);
        expect(logger.warningText, contains('Extension "fake_ext" returned an invalid'));

        logger.clear();
        final clientWithMalformedElement = ConfigurationExtensionClient(
          _FakeExtensionConnection(response: const <Object?>['not-a-map']),
          logger: logger,
        );
        expect(await clientWithMalformedElement.getFeatureFlags(), isEmpty);
        expect(logger.warningText, contains('Extension "fake_ext" returned malformed'));

        final clientWithNonStringActionUpdate = ConfigurationExtensionClient(
          _FakeExtensionConnection(response: const <String, Object?>{'key': 42}),
          logger: logger,
        );
        await expectLater(
          clientWithNonStringActionUpdate.runConfigAction(
            'action',
            currentSettings: const <String, String?>{},
          ),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('returned a non-string value for setting "key"'),
            ),
          ),
        );
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

    testWithoutContext(
      'ToolExtensionService host RPC helpers throw StateError before peer attachment',
      () async {
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
          service.promptForOption(message: 'Select option', options: const <String>['Option A']),
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
      },
    );

    testWithoutContext('extension.getConfigurationValues resolves nested settings and legacy aliases without re-entrant RPCs', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      hostConfig
        ..setValue('legacy-custom-sdk', '/opt/legacy-sdk')
        ..setValue('android-sdk', '/opt/android-sdk')
        ..setValue(ExtensionConfiguration.extensionsSettingsKey, <String, Object?>{
          'custom_signing_ext': <String, Object?>{
            'enable-custom-signing': true,
            'custom-signing-cert': 'cert-alpha',
          },
          'other_ext': <String, Object?>{'secret-key': 'should-not-leak'},
        });

      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(config: hostConfig, fs: fs, logger: logger),
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

      final extConfig = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup group = (await extConfig.fetchExtensionSettings()).single;
      final ConfigAction readAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kReadOwnedValuesAction,
      );

      final Map<String, String?> updates = await ExtensionConfiguration.runConfigAction(
        action: readAction,
        currentSettings: const <String, String?>{},
        group: group,
      );
      expect(
        updates[_InteractiveSigningConfigExtension.kSigningCert],
        'fetches=1;'
        'custom-sdk-path=/opt/legacy-sdk(String),'
        'custom-signing-cert=cert-alpha(String),'
        'enable-custom-signing=true(bool)',
      );

      // Nested `"extensions"` setting takes precedence over legacy top-level alias fallback without re-querying getFeatureFlags().
      ExtensionConfiguration.setSettingValue(
        hostConfig,
        _InteractiveSigningConfigExtension.kCustomSdkPath,
        '/opt/scoped-sdk',
        extensionName: 'custom_signing_ext',
      );
      final Map<String, String?> updated = await ExtensionConfiguration.runConfigAction(
        action: readAction,
        currentSettings: const <String, String?>{},
        group: group,
      );
      expect(
        updated[_InteractiveSigningConfigExtension.kSigningCert],
        'fetches=1;'
        'custom-sdk-path=/opt/scoped-sdk(String),'
        'custom-signing-cert=cert-alpha(String),'
        'enable-custom-signing=true(bool)',
      );
    });

    testWithoutContext(
      'extension.getConfigurationValues resolves environmentOverride ahead of persisted settings',
      () async {
        final fs = MemoryFileSystem.test();
        final hostConfig = Config.test(directory: fs.directory('/'));
        hostConfig.setValue(ExtensionConfiguration.extensionsSettingsKey, <String, Object?>{
          'custom_signing_ext': <String, Object?>{
            'enable-custom-signing': true,
            'custom-sdk-path': '/opt/scoped-sdk',
            'custom-signing-cert': 'cert-alpha',
          },
        });

        final env = <String, String>{
          _InteractiveSigningConfigExtension.kEnableSigningEnv: '0',
          _InteractiveSigningConfigExtension.kCustomSdkEnv: '/opt/env-sdk',
        };
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          toolContext: FakeToolContext(
            config: hostConfig,
            fs: fs,
            logger: logger,
            platform: FakePlatform(environment: env),
          ),
        );
        addTearDown(manager.dispose);
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

        final extConfig = ExtensionConfiguration(
          extensions: manager.configurationExtensions,
          logger: logger,
        );
        final ExtensionSettingsGroup group = (await extConfig.fetchExtensionSettings()).single;
        final ConfigAction readAction = group.configActions.firstWhere(
          (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kReadOwnedValuesAction,
        );

        final Map<String, String?> envOverridden = await ExtensionConfiguration.runConfigAction(
          action: readAction,
          currentSettings: const <String, String?>{},
          group: group,
        );
        expect(
          envOverridden[_InteractiveSigningConfigExtension.kSigningCert],
          'fetches=1;'
          'custom-sdk-path=/opt/env-sdk(String),'
          'custom-signing-cert=cert-alpha(String),'
          'enable-custom-signing=false(bool)',
        );
      },
    );

    testWithoutContext('terminal.promptForOption re-prompts on invalid input and terminal.promptForInput toggles echoMode on AnsiTerminal', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      final logger = BufferLogger.test();
      final fakeStdin = _SingleSubscriptionStdin(const <String>[
        'invalid\n',
        '99\n',
        '2\n',
        'super-secret-passphrase\n',
      ]);
      final stdio = _EchoTrackingStdio(fakeStdin);
      final terminal = AnsiTerminal(stdio: stdio, platform: FakePlatform());

      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(
          config: hostConfig,
          fs: fs,
          logger: logger,
          stdio: stdio,
          terminal: terminal,
        ),
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

      final Map<String, String?> updates = await ExtensionConfiguration.runConfigAction(
        action: selectAction,
        currentSettings: const <String, String?>{},
        group: group,
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
    });

    testWithoutContext('terminal.promptForOption and terminal.promptForInput fail with domainErrorCode (-32001) in non-TTY mode', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      final logger = BufferLogger.test();
      final nonTtyManager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(config: hostConfig, fs: fs, logger: logger),
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
        ExtensionConfiguration.runConfigAction(
          action: selectAction,
          currentSettings: const <String, String?>{},
          group: nonTtyGroup,
        ),
        throwsA(
          isA<ToolExtensionException>()
              .having(
                (ToolExtensionException e) => e.code,
                'code',
                ToolExtensionException.domainErrorCode,
              )
              .having(
                (ToolExtensionException e) => e.message,
                'message',
                contains('non-interactive terminal'),
              ),
        ),
      );
    });

    testWithoutContext('terminal.promptForOption rejects out-of-range defaultChoiceIndex with INVALID_PARAMS (-32602)', () async {
      final prompter = ExtensionTerminalPrompter(toolContext: FakeToolContext());
      await expectLater(
        prompter.handlePromptForOption(const <String, Object?>{
          'message': 'Pick one',
          'options': <String>['A', 'B'],
          'defaultChoiceIndex': 2,
        }),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );
    });

    testWithoutContext('terminal.promptForOption and terminal.promptForInput fail with domainErrorCode (-32001) in --machine mode', () async {
      final fs = MemoryFileSystem.test();
      final hostConfig = Config.test(directory: fs.directory('/'));
      final logger = BufferLogger.test();
      final machineStdio = _EchoTrackingStdio(_SingleSubscriptionStdin(const <String>['1\n']));
      final machineManager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(
          config: hostConfig,
          fs: fs,
          logger: logger,
          stdio: machineStdio,
          terminal: AnsiTerminal(stdio: machineStdio, platform: FakePlatform()),
        ),
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
      final ConfigAction selectAction = machineGroup.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kSelectSigningAction,
      );

      await expectLater(
        ExtensionConfiguration.runConfigAction(
          action: selectAction,
          currentSettings: const <String, String?>{},
          group: machineGroup,
        ),
        throwsA(
          isA<ToolExtensionException>()
              .having(
                (ToolExtensionException e) => e.code,
                'code',
                ToolExtensionException.domainErrorCode,
              )
              .having((ToolExtensionException e) => e.message, 'message', contains('"--machine"')),
        ),
      );
    });

    testWithoutContext('ExtensionConfiguration.runConfigAction allows updating declared ConfigOptions and rejects undeclared setting keys and invalid RPC params', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        toolContext: FakeToolContext(logger: logger),
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_interactiveSigningEntryPoint]);

      final extConfig = ExtensionConfiguration(
        extensions: manager.configurationExtensions,
        logger: logger,
      );
      final ExtensionSettingsGroup group = (await extConfig.fetchExtensionSettings()).single;

      final ConfigAction updateOptionAction = group.configActions.firstWhere(
        (ConfigAction a) =>
            a.name == _InteractiveSigningConfigExtension.kUpdateDeclaredOptionAction,
      );
      final Map<String, String?> optionUpdates = await ExtensionConfiguration.runConfigAction(
        action: updateOptionAction,
        currentSettings: const <String, String?>{},
        group: group,
      );
      expect(optionUpdates, const <String, String?>{
        _InteractiveSigningConfigExtension.kCustomSdkPath: '/opt/action-updated-sdk',
        _InteractiveSigningConfigExtension.kSigningCert: 'cert-alpha',
      });

      final ConfigAction undeclaredAction = group.configActions.firstWhere(
        (ConfigAction a) => a.name == _InteractiveSigningConfigExtension.kUndeclaredKeyAction,
      );
      await expectLater(
        ExtensionConfiguration.runConfigAction(
          action: undeclaredAction,
          currentSettings: const <String, String?>{},
          group: group,
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
