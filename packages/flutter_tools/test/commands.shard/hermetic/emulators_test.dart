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

    setUp(() {
      logger = BufferLogger.test();
      platform = FakePlatform();
    });

    group('doctor validation', () {
      testWithoutContext(
        'throws ToolExit if no emulator sources are available on non-macOS',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final doctor = _FakeDoctor(canListEmulators: false);
          final command = EmulatorsCommand(toolContext: toolContext, doctor: doctor);

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
        final command = EmulatorsCommand(toolContext: toolContext, doctor: doctor);

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
        final emulatorManager = _FakeEmulatorManager();
        final command = EmulatorsCommand(
          toolContext: toolContext,
          doctor: doctor,
          emulatorManager: emulatorManager,
        );

        await createTestCommandRunner(command).run(<String>['emulators']);
        expect(logger.statusText, contains('No emulators available.'));
      });
    });

    group('list emulators', () {
      testWithoutContext('shows message when no emulators available', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = _FakeEmulatorManager();
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager();
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager(emulators: emulators);
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager(emulators: <_FakeEmulator>[emulator]);
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
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
        final emulatorManager = _FakeEmulatorManager(emulators: <_FakeEmulator>[emulator]);
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
        );

        await createTestCommandRunner(
          command,
        ).run(<String>['emulators', '--launch', 'pixel_6', '--cold']);

        expect(launchCount, 1);
        expect(lastColdBoot, isTrue);
      });
    });

    group('create emulator', () {
      testWithoutContext('creates emulator successfully without name', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = _FakeEmulatorManager(
          createResult: CreateEmulatorResult('flutter_emulator', success: true),
        );
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(logger.statusText, contains("Emulator 'flutter_emulator' created successfully."));
        expect(emulatorManager.lastCreatedName, isNull);
      });

      testWithoutContext('creates emulator successfully with custom name', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = _FakeEmulatorManager(
          createResult: CreateEmulatorResult('my_custom_emulator', success: true),
        );
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
        );

        await createTestCommandRunner(
          command,
        ).run(<String>['emulators', '--create', '--name', 'my_custom_emulator']);

        expect(logger.statusText, contains("Emulator 'my_custom_emulator' created successfully."));
        expect(emulatorManager.lastCreatedName, 'my_custom_emulator');
      });

      testWithoutContext('prints error and additional info when creation fails', () async {
        final toolContext = FakeToolContext(logger: logger, platform: platform);
        final emulatorManager = _FakeEmulatorManager(
          createResult: CreateEmulatorResult(
            'existing_emulator',
            success: false,
            error: 'AVD already exists',
          ),
        );
        final command = EmulatorsCommand(
          toolContext: toolContext,
          emulatorManager: emulatorManager,
        );

        await createTestCommandRunner(command).run(<String>['emulators', '--create']);

        expect(logger.statusText, contains("Failed to create emulator 'existing_emulator'."));
        expect(logger.statusText, contains('AVD already exists'));
        expect(
          logger.statusText,
          contains('https://developer.android.com/studio/run/managing-avds'),
        );
      });
    });
  });
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

class _FakeEmulatorManager extends Fake implements EmulatorManager {
  _FakeEmulatorManager({this.emulators = const <Emulator>[], this.createResult});

  final List<Emulator> emulators;
  final CreateEmulatorResult? createResult;
  String? lastCreatedName;

  @override
  Future<List<Emulator>> getAllAvailableEmulators() async => emulators;

  @override
  Future<List<Emulator>> getEmulatorsMatching(String id) async {
    return emulators
        .where(
          (Emulator e) =>
              e.id.toLowerCase().contains(id.toLowerCase()) ||
              e.name.toLowerCase().contains(id.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<CreateEmulatorResult> createEmulator({String? name}) async {
    lastCreatedName = name;
    return createResult ?? CreateEmulatorResult('flutter_emulator', success: true);
  }
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
