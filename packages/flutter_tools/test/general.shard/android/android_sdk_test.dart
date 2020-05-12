// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessResult;
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  MemoryFileSystem fs;
  MockProcessManager processManager;

  setUp(() {
    fs = MemoryFileSystem();
    processManager = MockProcessManager();
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
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('parse sdk N', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withAndroidN: true);
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns sdkmanager path under cmdline tools on Linux/macOS', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      globals.fs.file(
        globals.fs.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath, globals.fs.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
    });

    testUsingContext('returns sdkmanager.bat path under cmdline tools for windows', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      globals.fs.file(
        globals.fs.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath,
        globals.fs.path.join(sdk.directory, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
    });

    testUsingContext('returns sdkmanager path under tools if cmdline doesnt exist', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerPath, globals.fs.path.join(sdk.directory, 'tools', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns sdkmanager version', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(globals.processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(globals.processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
          environment: argThat(isNotNull,  named: 'environment')))
          .thenReturn(ProcessResult(1, 0, '26.1.1\n', ''));
      if (globals.platform.isMacOS) {
        when(globals.processManager.runSync(
          <String>['/usr/libexec/java_home', '-v', '1.8'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenReturn(ProcessResult(0, 0, '', ''));
      }
      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('returns validate sdk is well formed', () {
      sdkDir = MockBrokenAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(globals.processManager.canRun(sdk.adbPath)).thenReturn(true);

      final List<String> validationIssues = sdk.validateSdkWellFormed();
      expect(validationIssues.first, 'No valid Android SDK platforms found in'
        ' /.tmp_rand0/flutter_mock_android_sdk.rand0/platforms. Candidates were:\n'
        '  - android-22\n'
        '  - android-23');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('does not throw on sdkmanager version check failure', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(globals.processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(globals.processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
          environment: argThat(isNotNull,  named: 'environment')))
          .thenReturn(ProcessResult(1, 1, '26.1.1\n', 'Mystery error'));
      if (globals.platform.isMacOS) {
        when(globals.processManager.runSync(
          <String>['/usr/libexec/java_home', '-v', '1.8'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenReturn(ProcessResult(0, 0, '', ''));
      }
      expect(sdk.sdkManagerVersion, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withSdkManager: false);
      globals.config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(globals.processManager.canRun(sdk.sdkManagerPath)).thenReturn(false);
      expect(() => sdk.sdkManagerVersion, throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });
  });
}

/// A broken SDK installation.
class MockBrokenAndroidSdk extends Mock implements AndroidSdk {
  static Directory createSdkDirectory({
    bool withAndroidN = false,
    bool withSdkManager = true,
  }) {
    final Directory dir = globals.fs.systemTempDirectory.createTempSync('flutter_mock_android_sdk.');
    final String exe = globals.platform.isWindows ? '.exe' : '';
    _createSdkFile(dir, 'licenses/dummy');
    _createSdkFile(dir, 'platform-tools/adb$exe');

    _createSdkFile(dir, 'build-tools/sda/aapt$exe');
    _createSdkFile(dir, 'build-tools/af/aapt$exe');
    _createSdkFile(dir, 'build-tools/ljkasd/aapt$exe');

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
