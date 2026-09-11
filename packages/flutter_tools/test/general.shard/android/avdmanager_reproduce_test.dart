// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  group('avdmanager reproduction tests', () {
    late MemoryFileSystem fileSystem;
    late BufferLogger logger;
    late FakeProcessManager processManager;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
    });

    testUsingContext('doctor detects and reports a missing avdmanager', () async {
      final sdk = FakeAndroidSdk()
        ..directory = fileSystem.directory('/sdk')
        ..adbPath = '/sdk/platform-tools/adb'
        ..emulatorPath = '/sdk/emulator/emulator'
        ..cmdlineToolsAvailable = true
        ..platformToolsAvailable = true
        ..licensesAvailable = true
        ..latestVersion = FakeAndroidSdkVersion();

      fileSystem.directory('/sdk/cmdline-tools').createSync(recursive: true);

      expect(sdk.avdManagerPath, isNull);

      final validator = AndroidValidator(
        java: FakeJava(),
        androidSdk: sdk,
        logger: logger,
        platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
        userMessages: UserMessages(),
        processManager: processManager,
        osUtils: FakeOperatingSystemUtils(),
      );

      final ValidationResult result = await validator.validate();

      expect(result.type, isNot(ValidationType.success));
      final bool containsAvdManagerError = result.messages.any(
        (ValidationMessage message) => message.isError && message.message.contains('avdmanager'),
      );
      expect(containsAvdManagerError, isTrue, reason: 'Doctor should report missing avdmanager.');
    });

    testUsingContext('create emulator fails gracefully if avdmanager path is null', () async {
      final sdk = FakeAndroidSdk()
        ..directory = fileSystem.directory('/sdk')
        ..adbPath = '/sdk/platform-tools/adb'
        ..emulatorPath = '/sdk/emulator/emulator'
        ..cmdlineToolsAvailable = true
        ..platformToolsAvailable = true
        ..licensesAvailable = true
        ..latestVersion = FakeAndroidSdkVersion();

      expect(sdk.avdManagerPath, isNull);

      processManager.addCommand(
        const FakeCommand(command: <String>['/sdk/emulator/emulator', '-list-avds']),
      );

      final emulatorManager = EmulatorManager(
        java: FakeJava(),
        androidSdk: sdk,
        logger: logger,
        processManager: processManager,
        androidWorkflow: AndroidWorkflow(androidSdk: sdk, featureFlags: TestFeatureFlags()),
        fileSystem: fileSystem,
      );

      final CreateEmulatorResult result = await emulatorManager.createEmulator();
      expect(result.success, isFalse);
      expect(result.error, contains('avdmanager is missing'));
    });

    testUsingContext('create emulator fails gracefully if avdmanager fails to execute', () async {
      final sdk = FakeAndroidSdk()
        ..directory = fileSystem.directory('/sdk')
        ..adbPath = '/sdk/platform-tools/adb'
        ..emulatorPath = '/sdk/emulator/emulator'
        ..cmdlineToolsAvailable = true
        ..platformToolsAvailable = true
        ..licensesAvailable = true
        ..latestVersion = FakeAndroidSdkVersion();

      sdk.avdManagerPath = 'avdmanager';

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>['/sdk/emulator/emulator', '-list-avds']),
        const FakeCommand(
          command: <String>['avdmanager', 'list', 'device', '-c'],
          exception: ProcessException('avdmanager', <String>[
            'list',
            'device',
            '-c',
          ], 'Permission denied'),
        ),
      ]);

      final emulatorManager = EmulatorManager(
        java: FakeJava(),
        androidSdk: sdk,
        logger: logger,
        processManager: processManager,
        androidWorkflow: AndroidWorkflow(androidSdk: sdk, featureFlags: TestFeatureFlags()),
        fileSystem: fileSystem,
      );

      final CreateEmulatorResult result = await emulatorManager.createEmulator();
      expect(result.success, isFalse);
      expect(result.error, contains('Permission denied'));
    });
  });
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String? sdkManagerPath;

  @override
  String? sdkManagerVersion;

  @override
  String? adbPath;

  @override
  bool licensesAvailable = false;

  @override
  bool platformToolsAvailable = false;

  @override
  bool cmdlineToolsAvailable = false;

  @override
  late Directory directory;

  @override
  AndroidSdkVersion? latestVersion;

  @override
  String? emulatorPath;

  @override
  String? avdManagerPath;

  @override
  String? getAvdManagerPath() => avdManagerPath;

  @override
  String getAvdPath() => 'avd';

  @override
  List<String> validateSdkWellFormed() => <String>[];
}

class FakeAndroidSdkVersion extends Fake implements AndroidSdkVersion {
  @override
  int sdkLevel = 36;

  @override
  Version buildToolsVersion = Version(36, 0, 0);

  @override
  String get buildToolsVersionName => '36.0.0';

  @override
  String get platformName => 'android-36';

  @override
  List<String> validateSdkWellFormed() => <String>[];
}
