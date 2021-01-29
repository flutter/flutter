// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/android/android_emulator.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/mocks.dart' show MockAndroidSdk;

const String emulatorID = 'i1234';
const String errorText = '[Android emulator test error]';
const List<String> kEmulatorLaunchCommand = <String>[
  'emulator', '-avd', emulatorID,
];

void main() {
  group('android_emulator', () {
    testWithoutContext('flags emulators without config', () {
      const String emulatorID = '1234';

      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: MockAndroidSdk(),
      );
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, false);
    });

    testWithoutContext('flags emulators with config', () {
      const String emulatorID = '1234';
      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        properties: const <String, String>{'name': 'test'},
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: MockAndroidSdk(),
      );

      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, true);
    });

    testWithoutContext('reads expected metadata', () {
      const String emulatorID = '1234';
      const String manufacturer = 'Me';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'hw.device.manufacturer': manufacturer,
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: MockAndroidSdk(),
      );

      expect(emulator.id, emulatorID);
      expect(emulator.name, displayName);
      expect(emulator.manufacturer, manufacturer);
      expect(emulator.category, Category.mobile);
      expect(emulator.platformType, PlatformType.android);
    });

    testWithoutContext('prefers displayname for name', () {
      const String emulatorID = '1234';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: MockAndroidSdk(),
      );

      expect(emulator.name, displayName);
    });

    testWithoutContext('uses cleaned up ID if no displayname is set', () {
      // Android Studio uses the ID with underscores replaced with spaces
      // for the name if displayname is not set so we do the same.
      const String emulatorID = 'This_is_my_ID';
      final Map<String, String> properties = <String, String>{
        'avd.ini.notadisplayname': 'this is not a display name',
      };
      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        properties: properties,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        androidSdk: MockAndroidSdk(),
      );

      expect(emulator.name, 'This is my ID');
    });

    testWithoutContext('parses ini files', () {
      const String iniFile = '''
        hw.device.name=My Test Name
        #hw.device.name=Bad Name

        hw.device.manufacturer=Me
        avd.ini.displayname = dispName
      ''';
      final Map<String, String> results = parseIniLines(iniFile.split('\n'));

      expect(results['hw.device.name'], 'My Test Name');
      expect(results['hw.device.manufacturer'], 'Me');
      expect(results['avd.ini.displayname'], 'dispName');
    });
  });

  group('Android emulator launch ', () {
    MockAndroidSdk mockSdk;

    setUp(() {
      mockSdk = MockAndroidSdk();
      when(mockSdk.emulatorPath).thenReturn('emulator');
    });

    testWithoutContext('succeeds', () async {
      final AndroidEmulator emulator = AndroidEmulator(emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: kEmulatorLaunchCommand),
        ]),
        androidSdk: mockSdk,
        logger: BufferLogger.test(),
      );

      final Completer<void> completer = Completer<void>();
      FakeAsync().run((FakeAsync time) {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;
    });

    testWithoutContext('prints error on failure', () async {
      final BufferLogger logger =  BufferLogger.test();
      final AndroidEmulator emulator = AndroidEmulator(emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: kEmulatorLaunchCommand,
            exitCode: 1,
            stderr: errorText,
            stdout: 'dummy text',
            duration: Duration(seconds: 1),
          ),
        ]),
        androidSdk: mockSdk,
        logger: logger,
      );

      final Completer<void> completer = Completer<void>();
      FakeAsync().run((FakeAsync time) {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;

      expect(logger.errorText, contains(errorText));
    });

    testWithoutContext('prints nothing on late failure with empty stderr', () async {
      final BufferLogger logger =  BufferLogger.test();
      final AndroidEmulator emulator = AndroidEmulator(emulatorID,
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: kEmulatorLaunchCommand,
            exitCode: 1,
            stderr: '',
            stdout: 'dummy text',
            duration: Duration(seconds: 4),
          ),
        ]),
        androidSdk: mockSdk,
        logger: logger,
      );
      final Completer<void> completer = Completer<void>();
      await FakeAsync().run((FakeAsync time) async {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;

      expect(logger.errorText, isEmpty);
    }, skip: true); // TODO(jonahwilliams): clean up with https://github.com/flutter/flutter/issues/60675
  });
}
