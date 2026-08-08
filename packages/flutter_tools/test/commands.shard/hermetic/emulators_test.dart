// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/emulators.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('EmulatorsCommand', () {
    late MemoryFileSystem fileSystem;
    late BufferLogger logger;
    late FakePlatform platform;
    late FakeDoctor doctor;
    late FakeEmulatorManager emulatorManager;
    late FakeToolContext toolContext;

    EmulatorsCommand createEmulatorsCommand() {
      return EmulatorsCommand(
        doctor: doctor,
        emulatorManager: emulatorManager,
        toolContext: toolContext,
      );
    }

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      platform = FakePlatform();
      doctor = FakeDoctor(workflows: <Workflow>[FakeWorkflow(canListEmulators: true)]);
      emulatorManager = FakeEmulatorManager();
      toolContext = FakeToolContext(fs: fileSystem, logger: logger, platform: platform);
    });

    testUsingContext('listing emulators - none available', () async {
      emulatorManager.emulators = <Emulator>[];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators']);

      expect(logger.statusText, contains('No emulators available.'));
      expect(logger.statusText, contains('To create a new emulator, run'));
    });

    testUsingContext('listing emulators - some available', () async {
      final emulator = FakeEmulator('emu1', 'Nexus 5', 'Google', PlatformType.android);
      emulatorManager.emulators = <Emulator>[emulator];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators']);

      expect(logger.statusText, contains('1 available emulator:'));
      expect(logger.statusText, matches(RegExp(r'emu1\s+•\s+Nexus 5\s+•\s+Google\s+•\s+android')));
    });

    testUsingContext('listing emulators - with search text filtering', () async {
      final emu1 = FakeEmulator('emu1', 'Nexus 5', 'Google', PlatformType.android);
      final emu2 = FakeEmulator('ios_emu', 'iOS Simulator', 'Apple', PlatformType.ios);
      emulatorManager.emulators = <Emulator>[emu1, emu2];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators', 'nexus']);

      expect(logger.statusText, contains('1 available emulator:'));
      expect(logger.statusText, matches(RegExp(r'emu1\s+•\s+Nexus 5\s+•\s+Google\s+•\s+android')));
      expect(logger.statusText, isNot(contains('ios_emu')));
    });

    testUsingContext('launching emulators - warning when none match', () async {
      emulatorManager.emulators = <Emulator>[];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'non_existent']);

      expect(logger.statusText, contains("No emulator found that matches 'non_existent'."));
    });

    testUsingContext('launching emulators - unique match launches successfully', () async {
      final emulator = FakeEmulator('emu1', 'Nexus 5', 'Google', PlatformType.android);
      emulatorManager.emulators = <Emulator>[emulator];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'emu1']);

      expect(emulator.launched, isTrue);
      expect(emulator.coldBootUsed, isFalse);
    });

    testUsingContext('launching emulators - cold boot flag passed through', () async {
      final emulator = FakeEmulator('emu1', 'Nexus 5', 'Google', PlatformType.android);
      emulatorManager.emulators = <Emulator>[emulator];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(
        command,
      ).run(<String>['emulators', '--launch', 'emu1', '--cold']);

      expect(emulator.launched, isTrue);
      expect(emulator.coldBootUsed, isTrue);
    });

    testUsingContext('launching emulators - list choices when multiple match', () async {
      final emu1 = FakeEmulator('emu1', 'Nexus 5', 'Google', PlatformType.android);
      final emu2 = FakeEmulator('emu2', 'Nexus 6', 'Google', PlatformType.android);
      emulatorManager.emulators = <Emulator>[emu1, emu2];
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(command).run(<String>['emulators', '--launch', 'emu']);

      expect(emu1.launched, isFalse);
      expect(emu2.launched, isFalse);
      expect(logger.statusText, contains("More than one emulator matches 'emu':"));
      expect(logger.statusText, matches(RegExp(r'emu1\s+•\s+Nexus 5\s+•\s+Google\s+•\s+android')));
      expect(logger.statusText, matches(RegExp(r'emu2\s+•\s+Nexus 6\s+•\s+Google\s+•\s+android')));
    });

    testUsingContext('creating emulators - success prints emulator name', () async {
      emulatorManager.createResult = CreateEmulatorResult('new_emu', success: true);
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(
        command,
      ).run(<String>['emulators', '--create', '--name', 'new_emu']);

      expect(emulatorManager.createdEmulators, <String?>['new_emu']);
      expect(logger.statusText, contains("Emulator 'new_emu' created successfully."));
    });

    testUsingContext('creating emulators - failure prints error and info', () async {
      emulatorManager.createResult = CreateEmulatorResult(
        'failed_emu',
        success: false,
        error: 'Android SDK is missing system images',
      );
      final EmulatorsCommand command = createEmulatorsCommand();

      await createTestCommandRunner(
        command,
      ).run(<String>['emulators', '--create', '--name', 'failed_emu']);

      expect(emulatorManager.createdEmulators, <String?>['failed_emu']);
      expect(logger.statusText, contains("Failed to create emulator 'failed_emu'."));
      expect(logger.statusText, contains('Android SDK is missing system images'));
      expect(logger.statusText, contains('managing emulators at the links below'));
    });

    testUsingContext(
      'Dependency Injection Validation - resolves from injected ToolContext rather than Zone',
      () async {
        // Construct a completely different ToolContext
        final injectedFs = MemoryFileSystem.test();
        final injectedLogger = BufferLogger.test();
        final injectedPlatform = FakePlatform(operatingSystem: 'macos');
        final injectedDoctor = FakeDoctor(
          workflows: <Workflow>[FakeWorkflow(canListEmulators: true)],
        );
        final injectedEmulatorManager = FakeEmulatorManager();
        final injectedToolContext = FakeToolContext(
          fs: injectedFs,
          logger: injectedLogger,
          platform: injectedPlatform,
        );

        // Populate emulators ONLY in the injected EmulatorManager
        final emulator = FakeEmulator(
          'injected_emu',
          'Injected AVD',
          'Google',
          PlatformType.android,
        );
        injectedEmulatorManager.emulators = <Emulator>[emulator];

        // The Zone context will have a throwing EmulatorManager and a different logger/platform
        final command = EmulatorsCommand(
          doctor: injectedDoctor,
          emulatorManager: injectedEmulatorManager,
          toolContext: injectedToolContext,
        );

        // Run the command. If it uses the Zone's EmulatorManager or Doctor, it will throw/fail.
        // If it uses the Zone's Logger, the output won't be in injectedLogger.
        await createTestCommandRunner(command).run(<String>['emulators']);

        // Verify that the output went to the injected logger and resolved the injected emulator
        expect(injectedLogger.statusText, contains('1 available emulator:'));
        expect(
          injectedLogger.statusText,
          matches(RegExp(r'injected_emu\s+•\s+Injected AVD\s+•\s+Google\s+•\s+android')),
        );

        // Verify the Zone's logger remains empty
        expect(testLogger.statusText, isEmpty);
      },
      overrides: <Type, Generator>{
        EmulatorManager: () =>
            throw UnimplementedError('Zone EmulatorManager should not be called'),
        Doctor: () => throw UnimplementedError('Zone Doctor should not be called'),
      },
    );
    group('doctor workflows check', () {
      testUsingContext('throws error when no doctor workflows can list emulators', () async {
        final emptyDoctor = FakeDoctor(
          workflows: <Workflow>[FakeWorkflow(canListEmulators: false)],
        );
        final emptyToolContext = FakeToolContext(
          fs: fileSystem,
          logger: logger,
          platform: platform,
        );

        final command = EmulatorsCommand(
          doctor: emptyDoctor,
          emulatorManager: emulatorManager,
          toolContext: emptyToolContext,
        );

        expect(
          () => createTestCommandRunner(command).run(<String>['emulators']),
          throwsToolExit(
            message:
                'Unable to find any emulator sources. Please ensure you have some\n'
                'Android AVD images available.',
          ),
        );
      });
    });
  });
}

