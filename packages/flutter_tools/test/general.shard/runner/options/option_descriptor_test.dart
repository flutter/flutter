// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../../src/common.dart';
import '../../../src/fakes.dart';
import '../../../src/test_flutter_command_runner.dart';

class _FakeCommand extends FlutterCommand {
  _FakeCommand({
    required this.name,
    required this.description,
    super.verboseHelp = false,
    List<OptionBundle> bundles = const <OptionBundle>[],
  }) : super(toolContext: FakeToolContext()) {
    registerOptionBundles(bundles);
  }

  @override
  final String name;

  @override
  final String description;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.success();
}

void main() {
  group('FlagOptionDescriptor', () {
    test('defaultsTo true returns true when omitted', () {
      const descriptor = FlagOptionDescriptor(
        name: 'test-flag',
        defaultsTo: true,
        help: 'Test flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.wasParsed(results), isFalse);
      expect(descriptor.getValue(results), isTrue);
    });

    test('defaultsTo false returns false when omitted', () {
      const descriptor = FlagOptionDescriptor(name: 'test-flag', help: 'Test flag help');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isFalse);
    });

    test('returns true when passed explicitly', () {
      const descriptor = FlagOptionDescriptor(name: 'test-flag', help: 'Test flag help');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--test-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isTrue);
    });

    test('returns false when negated explicitly', () {
      const descriptor = FlagOptionDescriptor(
        name: 'test-flag',
        defaultsTo: true,
        help: 'Test flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--no-test-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isFalse);
    });

    test('isRegistered reports true when added to parser and false when not', () {
      const descriptor = FlagOptionDescriptor(
        name: 'registered-flag',
        defaultsTo: true,
        help: 'Registered flag help',
      );
      const unaddedDescriptor = FlagOptionDescriptor(
        name: 'unadded-flag',
        defaultsTo: true,
        help: 'Unadded flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.isRegistered(results), isTrue);
      expect(unaddedDescriptor.isRegistered(results), isFalse);
    });
  });

  group('NullableFlagOptionDescriptor', () {
    test('returns null when omitted from command line', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('returns true when passed explicitly', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--tri-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isTrue);
    });

    test('returns false when negated explicitly', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--no-tri-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isFalse);
    });
  });

  group('StringOptionDescriptor', () {
    test('returns default value when omitted', () {
      const descriptor = StringOptionDescriptor(
        name: 'target',
        defaultsTo: 'lib/main.dart',
        help: 'Target entrypoint',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), 'lib/main.dart');
    });

    test('returns null when omitted without default value', () {
      const descriptor = StringOptionDescriptor(name: 'base-href', help: 'Base href');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('returns explicit value and respects aliases', () {
      const descriptor = StringOptionDescriptor(
        name: 'output',
        aliases: <String>['output-dir'],
        help: 'Output directory',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--output-dir=/tmp/build']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), '/tmp/build');
    });
  });

  group('MultiOptionDescriptor', () {
    test('returns empty list when omitted', () {
      const descriptor = MultiOptionDescriptor(name: 'define', help: 'Defines');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isEmpty);
    });

    test('returns default values when omitted with custom defaultsTo', () {
      const descriptor = MultiOptionDescriptor(
        name: 'tags',
        defaultsTo: <String>['alpha', 'beta'],
        help: 'Tags',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['tags']!.defaultsTo, <String>['alpha', 'beta']);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), <String>['alpha', 'beta']);
    });

    test('returns all parsed items in order', () {
      const descriptor = MultiOptionDescriptor(name: 'define', splitCommas: false, help: 'Defines');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--define=a=1', '--define=b=2']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), <String>['a=1', 'b=2']);
    });

    test('supports abbreviation and aliases', () {
      const descriptor = MultiOptionDescriptor(
        name: 'project-arg',
        abbr: 'P',
        aliases: <String>['project-args'],
        help: 'Project args',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['project-arg']!.abbr, 'P');
      expect(parser.options['project-arg']!.aliases, contains('project-args'));

      final ArgResults abbrResults = parser.parse(<String>['-P', 'key=val', '-P', 'key2=val2']);
      expect(descriptor.wasProvided(abbrResults), isTrue);
      expect(descriptor.getValue(abbrResults), <String>['key=val', 'key2=val2']);

      final ArgResults aliasResults = parser.parse(<String>['--project-args=foo=bar']);
      expect(descriptor.wasProvided(aliasResults), isTrue);
      expect(descriptor.getValue(aliasResults), <String>['foo=bar']);
    });
  });

  group('DefaultedStringOptionDescriptor', () {
    test('returns non-nullable default value when omitted', () {
      const descriptor = DefaultedStringOptionDescriptor(
        name: 'target',
        defaultsTo: 'lib/main.dart',
        help: 'Target entrypoint',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), 'lib/main.dart');
    });

    test('returns parsed string when provided', () {
      const descriptor = DefaultedStringOptionDescriptor(
        name: 'target',
        defaultsTo: 'lib/main.dart',
        help: 'Target entrypoint',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--target=lib/custom.dart']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), 'lib/custom.dart');
    });
  });

  group('IntOptionDescriptor', () {
    test('returns null when omitted without default', () {
      const descriptor = IntOptionDescriptor(name: 'port', help: 'Port number');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('parses valid integer string', () {
      const descriptor = IntOptionDescriptor(name: 'port', help: 'Port number');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--port=8080']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), 8080);
    });

    test('throws FormatException on invalid integer string', () {
      const descriptor = IntOptionDescriptor(name: 'port', help: 'Port number');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--port=not-an-int']);
      expect(() => descriptor.getValue(results), throwsA(isA<FormatException>()));
    });
  });

  group('DefaultedIntOptionDescriptor', () {
    test('returns default value when omitted', () {
      const descriptor = DefaultedIntOptionDescriptor(
        name: 'timeout',
        defaultsTo: 30,
        help: 'Timeout in seconds',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), 30);
    });

    test('returns parsed integer when provided', () {
      const descriptor = DefaultedIntOptionDescriptor(
        name: 'timeout',
        defaultsTo: 30,
        help: 'Timeout in seconds',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--timeout=60']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), 60);
    });

    test('throws FormatException on invalid integer string', () {
      const descriptor = DefaultedIntOptionDescriptor(
        name: 'timeout',
        defaultsTo: 30,
        help: 'Timeout in seconds',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--timeout=abc']);
      expect(() => descriptor.getValue(results), throwsA(isA<FormatException>()));
    });
  });

  group('EnumOptionDescriptor', () {
    test('derives allowed from enum values and returns null when omitted', () {
      const descriptor = EnumOptionDescriptor<_TestEnum>(
        name: 'mode',
        values: _TestEnum.values,
        help: 'Mode option',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['mode']!.allowed, <String>['firstOption', 'secondOption']);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('parses matching enum value', () {
      const descriptor = EnumOptionDescriptor<_TestEnum>(
        name: 'mode',
        values: _TestEnum.values,
        help: 'Mode option',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--mode=secondOption']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), _TestEnum.secondOption);
    });

    test('supports CliEnum auto-formatting for allowed and allowedHelp', () {
      const descriptor = EnumOptionDescriptor<_TestCliEnum>(
        name: 'strategy',
        values: _TestCliEnum.values,
        help: 'Strategy option',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['strategy']!.allowed, <String>['alpha-val', 'beta-val']);
      expect(parser.options['strategy']!.allowedHelp, <String, String>{
        'alpha-val': 'Help for alpha',
        'beta-val': 'Help for beta',
      });

      final ArgResults results = parser.parse(<String>['--strategy=beta-val']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), _TestCliEnum.beta);
    });

    test('supports custom nameMapper and valueParser', () {
      final descriptor = EnumOptionDescriptor<_TestEnum>(
        name: 'mode',
        values: _TestEnum.values,
        help: 'Mode option',
        nameMapper: (_TestEnum e) => e == _TestEnum.firstOption ? 'first' : 'second',
        valueParser: (String s) => s == 'first' ? _TestEnum.firstOption : _TestEnum.secondOption,
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['mode']!.allowed, <String>['first', 'second']);

      final ArgResults results = parser.parse(<String>['--mode=first']);
      expect(descriptor.getValue(results), _TestEnum.firstOption);
    });
  });

  group('DefaultedEnumOptionDescriptor', () {
    test('returns non-nullable default value when omitted', () {
      const descriptor = DefaultedEnumOptionDescriptor<_TestEnum>(
        name: 'mode',
        values: _TestEnum.values,
        defaultsTo: _TestEnum.firstOption,
        help: 'Mode option with default',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['mode']!.defaultsTo, 'firstOption');

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), _TestEnum.firstOption);
    });

    test('parses explicit enum value over default', () {
      const descriptor = DefaultedEnumOptionDescriptor<_TestEnum>(
        name: 'mode',
        values: _TestEnum.values,
        defaultsTo: _TestEnum.firstOption,
        help: 'Mode option with default',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--mode=secondOption']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), _TestEnum.secondOption);
    });
  });

  group('OptionDescriptor conflicts and identity', () {
    test('re-registering identical descriptor succeeds automatically via Expando', () {
      const descriptor = FlagOptionDescriptor(name: 'shared-flag', help: 'Shared flag');
      final parser = ArgParser();

      descriptor.addTo(parser);
      expect(() => descriptor.addTo(parser), returnsNormally);
      expect(() => parser.addDescriptor(descriptor), returnsNormally);
      expect(() => parser.addDescriptors(<OptionDescriptor<Object?>>[descriptor]), returnsNormally);
    });

    test('registering conflicting descriptor throws detailed ArgumentError', () {
      const first = FlagOptionDescriptor(name: 'conflict-flag', help: 'First flag');
      const second = FlagOptionDescriptor(name: 'conflict-flag', help: 'Second flag');
      final parser = ArgParser();

      first.addTo(parser);
      expect(
        () => second.addTo(parser),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            contains('Conflicting option descriptor registered for "conflict-flag"!'),
          ),
        ),
      );
    });
  });

  group('OptionBundle and Command Integration', () {
    testWithoutContext('registers options and provides typed values via SafeArgResults', () async {
      const flagOpt = FlagOptionDescriptor(name: 'fast', defaultsTo: true, help: 'Fast mode');
      const triFlagOpt = NullableFlagOptionDescriptor(name: 'optimize', help: 'Optimize');
      const stringOpt = StringOptionDescriptor(name: 'name', defaultsTo: 'app', help: 'App name');

      const bundle = _SimpleBundle(
        descriptors: <OptionDescriptor<Object?>>[flagOpt, triFlagOpt, stringOpt],
      );
      final command = _FakeCommand(
        name: 'build',
        description: 'Build command',
        bundles: const <OptionBundle>[bundle],
      );

      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['build', '--no-fast', '--optimize', '--name=custom']);

      expect(command.getValue(flagOpt), isFalse);
      expect(command.wasProvided(flagOpt), isTrue);

      expect(command.getValue(triFlagOpt), isTrue);
      expect(command.wasProvided(triFlagOpt), isTrue);

      expect(command.getValue(stringOpt), 'custom');
      expect(command.wasProvided(stringOpt), isTrue);
    });

    testWithoutContext('converts FormatException from IntOptionDescriptor into ToolExit', () async {
      const intOpt = IntOptionDescriptor(name: 'port', help: 'Server port');
      const bundle = _SimpleBundle(descriptors: <OptionDescriptor<Object?>>[intOpt]);
      final command = _FakeCommand(
        name: 'serve',
        description: 'Serve command',
        bundles: const <OptionBundle>[bundle],
      );

      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['serve', '--port=not-a-number']);

      expect(
        () => command.getValue(intOpt),
        throwsToolExit(message: 'Invalid integer value "not-a-number" for "--port".'),
      );
    });

    testWithoutContext('renders section separator titles in command usage', () {
      const bundle = _TitledBundle();
      final command = _FakeCommand(
        name: 'build',
        description: 'Build command',
        bundles: const <OptionBundle>[bundle],
      );
      createTestCommandRunner(command);

      expect(command.usage, contains('Section Header'));
      expect(command.usage, contains('--[no-]titled-flag'));
    });

    testWithoutContext(
      'auto-wires verboseHelp to dynamically hide or show verboseOnly options',
      () {
        const verboseFlag = FlagOptionDescriptor(
          name: 'internal-flag',
          verboseOnly: true,
          help: 'Internal flag help',
        );
        const standardFlag = FlagOptionDescriptor(name: 'public-flag', help: 'Public flag help');
        const bundle = _SimpleBundle(
          descriptors: <OptionDescriptor<Object?>>[verboseFlag, standardFlag],
        );

        final normalCommand = _FakeCommand(
          name: 'build',
          description: 'Build command',
          bundles: const <OptionBundle>[bundle],
        );

        createTestCommandRunner(normalCommand);

        expect(normalCommand.argParser.options['internal-flag']!.hide, isTrue);
        expect(normalCommand.argParser.options['public-flag']!.hide, isFalse);
        expect(normalCommand.usage, isNot(contains('internal-flag')));
        expect(normalCommand.usage, contains('public-flag'));

        final verboseCommand = _FakeCommand(
          name: 'build',
          description: 'Build command',
          verboseHelp: true,
          bundles: const <OptionBundle>[bundle],
        );
        createTestCommandRunner(verboseCommand);

        expect(verboseCommand.argParser.options['internal-flag']!.hide, isFalse);
        expect(verboseCommand.argParser.options['public-flag']!.hide, isFalse);
        expect(verboseCommand.usage, contains('internal-flag'));
        expect(verboseCommand.usage, contains('public-flag'));
      },
    );

    testWithoutContext(
      'AndroidGradleOptionsBundle registers Gradle options with verbose hiding',
      () {
        final normalCommand = _FakeCommand(
          name: 'apk',
          description: 'Build APK',
          bundles: const <OptionBundle>[AndroidGradleOptionsBundle()],
        );
        createTestCommandRunner(normalCommand);

        for (final name in const <String>[
          FlutterOptions.kAndroidGradleDaemon,
          FlutterOptions.kAndroidSkipBuildDependencyValidation,
          FlutterOptions.kAndroidProjectArgs,
          FlutterOptions.kAndroidGradleProjectCacheDir,
        ]) {
          expect(normalCommand.argParser.options.containsKey(name), isTrue);
          expect(normalCommand.argParser.options[name]!.hide, isTrue);
        }

        final verboseCommand = _FakeCommand(
          name: 'apk',
          description: 'Build APK',
          verboseHelp: true,
          bundles: const <OptionBundle>[AndroidGradleOptionsBundle()],
        );
        createTestCommandRunner(verboseCommand);

        for (final name in const <String>[
          FlutterOptions.kAndroidGradleDaemon,
          FlutterOptions.kAndroidSkipBuildDependencyValidation,
          FlutterOptions.kAndroidProjectArgs,
          FlutterOptions.kAndroidGradleProjectCacheDir,
        ]) {
          expect(verboseCommand.argParser.options[name]!.hide, isFalse);
        }
      },
    );

    testWithoutContext('AndroidBuildOptionsBundle registers Android and Gradle options', () {
      final command = _FakeCommand(
        name: 'apk',
        description: 'Build APK',
        bundles: const <OptionBundle>[AndroidBuildOptionsBundle()],
      );
      createTestCommandRunner(command);

      const allOptions = <OptionDescriptor<Object?>>[
        BuildInfoOptions.shrink,
        BuildInfoOptions.flavor,
        BuildInfoOptions.ignoreDeprecation,
        BuildInfoOptions.splitDebugInfo,
        BuildInfoOptions.obfuscate,
        BuildInfoOptions.extraFrontEndOptions,
        BuildInfoOptions.extraGenSnapshotOptions,
        BuildInfoOptions.performanceMeasurementFile,
        BuildInfoOptions.analyzeSize,
        BuildInfoOptions.codeSizeDirectory,
        BuildInfoOptions.trackWidgetCreation,
        DebuggingOptionDescriptors.enableHcpp,
        BuildInfoOptions.androidGradleDaemon,
        BuildInfoOptions.androidSkipBuildDependencyValidation,
        BuildInfoOptions.androidProjectArg,
        BuildInfoOptions.androidProjectCacheDir,
      ];

      for (final descriptor in allOptions) {
        expect(
          command.argParser.options.containsKey(descriptor.name),
          isTrue,
          reason: 'Option ${descriptor.name} should be registered',
        );
      }
    });

    testWithoutContext('AppleBuildOptionsBundle registers Apple build options', () {
      final command = _FakeCommand(
        name: 'ios',
        description: 'Build iOS',
        bundles: const <OptionBundle>[AppleBuildOptionsBundle()],
      );
      createTestCommandRunner(command);

      const allOptions = <OptionDescriptor<Object?>>[
        BuildInfoOptions.flavor,
        BuildInfoOptions.splitDebugInfo,
        BuildInfoOptions.obfuscate,
        BuildInfoOptions.extraFrontEndOptions,
        BuildInfoOptions.extraGenSnapshotOptions,
        BuildInfoOptions.performanceMeasurementFile,
        BuildInfoOptions.analyzeSize,
        BuildInfoOptions.codeSizeDirectory,
      ];

      for (final descriptor in allOptions) {
        expect(
          command.argParser.options.containsKey(descriptor.name),
          isTrue,
          reason: 'Option ${descriptor.name} should be registered',
        );
      }
    });

    testWithoutContext(
      'DarwinCodeSignXCFrameworksOptionsBundle registers codesign and codesign-identity',
      () {
        final command = _FakeCommand(
          name: 'ios-framework',
          description: 'Build iOS Framework',
          bundles: const <OptionBundle>[DarwinCodeSignXCFrameworksOptionsBundle()],
        );
        createTestCommandRunner(command);

        const allOptions = <OptionDescriptor<Object?>>[
          BuildInfoOptions.codesign,
          BuildInfoOptions.codesignIdentity,
        ];

        for (final descriptor in allOptions) {
          expect(
            command.argParser.options.containsKey(descriptor.name),
            isTrue,
            reason: 'Option ${descriptor.name} should be registered',
          );
        }
      },
    );

    testWithoutContext(
      'DarwinAddToAppOptionsBundle registers shared Darwin Add-to-App options and subBundles',
      () {
        final command = _FakeCommand(
          name: 'ios-framework',
          description: 'Build iOS Framework',
          bundles: const <OptionBundle>[DarwinAddToAppOptionsBundle()],
        );
        createTestCommandRunner(command);

        const allOptions = <OptionDescriptor<Object?>>[
          CommonOptions.treeShakeIcons,
          CommonOptions.target,
          CommonOptions.pub,
          BuildInfoOptions.splitDebugInfo,
          BuildInfoOptions.obfuscate,
          BuildInfoOptions.extraFrontEndOptions,
          BuildInfoOptions.extraGenSnapshotOptions,
          DarwinAddToAppOptionsBundle.staticFrameworks,
          CommonOptions.dartDefines,
          CommonOptions.dartDefineFromFile,
          CommonOptions.enableExperiment,
          BuildInfoOptions.codesign,
          BuildInfoOptions.codesignIdentity,
        ];

        for (final descriptor in allOptions) {
          expect(
            command.argParser.options.containsKey(descriptor.name),
            isTrue,
            reason: 'Option ${descriptor.name} should be registered',
          );
        }
      },
    );

    testWithoutContext('BuildModeOptionsBundle configures defaultBuildMode and respects excludeDebug and excludeRelease', () {
      final debugDefaultCommand = _FakeCommand(
        name: 'run',
        description: 'Run app',
        bundles: const <OptionBundle>[BuildModeOptionsBundle(defaultToRelease: false)],
      );
      createTestCommandRunner(debugDefaultCommand);

      expect(debugDefaultCommand.getBuildMode(), BuildMode.debug);
      expect(
        debugDefaultCommand.argParser.options.keys,
        containsAll(<String>['debug', 'profile', 'release', 'jit-release']),
      );

      final noReleaseCommand = _FakeCommand(
        name: 'attach',
        description: 'Attach to app',
        bundles: const <OptionBundle>[
          BuildModeOptionsBundle(defaultToRelease: false, excludeRelease: true),
        ],
      );
      createTestCommandRunner(noReleaseCommand);

      expect(noReleaseCommand.getBuildMode(), BuildMode.debug);
      expect(noReleaseCommand.argParser.options.keys, containsAll(<String>['debug', 'profile']));
      expect(noReleaseCommand.argParser.options, isNot(contains('release')));
      expect(noReleaseCommand.argParser.options, isNot(contains('jit-release')));

      final noDebugCommand = _FakeCommand(
        name: 'release-only',
        description: 'Release only',
        bundles: const <OptionBundle>[BuildModeOptionsBundle(excludeDebug: true)],
      );
      createTestCommandRunner(noDebugCommand);

      expect(noDebugCommand.getBuildMode(), BuildMode.release);
      expect(noDebugCommand.argParser.options.keys, containsAll(<String>['profile', 'release']));
      expect(noDebugCommand.argParser.options, isNot(contains('debug')));

      expect(
        // ignore: prefer_const_constructors
        () => BuildModeOptionsBundle(defaultToRelease: false, excludeDebug: true),
        throwsAssertionError,
      );
      expect(
        // ignore: prefer_const_constructors
        () => BuildModeOptionsBundle(excludeRelease: true),
        throwsAssertionError,
      );
    });

    testWithoutContext(
      'DeviceDiscoveryOptionsBundle, FilesystemOptionsBundle, VmServicePortOptionsBundle, '
      'DdsAndDevToolsOptionsBundle, ResidentCompilerOptionsBundle, and EngineRenderingFlagsBundle register expected options',
      () async {
        final command = _FakeCommand(
          name: 'run',
          description: 'Run app',
          bundles: const <OptionBundle>[
            DeviceDiscoveryOptionsBundle(includeDeviceUser: true),
            FilesystemOptionsBundle(),
            VmServicePortOptionsBundle(),
            DdsAndDevToolsOptionsBundle(),
            ResidentCompilerOptionsBundle(
              includeFrontendServerStarterPath: true,
              includeExtraDartFlags: true,
            ),
            EngineRenderingFlagsBundle(includeTestFlag: true),
          ],
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);
        await runner.run(<String>[
          'run',
          '--device-timeout=15',
          '--device-connection=attached',
          '--device-user=10',
          '--host-vmservice-port=8181',
          '--device-vmservice-port=8282',
          '--no-dds',
          '--ipv6',
        ]);

        expect(command.deviceDiscoveryTimeout, const Duration(seconds: 15));
        expect(command.getValue(CommonOptions.deviceUser), '10');
        expect(command.hostVmservicePort, 8181);
        expect(command.deviceVmservicePort, 8282);
        expect(command.ipv6, isTrue);

        const expectedDescriptors = <OptionDescriptor<Object?>>[
          CommonOptions.deviceTimeout,
          CommonOptions.deviceConnection,
          CommonOptions.deviceUser,
          BuildInfoOptions.outputDill,
          BuildInfoOptions.fileSystemRoot,
          BuildInfoOptions.fileSystemScheme,
          DebuggingOptionDescriptors.vmServicePort,
          DebuggingOptionDescriptors.deviceVmservicePort,
          DebuggingOptionDescriptors.hostVmservicePort,
          DebuggingOptionDescriptors.ipv6,
          DebuggingOptionDescriptors.ddsPort,
          DebuggingOptionDescriptors.dds,
          DebuggingOptionDescriptors.disableDds,
          DebuggingOptionDescriptors.enableDevTools,
          DebuggingOptionDescriptors.devToolsServerAddressOption,
          BuildInfoOptions.initializeFromDill,
          BuildInfoOptions.assumeInitializeFromDillUpToDate,
          BuildInfoOptions.nativeAssetsYamlFile,
          BuildInfoOptions.frontendServerStarterPath,
          BuildInfoOptions.extraFrontEndOptions,
          BuildInfoOptions.extraGenSnapshotOptions,
          DebuggingOptionDescriptors.enableImpeller,
          DebuggingOptionDescriptors.enableFlutterGpu,
          DebuggingOptionDescriptors.enableHcpp,
          DebuggingOptionDescriptors.enableVulkanValidation,
          DebuggingOptionDescriptors.enableEmbedderApi,
          DebuggingOptionDescriptors.testFlag,
        ];

        expect(
          command.argParser.options.keys,
          containsAll(expectedDescriptors.map((OptionDescriptor<Object?> d) => d.name)),
        );
      },
    );

    testWithoutContext('OptionBundle.register supports verboseHelp and hideOverride overrides for FlutterCommand helpers', () async {
      final command = _FakeCommand(name: 'helper-test', description: 'Helper delegation test');
      command.usesFilesystemOptions(hide: false);
      command.usesPortOptions(verboseHelp: true);
      command.addBuildModeFlags(verboseHelp: true, defaultToRelease: false, excludeRelease: true);

      expect(command.argParser.options['output-dill']!.hide, isFalse);
      expect(command.argParser.options['vm-service-port']!.hide, isFalse);
      expect(command.argParser.options, isNot(contains('ipv6')));
      expect(command.getBuildMode(), BuildMode.debug);
      expect(command.argParser.options.keys, containsAll(<String>['debug', 'profile']));
      expect(command.argParser.options, isNot(contains('release')));

      final hiddenCommand = _FakeCommand(name: 'hidden-test', description: 'Hidden override');
      const FilesystemOptionsBundle().register(
        hiddenCommand,
        hiddenCommand.argParser,
        verboseHelp: true,
        hideOverride: true,
      );
      expect(hiddenCommand.argParser.options['output-dill']!.hide, isTrue);
    });
  });
}

class _SimpleBundle extends OptionBundle {
  const _SimpleBundle({required this.descriptors});

  @override
  final List<OptionDescriptor<Object?>> descriptors;
}

class _TitledBundle extends OptionBundle {
  const _TitledBundle();

  @override
  String get title => 'Section Header';

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    FlagOptionDescriptor(name: 'titled-flag', help: 'Flag under title'),
  ];
}

enum _TestEnum { firstOption, secondOption }

enum _TestCliEnum implements CliEnum {
  alpha('alpha-val', 'Help for alpha'),
  beta('beta-val', 'Help for beta');

  const _TestCliEnum(this.cliName, this.helpText);

  @override
  final String cliName;

  @override
  final String helpText;
}
