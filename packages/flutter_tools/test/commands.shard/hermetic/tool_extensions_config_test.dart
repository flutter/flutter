// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

class _TestSigningConfigExtension extends ConfigurationExtension {
  static const String kEnableSigning = 'enable-custom-signing';
  static const String kCustomSdkPath = 'custom-sdk-path';
  static const String kLegacySdkAlias = 'legacy-custom-sdk-dir';
  static const String kSigningCert = 'custom-signing-cert';
  static const String kSigningProfile = 'custom-signing-profile';
  static const String kSelectSigningAction = 'select-custom-signing-settings';
  static const String kSelectSigningAlias = 'select-custom-signing-cert';
  static const String kClearSigningAction = 'clear-custom-signing-settings';
  static const String kEmptyAndBoolAction = 'set-empty-and-bool-settings';
  static const String kInvalidKeyAction = 'invalid-key-action';

  @override
  String get title => 'Custom Signing Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(
        name: kEnableSigning,
        help: 'Enable custom platform signing.',
        enabledByDefault: true,
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: kCustomSdkPath,
        help: 'The custom platform SDK installation directory.',
        aliases: <String>[kLegacySdkAlias],
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: kSelectSigningAction,
        help: 'Select and save custom signing settings interactively.',
        aliases: <String>[kSelectSigningAlias],
        settingsKeys: <String>[kSigningCert, kSigningProfile],
      ),
      ConfigAction(
        name: kClearSigningAction,
        help: 'Clear saved custom signing settings.',
        settingsKeys: <String>[kSigningCert, kSigningProfile],
      ),
      ConfigAction(
        name: kEmptyAndBoolAction,
        help: 'Persist empty string and boolean feature flag updates.',
        settingsKeys: <String>[kCustomSdkPath, kSigningProfile, kEnableSigning],
      ),
      ConfigAction(
        name: kInvalidKeyAction,
        help: 'Returns an undeclared key for validation testing.',
        settingsKeys: <String>[kSigningCert],
      ),
    ];
  }

  @override
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    if (currentSettings.containsKey(kEnableSigning)) {
      throw const ToolExtensionException(
        'FeatureFlag keys must not leak into currentSettings unless declared in settingsKeys.',
      );
    }
    switch (name) {
      case kClearSigningAction:
        return const <String, String?>{kSigningCert: null, kSigningProfile: null};
      case kSelectSigningAction:
        final String? existingCert = currentSettings[kSigningCert];
        final String? chosenCert = await promptForOption(
          message: 'Select a signing certificate',
          options: const <String, String>{
            'cert-1': 'Custom Developer 1 (TEAM1)',
            'cert-2': 'Custom Developer 2 (TEAM2)',
          },
          defaultOptionId: existingCert ?? 'cert-1',
        );
        if (chosenCert == null) {
          return const <String, String?>{};
        }
        final String? profilePath = await promptForInput(
          message: 'Enter provisioning profile path',
          defaultValue: '/profiles/default.profile',
          echo: false,
        );
        return <String, String?>{kSigningCert: chosenCert, kSigningProfile: profilePath};
      case kEmptyAndBoolAction:
        return const <String, String?>{
          kCustomSdkPath: '/opt/action-sdk',
          kSigningProfile: '',
          kEnableSigning: 'true',
        };
      case kInvalidKeyAction:
        return const <String, String?>{'undeclared-key': 'bad'};
      default:
        throw ToolExtensionException('Unsupported action: $name');
    }
  }
}

void _signingConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _TestSigningConfigExtension(),
  ], extensionName: 'custom_signing_ext');
}

class _CollidingConfigExtension extends ConfigurationExtension {
  @override
  String get title => 'Colliding Config Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(name: 'list', help: 'Collides with built-in --list flag.'),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: _TestSigningConfigExtension.kLegacySdkAlias,
        help: 'Primary name collides with earlier option alias.',
      ),
      ConfigOption(
        name: 'valid-colliding-ext-opt',
        help: 'Valid option with colliding and duplicate aliases.',
        aliases: <String>[
          'valid-colliding-ext-opt',
          'android-sdk',
          'valid-ext-alias',
          'valid-ext-alias',
        ],
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: _TestSigningConfigExtension.kSelectSigningAlias,
        help: 'Primary action name collides with earlier action alias.',
      ),
      ConfigAction(
        name: 'valid-colliding-ext-action',
        help: 'Valid action with colliding alias.',
        aliases: <String>['valid-ext-alias'],
      ),
    ];
  }
}

