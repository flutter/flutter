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
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  MemoryFileSystem fs;
  MockProcessManager processManager;

  setUp(() {
    fs = new MemoryFileSystem();
    processManager = new MockProcessManager();
  });

  group('android_sdk AndroidSdk', () {
    Directory sdkDir;

    tearDown(() {
      sdkDir?.deleteSync(recursive: true);
      sdkDir = null;
    });

    testUsingContext('parse sdk', () {
      sdkDir = _createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('parse sdk N', () {
      sdkDir = _createSdkDirectory(withAndroidN: true);
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns sdkmanager path', () {
      sdkDir = _createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      expect(sdk.sdkManagerPath, fs.path.join(sdk.directory, 'tools', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns sdkmanager version', () {
      sdkDir = _createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version']))
          .thenReturn(new ProcessResult(1, 0, '26.1.1\n', ''));
      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('throws on sdkmanager version check failure', () {
      sdkDir = _createSdkDirectory();
      Config.instance.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      when(processManager.canRun(sdk.sdkManagerPath)).thenReturn(true);
      when(processManager.runSync(<String>[sdk.sdkManagerPath, '--version']))
          .thenReturn(new ProcessResult(1, 1, '26.1.1\n', 'Mystery error'));
      expect(() => sdk.sdkManagerVersion, throwsToolExit(exitCode: 1));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => processManager,
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = _createSdkDirectory(withSdkManager: false);
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
          sdkDir = _createSdkDirectory(
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
          expect(sdk.ndkDirectory, realNdkDir);
          expect(sdk.ndkCompiler, realNdkCompiler);
          expect(sdk.ndkCompilerArgs, <String>['--sysroot', realNdkSysroot]);
        }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          Platform: () => new FakePlatform(operatingSystem: os),
        });
      });

      for (String os in <String>['linux', 'macos']) {
        testUsingContext('detection on $os (no ndk available)', () {
          sdkDir = _createSdkDirectory(withAndroidN: true);
          Config.instance.setValue('android-sdk', sdkDir.path);

          final String realSdkDir = sdkDir.path;
          final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
          expect(sdk.directory, realSdkDir);
          expect(sdk.ndkDirectory, null);
          expect(sdk.ndkCompiler, null);
          expect(sdk.ndkCompilerArgs, null);
        }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          Platform: () => new FakePlatform(operatingSystem: os),
        });
      }
    });
  });
}

Directory _createSdkDirectory({
  bool withAndroidN: false,
  String withNdkDir,
  bool withNdkSysroot: false,
  bool withSdkManager: true,
}) {
  final Directory dir = fs.systemTempDirectory.createTempSync('android-sdk');

  _createSdkFile(dir, 'platform-tools/adb');

  _createSdkFile(dir, 'build-tools/19.1.0/aapt');
  _createSdkFile(dir, 'build-tools/22.0.1/aapt');
  _createSdkFile(dir, 'build-tools/23.0.2/aapt');
  if (withAndroidN)
    _createSdkFile(dir, 'build-tools/24.0.0-preview/aapt');

  _createSdkFile(dir, 'platforms/android-22/android.jar');
  _createSdkFile(dir, 'platforms/android-23/android.jar');
  if (withAndroidN) {
    _createSdkFile(dir, 'platforms/android-N/android.jar');
    _createSdkFile(dir, 'platforms/android-N/build.prop', contents: _buildProp);
  }

  if (withSdkManager)
    _createSdkFile(dir, 'tools/bin/sdkmanager');

  if (withNdkDir != null) {
    final String ndkCompiler = fs.path.join(
        'ndk-bundle',
        'toolchains',
        'arm-linux-androideabi-4.9',
        'prebuilt',
        withNdkDir,
        'bin',
        'arm-linux-androideabi-gcc');
    _createSdkFile(dir, ndkCompiler);
  }
  if (withNdkSysroot) {
    final String armPlatform =
        fs.path.join('ndk-bundle', 'platforms', 'android-9', 'arch-arm');
    _createDir(dir, armPlatform);
  }

  return dir;
}

void _createSdkFile(Directory dir, String filePath, { String contents }) {
  final File file = dir.childFile(filePath);
  file.createSync(recursive: true);
  if (contents != null) {
    file.writeAsStringSync(contents, flush: true);
  }
}

void _createDir(Directory dir, String path) {
  final Directory directory = fs.directory(fs.path.join(dir.path, path));
  directory.createSync(recursive: true);
}

const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
