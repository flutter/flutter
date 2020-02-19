// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart'
  show getEmulatorPath, AndroidSdk, androidSdk;
import 'package:flutter_tools/src/android/android_emulator.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/mocks.dart' show MockAndroidSdk;

void main() {
  group('android_emulator', () {
    testUsingContext('flags emulators without config', () {
      const String emulatorID = '1234';
      final AndroidEmulator emulator = AndroidEmulator(emulatorID);
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, false);
    });
    testUsingContext('flags emulators with config', () {
      const String emulatorID = '1234';
      final AndroidEmulator emulator = AndroidEmulator(
        emulatorID,
        <String, String>{'name': 'test'},
      );
      expect(emulator.id, emulatorID);
      expect(emulator.hasConfig, true);
    });
    testUsingContext('reads expected metadata', () {
      const String emulatorID = '1234';
      const String manufacturer = 'Me';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'hw.device.manufacturer': manufacturer,
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator = AndroidEmulator(emulatorID, properties);
      expect(emulator.id, emulatorID);
      expect(emulator.name, displayName);
      expect(emulator.manufacturer, manufacturer);
      expect(emulator.category, Category.mobile);
      expect(emulator.platformType, PlatformType.android);
    });
    testUsingContext('prefers displayname for name', () {
      const String emulatorID = '1234';
      const String displayName = 'The best one';
      final Map<String, String> properties = <String, String>{
        'avd.ini.displayname': displayName,
      };
      final AndroidEmulator emulator = AndroidEmulator(emulatorID, properties);
      expect(emulator.name, displayName);
    });
    testUsingContext('uses cleaned up ID if no displayname is set', () {
      // Android Studio uses the ID with underscores replaced with spaces
      // for the name if displayname is not set so we do the same.
      const String emulatorID = 'This_is_my_ID';
      final Map<String, String> properties = <String, String>{
        'avd.ini.notadisplayname': 'this is not a display name',
      };
      final AndroidEmulator emulator = AndroidEmulator(emulatorID, properties);
      expect(emulator.name, 'This is my ID');
    });
    testUsingContext('parses ini files', () {
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
    const String emulatorID = 'i1234';
    const String errorText = '[Android emulator test error]';
    MockAndroidSdk mockSdk;
    FakeProcessManager successProcessManager;
    FakeProcessManager errorProcessManager;
    FakeProcessManager lateFailureProcessManager;
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      mockSdk = MockAndroidSdk();
      when(mockSdk.emulatorPath).thenReturn('emulator');

      const List<String> command = <String>[
        'emulator', '-avd', emulatorID,
      ];

      successProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: command),
      ]);

      errorProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: command,
          exitCode: 1,
          stderr: errorText,
          stdout: 'dummy text',
          duration: Duration(seconds: 1),
        ),
      ]);

      lateFailureProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: command,
          exitCode: 1,
          stderr: '',
          stdout: 'dummy text',
          duration: Duration(seconds: 4),
        ),
      ]);
    });

    testUsingContext('succeeds', () async {
      final AndroidEmulator emulator = AndroidEmulator(emulatorID);
      expect(getEmulatorPath(androidSdk), mockSdk.emulatorPath);
      final Completer<void> completer = Completer<void>();
      FakeAsync().run((FakeAsync time) {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;

    }, overrides: <Type, Generator>{
      ProcessManager: () => successProcessManager,
      AndroidSdk: () => mockSdk,
      FileSystem: () => fs,
    });

    testUsingContext('prints error on failure', () async {
      final AndroidEmulator emulator = AndroidEmulator(emulatorID);
      final Completer<void> completer = Completer<void>();
      FakeAsync().run((FakeAsync time) {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;

      expect(testLogger.errorText, contains(errorText));
    }, overrides: <Type, Generator>{
      ProcessManager: () => errorProcessManager,
      AndroidSdk: () => mockSdk,
      FileSystem: () => fs,
    });

    testUsingContext('prints nothing on late failure with empty stderr', () async {
      final AndroidEmulator emulator = AndroidEmulator(emulatorID);
      final Completer<void> completer = Completer<void>();
      FakeAsync().run((FakeAsync time) async {
        unawaited(emulator.launch().whenComplete(completer.complete));
        time.elapse(const Duration(seconds: 5));
        time.flushMicrotasks();
      });
      await completer.future;
      expect(testLogger.errorText, isEmpty);
    }, overrides: <Type, Generator>{
      ProcessManager: () => lateFailureProcessManager,
      AndroidSdk: () => mockSdk,
      FileSystem: () => fs,
    });
  });
}
