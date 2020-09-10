// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/ios/ios_emulators.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';
import '../src/testbed.dart';

const FakeEmulator emulator1 = FakeEmulator('Nexus_5', 'Nexus 5', 'Google');
const FakeEmulator emulator2 = FakeEmulator('Nexus_5X_API_27_x86', 'Nexus 5X', 'Google');
const FakeEmulator emulator3 = FakeEmulator('iOS Simulator', 'iOS Simulator', 'Apple');
const List<Emulator> emulators = <Emulator>[
  emulator1,
  emulator2,
  emulator3,
];

// We have to send a command that fails in order to get the list of valid
// system images paths. This is an example of the output to use in the mock.
const String fakeCreateFailureOutput =
  'Error: Package path (-k) not specified. Valid system image paths are:\n'
  'system-images;android-27;google_apis;x86\n'
  'system-images;android-P;google_apis;x86\n'
  'system-images;android-27;google_apis_playstore;x86\n'
  'null\n'; // Yep, these really end with null (on dantup's machine at least)

const FakeCommand kListEmulatorsCommand = FakeCommand(
  command: <String>['avdmanager', 'create', 'avd', '-n', 'temp'],
  stderr: fakeCreateFailureOutput,
  exitCode: 1,
);

void main() {
  MockProcessManager mockProcessManager;
  MockAndroidSdk mockSdk;
  MockXcode mockXcode;

  setUp(() {
    mockProcessManager = MockProcessManager();
    mockSdk = MockAndroidSdk();
    mockXcode = MockXcode();

    when(mockSdk.avdManagerPath).thenReturn('avdmanager');
    when(mockSdk.getAvdManagerPath()).thenReturn('avdmanager');
    when(mockSdk.emulatorPath).thenReturn('emulator');
    when(mockSdk.adbPath).thenReturn('adb');
  });

  group('EmulatorManager', () {
    // iOS discovery uses context.
    testUsingContext('getEmulators', () async {
      // Test that EmulatorManager.getEmulators() doesn't throw.
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['emulator', '-list-avds'],
            stdout: 'existing-avd-1',
          ),
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );

      await expectLater(() async => await emulatorManager.getAllAvailableEmulators(),
        returnsNormally);
    });

    testWithoutContext('getEmulatorsById', () async {
      final TestEmulatorManager testEmulatorManager = TestEmulatorManager(emulators);

      expect(await testEmulatorManager.getEmulatorsMatching('Nexus_5'), <Emulator>[emulator1]);
      expect(await testEmulatorManager.getEmulatorsMatching('Nexus_5X'), <Emulator>[emulator2]);
      expect(await testEmulatorManager.getEmulatorsMatching('Nexus_5X_API_27_x86'),  <Emulator>[emulator2]);
      expect(await testEmulatorManager.getEmulatorsMatching('Nexus'), <Emulator>[emulator1, emulator2]);
      expect(await testEmulatorManager.getEmulatorsMatching('iOS Simulator'), <Emulator>[emulator3]);
      expect(await testEmulatorManager.getEmulatorsMatching('ios'),  <Emulator>[emulator3]);
    });

    testUsingContext('create emulator with a missing avdmanager does not crash.', () async {
      when(mockSdk.avdManagerPath).thenReturn(null);
      when(mockSdk.getAvdManagerPath()).thenReturn(null);
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['emulator', '-list-avds'],
            stdout: 'existing-avd-1',
          ),
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );
      final CreateEmulatorResult result = await emulatorManager.createEmulator();

      expect(result.success, false);
      expect(result.error, contains('avdmanager is missing from the Android SDK'));
    });

    // iOS discovery uses context.
    testUsingContext('create emulator with an empty name does not fail', () async {
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['emulator', '-list-avds'],
            stdout: 'existing-avd-1',
          ),
          const FakeCommand(
            command: <String>['avdmanager', 'list', 'device', '-c'],
            stdout: 'test\ntest2\npixel\npixel-xl\n',
          ),
          kListEmulatorsCommand,
          const FakeCommand(
            command: <String>[
              'avdmanager',
              'create',
              'avd',
              '-n',
              'flutter_emulator',
              '-k',
              'system-images;android-27;google_apis_playstore;x86',
              '-d',
              'pixel',
            ],
          )
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );
      final CreateEmulatorResult result = await emulatorManager.createEmulator();

      expect(result.success, true);
    });

    testWithoutContext('create emulator with a unique name does not throw', () async {
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['avdmanager', 'list', 'device', '-c'],
            stdout: 'test\ntest2\npixel\npixel-xl\n',
          ),
          kListEmulatorsCommand,
          const FakeCommand(
            command: <String>[
              'avdmanager',
              'create',
              'avd',
              // The specified name is given with the -n flag.
              '-n',
              'test',
              '-k',
              'system-images;android-27;google_apis_playstore;x86',
              '-d',
              'pixel',
            ],
          )
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );
      final CreateEmulatorResult result = await emulatorManager.createEmulator(name: 'test');

      expect(result.success, true);
    });

    testWithoutContext('create emulator with an existing name errors', () async {
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['avdmanager', 'list', 'device', '-c'],
            stdout: 'test\ntest2\npixel\npixel-xl\n',
          ),
          kListEmulatorsCommand,
          const FakeCommand(
            command: <String>[
              'avdmanager',
              'create',
              'avd',
              '-n',
              'existing-avd-1',
              '-k',
              'system-images;android-27;google_apis_playstore;x86',
              '-d',
              'pixel',
            ],
            exitCode: 1,
            stderr: "Error: Android Virtual Device 'existing-avd-1' already exists.\n"
              'Use --force if you want to replace it.'
          )
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );
      final CreateEmulatorResult result = await emulatorManager.createEmulator(name: 'existing-avd-1');

      expect(result.success, false);
    });

    // iOS discovery uses context.
    testUsingContext('create emulator without a name but when default exists adds a suffix', () async {
      final EmulatorManager emulatorManager = EmulatorManager(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['emulator', '-list-avds'],
            stdout: 'existing-avd-1\nflutter_emulator',
          ),
          const FakeCommand(
            command: <String>['avdmanager', 'list', 'device', '-c'],
            stdout: 'test\ntest2\npixel\npixel-xl\n',
          ),
          kListEmulatorsCommand,
          const FakeCommand(
            command: <String>[
              'avdmanager',
              'create',
              'avd',
              // a "_2" suffix is added to disambiguate from the existing emulator.
              '-n',
              'flutter_emulator_2',
              '-k',
              'system-images;android-27;google_apis_playstore;x86',
              '-d',
              'pixel',
            ],
          )
        ]),
        androidSdk: mockSdk,
        androidWorkflow: AndroidWorkflow(
          androidSdk: mockSdk,
          featureFlags: TestFeatureFlags(),
        ),
      );
      final CreateEmulatorResult result = await emulatorManager.createEmulator();

      expect(result.success, true);
      expect(result.emulatorName, 'flutter_emulator_2');
    });
  });

  group('ios_emulators', () {
    bool didAttemptToRunSimulator = false;
    setUp(() {
      when(mockXcode.xcodeSelectPath).thenReturn('/fake/Xcode.app/Contents/Developer');
      when(mockXcode.getSimulatorPath()).thenAnswer((_) => '/fake/simulator.app');
      when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
        final List<String> args = invocation.positionalArguments[0] as List<String>;
        if (args.length >= 3 && args[0] == 'open' && args[1] == '-a' && args[2] == '/fake/simulator.app') {
          didAttemptToRunSimulator = true;
        }
        return ProcessResult(101, 0, '', '');
      });
    });
    testUsingContext('runs correct launch commands', () async {
      const Emulator emulator = IOSEmulator('ios');
      await emulator.launch();
      expect(didAttemptToRunSimulator, equals(true));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Xcode: () => mockXcode,
    });
  });
}

class TestEmulatorManager extends EmulatorManager {
  TestEmulatorManager(this.allEmulators);

  final List<Emulator> allEmulators;

  @override
  Future<List<Emulator>> getAllAvailableEmulators() {
    return Future<List<Emulator>>.value(allEmulators);
  }
}

class FakeEmulator extends Emulator {
  const FakeEmulator(String id, this.name, this.manufacturer)
    : super(id, true);

  @override
  final String name;

  @override
  final String manufacturer;

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.android;

  @override
  Future<void> launch() {
    throw UnimplementedError('Not implemented in Mock');
  }
}

class MockProcessManager extends Mock implements ProcessManager {

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    final String program = command[0] as String;
    final List<String> args = command.sublist(1) as List<String>;
    switch (program) {
      case '/usr/bin/xcode-select':
        throw ProcessException(program, args);
        break;
    }
    throw StateError('Unexpected process call: $command');
  }
}

class MockXcode extends Mock implements Xcode {}
