// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' as gradle_utils;
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  late FakeAndroidSdk sdk;
  late Logger logger;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;

  setUp(() {
    sdk = FakeAndroidSdk();
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory('/home/me').createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
  });

  testWithoutContext('AndroidValidator detects JRE only and reports missing JDK', () async {
    // 1. Set up a JRE-only environment (java exists, but javac does not).
    const javaHome = '/home/me/jre';
    final String javaBinaryPath = fileSystem.path.join(javaHome, 'bin', 'java');
    fileSystem.file(javaBinaryPath).createSync(recursive: true);
    // Note: bin/javac is NOT created.

    // Mock process runner for 'java --version'
    processManager.addCommand(
      FakeCommand(
        command: <String>[javaBinaryPath, '--version'],
        stdout: '''
openjdk version "17.0.6" 2023-01-17
OpenJDK Runtime Environment (build 17.0.6+0)
OpenJDK 64-Bit Server VM (build 17.0.6+0, mixed mode)
''',
      ),
    );

    final Platform platform = FakePlatform(
      environment: <String, String>{'JAVA_HOME': javaHome, 'HOME': '/home/me', 'PATH': ''},
    );

    final Java java = Java.find(
      config: Config.test(),
      androidStudio: null,
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
    )!;

    // Verify java is detected successfully
    expect(java.binaryPath, javaBinaryPath);

    // Mock Android SDK to pass other checks
    sdk
      ..licensesAvailable = true
      ..platformToolsAvailable = true
      ..cmdlineToolsAvailable = true
      ..directory = fileSystem.directory('/foo/bar')
      ..latestVersion = (FakeAndroidSdkVersion()
        ..sdkLevel = gradle_utils.compileSdkVersionInt
        ..buildToolsVersion = gradle_utils.minBuildToolsVersion);

    final androidValidator = AndroidValidator(
      java: java,
      androidSdk: sdk,
      logger: logger,
      platform: platform,
      userMessages: UserMessages(),
      processManager: processManager,
      osUtils: FakeOperatingSystemUtils(),
    );

    final ValidationResult validationResult = await androidValidator.validate();

    // The validator should detect that javac is missing (it is JRE, not JDK) and report a failure/warning.
    // Therefore, validationResult.type must NOT be ValidationType.success.
    expect(
      validationResult.type,
      isNot(ValidationType.success),
      reason: 'Doctor should not be happy with just a JRE (missing JDK).',
    );

    // And it should contain the missing JDK error message
    final bool hasJdkErrorMessage = validationResult.messages.any(
      (ValidationMessage msg) =>
          msg.type == ValidationMessageType.error &&
          msg.message.contains('No Java Development Kit (JDK) found'),
    );
    expect(
      hasJdkErrorMessage,
      isTrue,
      reason: 'Doctor validation messages should contain a JDK missing error.',
    );
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
  Directory directory = MemoryFileSystem.test().directory('/foo/bar');

  @override
  AndroidSdkVersion? latestVersion;

  @override
  String? emulatorPath;

  @override
  List<String> validateSdkWellFormed() => <String>[];
}

class FakeAndroidSdkVersion extends Fake implements AndroidSdkVersion {
  @override
  int sdkLevel = 0;

  @override
  Version buildToolsVersion = Version(0, 0, 0);

  @override
  String get buildToolsVersionName => '';

  @override
  String get platformName => '';
}
