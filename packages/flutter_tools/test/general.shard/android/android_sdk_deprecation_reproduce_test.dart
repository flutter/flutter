// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
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
  testWithoutContext('AndroidValidator warns when ANDROID_SDK_ROOT is set', () async {
    final sdk = FakeAndroidSdk()
      ..directory = MemoryFileSystem.test().directory('/foo/bar')
      ..platformToolsAvailable = true
      ..cmdlineToolsAvailable = true;

    final androidValidator = AndroidValidator(
      java: FakeJava(),
      androidSdk: sdk,
      logger: BufferLogger.test(),
      platform: FakePlatform()
        ..environment = <String, String>{'HOME': '/home/me', 'ANDROID_SDK_ROOT': '/foo/bar'},
      userMessages: UserMessages(),
      processManager: FakeProcessManager.empty(),
      osUtils: FakeOperatingSystemUtils(),
    );

    final ValidationResult validationResult = await androidValidator.validate();

    // Check that there is a warning/hint message stating that ANDROID_SDK_ROOT is deprecated.
    final bool hasDeprecationWarning = validationResult.messages.any(
      (ValidationMessage message) =>
          message.type == ValidationMessageType.hint &&
          message.message.contains('ANDROID_SDK_ROOT') &&
          message.message.contains('deprecated') &&
          message.message.contains('ANDROID_HOME'),
    );

    expect(
      hasDeprecationWarning,
      isTrue,
      reason: 'Should warn that ANDROID_SDK_ROOT is deprecated and recommend ANDROID_HOME instead',
    );
  });

  testWithoutContext('AndroidValidator does not warn when ANDROID_SDK_ROOT is not set', () async {
    final sdk = FakeAndroidSdk()
      ..directory = MemoryFileSystem.test().directory('/foo/bar')
      ..platformToolsAvailable = true
      ..cmdlineToolsAvailable = true;

    final androidValidator = AndroidValidator(
      java: FakeJava(),
      androidSdk: sdk,
      logger: BufferLogger.test(),
      platform: FakePlatform()
        ..environment = <String, String>{'HOME': '/home/me', 'ANDROID_HOME': '/foo/bar'},
      userMessages: UserMessages(),
      processManager: FakeProcessManager.empty(),
      osUtils: FakeOperatingSystemUtils(),
    );

    final ValidationResult validationResult = await androidValidator.validate();

    final bool hasDeprecationWarning = validationResult.messages.any(
      (ValidationMessage message) =>
          message.type == ValidationMessageType.hint &&
          message.message.contains('ANDROID_SDK_ROOT'),
    );

    expect(
      hasDeprecationWarning,
      isFalse,
      reason: 'Should not warn about ANDROID_SDK_ROOT when it is not set',
    );
  });

  testWithoutContext(
    'AndroidValidator warns when ANDROID_SDK_ROOT is set and SDK is not found',
    () async {
      final androidValidator = AndroidValidator(
        java: FakeJava(),
        androidSdk: null,
        logger: BufferLogger.test(),
        platform: FakePlatform()
          ..environment = <String, String>{'HOME': '/home/me', 'ANDROID_SDK_ROOT': '/foo/bar'},
        userMessages: UserMessages(),
        processManager: FakeProcessManager.empty(),
        osUtils: FakeOperatingSystemUtils(),
      );

      final ValidationResult validationResult = await androidValidator.validate();

      final bool hasDeprecationWarning = validationResult.messages.any(
        (ValidationMessage message) =>
            message.type == ValidationMessageType.hint &&
            message.message.contains('ANDROID_SDK_ROOT') &&
            message.message.contains('deprecated') &&
            message.message.contains('ANDROID_HOME'),
      );

      expect(
        hasDeprecationWarning,
        isTrue,
        reason: 'Should warn that ANDROID_SDK_ROOT is deprecated even when SDK is not found',
      );
    },
  );
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
