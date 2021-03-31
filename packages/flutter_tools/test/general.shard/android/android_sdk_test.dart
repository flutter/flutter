// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:meta/meta.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';


void main() {
  MemoryFileSystem fileSystem;
  FakeProcessManager processManager;
  Config config;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    config = Config.test();
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
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager path under cmdline tools (highest version) on Linux/macOS', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      final List<String> versions = <String>['3.0', '2.1', '1.0'];
      for (final String version in versions) {
        fileSystem.file(
          fileSystem.path.join(sdk.directory.path, 'cmdline-tools', version, 'bin', 'sdkmanager')
        ).createSync(recursive: true);
      }

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', '3.0', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      Config: () => config,
    });

    testUsingContext('Caches adb location after first access', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      final File adbFile = fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe')
      )..createSync(recursive: true);

      expect(sdk.adbPath,  fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe'));

      adbFile.deleteSync(recursive: true);

      expect(sdk.adbPath,  fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager.bat path under cmdline tools for windows', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath,
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
      Config: () => config,
    });

    testUsingContext("returns sdkmanager path under tools if cmdline doesn't exist", () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
    });

    testUsingContext("returns sdkmanager path under tools if cmdline doesn't exist on windows", () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'sdkmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'windows'),
    });

    testUsingContext('returns sdkmanager version', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);
      processManager.addCommand(
        const FakeCommand(
            command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/sdkmanager',
            '--version',
          ],
          stdout: '26.1.1\n',
        ),
      );
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'linux', environment: <String, String>{}),
    });

    testUsingContext('returns validate sdk is well formed', () {
      sdkDir = createSdkDirectory(
        fileSystem: fileSystem,
      );
      processManager.addCommand(const FakeCommand(command: <String>[
        '/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/sdkmanager',
        '--version',
      ]));
      config.setValue('android-sdk', sdkDir.path);
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

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
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/sdkmanager',
            '--version',
          ],
          stdout: '\n',
          stderr: 'Mystery error',
          exitCode: 1,
        ),
      );

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(sdk.sdkManagerVersion, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'linux', environment: <String, String>{}),
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = MockAndroidSdk.createSdkDirectory(withSdkManager: false);
      config.setValue('android-sdk', sdkDir.path);
      processManager.excludedExecutables.add('/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/sdkmanager');
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();

      expect(() => sdk.sdkManagerVersion, throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
    });

    testUsingContext('returns avdmanager path under cmdline tools', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      Config: () => config,
    });

    testUsingContext('returns avdmanager path under cmdline tools on windows', () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager.bat')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
      Config: () => config,
    });

    testUsingContext("returns avdmanager path under tools if cmdline doesn't exist", () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      Config: () => config,
    });

    testUsingContext("returns avdmanager path under tools if cmdline doesn't exist on windows", () {
      sdkDir = MockAndroidSdk.createSdkDirectory();
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk();
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager.bat')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager.bat'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(operatingSystem: 'windows'),
      Config: () => config,
    });
  });
}

/// A broken SDK installation.
Directory createSdkDirectory({
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

void _createSdkFile(Directory dir, String filePath, { String contents }) {
  final File file = dir.childFile(filePath);
  file.createSync(recursive: true);
  if (contents != null) {
    file.writeAsStringSync(contents, flush: true);
  }
}
