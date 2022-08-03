// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Config config;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
    config = Config.test();
  });

  group('AndroidSdk', () {
    Directory? sdkDir;

    tearDown(() {
      if (sdkDir != null) {
        tryToDelete(sdkDir!);
        sdkDir = null;
      }
    });

    testUsingContext('parse sdk', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion!.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
    });

    testUsingContext('parse sdk N', () {
      sdkDir = createSdkDirectory(withAndroidN: true, fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion!.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager path under cmdline tools on Linux/macOS', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext('returns sdkmanager path under cmdline tools (highest version) on Linux/macOS', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem, withSdkManager: false);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
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
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext('Does not return sdkmanager under deprecated tools component', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem, withSdkManager: false);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'tools/bin/sdkmanager')
      ).createSync(recursive: true);

      expect(sdk.sdkManagerPath, null);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext('Can look up cmdline tool from deprecated tools path', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem, withSdkManager: false);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'tools/bin/foo')
      ).createSync(recursive: true);

      expect(sdk.getCmdlineToolsPath('foo'), '/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/foo');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext('Caches adb location after first access', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
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
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
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

    testUsingContext('returns sdkmanager version', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);
      processManager.addCommand(
        const FakeCommand(
            command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
            '--version',
          ],
          stdout: '26.1.1\n',
        ),
      );
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;

      expect(sdk.sdkManagerVersion, '26.1.1');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(environment: <String, String>{}),
    });

    testUsingContext('returns validate sdk is well formed', () {
      sdkDir = createBrokenSdkDirectory(
        fileSystem: fileSystem,
      );
      processManager.addCommand(const FakeCommand(command: <String>[
        '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
        '--version',
      ]));
      config.setValue('android-sdk', sdkDir!.path);
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;

      final List<String> validationIssues = sdk.validateSdkWellFormed();
      expect(validationIssues.first, 'No valid Android SDK platforms found in'
        ' /.tmp_rand0/flutter_mock_android_sdk.rand0/platforms. Candidates were:\n'
        '  - android-22\n'
        '  - android-23');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(),
    });

    testUsingContext('does not throw on sdkmanager version check failure', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
            '--version',
          ],
          stdout: '\n',
          stderr: 'Mystery error',
          exitCode: 1,
        ),
      );

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;

      expect(sdk.sdkManagerVersion, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(environment: <String, String>{}),
    });

    testUsingContext('throws on sdkmanager version check if sdkmanager not found', () {
      sdkDir = createSdkDirectory(withSdkManager: false, fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);
      processManager.excludedExecutables.add('/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager');
      final AndroidSdk? sdk = AndroidSdk.locateAndroidSdk();

      expect(() => sdk!.sdkManagerVersion, throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Config: () => config,
      Platform: () => FakePlatform(),
    });

    testUsingContext('returns avdmanager path under cmdline tools', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext('returns avdmanager path under cmdline tools on windows', () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
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
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
      fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager')
      ).createSync(recursive: true);

      expect(sdk.avdManagerPath, fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
      Config: () => config,
    });

    testUsingContext("returns avdmanager path under tools if cmdline doesn't exist on windows", () {
      sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir!.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk()!;
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
Directory createBrokenSdkDirectory({
  bool withAndroidN = false,
  bool withSdkManager = true,
  required FileSystem fileSystem,
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

void _createSdkFile(Directory dir, String filePath, { String? contents }) {
  final File file = dir.childFile(filePath);
  file.createSync(recursive: true);
  if (contents != null) {
    file.writeAsStringSync(contents, flush: true);
  }
}

Directory createSdkDirectory({
  bool withAndroidN = false,
  bool withSdkManager = true,
  bool withPlatformTools = true,
  bool withBuildTools = true,
  required FileSystem fileSystem,
}) {
  final Directory dir = fileSystem.systemTempDirectory.createTempSync('flutter_mock_android_sdk.');
  final String exe = globals.platform.isWindows ? '.exe' : '';
  final String bat = globals.platform.isWindows ? '.bat' : '';

  void createDir(Directory dir, String path) {
    final Directory directory = dir.fileSystem.directory(dir.fileSystem.path.join(dir.path, path));
    directory.createSync(recursive: true);
  }

  createDir(dir, 'licenses');

  if (withPlatformTools) {
    _createSdkFile(dir, 'platform-tools/adb$exe');
  }

  if (withBuildTools) {
    _createSdkFile(dir, 'build-tools/19.1.0/aapt$exe');
    _createSdkFile(dir, 'build-tools/22.0.1/aapt$exe');
    _createSdkFile(dir, 'build-tools/23.0.2/aapt$exe');
    if (withAndroidN) {
      _createSdkFile(dir, 'build-tools/24.0.0-preview/aapt$exe');
    }
  }

  _createSdkFile(dir, 'platforms/android-22/android.jar');
  _createSdkFile(dir, 'platforms/android-23/android.jar');
  if (withAndroidN) {
    _createSdkFile(dir, 'platforms/android-N/android.jar');
    _createSdkFile(dir, 'platforms/android-N/build.prop', contents: _buildProp);
  }

  if (withSdkManager) {
    _createSdkFile(dir, 'cmdline-tools/latest/bin/sdkmanager$bat');
  }
  return dir;
}

const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