class FakeWorkflow extends Fake implements Workflow {
  FakeWorkflow({required this.canListEmulators});

  @override
  final bool canListEmulators;
}

class FakeDoctor extends Fake implements Doctor {
  FakeDoctor({required this.workflows});

  @override
  final List<Workflow> workflows;
}

class FakeEmulatorManager extends Fake implements EmulatorManager {
  List<Emulator> emulators = <Emulator>[];
  CreateEmulatorResult? createResult;
  final List<String?> createdEmulators = <String?>[];

  @override
  Future<List<Emulator>> getAllAvailableEmulators() async => emulators;

  @override
  Future<List<Emulator>> getEmulatorsMatching(String searchText) async {
    searchText = searchText.toLowerCase();
    return emulators
        .where(
          (Emulator e) =>
              e.id.toLowerCase().contains(searchText) || e.name.toLowerCase().contains(searchText),
        )
        .toList();
  }

  @override
  Future<CreateEmulatorResult> createEmulator({String? name}) async {
    createdEmulators.add(name);
    return createResult ?? CreateEmulatorResult(name ?? 'fake_emu', success: true);
  }
}

class FakeEmulator extends Fake implements Emulator {
  FakeEmulator(this.id, this.name, this.manufacturer, this.platformType);

  @override
  final String id;

  @override
  final String name;

  @override
  final String? manufacturer;

  @override
  final PlatformType platformType;

  @override
  Category get category => Category.mobile;

  @override
  bool get hasConfig => true;

  final List<bool> _launched = <bool>[false];
  final List<bool> _coldBootUsed = <bool>[false];

  bool get launched => _launched[0];
  bool get coldBootUsed => _coldBootUsed[0];

  @override
  Future<void> launch({bool coldBoot = false}) async {
    _launched[0] = true;
    _coldBootUsed[0] = coldBoot;
  }
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({required this.fs, required this.logger, required this.platform});

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final Platform platform;
}
