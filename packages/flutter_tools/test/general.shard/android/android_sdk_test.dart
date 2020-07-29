// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  testWithoutContext('Can locate SDK from file system', () {
    // sdkDir = MockAndroidSdk.createSdkDirectory();
    // config.setValue('android-sdk', sdkDir.path);

    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

    expect(sdk.latestVersion, isNotNull);
    expect(sdk.latestVersion.sdkLevel, 23);
  });

  testWithoutContext('Can locate SDK with at least version N from file system', () {
    // sdkDir = MockAndroidSdk.createSdkDirectory(withAndroidN: true);
    // config.setValue('android-sdk', sdkDir.path);

    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

    expect(sdk.latestVersion, isNotNull);
    expect(sdk.latestVersion.sdkLevel, 24);
  });

  testWithoutContext('returns sdkmanager path under cmdline tools on Linux/macOS', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final AndroidSdk sdk = setUpAndroidSdk(fileSystem: fileSystem);
    fileSystem.file(
      fileSystem.path.join(sdk.directory, 'cmdline-tools/latest/bin/sdkmanager')
    ).createSync(recursive: true);

    expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory, 'cmdline-tools/latest/bin/sdkmanager'));
  });

  testWithoutContext('returns sdkmanager.bat path under cmdline tools for windows', () {
    sdkDir = MockAndroidSdk.createSdkDirectory();
    config.setValue('android-sdk', sdkDir.path);

    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
    fileSystem.file(
      fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat')
    ).createSync(recursive: true);

    expect(sdk.sdkManagerPath,
      fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat'));
  });

  testWithoutContext('returns sdkmanager path under tools if cmdline doesnt exist', () {


    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

    expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory, 'tools', 'bin', 'sdkmanager'));
  });

  testWithoutContext('returns sdkmanager version', () {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          '',
          '--version'
        ],
        stdout: '26.1.1'
      ),
    ]);
    final AndroidSdk sdk = setUpAndroidSdk(processManager: processManager);

    // when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
    // when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
    //     environment: argThat(isNotNull,  named: 'environment')))
    //     .thenReturn(ProcessResult(1, 0, '26.1.1\n', ''));
    // when(processManager.runSync(
    //   <String>['/usr/libexec/java_home', '-v', '1.8'],
    //   workingDirectory: anyNamed('workingDirectory'),
    //   environment: anyNamed('environment'),
    // )).thenReturn(ProcessResult(0, 0, '', ''));

    expect(sdk.sdkManagerVersion, '26.1.1');
  });

  testWithoutContext('returns validate sdk is well formed', () {
    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
    when(processManager.canRun(sdk.adbPath)).thenReturn(true);

    final List<String> validationIssues = sdk.validateSdkWellFormed();
    expect(validationIssues.first, 'No valid Android SDK platforms found in'
      ' /.tmp_rand0/flutter_mock_android_sdk.rand0/platforms. Candidates were:\n'
      '  - android-22\n'
      '  - android-23');
  });

  testWithoutContext('does not throw on sdkmanager version check failure', () {


    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
    when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
    when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
        environment: argThat(isNotNull,  named: 'environment')))
        .thenReturn(ProcessResult(1, 1, '26.1.1\n', 'Mystery error'));
    when(processManager.runSync(
      <String>['/usr/libexec/java_home', '-v', '1.8'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(ProcessResult(0, 0, '', ''));

    expect(sdk.sdkManagerVersion, isNull);
  });

  testWithoutContext('throws on sdkmanager version check if sdkmanager not found', () {


    final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
    when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(false);
    expect(() => sdk.sdkManagerVersion, throwsToolExit());
  });
}

void setUpSdkDirectory(FileSystem fileSystem) {
  final List<String> files = <String>[
    'licenses/dummy',
    'platform-tools/adb',
    'build-tools/sda/aapt',
    'build-tools/af/aapt',
    'build-tools/ljkasd/aapt',
    'platforms/android-22/android.jar',
    'platforms/android-23/android.jar'
  ];
  for (final String file in files) {
    fileSystem.file(file).createSync(recursive: true);
  }
}

AndroidSdk setUpAndroidSdk({
  FileSystem fileSystem,
  ProcessManager processManager,
  Config config,
  Platform platform,
  Logger logger,
}) {
  logger ??= BufferLogger.test();
  fileSystem ??= MemoryFileSystem.test();
  processManager ??= FakeProcessManager.any();
  config ??= Config.test(
    'test',
    directory: fileSystem.currentDirectory,
    logger: logger,
  );
  platform ??= FakePlatform(operatingSystem: 'linux', environment: <String, String>{});
  return AndroidSdk(
    '',
    fileSystem: fileSystem,
    processManager: processManager,
    platform: platform,
    logger: logger,
    operatingSystemUtils: OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      processManager: processManager,
    ),
    androidStudio: MockAndroidStudio(),
  );
}

class MockAndroidStudio extends Mock implements AndroidStudio {}
