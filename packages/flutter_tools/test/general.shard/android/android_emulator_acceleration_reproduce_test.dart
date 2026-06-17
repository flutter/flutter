// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
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

  testUsingContext('AndroidValidator succeeds when emulator acceleration check passes', () async {
    sdk
      ..licensesAvailable = true
      ..platformToolsAvailable = false
      ..cmdlineToolsAvailable = true
      ..directory = fileSystem.directory('/foo/bar')
      ..emulatorPath = 'path/to/emulator';

    processManager.addCommand(
      FakeCommand(
        command: <String>[sdk.emulatorPath!, '-version'],
        stdout: 'INFO    | Android emulator version 35.2.10.0 (build_id 12414864) (CL:N/A)',
      ),
    );

    // Mock the -accel-check command succeeding with output accel:\n0
    processManager.addCommand(
      FakeCommand(
        command: <String>[sdk.emulatorPath!, '-accel-check'],
        stdout: 'accel:\n0\nHAXM version 6.0.1 (3) is installed and usable.\naccel',
      ),
    );

    final ValidationResult validationResult = await AndroidValidator(
      java: FakeJava(),
      androidSdk: sdk,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: UserMessages(),
      processManager: processManager,
      osUtils: FakeOperatingSystemUtils(),
    ).validate();

    // Verify it doesn't fail due to acceleration, and contains no acceleration warning.
    expect(validationResult.type, ValidationType.partial); // Partial because of missing other toolchain components
    final List<String> messages = validationResult.messages.map((m) => m.message).toList();
    expect(messages.any((msg) => msg.contains('acceleration')), isFalse);
    expect(messages.any((msg) => msg.contains('emulator-acceleration.html')), isFalse);
    expect(processManager.hasRemainingExpectations, isFalse);
  });

  testUsingContext('AndroidValidator warns when emulator acceleration check fails', () async {
    sdk
      ..licensesAvailable = true
      ..platformToolsAvailable = false
      ..cmdlineToolsAvailable = true
      ..directory = fileSystem.directory('/foo/bar')
      ..emulatorPath = 'path/to/emulator';

    processManager.addCommand(
      FakeCommand(
        command: <String>[sdk.emulatorPath!, '-version'],
        stdout: 'INFO    | Android emulator version 35.2.10.0 (build_id 12414864) (CL:N/A)',
      ),
    );

    // Mock the -accel-check command failing
    processManager.addCommand(
      FakeCommand(
        command: <String>[sdk.emulatorPath!, '-accel-check'],
        stdout: 'accel:\n1\nHAXM is not installed.\naccel',
        exitCode: 1,
      ),
    );

    final ValidationResult validationResult = await AndroidValidator(
      java: FakeJava(),
      androidSdk: sdk,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: UserMessages(),
      processManager: processManager,
      osUtils: FakeOperatingSystemUtils(),
    ).validate();

    expect(validationResult.type, ValidationType.partial);
    final List<String> messages = validationResult.messages.map((m) => m.message).toList();
    final bool hasWarning = messages.any((msg) =>
        msg.contains('Android emulator VM acceleration is not configured') &&
        msg.contains('https://developer.android.com/studio/run/emulator-acceleration.html'));
    expect(hasWarning, isTrue);
    expect(processManager.hasRemainingExpectations, isFalse);
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


