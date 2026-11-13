// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/emulators.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('EmulatorsCommand', () {
    late BufferLogger logger;
    late FakePlatform platform;
    late _FakeDoctor doctor;

    setUp(() {
      logger = BufferLogger.test();
      platform = FakePlatform();
      doctor = _FakeDoctor();
    });

    group('doctor validation', () {
      testWithoutContext(
        'throws ToolExit if no emulator sources are available on non-macOS',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final doctor = _FakeDoctor(canListEmulators: false);
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: FakeEmulatorManager(),
            toolContext: toolContext,
          );

          await expectLater(
            () => createTestCommandRunner(command).run(<String>['emulators']),
            throwsToolExit(
              message:
                  'Unable to find any emulator sources. Please ensure you have some\n'
                  'Android AVD images available.',
            ),
          );
        },
      );

      testWithoutContext('throws ToolExit if no emulator sources are available on macOS', () async {
        final macOSPlatform = FakePlatform(operatingSystem: 'macos');
        final toolContext = FakeToolContext(logger: logger, platform: macOSPlatform);
        final doctor = _FakeDoctor(canListEmulators: false);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: FakeEmulatorManager(),
          toolContext: toolContext,
        );

        await expectLater(
          () => createTestCommandRunner(command).run(<String>['emulators']),
          throwsToolExit(
            message:
                'Unable to find any emulator sources. Please ensure you have some\n'
                'Android AVD images or an iOS Simulator available.',
          ),
        );
      });

      testWithoutContext('proceeds when doctor reports canListEmulators is true', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final doctor = _FakeDoctor();
        final emulatorManager = FakeEmulatorManager();
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators']);
        expect(logger.statusText, contains('No emulators available.'));
      });

      testWithoutContext(
        'proceeds when built-in workflows cannot list emulators but extension sources exist',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final doctor = _FakeDoctor(canListEmulators: false);
          final emulatorManager = FakeEmulatorManager(
            extensionEmulatorSources: true,
            emulators: const <_FakeEmulator>[_FakeEmulator('custom_1', 'Custom Sim', 'Acme')],
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await createTestCommandRunner(command).run(<String>['emulators']);
          expect(logger.statusText, contains('1 available emulator:'));
          expect(logger.statusText, contains('Custom Sim'));
        },
      );
    });

    group('list emulators', () {
      testWithoutContext('shows message when no emulators available', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager();
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators']);

        expect(logger.statusText, contains('No emulators available.'));
        expect(
          logger.statusText,
          contains("To create a new emulator, run 'flutter emulators --create [--name xyz]'."),
        );
        expect(
          logger.statusText,
          contains('https://developer.android.com/studio/run/managing-avds'),
        );
      });

      testWithoutContext('lists available emulators with header', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        const emulators = <_FakeEmulator>[
          _FakeEmulator('nexus_5', 'Nexus 5', 'Google'),
          _FakeEmulator('pixel_6', 'Pixel 6', 'Google'),
        ];
        final emulatorManager = FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators']);

        expect(logger.statusText, contains('2 available emulators:'));
        expect(logger.statusText, contains('Nexus 5'));
        expect(logger.statusText, contains('Pixel 6'));
        expect(
          logger.statusText,
          contains("To run an emulator, run 'flutter emulators --launch <emulator id>'."),
        );
        expect(
          logger.statusText,
          contains("To create a new emulator, run 'flutter emulators --create [--name xyz]'."),
        );
      });

      testWithoutContext('filters emulators by search query', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        const emulators = <_FakeEmulator>[
          _FakeEmulator('nexus_5', 'Nexus 5', 'Google'),
          _FakeEmulator('pixel_6', 'Pixel 6', 'Google'),
        ];
        final emulatorManager = FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', 'pixel']);

        expect(logger.statusText, contains('1 available emulator:'));
        expect(logger.statusText, contains('Pixel 6'));
        expect(logger.statusText, isNot(contains('Nexus 5')));
      });
    });

    group('launch emulator', () {
      testWithoutContext('prints error when no matching emulator is found', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager();
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel']);

        expect(logger.statusText, contains("No emulator found that matches 'pixel'."));
      });

      testWithoutContext('prints list when multiple emulators match', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        const emulators = <_FakeEmulator>[
          _FakeEmulator('pixel_6', 'Pixel 6', 'Google'),
          _FakeEmulator('pixel_7', 'Pixel 7', 'Google'),
        ];
        final emulatorManager = FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel']);

        expect(logger.statusText, contains("More than one emulator matches 'pixel':"));
        expect(logger.statusText, contains('Pixel 6'));
        expect(logger.statusText, contains('Pixel 7'));
      });

      testWithoutContext('launches emulator when exactly one match found (warm boot)', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        var launchCount = 0;
        bool? lastColdBoot;
        final emulator = _FakeEmulator(
          'pixel_6',
          'Pixel 6',
          'Google',
          onLaunch: (bool coldBoot) {
            launchCount++;
            lastColdBoot = coldBoot;
          },
        );
        final emulatorManager = FakeEmulatorManager(emulators: <_FakeEmulator>[emulator]);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel_6']);

        expect(launchCount, 1);
        expect(lastColdBoot, isFalse);
      });

      testWithoutContext('launches emulator with cold boot when --cold is specified', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        var launchCount = 0;
        bool? lastColdBoot;
        final emulator = _FakeEmulator(
          'pixel_6',
          'Pixel 6',
          'Google',
          onLaunch: (bool coldBoot) {
            launchCount++;
            lastColdBoot = coldBoot;
          },
        );
        final emulatorManager = FakeEmulatorManager(emulators: <_FakeEmulator>[emulator]);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command)
            .run(<String>['emulators', '--launch', 'pixel_6', '--cold']);

        expect(launchCount, 1);
        expect(lastColdBoot, isTrue);
      });
    });

    group('create emulator', () {
      testWithoutContext('creates emulator successfully without name', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager(
          createResult: CreateEmulatorResult('flutter_emulator', success: true),
        );
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(logger.statusText, contains("Emulator 'flutter_emulator' created successfully."));
        expect(emulatorManager.lastCreatedName, isNull);
      });

      testWithoutContext('creates emulator successfully with custom name', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager(
          createResult: CreateEmulatorResult('my_custom_emulator', success: true),
        );
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command)
            .run(<String>['emulators', '--create', '--name', 'my_custom_emulator']);

        expect(logger.statusText, contains("Emulator 'my_custom_emulator' created successfully."));
        expect(emulatorManager.lastCreatedName, 'my_custom_emulator');
      });

      testWithoutContext('prints error and additional info when creation fails', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager(
          createResult: CreateEmulatorResult(
            'existing_emulator',
            success: false,
            error: 'AVD already exists',
          ),
        );
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(logger.statusText, contains("Failed to create emulator 'existing_emulator'."));
        expect(logger.statusText, contains('AVD already exists'));
        expect(
          logger.statusText,
          contains('https://developer.android.com/studio/run/managing-avds'),
        );
      });

      testWithoutContext('throws ToolExit when --platform is passed without --create', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: FakeEmulatorManager(),
          toolContext: toolContext,
        );

        await expectLater(
          () =>
              createTestCommandRunner(command)
                  .run(<String>['emulators', '--platform', 'custom_os']),
          throwsToolExit(message: 'The "--platform" option can only be used with "--create".'),
        );
      });

      testWithoutContext('throws ToolExit when --platform is empty', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: FakeEmulatorManager(),
          toolContext: toolContext,
        );

        await expectLater(
          () =>
              createTestCommandRunner(command)
                  .run(<String>['emulators', '--create', '--platform', '']),
          throwsToolExit(message: 'The "--platform" option must not be empty.'),
        );
      });

      testWithoutContext(
        'throws ToolExit listing available platforms when --platform is unknown',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final emulatorManager = FakeEmulatorManager(
            availableCreatePlatforms: const <String>['android', 'custom_os'],
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await expectLater(
            () =>
                createTestCommandRunner(command)
                    .run(<String>['emulators', '--create', '--platform', 'unknown_os']),
            throwsToolExit(
              message:
                  'Unknown emulator creation platform "unknown_os". '
                  'Available platforms: android, custom_os.',
            ),
          );
          expect(emulatorManager.lastCreatedPlatform, isNull);
        },
      );

      testWithoutContext(
        'throws ToolExit when --platform is unknown and no platforms are available',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final emulatorManager = FakeEmulatorManager();
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await expectLater(
            () =>
                createTestCommandRunner(command)
                    .run(<String>['emulators', '--create', '--platform', 'unknown_os']),
            throwsToolExit(
              message:
                  'Unknown emulator creation platform "unknown_os". '
                  'No emulator creation platforms are available.',
            ),
          );
          expect(emulatorManager.lastCreatedPlatform, isNull);
        },
      );

      testWithoutContext('delegates to EmulatorManager without prompting when single extension platform is available', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = FakeEmulatorManager(
          availableCreatePlatforms: const <String>['custom_os'],
          createResult: CreateEmulatorResult('custom_sim_1', success: true),
        );
        final command = EmulatorsCommand(
          doctor: _FakeDoctor(canListEmulators: false),
          emulatorManager: emulatorManager..extensionEmulatorSources = true,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(emulatorManager.lastCreatedPlatform, 'custom_os');
        expect(logger.statusText, contains("Emulator 'custom_sim_1' created successfully."));
      });

      testWithoutContext(
        'omits Android links when extension emulator creation fails without a name',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final emulatorManager = FakeEmulatorManager(
            availableCreatePlatforms: const <String>['custom_os'],
            createResult: CreateEmulatorResult('', success: false, error: 'Custom SDK missing'),
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await createTestCommandRunner(command)
              .run(<String>['emulators', '--create', '--platform', 'custom_os']);

          expect(logger.statusText, contains('Failed to create emulator.'));
          expect(logger.statusText, contains('Custom SDK missing'));
          expect(
            logger.statusText,
            isNot(contains('https://developer.android.com/studio/run/managing-avds')),
          );
        },
      );

      testWithoutContext(
        'routes directly to specified --platform without prompting when multiple platforms exist',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final emulatorManager = FakeEmulatorManager(
            availableCreatePlatforms: const <String>['android', 'custom_os'],
            createResult: CreateEmulatorResult('sim_1', success: true),
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await createTestCommandRunner(command)
              .run(<String>['emulators', '--create', '--platform', 'custom_os', '--name', 'sim_1']);

          expect(emulatorManager.lastCreatedPlatform, 'custom_os');
          expect(emulatorManager.lastCreatedName, 'sim_1');
          expect(logger.statusText, contains("Emulator 'sim_1' created successfully."));
        },
      );

      testWithoutContext('throws ToolExit listing platforms in non-interactive terminal when multiple platforms exist', () async {
        final terminal = _TestPromptTerminal(stdinHasTerminal: false);
        final toolContext = FakeToolContext(logger: logger, platform: platform, terminal: terminal);
        final emulatorManager = FakeEmulatorManager(
          availableCreatePlatforms: const <String>['android', 'custom_os'],
        );
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await expectLater(
          () => createTestCommandRunner(command).run(<String>['emulators', '--create']),
          throwsToolExit(
            message:
                'Multiple emulator creation platforms are available (android, custom_os). '
                'Specify one using "--platform <platform>".',
          ),
        );
      });

      testWithoutContext('prompts for platform in interactive terminal when multiple platforms exist and routes choice', () async {
        final terminal = _TestPromptTerminal(stdinHasTerminal: true, nextChoice: '2');
        final toolContext = FakeToolContext(logger: logger, platform: platform, terminal: terminal);
        final emulatorManager = FakeEmulatorManager(
          availableCreatePlatforms: const <String>['android', 'custom_os'],
          createResult: CreateEmulatorResult('custom_sim_2', success: true),
        );
        final command = EmulatorsCommand(
          doctor: doctor,
          emulatorManager: emulatorManager,
          toolContext: toolContext,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(terminal.usesTerminalUi, isTrue);
        expect(emulatorManager.lastCreatedPlatform, 'custom_os');
        expect(logger.statusText, contains('Multiple emulator creation platforms are available:'));
        expect(logger.statusText, contains('[1]: android'));
        expect(logger.statusText, contains('[2]: custom_os'));
        expect(
          logger.statusText,
          contains('To skip this prompt in the future, pass "--platform custom_os".'),
        );
        expect(logger.statusText, contains("Emulator 'custom_sim_2' created successfully."));
      });

      testWithoutContext(
        'aborts with ToolExit when user enters q at interactive platform prompt',
        () async {
          final terminal = _TestPromptTerminal(stdinHasTerminal: true, nextChoice: 'q');
          final toolContext = FakeToolContext(
            logger: logger,
            platform: platform,
            terminal: terminal,
          );
          final emulatorManager = FakeEmulatorManager(
            availableCreatePlatforms: const <String>['android', 'custom_os'],
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await expectLater(
            () => createTestCommandRunner(command).run(<String>['emulators', '--create']),
            throwsToolExit(),
          );
          expect(emulatorManager.lastCreatedPlatform, isNull);
        },
      );

      testWithoutContext(
        'prompts with line input when 10 or more platforms exist and retries invalid input',
        () async {
          final terminal = _TestPromptTerminal(
            stdinHasTerminal: true,
            lines: <String>['invalid', '99', '10'],
          );
          final toolContext = FakeToolContext(
            logger: logger,
            platform: platform,
            terminal: terminal,
          );
          final platforms = <String>[for (var i = 1; i <= 10; i++) 'platform_$i'];
          final emulatorManager = FakeEmulatorManager(
            availableCreatePlatforms: platforms,
            createResult: CreateEmulatorResult('sim_10', success: true),
          );
          final command = EmulatorsCommand(
            doctor: doctor,
            emulatorManager: emulatorManager,
            toolContext: toolContext,
          );

          await createTestCommandRunner(command).run(<String>['emulators', '--create']);

          expect(emulatorManager.lastCreatedPlatform, 'platform_10');
          expect(logger.statusText, contains('[10]: platform_10'));
          expect(logger.statusText, contains("Emulator 'sim_10' created successfully."));
        },
      );
    });
  });
}

