// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/mocks.dart' show MockAndroidSdk, MockProcessManager;

class MockAndroidSdkVersion extends Mock implements AndroidSdkVersion {}

void main() {
  AndroidSdk sdk;
  Logger logger;
  MemoryFileSystem fileSystem;
  MockProcessManager processManager;
  FakeStdio stdio;

  setUp(() {
    sdk = MockAndroidSdk();
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory('/home/me').createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = MockProcessManager();
    stdio = FakeStdio();
  });

  FakeProcess Function(List<String>) processMetaFactory(List<String> stdout) {
    final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(
        stdout.map<List<int>>((String s) => s.codeUnits));
    return (List<String> command) => FakeProcess(stdout: stdoutStream);
  }

  testWithoutContext('AndroidWorkflow handles a null AndroidSDK', () {
    final AndroidWorkflow androidWorkflow = AndroidWorkflow(
      featureFlags: TestFeatureFlags(),
      androidSdk: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
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
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    expect(androidWorkflow.canLaunchDevices, false);
    expect(androidWorkflow.canListDevices, false);
    expect(androidWorkflow.canListEmulators, false);
  });

  // Android Studio is not currently supported on Linux Arm64 hosts.
  testWithoutContext('Not supported AndroidStudio on Linux Arm Hosts', () {
    final MockAndroidSdk androidSdk = MockAndroidSdk();
    when(androidSdk.adbPath).thenReturn(null);
    final AndroidWorkflow androidWorkflow = AndroidWorkflow(
      featureFlags: TestFeatureFlags(),
      androidSdk: androidSdk,
      operatingSystemUtils: CustomFakeOperatingSystemUtils(hostPlatform: HostPlatform.linux_arm64),
    );

    expect(androidWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('licensesAccepted returns LicensesAccepted.unknown if cannot find sdkmanager', () async {
    processManager.canRunSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;

    expect(licenseStatus, LicensesAccepted.unknown);
  });

  testWithoutContext('licensesAccepted returns LicensesAccepted.unknown if cannot run sdkmanager', () async {
    processManager.runSucceeds = false;
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted licenseStatus = await licenseValidator.licensesAccepted;

    expect(licenseStatus, LicensesAccepted.unknown);
  });

  testWithoutContext('licensesAccepted handles garbage/no output', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted result = await licenseValidator.licensesAccepted;

    expect(result, equals(LicensesAccepted.unknown));
    expect(processManager.commands.first, equals('/foo/bar/sdkmanager'));
    expect(processManager.commands.last, equals('--licenses'));
  });

  testWithoutContext('licensesAccepted works for all licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      'All SDK package licenses accepted.',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted result = await licenseValidator.licensesAccepted;

    expect(result, equals(LicensesAccepted.all));
  });

  testWithoutContext('licensesAccepted works for some licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      '2 of 5 SDK package licenses not accepted.',
      'Review licenses that have not been accepted (y/N)?',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted result = await licenseValidator.licensesAccepted;

    expect(result, equals(LicensesAccepted.some));
  });

  testWithoutContext('licensesAccepted works for no licenses accepted', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.processFactory = processMetaFactory(<String>[
      '[=======================================] 100% Computing updates...             ',
      '5 of 5 SDK package licenses not accepted.',
      'Review licenses that have not been accepted (y/N)?',
    ]);

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    final LicensesAccepted result = await licenseValidator.licensesAccepted;

    expect(result, equals(LicensesAccepted.none));
  });

  testWithoutContext('runLicenseManager succeeds for version >= 26', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('26.0.0');

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    expect(await licenseValidator.runLicenseManager(), isTrue);
  });

  testWithoutContext('runLicenseManager errors when sdkmanager is not found', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.canRunSucceeds = false;

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    expect(licenseValidator.runLicenseManager(), throwsToolExit());
  });

  testWithoutContext('runLicenseManager errors when sdkmanager fails to run', () async {
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.runSucceeds = false;

    final AndroidLicenseValidator licenseValidator = AndroidLicenseValidator(
      androidSdk: sdk,
      fileSystem: fileSystem,
      processManager: processManager,
      platform: FakePlatform(environment: <String, String>{'HOME': '/home/me'}),
      stdio: stdio,
      logger: BufferLogger.test(),
      userMessages: UserMessages(),
      androidStudio: null,
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    expect(licenseValidator.runLicenseManager(), throwsToolExit());
  });

  testWithoutContext('detects license-only SDK installation', () async {
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(false);
    final ValidationResult validationResult = await AndroidValidator(
      androidStudio: null,
      androidSdk: sdk,
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: UserMessages(),
    ).validate();
    expect(validationResult.type, ValidationType.partial);
    expect(
      validationResult.messages.last.message,
      UserMessages().androidSdkLicenseOnly(kAndroidHome),
    );
  });

  testWithoutContext('detects minimum required SDK and buildtools', () async {
    final AndroidSdkVersion mockSdkVersion = MockAndroidSdkVersion();
    when(sdk.licensesAvailable).thenReturn(true);
    when(sdk.platformToolsAvailable).thenReturn(true);

    // Test with invalid SDK and build tools
    when(mockSdkVersion.sdkLevel).thenReturn(28);
    when(mockSdkVersion.buildToolsVersion).thenReturn(Version(26, 0, 3));
    when(sdk.directory).thenReturn(fileSystem.directory('/foo/bar'));
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.latestVersion).thenReturn(mockSdkVersion);
    when(sdk.validateSdkWellFormed()).thenReturn(<String>[]);
    when(processManager.runSync(<String>['which', 'java'])).thenReturn(ProcessResult(123, 1, '', ''));
    final String errorMessage = UserMessages().androidSdkBuildToolsOutdated(
      sdk.sdkManagerPath,
      kAndroidSdkMinVersion,
      kAndroidSdkBuildToolsMinVersion.toString(),
      FakePlatform(),
    );

    final AndroidValidator androidValidator = AndroidValidator(
      androidStudio: null,
      androidSdk: sdk,
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
      userMessages: UserMessages(),
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
    when(sdk.directory).thenReturn(fileSystem.directory('/foo/bar'));
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.latestVersion).thenReturn(mockSdkVersion);
    when(sdk.validateSdkWellFormed()).thenReturn(<String>[]);

    //Test with older version of JDK
    const String javaVersionText = 'openjdk version "1.7.0_212"';
    when(processManager.run(argThat(contains('-version')))).thenAnswer((_) =>
      Future<ProcessResult>.value(ProcessResult(0, 0, null, javaVersionText)));
    final String errorMessage = UserMessages().androidJavaMinimumVersion(javaVersionText);

    final ValidationResult validationResult = await AndroidValidator(
      androidSdk: sdk,
      androidStudio: null,
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me', 'JAVA_HOME': 'home/java'},
      processManager: processManager,
      userMessages: UserMessages(),
    ).validate();
    expect(validationResult.type, ValidationType.partial);
    expect(
      validationResult.messages.last.message,
      errorMessage,
    );
    expect(
      validationResult.messages.any(
        (ValidationMessage message) => message.message.contains('Unable to locate Android SDK')
      ),
      false,
    );
  });

  testWithoutContext('Mentions `flutter config --android-sdk if user has no AndroidSdk`', () async {
    final ValidationResult validationResult = await AndroidValidator(
      androidSdk: null,
      androidStudio: null,
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform()..environment = <String, String>{'HOME': '/home/me', 'JAVA_HOME': 'home/java'},
      processManager: processManager,
      userMessages: UserMessages(),
    ).validate();

    expect(
      validationResult.messages.any(
        (ValidationMessage message) => message.message.contains('flutter config --android-sdk')
      ),
      true,
    );
  });
}

class CustomFakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  CustomFakeOperatingSystemUtils({
    HostPlatform hostPlatform = HostPlatform.linux_x64
  })  : _hostPlatform = hostPlatform;

  final HostPlatform _hostPlatform;

  @override
  String get name => 'Linux';

  @override
  HostPlatform get hostPlatform => _hostPlatform;
}
