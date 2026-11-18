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
import 'package:flutter_tools/src/experimental/config.dart';
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
  static const String kEnableSigningEnv = 'FLUTTER_CUSTOM_SIGNING';
  static const String kUnlistedSigningFlag = 'enable-unlisted-signing-flag';
  static const String kCustomSdkPath = 'custom-sdk-path';
  static const String kCustomSdkEnv = 'FLUTTER_CUSTOM_SDK_PATH';
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
        environmentOverride: kEnableSigningEnv,
      ),
      FeatureFlag(
        name: kUnlistedSigningFlag,
        help: 'Unlisted feature flag not referenced by any ConfigAction.',
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
        environmentOverride: kCustomSdkEnv,
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
    if (currentSettings.containsKey(kUnlistedSigningFlag)) {
      throw const ToolExtensionException(
        'FeatureFlag keys must not leak into currentSettings unless declared in settingsKeys.',
      );
    }
    switch (name) {
      case kClearSigningAction:
        return const <String, String?>{kSigningCert: null, kSigningProfile: null};
      case kSelectSigningAction:
        const certIds = <String>['cert-1', 'cert-2'];
        const certLabels = <String>['Custom Developer 1 (TEAM1)', 'Custom Developer 2 (TEAM2)'];
        final String? existingCert = currentSettings[kSigningCert];
        final int defaultIndex = existingCert != null ? certIds.indexOf(existingCert) : 0;
        final int? chosenIndex = await promptForOption(
          message: 'Select a signing certificate',
          options: certLabels,
          defaultChoiceIndex: defaultIndex >= 0 ? defaultIndex : 0,
        );
        if (chosenIndex == null) {
          return const <String, String?>{};
        }
        final String? profilePath = await promptForInput(
          message: 'Enter provisioning profile path',
          defaultValue: '/profiles/default.profile',
          echo: false,
        );
        return <String, String?>{kSigningCert: certIds[chosenIndex], kSigningProfile: profilePath};
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
      FeatureFlag(name: 'verbose', help: 'Collides with global --verbose flag.'),
      FeatureFlag(
        name: _TestSigningConfigExtension.kEnableSigning,
        help: 'Collides with custom_signing_ext feature flag.',
      ),
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

void _zetaCollidingConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _CollidingConfigExtension(),
  ], extensionName: 'zeta_colliding_ext');
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
    late Map<String, String> env;
    late FakePlatform platform;
    late TestFeatureFlags featureFlags;

    setUp(() {
      fs = MemoryFileSystem.test();
      hostConfig = Config.test(directory: fs.directory('/'));
      logger = BufferLogger.test();
      env = <String, String>{};
      platform = FakePlatform(environment: env);
      featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
    });

    CommandRunner<void> createScopedRunner({
      ExtensionManager? activeManager,
      Stdio? stdio,
      AnsiTerminal? terminal,
    }) {
      final command = ConfigCommand(
        androidContext: FakeAndroidContext(),
        extensionManager: activeManager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(
          config: hostConfig,
          fs: fs,
          logger: logger,
          platform: platform,
          stdio: stdio,
          terminal: terminal,
        ),
      );
      return createTestCommandRunner(command, null, null, featureFlags);
    }

    testWithoutContext('sorts extensions lexicographically, groups --help under <title> (package:<name>), and logs collision warnings naming both packages', () async {
      // Pass zeta_colliding_ext before custom_signing_ext to verify deterministic lexicographical sorting.
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[
          _zetaCollidingConfigEntryPoint,
          _signingConfigEntryPoint,
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
      createTestCommandRunner(command, null, null, featureFlags);
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

      // Colliding primary names were skipped and logged as warnings naming both extensions.
      expect(parser.options.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);
      expect(parser.options.containsKey(_TestSigningConfigExtension.kSelectSigningAlias), isFalse);
      expect(parser.options.containsKey('verbose'), isFalse);
      final Option validOpt = parser.options['valid-colliding-ext-opt']!;
      expect(validOpt.aliases, const <String>['valid-ext-alias']);
      final Option validAction = parser.options['valid-colliding-ext-action']!;
      expect(validAction.aliases, isEmpty);

      final String helpText = command.usage;
      final int signingHeaderIndex = helpText.indexOf(
        'Custom Signing Extension (package:custom_signing_ext)',
      );
      final int collidingHeaderIndex = helpText.indexOf(
        'Colliding Config Extension (package:zeta_colliding_ext)',
      );
      expect(signingHeaderIndex, greaterThanOrEqualTo(0));
      expect(collidingHeaderIndex, greaterThan(signingHeaderIndex));

      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--list" conflicts with an existing option',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--verbose" conflicts with an existing option',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--enable-custom-signing" conflicts with an '
          'existing option registered by extension "custom_signing_ext"',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config option "--legacy-custom-sdk-dir" conflicts with an '
          'existing option registered by extension "custom_signing_ext"',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config option alias "--android-sdk" for "--valid-colliding-ext-opt" conflicts',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config action "--select-custom-signing-cert" conflicts with an '
          'existing option registered by extension "custom_signing_ext"',
        ),
      );
    });

    testWithoutContext('persists extension settings under nested "extensions" map, executes ConfigActions on AnsiTerminal, and cleans up legacy alias keys', () async {
      final stdio = _InteractiveStdio(_SingleSubscriptionStdin(const <String>['2', '\n']));
      final terminal = AnsiTerminal(stdio: stdio, platform: platform);
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        environment: env,
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        stdio: stdio,
        terminal: terminal,
      );
      addTearDown(manager.dispose);

      hostConfig.setValue(_TestSigningConfigExtension.kLegacySdkAlias, '/opt/stale-legacy-sdk');

      // 1. Set option via alias and feature flags via CLI.
      await createScopedRunner(activeManager: manager, stdio: stdio, terminal: terminal).run(
        <String>[
          'config',
          '--${_TestSigningConfigExtension.kLegacySdkAlias}=/opt/custom-sdk',
          '--no-${_TestSigningConfigExtension.kEnableSigning}',
          '--no-${_TestSigningConfigExtension.kUnlistedSigningFlag}',
        ],
      );

      final extensionsMap =
          hostConfig.getValue(ExtensionConfiguration.extensionsSettingsKey)!
              as Map<String, Object?>;
      final signingMap = extensionsMap['custom_signing_ext']! as Map<String, Object?>;
      expect(signingMap['custom-sdk-path'], '/opt/custom-sdk');
      expect(signingMap['enable-custom-signing'], isFalse);
      expect(signingMap['enable-unlisted-signing-flag'], isFalse);
      expect(hostConfig.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);

      // 2. Run interactive ConfigAction via alias flag (confirming unlisted FeatureFlag keys do not leak into currentSettings).
      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--${_TestSigningConfigExtension.kSelectSigningAlias}']);

      final updatedExtensions =
          hostConfig.getValue(ExtensionConfiguration.extensionsSettingsKey)!
              as Map<String, Object?>;
      final updatedSigning = updatedExtensions['custom_signing_ext']! as Map<String, Object?>;
      expect(updatedSigning['custom-signing-cert'], 'cert-2');
      expect(updatedSigning['custom-signing-profile'], '/profiles/default.profile');

      // 3. Verify `flutter config --list` skips `"extensions"` in `All Settings:` and displays `<title> (package:<name>):`.
      logger.clear();
      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--list']);
      expect(logger.statusText, isNot(contains('  extensions:')));
      expect(
        logger.statusText,
        contains('  Custom Signing Extension (package:custom_signing_ext):'),
      );
      expect(logger.statusText, contains('    enable-custom-signing: false'));
      expect(logger.statusText, contains('    custom-sdk-path: /opt/custom-sdk'));
      expect(logger.statusText, contains('    custom-signing-cert: cert-2'));
      expect(logger.statusText, contains('    custom-signing-profile: /profiles/default.profile'));

      // 4. Verify ConfigAction persists empty string (''), writes native bool for FeatureFlag, and removes legacy alias keys.
      hostConfig.setValue(_TestSigningConfigExtension.kLegacySdkAlias, '/opt/stale-alias');
      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--${_TestSigningConfigExtension.kEmptyAndBoolAction}']);
      final afterAction =
          (hostConfig.getValue(ExtensionConfiguration.extensionsSettingsKey)!
                  as Map<String, Object?>)['custom_signing_ext']!
              as Map<String, Object?>;
      expect(afterAction['custom-sdk-path'], '/opt/action-sdk');
      expect(hostConfig.containsKey(_TestSigningConfigExtension.kLegacySdkAlias), isFalse);
      expect(afterAction['custom-signing-profile'], '');
      expect(afterAction['enable-custom-signing'], isTrue);

      // 5. Clear signing settings via --clear-custom-signing-settings ConfigAction.
      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--${_TestSigningConfigExtension.kClearSigningAction}']);
      final afterClear =
          (hostConfig.getValue(ExtensionConfiguration.extensionsSettingsKey)!
                  as Map<String, Object?>)['custom_signing_ext']!
              as Map<String, Object?>;
      expect(afterClear.containsKey('custom-signing-cert'), isFalse);
      expect(afterClear.containsKey('custom-signing-profile'), isFalse);

      logger.clear();
      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--list']);
      expect(logger.statusText, contains('    custom-signing-cert: (Not set)'));
      expect(logger.statusText, contains('    custom-signing-profile: (Not set)'));
    });

    testWithoutContext('resolves environmentOverride ahead of persisted "extensions" settings in flutter config --list', () async {
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        environment: env,
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);

      hostConfig.setValue(ExtensionConfiguration.extensionsSettingsKey, <String, Object?>{
        'custom_signing_ext': <String, Object?>{
          _TestSigningConfigExtension.kEnableSigning: false,
          _TestSigningConfigExtension.kCustomSdkPath: '/opt/custom-sdk',
        },
      });
      env[_TestSigningConfigExtension.kEnableSigningEnv] = 'true';
      env[_TestSigningConfigExtension.kCustomSdkEnv] = '/opt/env-override-sdk';

      await createScopedRunner(activeManager: manager).run(<String>['config', '--list']);
      expect(logger.statusText, contains('    enable-custom-signing: true'));
      expect(logger.statusText, contains('    custom-sdk-path: /opt/env-override-sdk'));
    });

    testWithoutContext('displays inactive saved extension settings in flutter config --list inside and outside projects', () async {
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        environment: env,
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);

      hostConfig.setValue(ExtensionConfiguration.extensionsSettingsKey, <String, Object?>{
        'custom_signing_ext': <String, Object?>{
          _TestSigningConfigExtension.kCustomSdkPath: '/opt/custom-sdk',
        },
        'inactive_ext': <String, Object?>{'saved-path': '/opt/inactive-sdk'},
      });

      await createScopedRunner(activeManager: manager).run(<String>['config', '--list']);
      expect(
        logger.statusText,
        contains('  Custom Signing Extension (package:custom_signing_ext):'),
      );
      expect(logger.statusText, contains('Saved Extension Settings (inactive outside project):'));
      expect(logger.statusText, contains('  inactive_ext:\n    saved-path: /opt/inactive-sdk'));
      expect(logger.statusText, isNot(contains('  custom_signing_ext:')));

      logger.clear();
      await createScopedRunner().run(<String>['config', '--list']);
      expect(logger.statusText, isNot(contains('Extension Settings:\n')));
      expect(logger.statusText, contains('Saved Extension Settings (inactive outside project):'));
      expect(logger.statusText, contains('  custom_signing_ext:'));
      expect(logger.statusText, contains('  inactive_ext:'));
    });

    testWithoutContext('fails with ToolExit when interactive ConfigAction runs without a terminal or returns undeclared key', () async {
      final manager = ExtensionManager(
        config: hostConfig,
        entryPoints: const <ExtensionEntryPoint>[_signingConfigEntryPoint],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        terminal: Terminal.test(),
      );
      addTearDown(manager.dispose);

      await expectLater(
        createScopedRunner(activeManager: manager)
            .run(<String>['config', '--${_TestSigningConfigExtension.kSelectSigningAction}']),
        throwsToolExit(message: 'Cannot prompt for user input in a non-interactive terminal.'),
      );

      await expectLater(
        createScopedRunner(activeManager: manager)
            .run(<String>['config', '--${_TestSigningConfigExtension.kInvalidKeyAction}']),
        throwsToolExit(message: 'returned undeclared setting key "undeclared-key"'),
      );
    });
  });
}