class _TestPromptTerminal extends FakeTerminal {
  _TestPromptTerminal({
    required super.stdinHasTerminal,
    this.nextChoice = '1',
    List<String> lines = const <String>[],
  }) : _lines = List<String>.of(lines);

  final String nextChoice;
  final List<String> _lines;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    required Logger logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, contains(nextChoice));
    return nextChoice;
  }

  @override
  Future<String> readLine() async {
    return _lines.removeAt(0);
  }
}

class _FakeDoctor extends Fake implements Doctor {
  _FakeDoctor({this.canListEmulators = true});

  final bool canListEmulators;

  @override
  List<Workflow> get workflows => <Workflow>[_FakeWorkflow(canListEmulators: canListEmulators)];
}

class _FakeWorkflow extends Fake implements Workflow {
  _FakeWorkflow({this.canListEmulators = true});

  @override
  final bool canListEmulators;
}

class _FakeEmulator extends Emulator {
  const _FakeEmulator(String id, this.name, this.manufacturer, {this.onLaunch}) : super(id, true);

  @override
  final String name;

  @override
  final String manufacturer;

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.android;

  final void Function(bool coldBoot)? onLaunch;

  @override
  Future<void> launch({bool coldBoot = false}) async {
    onLaunch?.call(coldBoot);
  }
}
