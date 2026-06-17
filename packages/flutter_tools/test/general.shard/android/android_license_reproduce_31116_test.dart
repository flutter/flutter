// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  late Logger logger;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late FakeStdio stdio;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory('/home/me').createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
    stdio = FakeStdio();
  });

  testWithoutContext(
    'AndroidLicenseValidator falls back to compatible JDK on PATH if JAVA_HOME is incompatible',
    () async {
      // Setup incompatible JDK 11 at /jdk11
      fileSystem.directory('/jdk11/bin').createSync(recursive: true);
      fileSystem.file('/jdk11/bin/java').createSync();

      // Setup compatible JDK 8 at /jdk8
      fileSystem.directory('/jdk8/bin').createSync(recursive: true);
      fileSystem.file('/jdk8/bin/java').createSync();

      // Setup Android SDK
      final sdk = FakeAndroidSdk();
      sdk.directory = fileSystem.directory('/sdk');
      sdk.sdkManagerPath = '/sdk/tools/bin/sdkmanager';
      fileSystem.file(sdk.sdkManagerPath).createSync(recursive: true);
      sdk.latestVersion = FakeAndroidSdkVersion();

      // Platform has JAVA_HOME set to /jdk11, and /jdk8/bin on PATH
      final platform = FakePlatform(
        environment: <String, String>{
          'HOME': '/home/me',
          'JAVA_HOME': '/jdk11',
          'PATH': '/jdk8/bin',
        },
      );

      // Add commands to FakeProcessManager
      // 1. Finding java on PATH (during Java.find)
      processManager.addCommand(
        const FakeCommand(command: <String>['which', 'java'], stdout: '/jdk8/bin/java\n'),
      );

      // 2. Checking version of /jdk11/bin/java (incompatible)
      processManager.addCommand(
        const FakeCommand(
          command: <String>['/jdk11/bin/java', '-version'],
          stderr: 'openjdk version "11.0.2"\n',
        ),
      );

      // 3. Pre-flight check: running sdkmanager --version with JDK 11 (fails with ClassNotFoundException / exit code 1)
      processManager.addCommand(
        const FakeCommand(
          command: <String>['/sdk/tools/bin/sdkmanager', '--version'],
          environment: <String, String>{'JAVA_HOME': '/jdk11', 'PATH': '/jdk11/bin:/jdk8/bin'},
          exitCode: 1,
          stderr: 'java.lang.NoClassDefFoundError: javax/xml/bind/annotation/XmlSchema\n',
        ),
      );

      // 4. Pre-flight check: running sdkmanager --version with fallback JDK 8 (succeeds)
      processManager.addCommand(
        const FakeCommand(
          command: <String>['/sdk/tools/bin/sdkmanager', '--version'],
          environment: <String, String>{'JAVA_HOME': '/jdk8', 'PATH': '/jdk8/bin:/jdk8/bin'},
          stdout: '26.0.0\n',
        ),
      );

      // 5. Attempting to run sdkmanager with the fallback JDK 8 (succeeds)
      processManager.addCommand(
        const FakeCommand(
          command: <String>['/sdk/tools/bin/sdkmanager', '--licenses'],
          environment: <String, String>{'JAVA_HOME': '/jdk8', 'PATH': '/jdk8/bin:/jdk8/bin'},
          stdout: 'All SDK package licenses accepted.\n',
        ),
      );

      // Find java
      final Java? java = Java.find(
        config: FakeConfig(),
        androidStudio: null,
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
      );

      expect(java, isNotNull);
      expect(java!.javaHome, '/jdk11');

      final licenseValidator = AndroidLicenseValidator(
        java: java,
        androidSdk: sdk,
        processManager: processManager,
        platform: platform,
        stdio: stdio,
        logger: logger,
        userMessages: UserMessages(),
      );

      final ValidationResult result = await licenseValidator.validateImpl();

      // Verify that the validator resolves the compatibility issue and succeeds by falling back.
      expect(result.type, ValidationType.success);
      expect(result.messages.first.message, contains('All Android licenses accepted'));
      expect(processManager, hasNoRemainingExpectations);
    },
  );
}

class FakeConfig extends Fake implements Config {
  @override
  Object? getValue(String key) => null;
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
  List<String> validateSdkWellFormed() => <String>[];
}

class FakeAndroidSdkVersion extends Fake implements AndroidSdkVersion {
  @override
  int sdkLevel = 0;

  @override
  String get buildToolsVersionName => '28.0.3';
}
