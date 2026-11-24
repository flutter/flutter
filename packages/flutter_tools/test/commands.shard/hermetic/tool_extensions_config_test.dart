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

final class _AlphaConfigExtension extends ConfigurationExtension {
  static const kEnableAlpha = 'enable-alpha-platform';
  static const kEnableAlphaEnv = 'FLUTTER_ALPHA_PLATFORM';
  static const kAlphaSdkPath = 'alpha-sdk-path';
  static const kAlphaSdkEnv = 'FLUTTER_ALPHA_SDK_PATH';
  static const kLegacyAlphaSdkAlias = 'legacy-alpha-sdk-dir';
  static const kSigningCert = 'alpha-signing-cert';
  static const kSigningProfile = 'alpha-signing-profile';
  static const kSelectSigningAction = 'select-alpha-signing-settings';
  static const kSelectSigningAlias = 'select-alpha-signing-cert';
  static const kClearSigningAction = 'clear-alpha-signing-settings';
  static const kInvalidKeyAction = 'invalid-alpha-action';

  @override
  String get title => 'Alpha Platform Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(
        name: kEnableAlpha,
        help: 'Enable Alpha platform support.',
        enabledByDefault: true,
        environmentOverride: kEnableAlphaEnv,
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: kAlphaSdkPath,
        help: 'Path to the Alpha SDK installation.',
        aliases: <String>[kLegacyAlphaSdkAlias],
        environmentOverride: kAlphaSdkEnv,
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: kSelectSigningAction,
        help: 'Select Alpha signing settings interactively.',
        aliases: <String>[kSelectSigningAlias],
        settingsKeys: <String>[kSigningCert, kSigningProfile],
      ),
      ConfigAction(
        name: kClearSigningAction,
        help: 'Clear saved Alpha signing settings.',
        settingsKeys: <String>[kSigningCert, kSigningProfile],
      ),
      ConfigAction(
        name: kInvalidKeyAction,
        help: 'Returns an undeclared key.',
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
        return const <String, String?>{kSigningCert: null, kSigningProfile: null};
      case kSelectSigningAction:
        const certIds = <String>['cert-1', 'cert-2'];
        final int? chosen = await promptForOption(
          message: 'Select a signing certificate',
          options: const <String>['Alpha Dev 1', 'Alpha Dev 2'],
          defaultChoiceIndex: 0,
        );
        if (chosen == null) {
          return const <String, String?>{};
        }
        final String? profile = await promptForInput(
          message: 'Enter provisioning profile path',
          defaultValue: '/profiles/default.profile',
          echo: false,
        );
        return <String, String?>{kSigningCert: certIds[chosen], kSigningProfile: profile};
      case kInvalidKeyAction:
        return const <String, String?>{'undeclared-key': 'bad'};
      default:
        throw ToolExtensionException('Unsupported action: $name');
    }
  }
}

void _alphaConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _AlphaConfigExtension(),
  ], extensionName: 'alpha_platform_ext');
}

final class _ZetaCollidingConfigExtension extends ConfigurationExtension {
  @override
  String get title => 'Zeta Colliding Extension';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(name: 'list', help: 'Collides with built-in --list flag.'),
      FeatureFlag(name: 'verbose', help: 'Collides with global --verbose flag.'),
      FeatureFlag(
        name: _AlphaConfigExtension.kEnableAlpha,
        help: 'Collides with alpha_platform_ext feature flag.',
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(
        name: _AlphaConfigExtension.kLegacyAlphaSdkAlias,
        help: 'Primary name collides with earlier option alias.',
      ),
      ConfigOption(
        name: 'valid-zeta-opt',
        help: 'Valid option with colliding and duplicate aliases.',
        aliases: <String>[
          'valid-zeta-opt',
          'android-sdk',
          _AlphaConfigExtension.kLegacyAlphaSdkAlias,
          'valid-zeta-alias',
          'valid-zeta-alias',
        ],
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: _AlphaConfigExtension.kSelectSigningAlias,
        help: 'Primary action name collides with earlier action alias.',
      ),
      ConfigAction(
        name: 'valid-zeta-action',
        help: 'Valid action with colliding alias.',
        aliases: <String>['valid-zeta-alias'],
      ),
    ];
  }
}

