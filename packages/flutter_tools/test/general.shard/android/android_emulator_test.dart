// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_emulator.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

const emulatorID = 'i1234';
const errorText = '[Android emulator test error]';
const kEmulatorLaunchCommand = <String>['emulator', '-avd', emulatorID];

void main() {
  group('android_emulator', () {
    testWithoutContext('flags emulators without config', () {
      const emulatorID = '1234';

      final emulator = AndroidEmulator(
        emulatorID,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: FakeAndroidSdk(),
      );
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, false);
    });

    testWithoutContext('flags emulators with config', () {
      const emulatorID = '1234';
      final emulator = AndroidEmulator(
        emulatorID,
        properties: const <String, String>{'name': 'test'},
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: FakeAndroidSdk(),
      );

      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, true);
    });

    testWithoutContext('reads expected metadata', () {
      const emulatorID = '1234';
      const manufacturer = 'Me';
      const displayName = 'The best one';
      final properties = <String, String>{
        'hw.device.manufacturer': manufacturer,
        'avd.ini.displayname': displayName,
      };
      final emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: FakeAndroidSdk(),
      );

      expect(emulator.id, emulatorID);
      expect(emulator.name, displayName);
      expect(emulator.manufacturer, manufacturer);
      expect(emulator.category, Category.mobile);
      expect(emulator.platformType, PlatformType.android);
    });

    testWithoutContext('prefers displayname for name', () {
      const emulatorID = '1234';
      const displayName = 'The best one';
      final properties = <String, String>{'avd.ini.displayname': displayName};
      final emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: FakeAndroidSdk(),
      );

      expect(emulator.name, displayName);
    });

    testWithoutContext('uses cleaned up ID if no displayname is set', () {
      // Android Studio uses the ID with underscores replaced with spaces
      // for the name if displayname is not set so we do the same.
      const emulatorID = 'This_is_my_ID';
      final properties = <String, String>{'avd.ini.notadisplayname': 'this is not a display name'};
      final emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: FakeAndroidSdk(),
      );

      expect(emulator.name, 'This is my ID');
    });
  });

  group('Android emulator launch ', () {
    late FakeAndroidSdk mockSdk;

    setUp(() {
      mockSdk = FakeAndroidSdk();
      mockSdk.emulatorPath = 'emulator';
    });

    testWithoutContext('succeeds', () async {
      final emulator = AndroidEmulator(
        emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: kEmulatorLaunchCommand),
        ]),
        androidSdk: mockSdk,
        logger: BufferLogger.test(),
      );

      await emulator.launch(startupDuration: Duration.zero);
    });

    testWithoutContext('succeeds with coldboot launch', () async {
      final kEmulatorLaunchColdBootCommand = <String>[
        ...kEmulatorLaunchCommand,
        '-no-snapshot-load',
      ];
      final emulator = AndroidEmulator(
        emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(command: kEmulatorLaunchColdBootCommand),
        ]),
        androidSdk: mockSdk,
        logger: BufferLogger.test(),
      );

      await emulator.launch(startupDuration: Duration.zero, coldBoot: true);
    });

    testWithoutContext('prints error on failure', () async {
      final logger = BufferLogger.test();
      final emulator = AndroidEmulator(
        emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: kEmulatorLaunchCommand,
            exitCode: 1,
            stderr: errorText,
            stdout: 'dummy text',
          ),
        ]),
        androidSdk: mockSdk,
        logger: logger,
      );

      await emulator.launch(startupDuration: Duration.zero);

      expect(logger.errorText, contains(errorText));
    });

    testWithoutContext('prints nothing on late failure with empty stderr', () async {
      final logger = BufferLogger.test();
      final emulator = AndroidEmulator(
        emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: kEmulatorLaunchCommand,
            exitCode: 1,
            stdout: 'dummy text',
            completer: Completer<void>(),
          ),
        ]),
        androidSdk: mockSdk,
        logger: logger,
      );
      await emulator.launch(startupDuration: Duration.zero);

      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('throws if emulator not found', () async {
      mockSdk.emulatorPath = null;

      final emulator = AndroidEmulator(
        emulatorID,
        processManager: FakeProcessManager.empty(),
        androidSdk: mockSdk,
        logger: BufferLogger.test(),
      );

      await expectLater(
        () => emulator.launch(startupDuration: Duration.zero),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains('Emulator is missing from the Android SDK'),
          ),
        ),
      );
    });

    group('AndroidEmulators discovery', () {
      late MemoryFileSystem fileSystem;
      late FakeAndroidSdk mockSdk;

      setUp(() {
        fileSystem = MemoryFileSystem.test();
        mockSdk = FakeAndroidSdk()
          ..emulatorPath = 'emulator'
          ..adbPath = 'adb'
          ..avdPath = '/fake/avd';
      });

      testWithoutContext('discovers emulators and parses displayname and manufacturer', () async {
        // 1. Setup fake AVD directory structures and INI files.
        final Directory avdDir = fileSystem.directory('/fake/avd')..createSync(recursive: true);

        // Emulator 1: Nexus_5X. Has a display name.
        avdDir.childFile('Nexus_5X.ini').writeAsStringSync('path=/fake/avd/Nexus_5X.avd');
        final Directory nexus5xDir = fileSystem.directory('/fake/avd/Nexus_5X.avd')
          ..createSync(recursive: true);
        nexus5xDir.childFile('config.ini').writeAsStringSync('''
          avd.ini.displayname=My Custom Nexus 5X
          hw.device.manufacturer=Google
        ''');

        // Emulator 2: Pixel_6. Does not have a display name.
        avdDir.childFile('Pixel_6.ini').writeAsStringSync('path=/fake/avd/Pixel_6.avd');
        final Directory pixel6Dir = fileSystem.directory('/fake/avd/Pixel_6.avd')
          ..createSync(recursive: true);
        pixel6Dir.childFile('config.ini').writeAsStringSync('''
          hw.device.manufacturer=Google
        ''');

        final androidWorkflow = AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        );

        final discoverer = AndroidEmulators(
          androidSdk: mockSdk,
          androidWorkflow: androidWorkflow,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          processManager: FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(
              command: <String>['emulator', '-list-avds'],
              stdout: 'Nexus_5X\nPixel_6',
            ),
          ]),
        );

        final List<Emulator> emulators = await discoverer.emulators;
        expect(emulators, hasLength(2));

        expect(emulators[0].id, 'Nexus_5X');
        expect(emulators[0].name, 'My Custom Nexus 5X');
        expect(emulators[0].manufacturer, 'Google');

        expect(emulators[1].id, 'Pixel_6');
        expect(emulators[1].name, 'Pixel 6'); // Underscores replaced with space
        expect(emulators[1].manufacturer, 'Google');
      });
    });
  });
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String? emulatorPath;

  @override
  String? adbPath;

  String? avdPath;

  @override
  String? getAvdPath() => avdPath;
}
