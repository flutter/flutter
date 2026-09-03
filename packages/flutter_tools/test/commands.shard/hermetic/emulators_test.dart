// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/context.dart';
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
import '../../src/context.dart';
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
      testUsingContext(
        'throws ToolExit if no emulator sources are available on non-macOS',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await expectLater(
            () => createTestCommandRunner(command).run(<String>['emulators']),
            throwsToolExit(
              message:
                  'Unable to find any emulator sources. Please ensure you have some\n'
                  'Android AVD images available.',
            ),
          );
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(canListEmulators: false),
          EmulatorManager: () => _FakeEmulatorManager(),
        },
      );

      testUsingContext(
        'throws ToolExit if no emulator sources are available on macOS',
        () async {
          final macOSPlatform = FakePlatform(operatingSystem: 'macos');
          final toolContext = FakeToolContext(logger: logger, platform: macOSPlatform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await expectLater(
            () => createTestCommandRunner(command).run(<String>['emulators']),
            throwsToolExit(
              message:
                  'Unable to find any emulator sources. Please ensure you have some\n'
                  'Android AVD images or an iOS Simulator available.',
            ),
          );
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(canListEmulators: false),
          EmulatorManager: () => _FakeEmulatorManager(),
        },
      );

            testUsingContext(
        'shows message when no emulators available',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

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
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(),
        },
      );

      testUsingContext(
        'lists available emulators with header',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

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
          expect(
            logger.statusText,
            contains('https://developer.android.com/studio/run/managing-avds'),
          );
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(emulators: const <_FakeEmulator>[
            _FakeEmulator('nexus_5', 'Nexus 5', 'Google'),
            _FakeEmulator('pixel_6', 'Pixel 6', 'Google'),
          ]),
        },
      );



      testUsingContext(
        'prints error when no matching emulator is found',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel']);

          expect(logger.statusText, contains("No emulator found that matches 'pixel'."));
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(),
        },
      );

      testUsingContext(
        'prints list when multiple emulators match',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel']);

          expect(logger.statusText, contains("More than one emulator matches 'pixel':"));
          expect(logger.statusText, contains('Pixel 6'));
          expect(logger.statusText, contains('Pixel 7'));
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(emulators: const <_FakeEmulator>[
            _FakeEmulator('pixel_6', 'Pixel 6', 'Google'),
            _FakeEmulator('pixel_7', 'Pixel 7', 'Google'),
          ]),
        },
      );

      var launchCountWarm = 0;
      bool? lastColdBootWarm;
      final emulatorWarm = _FakeEmulator(
        'pixel_6',
        'Pixel 6',
        'Google',
        onLaunch: (bool coldBoot) {
          launchCountWarm++;
          lastColdBootWarm = coldBoot;
        },
      );
      testUsingContext(
        'launches emulator when exactly one match found (warm boot)',
        () async {
          launchCountWarm = 0;
          lastColdBootWarm = null;
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'pixel_6']);

          expect(launchCountWarm, 1);
          expect(lastColdBootWarm, isFalse);
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(emulators: <_FakeEmulator>[emulatorWarm])
        },
      );

      var launchCountCold = 0;
      bool? lastColdBootCold;
      final emulatorCold = _FakeEmulator(
        'pixel_6',
        'Pixel 6',
        'Google',
        onLaunch: (bool coldBoot) {
          launchCountCold++;
          lastColdBootCold = coldBoot;
        },
      );
      testUsingContext(
        'launches emulator with cold boot when --cold is specified',
        () async {
          launchCountCold = 0;
          lastColdBootCold = null;
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command)
              .run(<String>['emulators', '--launch', 'pixel_6', '--cold']);

          expect(launchCountCold, 1);
          expect(lastColdBootCold, isTrue);
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(emulators: <_FakeEmulator>[emulatorCold])
        },
      );
    });

    group('create emulator', () {
      testUsingContext(
        'creates emulator successfully without name',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command).run(<String>['emulators', '--create']);

          expect(logger.statusText, contains("Emulator 'flutter_emulator' created successfully."));
          expect((context.get<EmulatorManager>()! as _FakeEmulatorManager).lastCreatedName, isNull);
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(
            createResult: CreateEmulatorResult('flutter_emulator', success: true),
          ),
        },
      );

      testUsingContext(
        'creates emulator successfully with custom name',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command)
              .run(<String>['emulators', '--create', '--name', 'my_custom_emulator']);

          expect(
            logger.statusText,
            contains("Emulator 'my_custom_emulator' created successfully."),
          );
          expect((context.get<EmulatorManager>()! as _FakeEmulatorManager).lastCreatedName, 'my_custom_emulator');
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(
            createResult: CreateEmulatorResult('my_custom_emulator', success: true),
          ),
        },
      );

      testUsingContext(
        'prints error and additional info when creation fails',
        () async {
          final toolContext = FakeToolContext(logger: logger, platform: platform);
          final command = EmulatorsCommand(toolContext: toolContext);

          await createTestCommandRunner(command).run(<String>['emulators', '--create']);

          expect(logger.statusText, contains("Failed to create emulator 'existing_emulator'."));
          expect(logger.statusText, contains('AVD already exists'));
          expect(
            logger.statusText,
            contains('https://developer.android.com/studio/run/managing-avds'),
          );
        },
        overrides: <Type, Generator>{
          Doctor: () => _FakeDoctor(),
          EmulatorManager: () => _FakeEmulatorManager(
            createResult: CreateEmulatorResult('existing_emulator', success: false, error: 'AVD already exists'),
          ),
        },
      );
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
  _FakeEmulatorManager({this.createResult, this.emulators = const <Emulator>[]});

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
