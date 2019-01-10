// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessResult;
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

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
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('parse sdk N', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withAndroidN: true);
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns sdkmanager path', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.sdkManagerPath, fs.path.join(sdk.directory, 'tools', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns sdkmanager version', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
          environment: argThat(isNotNull,  named: 'environment')))
          .thenReturn(ProcessResult(1, 0, '26.1.1\n', ''));
      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('returns validate sdk is well formed', () {
      sdkDir = MockBrokenAndroidSdk.createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.adbPath)).thenReturn(true);

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
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version'],
          environment: argThat(isNotNull,  named: 'environment')))
          .thenReturn(ProcessResult(1, 1, '26.1.1\n', 'Mystery error'));
      expect(sdk.sdkManagerVersion, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withSdkManager: false);
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(false);
      expect(() => sdk.sdkManagerVersion, throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    group('ndk', () {
      const <String, String>{
        'linux': 'linux-x86_64',
        'macos': 'darwin-x86_64',
      }.forEach((String os, String osDir) {
        testUsingContext('detection on $os', () {
          sdkDir = MockAndroidSdk.createSdkDirectory(
              withAndroidN: true, withNdkDir: osDir, withNdkSysroot: true);
          Config.instance.setValue('android-sdk', sdkDir.path);

          final String realSdkDir = sdkDir.path;
          final String realNdkDir = fs.path.join(realSdkDir, 'ndk-bundle');
          final String realNdkCompiler = fs.path.join(
              realNdkDir,
              'toolchains',
              'arm-linux-androideabi-4.9',
              'prebuilt',
              osDir,
              'bin',
              'arm-linux-androideabi-gcc');
          final String realNdkSysroot =
              fs.path.join(realNdkDir, 'platforms', 'android-9', 'arch-arm');

          final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
          expect(sdk.directory, realSdkDir);
          expect(sdk.ndk, isNotNull);
          expect(sdk.ndk.directory, realNdkDir);
          expect(sdk.ndk.compiler, realNdkCompiler);
          expect(sdk.ndk.compilerArgs, <String>['--sysroot', realNdkSysroot]);
        }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          Platform: () => FakePlatform(operatingSystem: os),
        });
      });

      for (String os in <String>['linux', 'macos']) {
        testUsingContext('detection on $os (no ndk available)', () {
          sdkDir = MockAndroidSdk.createSdkDirectory(withAndroidN: true);
          Config.instance.setValue('android-sdk', sdkDir.path);

          final String realSdkDir = sdkDir.path;
          final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
          expect(sdk.directory, realSdkDir);
          expect(sdk.ndk, isNull);
          final String explanation = AndroidNdk.explainMissingNdk(sdk.directory);
          expect(explanation, contains('Can not locate ndk-bundle'));
        }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          Platform: () => FakePlatform(operatingSystem: os),
        });
      }
    });
  });
}

/// A broken SDK installation.
class MockBrokenAndroidSdk extends Mock implements AndroidSdk {
  static Directory createSdkDirectory({
    bool withAndroidN = false,
    String withNdkDir,
    bool withNdkSysroot = false,
    bool withSdkManager = true,
  }) {
    final Directory dir = fs.systemTempDirectory.createTempSync('flutter_mock_android_sdk.');

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
