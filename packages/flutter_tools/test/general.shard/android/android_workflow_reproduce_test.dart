// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

class LocalFakeAndroidSdkVersion extends Fake implements AndroidSdkVersion {
  @override
  int sdkLevel = 36;

  @override
  Version buildToolsVersion = Version(33, 0, 2);

  @override
  String buildToolsVersionName = '33.0.2';

  @override
  String platformName = 'android-33';
}

class LocalFakeAndroidSdk extends Fake implements AndroidSdk {
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
  Directory directory = MemoryFileSystem.test().directory('/foo/bar');

  @override
  AndroidSdkVersion? latestVersion;

  @override
  String? emulatorPath;

  @override
  List<String> validateSdkWellFormed() => <String>[];
}

class FakeAndroidStudioWithValidation extends Fake implements AndroidStudio {
  FakeAndroidStudioWithValidation({
    required this.directory,
    required this.validationMessages,
    this.javaPath,
    this.isValid = true,
    this.version,
  });

  @override
  final String directory;

  @override
  final List<String> validationMessages;

  @override
  final String? javaPath;

  @override
  final bool isValid;

  @override
  final Version? version;
}

void main() {
  late LocalFakeAndroidSdk sdk;
  late Logger logger;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;

  setUp(() {
    sdk = LocalFakeAndroidSdk();
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory('/home/me').createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
  });

  testUsingContext(
    'suggests installing cmdline-tools via Android Studio SDK Manager UI when installed',
    () async {
      sdk
        ..licensesAvailable = true
        ..platformToolsAvailable = true
        ..cmdlineToolsAvailable = false
        ..directory = fileSystem.directory('/foo/bar')
        ..emulatorPath = 'path/to/emulator';

      final fakeStudio = FakeAndroidStudioWithValidation(
        directory: '/opt/android-studio',
        validationMessages: <String>['Java version 17.0.2'],
      );

      final androidValidator = AndroidValidator(
        java: FakeJava(),
        androidSdk: sdk,
        logger: logger,
        platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
        userMessages: UserMessages(),
        processManager: processManager,
        osUtils: FakeOperatingSystemUtils(),
        androidStudios: <AndroidStudio>[fakeStudio],
      );

      final ValidationResult validationResult = await androidValidator.validate();
      expect(validationResult.type, ValidationType.missing);

      final ValidationMessage cmdlineMessage = validationResult.messages.last;
      expect(cmdlineMessage.type, ValidationMessageType.error);
      expect(cmdlineMessage.message, contains('Android SDK Command-line Tools (latest)'));
      expect(cmdlineMessage.message, contains('SDK Manager'));
    },
  );

  testUsingContext(
    'shows Android Studio Java validation messages when bundled Java is invalid',
    () async {
      final sdkVersion = LocalFakeAndroidSdkVersion();
      sdk
        ..licensesAvailable = true
        ..platformToolsAvailable = true
        ..cmdlineToolsAvailable = true
        ..directory = fileSystem.directory('/foo/bar')
        ..emulatorPath = 'path/to/emulator'
        ..latestVersion = sdkVersion;

      final fakeStudio = FakeAndroidStudioWithValidation(
        directory: '/opt/android-studio',
        validationMessages: <String>[
          'Unable to find bundled Java version.',
          'Failed to run Java: ProcessException: Permission denied',
        ],
        isValid: false,
      );

      final androidValidator = AndroidValidator(
        java: FakeJava(canRun: false),
        androidSdk: sdk,
        logger: logger,
        platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
        userMessages: UserMessages(),
        processManager: processManager,
        osUtils: FakeOperatingSystemUtils(),
        androidStudios: <AndroidStudio>[fakeStudio],
      );

      final ValidationResult validationResult = await androidValidator.validate();
      expect(validationResult.type, ValidationType.partial);
      final String messages = validationResult.messages.map((m) => m.message).join('\n');
      expect(messages, contains('Android Studio at /opt/android-studio'));
      expect(messages, contains('Unable to find bundled Java version.'));
      expect(messages, contains('Failed to run Java: ProcessException: Permission denied'));
    },
  );
}