void _zetaCollidingConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _ZetaCollidingConfigExtension(),
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

  group('ConfigCommand with Tool Extensions', () {
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

    ExtensionManager createManager({
      List<ExtensionEntryPoint> entryPoints = const <ExtensionEntryPoint>[_alphaConfigEntryPoint],
      Stdio? stdio,
      AnsiTerminal? terminal,
    }) {
      final manager = ExtensionManager(
        entryPoints: entryPoints,
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
      addTearDown(manager.dispose);
      return manager;
    }

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

    testWithoutContext('sorts extensions lexicographically, groups --help, and logs deterministic collision warnings', () async {
      final ExtensionManager manager = createManager(
        entryPoints: const <ExtensionEntryPoint>[
          _zetaCollidingConfigEntryPoint,
          _alphaConfigEntryPoint,
        ],
      );

      final command = ConfigCommand(
        androidContext: FakeAndroidContext(),
        extensionManager: manager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(config: hostConfig, fs: fs, logger: logger),
      );
      createTestCommandRunner(command, null, null, featureFlags);
      await command.initializeDynamicOptions();
      final ArgParser parser = command.argParser;

      final Option sdkOption = parser.options[_AlphaConfigExtension.kAlphaSdkPath]!;
      expect(sdkOption.isFlag, isFalse);
      expect(sdkOption.aliases, contains(_AlphaConfigExtension.kLegacyAlphaSdkAlias));

      final Option selectAction = parser.options[_AlphaConfigExtension.kSelectSigningAction]!;
      expect(selectAction.isFlag, isTrue);
      expect(selectAction.negatable, isFalse);
      expect(selectAction.aliases, contains(_AlphaConfigExtension.kSelectSigningAlias));

      final Option zetaOpt = parser.options['valid-zeta-opt']!;
      expect(zetaOpt.aliases, const <String>['valid-zeta-alias']);
      final Option zetaAction = parser.options['valid-zeta-action']!;
      expect(zetaAction.aliases, isEmpty);

      final String helpText = parser.usage;
      final int alphaIdx = helpText.indexOf(
        'Alpha Platform Extension (package:alpha_platform_ext)',
      );
      final int zetaIdx = helpText.indexOf('Zeta Colliding Extension (package:zeta_colliding_ext)');
      expect(alphaIdx, greaterThan(-1));
      expect(zetaIdx, greaterThan(alphaIdx));

      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--list" conflicts with an existing option and was skipped.',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--verbose" conflicts with an existing option and was skipped.',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" feature flag "--enable-alpha-platform" '
          'conflicts with an existing option registered by extension "alpha_platform_ext" and was skipped.',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config option "--legacy-alpha-sdk-dir" '
          'conflicts with an existing option registered by extension "alpha_platform_ext" and was skipped.',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config option alias "--android-sdk" for "--valid-zeta-opt" '
          'conflicts with an existing option and was skipped.',
        ),
      );
      expect(
        logger.warningText,
        contains(
          'Extension "zeta_colliding_ext" config action "--select-alpha-signing-cert" '
          'conflicts with an existing option registered by extension "alpha_platform_ext" and was skipped.',
        ),
      );

      // Even when a legacy alias collided on the CLI parser, setting or
      // clearing `--valid-zeta-opt` still cleans up that legacy top-level key.
      hostConfig.setValue(_AlphaConfigExtension.kLegacyAlphaSdkAlias, '/opt/stale-collided');
      await createScopedRunner(activeManager: manager)
          .run(<String>['config', '--valid-zeta-opt=/opt/new-value']);
      expect(hostConfig.containsKey(_AlphaConfigExtension.kLegacyAlphaSdkAlias), isFalse);

      hostConfig.setValue(_AlphaConfigExtension.kLegacyAlphaSdkAlias, '/opt/stale-collided');
      await createScopedRunner(activeManager: manager).run(<String>['config', '--valid-zeta-opt=']);
      expect(hostConfig.containsKey(_AlphaConfigExtension.kLegacyAlphaSdkAlias), isFalse);
    });

    testWithoutContext(
      'persists settings under nested extensions map and migrates/cleans up legacy alias keys',
      () async {
        hostConfig.setValue(_AlphaConfigExtension.kLegacyAlphaSdkAlias, '/opt/legacy-sdk');
        final ExtensionManager manager = createManager();
        final CommandRunner<void> runner = createScopedRunner(activeManager: manager);

        await runner.run(<String>[
          'config',
          '--${_AlphaConfigExtension.kLegacyAlphaSdkAlias}=/opt/new-sdk',
        ]);

        expect(hostConfig.containsKey(_AlphaConfigExtension.kLegacyAlphaSdkAlias), isFalse);
        expect(
          ExtensionConfiguration.lookupSettingValue(
            hostConfig,
            _AlphaConfigExtension.kAlphaSdkPath,
            extensionName: 'alpha_platform_ext',
          ),
          '/opt/new-sdk',
        );

        await runner.run(<String>['config', '--${_AlphaConfigExtension.kAlphaSdkPath}=']);
        expect(
          ExtensionConfiguration.lookupSettingValue(
            hostConfig,
            _AlphaConfigExtension.kAlphaSdkPath,
            extensionName: 'alpha_platform_ext',
          ),
          isNull,
        );
      },
    );

    testWithoutContext('runs ConfigAction with host prompts and clears settings', () async {
      final stdin = _SingleSubscriptionStdin(<String>['2\n', '/profiles/team2.profile\n']);
      final stdio = _InteractiveStdio(stdin);
      final terminal = AnsiTerminal(stdio: stdio, platform: platform);
      final ExtensionManager manager = createManager(stdio: stdio, terminal: terminal);

      await createScopedRunner(
        activeManager: manager,
        stdio: stdio,
        terminal: terminal,
      ).run(<String>['config', '--${_AlphaConfigExtension.kSelectSigningAlias}']);

      expect(stdin.echoMode, isTrue);
      expect(
        ExtensionConfiguration.lookupSettingValue(
          hostConfig,
          _AlphaConfigExtension.kSigningCert,
          extensionName: 'alpha_platform_ext',
        ),
        'cert-2',
      );
      expect(
        ExtensionConfiguration.lookupSettingValue(
          hostConfig,
          _AlphaConfigExtension.kSigningProfile,
          extensionName: 'alpha_platform_ext',
        ),
        '/profiles/team2.profile',
      );

      logger.clear();
      await createScopedRunner(activeManager: manager).run(<String>['config', '--list']);
      expect(logger.statusText, contains('    alpha-signing-cert: cert-2'));
      expect(logger.statusText, contains('    alpha-signing-profile: /profiles/team2.profile'));

      await createScopedRunner(activeManager: manager)
          .run(<String>['config', '--${_AlphaConfigExtension.kClearSigningAction}']);
      expect(
        ExtensionConfiguration.lookupSettingValue(
          hostConfig,
          _AlphaConfigExtension.kSigningCert,
          extensionName: 'alpha_platform_ext',
        ),
        isNull,
      );
    });

    testWithoutContext('ConfigAction fails on non-TTY, --machine, and undeclared keys', () async {
      final ExtensionManager manager = createManager();

      await expectLater(
        createScopedRunner(activeManager: manager)
            .run(<String>['config', '--${_AlphaConfigExtension.kSelectSigningAction}']),
        throwsToolExit(message: 'non-interactive terminal'),
      );

      final stdin = _SingleSubscriptionStdin(<String>['1\n']);
      final stdio = _InteractiveStdio(stdin);
      final terminal = AnsiTerminal(stdio: stdio, platform: platform);
      final ExtensionManager machineManager = createManager(stdio: stdio, terminal: terminal)
        ..enableMachineMode();
      await expectLater(
        createScopedRunner(
          activeManager: machineManager,
          stdio: stdio,
          terminal: terminal,
        ).run(<String>['config', '--${_AlphaConfigExtension.kSelectSigningAction}']),
        throwsToolExit(message: '--machine'),
      );

      await expectLater(
        createScopedRunner(activeManager: manager)
            .run(<String>['config', '--${_AlphaConfigExtension.kInvalidKeyAction}']),
        throwsToolExit(message: 'undeclared setting key "undeclared-key"'),
      );
    });

    testWithoutContext('flutter config --list renders environmentOverride, package headers, and inactive saved extension settings', () async {
      ExtensionConfiguration.setSettingValue(
        hostConfig,
        'saved-key',
        '/saved/value',
        extensionName: 'inactive_ext',
      );
      env[_AlphaConfigExtension.kEnableAlphaEnv] = 'false';
      env[_AlphaConfigExtension.kAlphaSdkEnv] = '/env/alpha-sdk';

      final ExtensionManager manager = createManager();
      final CommandRunner<void> runner = createScopedRunner(activeManager: manager);
      await runner.run(<String>['config', '--list']);

      expect(logger.statusText, isNot(contains('  extensions:')));
      expect(
        logger.statusText,
        contains('  Alpha Platform Extension (package:alpha_platform_ext):'),
      );
      expect(logger.statusText, contains('    enable-alpha-platform: false'));
      expect(logger.statusText, contains('    alpha-sdk-path: /env/alpha-sdk'));
      expect(logger.statusText, contains('Saved Extension Settings (inactive outside project):'));
      expect(logger.statusText, contains('  inactive_ext:\n    saved-key: /saved/value'));
    });

    testWithoutContext('unknown flag outside project prints extension project-scope hint when tool extensions are enabled', () async {
      final CommandRunner<void> runner = createScopedRunner();

      await expectLater(
        runner.run(<String>['config', '--unknown-extension-flag']),
        throwsA(
          isA<UsageException>().having(
            (UsageException e) => e.message,
            'message',
            allOf(
              contains('Could not find an option named "--unknown-extension-flag"'),
              contains('Extension configuration flags are provided by project extensions.'),
            ),
          ),
        ),
      );
    });
  });
}
