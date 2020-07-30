// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  testWithoutContext('Can locate SDK from file system', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Platform platform = FakePlatform(environment: <String, String>{});
    createSdkDirectory(fileSystem: fileSystem, platform: platform);

    final AndroidSdk sdk = setUpAndroidSdk(locate: true, fileSystem: fileSystem, platform: platform);

    expect(sdk.latestVersion, isNotNull);
    expect(sdk.latestVersion.sdkLevel, 23);
  });

  testWithoutContext('Can locate SDK with at least version N from file system', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Platform platform = FakePlatform(environment: <String, String>{});
    createSdkDirectory(fileSystem: fileSystem, platform: platform, withAndroidN: true);

    final AndroidSdk sdk = setUpAndroidSdk(locate: true, fileSystem: fileSystem, platform: platform);

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
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final Platform platform = FakePlatform(operatingSystem: 'windows', environment: <String, String>{});
    final AndroidSdk sdk = setUpAndroidSdk(fileSystem: fileSystem, platform: platform);

    fileSystem.file(
      fileSystem.path.join(sdk.directory, 'cmdline-tools\\latest\\bin\\sdkmanager.bat')
    ).createSync(recursive: true);

    expect(sdk.sdkManagerPath,
      fileSystem.path.join(sdk.directory, 'cmdline-tools\\latest\\bin\\sdkmanager.bat'));
  });

  testWithoutContext('returns sdkmanager path under tools if cmdline doesnt exist', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final AndroidSdk sdk = setUpAndroidSdk(fileSystem: fileSystem);

    expect(sdk.sdkManagerPath, fileSystem.path.join(sdk.directory, 'tools/bin/sdkmanager'));
  });

  testWithoutContext('returns sdkmanager version', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'which',
          'java'
        ],
        stdout: ''
      ),
      const FakeCommand(
        command: <String>[
          'tools/bin/sdkmanager',
          '--version'
        ],
        stdout: '26.1.1'
      ),
      const FakeCommand(
        command: <String>[
          '/usr/libexec/java_home',
          '-v',
          '1.8',
        ],
        stdout: ''
      ),
    ]);
    final AndroidSdk sdk = setUpAndroidSdk(processManager: processManager);

    expect(await sdk.sdkManagerVersion, '26.1.1');
  });

  testWithoutContext('returns validate sdk is well formed', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Platform platform = FakePlatform(environment: <String, String>{});
    createSdkDirectory(fileSystem: fileSystem, platform: platform);

    final AndroidSdk sdk = setUpAndroidSdk(fileSystem: fileSystem, platform: platform);

    final List<String> validationIssues = sdk.validateSdkWellFormed();
    expect(validationIssues, isEmpty);
  });

  testWithoutContext('does not throw on sdkmanager version check failure', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Platform platform = FakePlatform(environment: <String, String>{
      'PATH': '/',
    });
    createSdkDirectory(fileSystem: fileSystem, platform: platform);
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'which',
          'java'
        ],
        stdout: ''
      ),
      const FakeCommand(
        command: <String>[
          'tools/bin/sdkmanager',
          '--version'
        ],
        stdout: '26.1.1',
        stderr: 'Mystery error',
        exitCode: 1,
      ),
      const FakeCommand(
        command: <String>[
          '/usr/libexec/java_home',
          '-v',
          '1.8',
        ],
        stdout: ''
      ),
    ]);
    final AndroidSdk sdk = setUpAndroidSdk(
      processManager: processManager,
      fileSystem: fileSystem,
      platform: platform,
    );

    expect(await sdk.sdkManagerVersion, isNull);
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
  bool locate = false,
}) {
  logger ??= BufferLogger.test();
  fileSystem ??= MemoryFileSystem.test();
  processManager ??= FakeProcessManager.any();
  config ??= Config.test(
    'test',
    directory: fileSystem.currentDirectory,
    logger: logger,
  );
  config.setValue('android-sdk', fileSystem.currentDirectory.path);
  platform ??= FakePlatform(operatingSystem: 'linux', environment: <String, String>{
    'PATH': '/',
  });
  if (locate) {
    return AndroidSdk.locateAndroidSdk(
      config: config,
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

/// An SDK installation with several SDK levels (19, 22, 23).
Directory createSdkDirectory({
  @required FileSystem fileSystem,
  @required Platform platform,
  bool withAndroidN = false,
  bool withSdkManager = true,
  bool withPlatformTools = true,
  bool withBuildTools = true,
}) {
  final Directory dir = fileSystem.currentDirectory;
  final String exe = platform.isWindows ? '.exe' : '';
  final String bat = platform.isWindows ? '.bat' : '';

  _createDir(dir, 'licenses');

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
    _createSdkFile(dir, 'tools/bin/sdkmanager$bat');
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
  final Directory directory = dir.fileSystem.directory(dir.fileSystem.path.join(dir.path, path));
  directory.createSync(recursive: true);
}

const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
