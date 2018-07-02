// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  MockProcessManager mockProcessManager;
  MockConfig mockConfig;
  MockAndroidSdk mockSdk;

  setUp(() {
    mockProcessManager = new MockProcessManager();
    mockConfig = new MockConfig();
    mockSdk = new MockAndroidSdk();

    when(mockSdk.avdManagerPath).thenReturn('avdmanager');
    when(mockSdk.emulatorPath).thenReturn('emulator');
  });

  group('EmulatorManager', () {
    testUsingContext('getEmulators', () async {
      // Test that EmulatorManager.getEmulators() doesn't throw.
      final List<Emulator> emulators =
          await emulatorManager.getAllAvailableEmulators();
      expect(emulators, isList);
    });

    testUsingContext('getEmulatorsById', () async {
      final _MockEmulator emulator1 =
          new _MockEmulator('Nexus_5', 'Nexus 5', 'Google', '');
      final _MockEmulator emulator2 =
          new _MockEmulator('Nexus_5X_API_27_x86', 'Nexus 5X', 'Google', '');
      final _MockEmulator emulator3 =
          new _MockEmulator('iOS Simulator', 'iOS Simulator', 'Apple', '');
      final List<Emulator> emulators = <Emulator>[
        emulator1,
        emulator2,
        emulator3
      ];
      final TestEmulatorManager testEmulatorManager =
          new TestEmulatorManager(emulators);

      Future<Null> expectEmulator(String id, List<Emulator> expected) async {
        expect(await testEmulatorManager.getEmulatorsMatching(id), expected);
      }

      expectEmulator('Nexus_5', <Emulator>[emulator1]);
      expectEmulator('Nexus_5X', <Emulator>[emulator2]);
      expectEmulator('Nexus_5X_API_27_x86', <Emulator>[emulator2]);
      expectEmulator('Nexus', <Emulator>[emulator1, emulator2]);
      expectEmulator('iOS Simulator', <Emulator>[emulator3]);
      expectEmulator('ios', <Emulator>[emulator3]);
    });

    testUsingContext('create emulator with an empty name does not fail',
        () async {
      final CreateEmulatorResult res = await emulatorManager.createEmulator();
      expect(res.success, equals(true));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext('create emulator with a unique name does not throw',
        () async {
      final CreateEmulatorResult res =
          await emulatorManager.createEmulator(name: 'test');
      expect(res.success, equals(true));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext('create emulator with an existing name errors', () async {
      final CreateEmulatorResult res =
          await emulatorManager.createEmulator(name: 'existing-avd-1');
      expect(res.success, equals(false));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext(
        'create emulator without a name but when default exists adds a suffix',
        () async {
      // First will get default name.
      CreateEmulatorResult res = await emulatorManager.createEmulator();
      expect(res.success, equals(true));

      final String defaultName = res.emulatorName;

      // Second...
      res = await emulatorManager.createEmulator();
      expect(res.success, equals(true));
      expect(res.emulatorName, equals('${defaultName}_2'));

      // Third...
      res = await emulatorManager.createEmulator();
      expect(res.success, equals(true));
      expect(res.emulatorName, equals('${defaultName}_3'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });
  });
}

class TestEmulatorManager extends EmulatorManager {
  final List<Emulator> allEmulators;

  TestEmulatorManager(this.allEmulators);

  @override
  Future<List<Emulator>> getAllAvailableEmulators() {
    return new Future<List<Emulator>>.value(allEmulators);
  }
}

class _MockEmulator extends Emulator {
  _MockEmulator(String id, this.name, this.manufacturer, this.label)
      : super(id, true);

  @override
  final String name;

  @override
  final String manufacturer;

  @override
  final String label;

  @override
  Future<void> launch() {
    throw new UnimplementedError('Not implemented in Mock');
  }
}

class MockConfig extends Mock implements Config {}

class MockProcessManager extends Mock implements ProcessManager {
  /// We have to send a command that fails in order to get the list of valid
  /// system images paths. This is an example of the output to use in the mock.
  static const String mockCreateFailureOutput =
      'Error: Package path (-k) not specified. Valid system image paths are:\n'
      'system-images;android-27;google_apis;x86\n'
      'system-images;android-P;google_apis;x86\n'
      'system-images;android-27;google_apis_playstore;x86\n'
      'null\n'; // Yep, these really end with null (on dantup's machine at least)

  static const ListEquality<String> _equality = const ListEquality<String>();
  final List<String> _existingAvds = <String>['existing-avd-1'];

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding,
    Encoding stderrEncoding
  }) {
    final String program = command[0];
    final List<String> args = command.sublist(1);
    switch (command[0]) {
      case '/usr/bin/xcode-select':
        throw new ProcessException(program, args);
        break;
      case 'emulator':
        return _handleEmulator(args);
      case 'avdmanager':
        return _handleAvdManager(args);
    }
    throw new StateError('Unexpected process call: $command');
  }

  ProcessResult _handleEmulator(List<String> args) {
    if (_equality.equals(args, <String>['-list-avds'])) {
      return new ProcessResult(101, 0, '${_existingAvds.join('\n')}\n', '');
    }
    throw new ProcessException('emulator', args);
  }

  ProcessResult _handleAvdManager(List<String> args) {
    if (_equality.equals(args, <String>['list', 'device', '-c'])) {
      return new ProcessResult(101, 0, 'test\ntest2\npixel\npixel-xl\n', '');
    }
    if (_equality.equals(args, <String>['create', 'avd', '-n', 'temp'])) {
      return new ProcessResult(101, 1, '', mockCreateFailureOutput);
    }
    if (args.length == 8 &&
        _equality.equals(args,
            <String>['create', 'avd', '-n', args[3], '-k', args[5], '-d', args[7]])) {
      // In order to support testing auto generation of names we need to support
      // tracking any created emulators and reject when they already exist so this
      // mock will compare the name of the AVD being created with the fake existing
      // list and either reject if it exists, or add it to the list and return success.
      final String name = args[3];
      // Error if this AVD already existed
      if (_existingAvds.contains(name)) {
        return new ProcessResult(
            101,
            1,
            '',
            "Error: Android Virtual Device '$name' already exists.\n"
            'Use --force if you want to replace it.');
      } else {
        _existingAvds.add(name);
        return new ProcessResult(101, 0, '', '');
      }
    }
    throw new ProcessException('emulator', args);
  }
}
