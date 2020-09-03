// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart' show AnsiTerminal, OutputPreferences;
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show MockAndroidSdk, MockProcess, MockProcessManager, MockStdio;
import '../../src/testbed.dart';

class MockAndroidSdkVersion extends Mock implements AndroidSdkVersion {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

void main() {
  AndroidSdk sdk;
  Logger logger;
  MemoryFileSystem fs;
  MockProcessManager processManager;
  MockStdio stdio;
  UserMessages userMessages;

  setUp(() {
    sdk = MockAndroidSdk();
    fs = MemoryFileSystem();
    fs.directory('/home/me').createSync(recursive: true);
    logger = BufferLogger(
      terminal: AnsiTerminal(
        stdio: null,
        platform: const LocalPlatform(),
      ),
      outputPreferences: OutputPreferences.test(),
    );
    processManager = MockProcessManager();
    stdio = MockStdio();
    userMessages = UserMessages();
  });

  MockProcess Function(List<String>) processMetaFactory(List<String> stdout) {
    final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(
        stdout.map<List<int>>((String s) => s.codeUnits));
    return (List<String> command) => MockProcess(stdout: stdoutStream);
  }

  testWithoutContext('AndroidWorkflow handles a null AndroidSDK', () {
    final AndroidWorkflow androidWorkflow = AndroidWorkflow(
      featureFlags: TestFeatureFlags(),
      androidSdk: null,
    );

    expect(androidWorkflow.canLaunchDevices, false);
    expect(androidWorkflow.canListDevices, false);
    expect(androidWorkflow.canListEmulators, false);
  });

  testWithoutContext('AndroidWorkflow handles a null adb', () {
    final MockAndroidSdk androidSdk = MockAndroidSdk();
    when(androidSdk.adbPath).thenReturn(null);
    final AndroidWorkflow androidWorkflow = AndroidWorkflow(
      featureFlags: TestFeatureFlags(),
      androidSdk: androidSdk,
    );

    expect(androidWorkflow.canLaunchDevices, false);
    expect(androidWorkflow.canListDevices, false);
    expect(androidWorkflow.canListEmulators, false);
  });


  testUsingContext('licensesAccepted returns LicensesAccepted.unknown if cannot find sdkmanager', () async {
    processManager.canRunSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;
    expect(licenseStatus, LicensesAccepted.unknown);
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('licensesAccepted returns LicensesAccepted.unknown if cannot run sdkmanager', () async {
    processManager.runSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;
    expect(licenseStatus, LicensesAccepted.unknown);
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('licensesAccepted handles garbage/no output', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.unknown));
    expect(processManager.commands.first, equals('/foo/bar/sdkmanager'));
    expect(processManager.commands.last, equals('--licenses'));
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('licensesAccepted works for all licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      'All SDK package licenses accepted.',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator();
    final LicensesAccepted result = await licenseValidator.licensesAccepted;
    expect(result, equals(LicensesAccepted.all));
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

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
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

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
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('runLicenseManager succeeds for version >= 26', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('26.0.0');

    expect(await AndroidLicenseValidator.runLicenseManager(), isTrue);
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('runLicenseManager errors when sdkmanager is not found', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.canRunSucceeds = false;

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit());
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testUsingContext('runLicenseManager errors when sdkmanager fails to run', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.runSucceeds = false;

    expect(AndroidLicenseValidator.runLicenseManager(), throwsToolExit());
  }, overrides: Map<Type, Generator>.unmodifiable(<Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    ProcessManager: () => processManager,
    Platform: () => FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    Stdio: () => stdio,
  }));

  testWithoutContext('detects license-only SDK installation', () async {
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(false);
    final ValidationResult validationResult = await AndroidValidator(
      androidStudio: null,
      androidSdk: sdk,
      fileSystem: fs,
      logger: logger,
      processManager: processManager,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: userMessages,
    ).validate();
    expect(validationResult.type, ValidationType.partial);
    expect(
      validationResult.messages.last.message,
      userMessages.androidSdkLicenseOnly(kAndroidHome),
    );
  });

  testWithoutContext('detects minimum required SDK and buildtools', () async {
    final AndroidSdkVersion mockSdkVersion = MockAndroidSdkVersion();
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(true);

    // Test with invalid SDK and build tools
    when(mockSdkVersion.sdkLevel).thenReturn(28);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(26, 0, 3));
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.latestVersion).thenReturn(mockSdkVersion);
    when(sdk.validateSdkWellFormed()).thenReturn(<String>[]);
    when(processManager.runSync(<String>['which', 'java'])).thenReturn(ProcessResult(123, 1, '', ''));
    final String errorMessage = userMessages.androidSdkBuildToolsOutdated(
      sdk.sdkManagerPath,
      kAndroidSdkMinVersion,
      kAndroidSdkBuildToolsMinVersion.toString(),
      FakePlatform(),
    );

    final AndroidValidator androidValidator = AndroidValidator(
      androidStudio: null,
      androidSdk: sdk,
      fileSystem: fs,
      logger: logger,
      processManager: processManager,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: userMessages,
    );

    ValidationResult validationResult = await androidValidator.validate();
    expect(validationResult.type, ValidationType.missing);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );

    // Test with valid SDK but invalid build tools
    when(mockSdkVersion.sdkLevel).thenReturn(29);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(28, 0, 2));

    validationResult = await androidValidator.validate();
    expect(validationResult.type, ValidationType.missing);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );

    // Test with valid SDK and valid build tools
    // Will still be partial because AnroidSdk.findJavaBinary is static :(
    when(mockSdkVersion.sdkLevel).thenReturn(kAndroidSdkMinVersion);
    when(mockSdkVersion.buildToolsVersion).thenReturn(kAndroidSdkBuildToolsMinVersion);

    validationResult = await androidValidator.validate();
    expect(validationResult.type, ValidationType.partial); // No Java binary
    expect(
      validationResult.messages.any((ValidationMessage message) => message.message == errorMessage),
      isFalse,
    );
  });

  testWithoutContext('detects minimum required java version', () async {
    final AndroidSdkVersion mockSdkVersion = MockAndroidSdkVersion();

    // Mock a pass through scenario to reach _checkJavaVersion()
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(true);
    when(mockSdkVersion.sdkLevel).thenReturn(29);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(28, 0, 3));
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.latestVersion).thenReturn(mockSdkVersion);
    when(sdk.validateSdkWellFormed()).thenReturn(<String>[]);

    //Test with older version of JDK
    const String javaVersionText = 'openjdk version "1.7.0_212"';
    when(processManager.run(argThat(contains('-version')))).thenAnswer((_) =>
      Future<ProcessResult>.value(ProcessResult(0, 0, null, javaVersionText)));
    final String errorMessage = userMessages.androidJavaMinimumVersion(javaVersionText);

    final ValidationResult validationResult = await AndroidValidator(
      androidSdk: sdk,
      androidStudio: null,
      fileSystem: fs,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me', 'JAVA_HOME': 'home/java'},
      processManager: processManager,
      userMessages: userMessages,
    ).validate();
    expect(validationResult.type, ValidationType.partial);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );
  });

  testWithoutContext('Mentions `kAndroidSdkRoot if user has no AndroidSdk`', () async {
    final ValidationResult validationResult = await AndroidValidator(
      androidSdk: null,
      androidStudio: null,
      fileSystem: fs,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me', 'JAVA_HOME': 'home/java'},
      processManager: processManager,
      userMessages: userMessages,
    ).validate();
    expect(
      validationResult.messages.any(
        (ValidationMessage message) => message.message.contains(kAndroidSdkRoot)
      ),
      true,
    );
  });
}