void _collidingConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _CollidingConfigExtension(),
  ], extensionName: 'colliding_ext');
}

class _SingleSubscriptionStdin extends Stream<List<int>> with Fake implements Stdin {
  _SingleSubscriptionStdin(List<String> chunks)
    : _stream = Stream<List<int>>.fromIterable(chunks.map(utf8.encode));

  final Stream<List<int>> _stream;
  var _echoMode = true;
  var _lineMode = true;

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool value) {
    _echoMode = value;
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

class _InteractiveStdio extends FakeStdio {
  _InteractiveStdio(this._stdin);

  final _SingleSubscriptionStdin _stdin;

  @override
  bool get stdinHasTerminal => true;

  @override
  Stream<List<int>> get stdin => _stdin;
}

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('ConfigCommand with Tool Extensions (N2)', () {
    late MemoryFileSystem fs;
    late Config hostConfig;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      hostConfig = Config.test(directory: fs.directory('/'));
      logger = BufferLogger.test();
    });

    testWithoutContext('registers ConfigOption aliases, non-negatable ConfigAction flags, and logs warnings on flag or alias collisions', () async {
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[
          _signingConfigEntryPoint,
          _collidingConfigEntryPoint,
        ],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);

      final command = ConfigCommand(
        androidContext: FakeAndroidContext(),
        extensionManager: manager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(config: hostConfig, fs: fs, logger: logger),
      );
      await command.initializeDynamicOptions();
      final ArgParser parser = command.argParser;

      final Option sdkOption = parser.options[_TestSigningConfigExtension.kCustomSdkPath]!;
      expect(sdkOption.isFlag, isFalse);
      expect(sdkOption.aliases, contains(_TestSigningConfigExtension.kLegacySdkAlias));

      final Option selectActionFlag =
          parser.options[_TestSigningConfigExtension.kSelectSigningAction]!;
      expect(selectActionFlag.isFlag, isTrue);
      expect(selectActionFlag.negatable, isFalse);
      expect(selectActionFlag.aliases, contains(_TestSigningConfigExtension.kSelectSigningAlias));

      final Option clearActionFlag =
          parser.options[_TestSigningConfigExtension.kClearSigningAction]!;
      expect(clearActionFlag.isFlag, isTrue);
      expect(clearActionFlag.negatable, isFalse);

      // Colliding primary names were skipped and logged as warnings with the extension name.
      expect(parser.options.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);
      expect(parser.options.containsKey(_TestSigningConfigExtension.kSelectSigningAlias), isFalse);
      final Option validOpt = parser.options['valid-colliding-ext-opt']!;
      expect(validOpt.aliases, const <String>['valid-ext-alias']);
      final Option validAction = parser.options['valid-colliding-ext-action']!;
      expect(validAction.aliases, isEmpty);

      expect(
        logger.warningText,
        contains(
          'Extension "colliding_ext" feature flag "--list" conflicts with an existing option',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "colliding_ext" config option "--legacy-custom-sdk-dir" conflicts with an existing option',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "colliding_ext" config option alias "--android-sdk" for "--valid-colliding-ext-opt" conflicts',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "colliding_ext" config action "--select-custom-signing-cert" conflicts with an existing option',
        ),
      );
    });

    testWithoutContext('persists extension settings under <extensionName>.<key>, executes ConfigActions on AnsiTerminal, and cleans up legacy/alias keys', () async {
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final stdio = _InteractiveStdio(_SingleSubscriptionStdin(const <String>['2', '\n']));
      final terminal = AnsiTerminal(stdio: stdio, platform: FakePlatform());
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        stdio: stdio,
        terminal: terminal,
      );
      addTearDown(manager.dispose);

      // Seed legacy unprefixed and alias keys to verify they are cleaned up when canonical keys are written.
      hostConfig
        ..setValue(_TestSigningConfigExtension.kLegacySdkAlias, '/opt/stale-legacy-sdk')
        ..setValue(_TestSigningConfigExtension.kCustomSdkPath, '/opt/stale-unprefixed-sdk');

      CommandRunner<void> createScopedRunner() {
        final command = ConfigCommand(
          androidContext: FakeAndroidContext(),
          extensionManager: manager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(
            config: hostConfig,
            fs: fs,
            logger: logger,
            stdio: stdio,
            terminal: terminal,
          ),
        );
        return createTestCommandRunner(command, null, null, featureFlags);
      }

      // 1. Set option via alias and feature flag via CLI.
      await createScopedRunner().run(<String>[
        'config',
        '--${_TestSigningConfigExtension.kLegacySdkAlias}=/opt/custom-sdk',
        '--no-${_TestSigningConfigExtension.kEnableSigning}',
      ]);

      expect(hostConfig.getValue('custom_signing_ext.custom-sdk-path'), '/opt/custom-sdk');
      expect(hostConfig.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);
      expect(hostConfig.containsKey(_TestSigningConfigExtension.kCustomSdkPath), isFalse);
      expect(hostConfig.getValue('custom_signing_ext.enable-custom-signing'), isFalse);

      // 2. Run interactive ConfigAction via alias flag (confirming FeatureFlag keys do not leak into currentSettings).
      await createScopedRunner().run(<String>[
        'config',
        '--${_TestSigningConfigExtension.kSelectSigningAlias}',
      ]);

      expect(hostConfig.getValue('custom_signing_ext.custom-signing-cert'), 'cert-2');
      expect(
        hostConfig.getValue('custom_signing_ext.custom-signing-profile'),
        '/profiles/default.profile',
      );

      // 3. Verify `flutter config --list` displays ConfigOption and ConfigAction.settingsKeys.
      logger.clear();
      await createScopedRunner().run(<String>['config', '--list']);
      expect(logger.statusText, contains('  Custom Signing Extension:'));
      expect(logger.statusText, contains('    enable-custom-signing: false'));
      expect(logger.statusText, contains('    custom-sdk-path: /opt/custom-sdk'));
      expect(logger.statusText, contains('    custom-signing-cert: cert-2'));
      expect(logger.statusText, contains('    custom-signing-profile: /profiles/default.profile'));

      // 4. Verify ConfigAction persists empty string (''), writes native bool for FeatureFlag, and removes legacy alias keys.
      hostConfig.setValue(_TestSigningConfigExtension.kLegacySdkAlias, '/opt/stale-alias');
      await createScopedRunner().run(<String>[
        'config',
        '--${_TestSigningConfigExtension.kEmptyAndBoolAction}',
      ]);
      expect(hostConfig.getValue('custom_signing_ext.custom-sdk-path'), '/opt/action-sdk');
      expect(hostConfig.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);
      expect(hostConfig.getValue('custom_signing_ext.custom-signing-profile'), '');
      expect(hostConfig.getValue('custom_signing_ext.enable-custom-signing'), isTrue);

      // 5. Clear signing settings via --clear-custom-signing-settings ConfigAction.
      await createScopedRunner().run(<String>[
        'config',
        '--${_TestSigningConfigExtension.kClearSigningAction}',
      ]);
      expect(hostConfig.getValue('custom_signing_ext.custom-signing-cert'), isNull);
      expect(hostConfig.getValue('custom_signing_ext.custom-signing-profile'), isNull);

      logger.clear();
      await createScopedRunner().run(<String>['config', '--list']);
      expect(logger.statusText, contains('    custom-signing-cert: (Not set)'));
      expect(logger.statusText, contains('    custom-signing-profile: (Not set)'));
    });

    testWithoutContext('fails with ToolExit when interactive ConfigAction runs without a terminal or returns undeclared key', () async {
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        terminal: Terminal.test(),
      );
      addTearDown(manager.dispose);

      CommandRunner<void> createScopedRunner() {
        final command = ConfigCommand(
          androidContext: FakeAndroidContext(),
          extensionManager: manager,
          featureFlags: featureFlags,
          toolContext: FakeToolContext(config: hostConfig, fs: fs, logger: logger),
        );
        return createTestCommandRunner(command, null, null, featureFlags);
      }

      await expectLater(
        createScopedRunner().run(<String>[
          'config',
          '--${_TestSigningConfigExtension.kSelectSigningAction}',
        ]),
        throwsToolExit(message: 'Cannot prompt for user input in a non-interactive terminal.'),
      );

      await expectLater(
        createScopedRunner().run(<String>[
          'config',
          '--${_TestSigningConfigExtension.kInvalidKeyAction}',
        ]),
        throwsToolExit(message: 'returned undeclared setting key "undeclared-key"'),
      );
    });
  });
}
