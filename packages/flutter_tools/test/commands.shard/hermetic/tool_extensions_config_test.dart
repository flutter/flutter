// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/experimental/config.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

final class _AlphaConfigExtension extends ConfigurationExtension {
  static const kEnableAlpha = 'enable-alpha-platform';
  static const kEnableAlphaEnv = 'FLUTTER_ALPHA_PLATFORM';
  static const kAlphaSdkPath = 'alpha-sdk-path';
  static const kAlphaSdkEnv = 'FLUTTER_ALPHA_SDK_PATH';
  static const kLegacyAlphaSdkAlias = 'legacy-alpha-sdk-dir';

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
}

void _zetaCollidingConfigEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
    _ZetaCollidingConfigExtension(),
  ], extensionName: 'zeta_colliding_ext');
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
    }) {
      final manager = ExtensionManager(
        entryPoints: entryPoints,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(
          config: hostConfig,
          fs: fs,
          logger: logger,
          platform: platform,
        ),
      );
      addTearDown(manager.dispose);
      return manager;
    }

    CommandRunner<void> createScopedRunner({ExtensionManager? activeManager}) {
      final command = ConfigCommand(
        androidContext: FakeAndroidContext(),
        extensionManager: activeManager,
        featureFlags: featureFlags,
        toolContext: FakeToolContext(
          config: hostConfig,
          fs: fs,
          logger: logger,
          platform: platform,
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

      final Option zetaOpt = parser.options['valid-zeta-opt']!;
      expect(zetaOpt.aliases, const <String>['valid-zeta-alias']);

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
          'Extension "zeta_colliding_ext" config option alias "--valid-zeta-alias" for "--valid-zeta-opt" '
          'conflicts with an existing option in "zeta_colliding_ext" and was skipped.',
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
