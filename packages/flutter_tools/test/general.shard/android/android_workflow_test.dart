// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show MockAndroidSdk, MockProcess, MockProcessManager, MockStdio;

class MockAndroidSdkVersion extends Mock implements AndroidSdkVersion {}

void main() {
  AndroidSdk sdk;
  MemoryFileSystem fs;
  MockProcessManager processManager;
  MockStdio stdio;

  setUp(() {
    sdk = MockAndroidSdk();
    fs = MemoryFileSystem();
    fs.directory('/home/me').createSync(recursive: true);
    processManager = MockProcessManager();
    stdio = MockStdio();
  });

  MockProcess Function(List<String>) processMetaFactory(List<String> stdout) {
    final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(
        stdout.map<List<int>>((String s) => s.codeUnits));
    return (List<String> command) => MockProcess(stdout: stdoutStream);
  }

  testUsingContext('licensesAccepted returns LicensesAccepted.unknown if cannot find sdkmanager', () async {
    processManager.canRunSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;
    expect(licenseStatus, LicensesAccepted.unknown);
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('licensesAccepted returns LicensesAccepted.unknown if cannot run sdkmanager', () async {
    processManager.runSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;
    expect(licenseStatus, LicensesAccepted.unknown);
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('licensesAccepted handles garbage/no output', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.unknown));
    expect(processManager.commands.first, equals('/foo/bar/sdkmanager'));
    expect(processManager.commands.last, equals('--licenses'));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('licensesAccepted works for all licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
       '[=======================================] 100% Computing updates...             ',
       'All SDK package licenses accepted.',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.all));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('licensesAccepted works for some licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      '2 of 5 SDK package licenses not accepted.',
      'Review licenses that have not been accepted (y/N)?',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.some));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('licensesAccepted works for no licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      '5 of 5 SDK package licenses not accepted.',
      'Review licenses that have not been accepted (y/N)?',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.none));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager succeeds for version >= 26', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('26.0.0');

    expect(await AndroidLicenseValidator.runLicenseManager(), isTrue);
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors for version < 26', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('25.0.0');

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit(message: 'To update, run'));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors correctly for null version', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn(null);

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit(message: 'To update, run'));
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors when sdkmanager is not found', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.canRunSucceeds = false;

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit());
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors when sdkmanager fails to run', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.runSucceeds = false;

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit());
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('detects license-only SDK installation', () async {
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(false);
    final ValidationResult validationResult = await AndroidValidator().validate();
    expect(validationResult.type, ValidationType.partial);
    expect(
      validationResult.messages.last.message,
      userMessages.androidSdkLicenseOnly(kAndroidHome),
    );
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('detects minium required SDK and buildtools', () async {
    final AndroidSdkVersion mockSdkVersion = MockAndroidSdkVersion();
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(true);

    // Test with invalid SDK and build tools
    when(mockSdkVersion.sdkLevel).thenReturn(26);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(26, 0, 3));
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.latestVersion).thenReturn(mockSdkVersion);
    when(sdk.validateSdkWellFormed()).thenReturn(<String>[]);
    final String errorMessage = userMessages.androidSdkBuildToolsOutdated(
      sdk.sdkManagerPath,
      kAndroidSdkMinVersion,
      kAndroidSdkBuildToolsMinVersion.toString(),
    );

    ValidationResult validationResult = await AndroidValidator().validate();
    expect(validationResult.type, ValidationType.missing);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );

    // Test with valid SDK but invalid build tools
    when(mockSdkVersion.sdkLevel).thenReturn(28);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(28, 0, 2));

    validationResult = await AndroidValidator().validate();
    expect(validationResult.type, ValidationType.missing);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );

    // Test with valid SDK and valid build tools
    // Will still be partial because AnroidSdk.findJavaBinary is static :(
    when(mockSdkVersion.sdkLevel).thenReturn(kAndroidSdkMinVersion);
    when(mockSdkVersion.buildToolsVersion).thenReturn(kAndroidSdkBuildToolsMinVersion);

    validationResult = await AndroidValidator().validate();
    expect(validationResult.type, ValidationType.partial); // No Java binary
    expect(
      validationResult.messages.any((ValidationMessage message) => message.message == errorMessage),
      isFalse,
    );
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

}
