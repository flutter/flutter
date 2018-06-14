// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  final MockProcessManager mockProcessManager = new MockProcessManager();
  final MockConfig mockConfig = new MockConfig();
  final MockAndroidSdk mockSdk = new MockAndroidSdk();

  /// We have to send a command that fails in order to get the list of valid
  /// system images paths. This is an example of the output to use in the mock.
  const String mockCreateFailureOutput =
      'Error: Package path (-k) not specified. Valid system image paths are:\n'
      'system-images;android-27;google_apis;x86\n'
      'system-images;android-P;google_apis;x86\n'
      'system-images;android-27;google_apis_playstore;x86\n'
      'null\n'; // Yep, these really end with null (on dantup's machine at least)
  
  setUp(() {
    when(mockSdk.avdManagerPath).thenReturn('avdmanager');
    when(mockSdk.emulatorPath).thenReturn('emulator');

    // Emulate not having XCode/iOS Simulator.
    when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select',
        '--print-path'],
    )).thenThrow(const ProcessException('/usr/bin/xcode-select', const <String>[]));

    final List<String> existingAvds = <String>['existing-avd-1'];

    // Mock the responses to commands required for creating/listing emulators
    when(mockProcessManager.runSync(<String>['emulator', '-list-avds']))
        .thenAnswer((Invocation inv) => new ProcessResult(101, 0, '${existingAvds.join('\n')}\n', ''));
    when(mockProcessManager.runSync(<String>['avdmanager', 'list', 'device', '-c']))
        .thenReturn(new ProcessResult(101, 0, 'test\ntest2\npixel\npixel-xl\n', ''));
    when(mockProcessManager.runSync(<String>['avdmanager', 'create', 'avd', '-n', 'temp']))
        .thenReturn(new ProcessResult(101, 1, '', mockCreateFailureOutput));

    // In order to support testing auto generation of names we need to support
    // tracking any created emulators and reject when they already exist so this
    // mock will compare the name of the AVD being created with the fake existing
    // list and either reject if it exists, or add it to the list and return success.
    when(mockProcessManager.runSync(<String>['avdmanager',
        'create', 'avd', '-n', any, '-k', any, '-d', any]))
        .thenAnswer((Invocation inv) {
          // Push this name into the list of existing AVDs.
          //   [0] is args
          //   [4] is the value after '-n' (the supplied name)
          final String name = inv.positionalArguments[0][4];
          // Error if this AVD already existed
          if (existingAvds.contains(name)) {
            return new ProcessResult(101, 1, '',
              "Error: Android Virtual Device '$name' already exists.\n"
              'Use --force if you want to replace it.'
            );
          } else {
            existingAvds.add(name);
            return new ProcessResult(101, 0, '', '');
          }
        });
  });

  group('EmulatorManager', () {
    testUsingContext('getEmulators', () async {
      // Test that EmulatorManager.getEmulators() doesn't throw.
      final List<Emulator> emulators = await emulatorManager.getAllAvailableEmulators();
      expect(emulators, isList);
    });

    testUsingContext('getEmulatorsById', () async {
      final _MockEmulator emulator1 = new _MockEmulator('Nexus_5', 'Nexus 5', 'Google', '');
      final _MockEmulator emulator2 = new _MockEmulator('Nexus_5X_API_27_x86', 'Nexus 5X', 'Google', '');
      final _MockEmulator emulator3 = new _MockEmulator('iOS Simulator', 'iOS Simulator', 'Apple', '');
      final List<Emulator> emulators = <Emulator>[emulator1, emulator2, emulator3];
      final TestEmulatorManager testEmulatorManager = new TestEmulatorManager(emulators);
      
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

    testUsingContext('create emulator with an empty name does not fail', () async {
      final CreateEmulatorResult res = await emulatorManager.createEmulator('');
      expect(res.success, equals(true));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext('create emulator with a unique name does not throw', () async {
      final CreateEmulatorResult res = await emulatorManager.createEmulator('test');
      expect(res.success, equals(true));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext('create emulator with an existing name errors', () async {
      final CreateEmulatorResult res = await emulatorManager.createEmulator('existing-avd-1');
      expect(res.success, equals(false));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Config: () => mockConfig,
      AndroidSdk: () => mockSdk,
    });

    testUsingContext('create emulator without a name but when default exists adds a suffix', () async {
      // First will get default name.
      CreateEmulatorResult res = await emulatorManager.createEmulator('');
      expect(res.success, equals(true));
      
      final String defaultName = res.emulatorName;

      // Second...
      res = await emulatorManager.createEmulator('');
      expect(res.success, equals(true));
      expect(res.emulatorName, equals('${defaultName}_2'));

      // Third...
      res = await emulatorManager.createEmulator('');
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
  _MockEmulator(String id, this.name, this.manufacturer, this.label) : super(id, true);

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

class MockProcessManager extends Mock implements ProcessManager {}
class MockConfig extends Mock implements Config {}
