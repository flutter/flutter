// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  MemoryFileSystem fileSystem;
  MockProcessManager processManager;
  Config config;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = MockProcessManager();
    config = Config.test(
      'test',
      directory: fileSystem.currentDirectory,
      logger: BufferLogger.test(),
    );
  });

  group('android_sdk AndroidSdk', () {
    Directory sdkDir;

    tearDown(() {
      if (sdkDir != null) {
        tryToDelete(sdkDir);
        sdkDir = null;
      }
    });

    testUsingContext('parse sdk', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
    });

    testUsingContext('parse sdk N', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withAndroidN: true);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager path under cmdline tools on Linux/macOS', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager.bat path under cmdline tools for windows', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath,
        fileSystem.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager path under tools if cmdline doesnt exist', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory, 'tools', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager version', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
          environment: argThat(isNotNull,  named: 'environment')))
          .thenReturn(ProcessResult(1, 0, '26.1.1\n', ''));
      when(processManager.runSync(
        <String>['/usr/libexec/java_home', '-v', '1.8'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenReturn(ProcessResult(0, 0, '', ''));

      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
    });

    testUsingContext('returns validate sdk is well formed', () {
      sdkDir = MockBrokenAndroidSdk.createSdkDirectory(
        fileSystem: fileSystem,
      );
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.adbPath)).thenReturn(true);

      final List<String> validationIssues = sdk.validateSdkWellFormed();
      expect(validationIssues.first, 'No valid Android SDK platforms found in'
        ' /.tmp_rand0/flutter_mock_android_sdk.rand0/platforms. Candidates were:\n'
        '  - android-22\n'
        '  - android-23');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
    });

    testUsingContext('does not throw on sdkmanager version check failure', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

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
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withSdkManager: false);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(false);
      expect(() => sdk.sdkManagerVersion, throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
    });
  });
}

/// A broken SDK installation.
class MockBrokenAndroidSdk extends Mock implements AndroidSdk {
  static Directory createSdkDirectory({
    bool withAndroidN = false,
    bool withSdkManager = true,
    @required FileSystem fileSystem,
  }) {
    final Directory dir = fileSystem.systemTempDirectory.createTempSync('flutter_mock_android_sdk.');
    _createSdkFile(dir, 'licenses/dummy');
    _createSdkFile(dir, 'platform-tools/adb');

    _createSdkFile(dir, 'build-tools/sda/aapt');
    _createSdkFile(dir, 'build-tools/af/aapt');
    _createSdkFile(dir, 'build-tools/ljkasd/aapt');

    _createSdkFile(dir, 'platforms/android-22/android.jar');
    _createSdkFile(dir, 'platforms/android-23/android.jar');

    return dir;
  }

  static void _createSdkFile(Directory dir, String filePath, { String contents }) {
    final File file = dir.childFile(filePath);
    file.createSync(recursive: true);
    if (contents != null) {
      file.writeAsStringSync(contents, flush: true);
    }
  }
}
