// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Config config;
  late BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
    config = Config.test();
    logger = BufferLogger.test();
  });

  group('AndroidSdk', () {
    testWithoutContext('constructing an AndroidSdk handles no matching lines in build.prop', () {
      final Directory sdkDir = createSdkDirectory(
        fileSystem: fileSystem,
        withAndroidN: true,
        // Does not have valid version string
        buildProp: '\n\n\n',
      );
      config.setValue('android-sdk', sdkDir.path);

      try {
        final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
          config: config,
          fileSystem: fileSystem,
          logger: logger,
          processManager: FakeProcessManager.any(),
        )!;
        sdk.latestVersion;
      } on StateError catch (err) {
        fail('sdk.reinitialize() threw a StateError:\n$err');
      }
    });

    testWithoutContext('parse sdk', () {
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        processManager: FakeProcessManager.any(),
      )!;
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion!.sdkLevel, 23);
    });

    testWithoutContext('parse sdk N', () {
      final Directory sdkDir = createSdkDirectory(withAndroidN: true, fileSystem: fileSystem);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        processManager: FakeProcessManager.any(),
      )!;
      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion!.sdkLevel, 24);
    });

    testWithoutContext('returns sdkmanager path under cmdline tools on Linux/macOS', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(
            fileSystem.path.join(
              sdk.directory.path,
              'cmdline-tools',
              'latest',
              'bin',
              'sdkmanager',
            ),
          )
          .createSync(recursive: true);

      expect(
        sdk.sdkManagerPath,
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'),
      );
    });

    testWithoutContext(
      'returns sdkmanager path under cmdline tools (highest version) on Linux/macOS',
      () {
        final platform = FakePlatform();
        final Directory sdkDir = createSdkDirectory(
          fileSystem: fileSystem,
          platform: platform,
          withSdkManager: false,
        );
        config.setValue('android-sdk', sdkDir.path);

        final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
          config: config,
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: FakeProcessManager.any(),
        )!;
        final versions = <String>['3.0', '2.1', '1.0'];
        for (final version in versions) {
          fileSystem
              .file(
                fileSystem.path.join(
                  sdk.directory.path,
                  'cmdline-tools',
                  version,
                  'bin',
                  'sdkmanager',
                ),
              )
              .createSync(recursive: true);
        }

        expect(
          sdk.sdkManagerPath,
          fileSystem.path.join(sdk.directory.path, 'cmdline-tools', '3.0', 'bin', 'sdkmanager'),
        );
      },
    );

    testWithoutContext('Does not return sdkmanager under deprecated tools component', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(
        fileSystem: fileSystem,
        platform: platform,
        withSdkManager: false,
      );
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(fileSystem.path.join(sdk.directory.path, 'tools/bin/sdkmanager'))
          .createSync(recursive: true);

      expect(sdk.sdkManagerPath, null);
    });

    testWithoutContext('Can look up cmdline tool from deprecated tools path', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(
        fileSystem: fileSystem,
        platform: platform,
        withSdkManager: false,
      );
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(fileSystem.path.join(sdk.directory.path, 'tools/bin/foo'))
          .createSync(recursive: true);

      expect(
        sdk.getCmdlineToolsPath('foo'),
        '/.tmp_rand0/flutter_mock_android_sdk.rand0/tools/bin/foo',
      );
    });

    testWithoutContext('Caches adb location after first access', () {
      final platform = FakePlatform(operatingSystem: 'windows');
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      final File adbFile = fileSystem.file(
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe'),
      )..createSync(recursive: true);

      expect(sdk.adbPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe'));

      adbFile.deleteSync(recursive: true);

      expect(sdk.adbPath, fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'adb.exe'));
    });

    testWithoutContext('returns sdkmanager.bat path under cmdline tools for windows', () {
      final platform = FakePlatform(operatingSystem: 'windows');
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(
            fileSystem.path.join(
              sdk.directory.path,
              'cmdline-tools',
              'latest',
              'bin',
              'sdkmanager.bat',
            ),
          )
          .createSync(recursive: true);

      expect(
        sdk.sdkManagerPath,
        fileSystem.path.join(
          sdk.directory.path,
          'cmdline-tools',
          'latest',
          'bin',
          'sdkmanager.bat',
        ),
      );
    });

    testWithoutContext('returns sdkmanager version', () {
      final platform = FakePlatform(environment: <String, String>{});
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
            '--version',
          ],
          stdout: '26.1.1\n',
        ),
      );
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      )!;

      expect(sdk.sdkManagerVersion, '26.1.1');
    });

    testWithoutContext('returns validate sdk is well formed', () {
      final platform = FakePlatform();
      final Directory sdkDir = createBrokenSdkDirectory(fileSystem: fileSystem);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
            '--version',
          ],
        ),
      );
      config.setValue('android-sdk', sdkDir.path);
      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      )!;

      final validationIssues = <String>[...sdk.validateSdkWellFormed()];
      expect(
        validationIssues.first,
        'No valid Android SDK platforms found in'
        ' /.tmp_rand0/flutter_mock_android_sdk.rand0/platforms. Candidates were:\n'
        '  - android-22\n'
        '  - android-23',
      );
    });

    testWithoutContext('detects spaces in Android SDK path', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(
        fileSystem: fileSystem,
        platform: platform,
        directoryName: 'flutter_mock_android_sdk with spaces.',
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            '/.tmp_rand0/flutter_mock_android_sdk with spaces.rand0/cmdline-tools/latest/bin/sdkmanager',
            '--version',
          ],
        ),
      );
      config.setValue('android-sdk', sdkDir.path);

      final validationIssues = <String>[
        ...AndroidSdk.locateAndroidSdk(
          config: config,
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: processManager,
        )!.validateSdkWellFormed(),
      ];
      expect(validationIssues.first, contains('Android SDK location currently contains spaces'));
    });

    testWithoutContext('does not throw on sdkmanager version check failure', () {
      final platform = FakePlatform(environment: <String, String>{});
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);
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

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      )!;

      expect(sdk.sdkManagerVersion, isNull);
    });

    testWithoutContext('throws on sdkmanager version check if sdkmanager not found', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(
        withSdkManager: false,
        fileSystem: fileSystem,
        platform: platform,
      );
      config.setValue('android-sdk', sdkDir.path);
      processManager.excludedExecutables.add(
        '/.tmp_rand0/flutter_mock_android_sdk.rand0/cmdline-tools/latest/bin/sdkmanager',
      );
      final AndroidSdk? sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      expect(() => sdk!.sdkManagerVersion, throwsToolExit());
    });

    testWithoutContext('returns avdmanager path under cmdline tools', () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(
            fileSystem.path.join(
              sdk.directory.path,
              'cmdline-tools',
              'latest',
              'bin',
              'avdmanager',
            ),
          )
          .createSync(recursive: true);

      expect(
        sdk.avdManagerPath,
        fileSystem.path.join(sdk.directory.path, 'cmdline-tools', 'latest', 'bin', 'avdmanager'),
      );
    });

    testWithoutContext('returns avdmanager path under cmdline tools on windows', () {
      final platform = FakePlatform(operatingSystem: 'windows');
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(
            fileSystem.path.join(
              sdk.directory.path,
              'cmdline-tools',
              'latest',
              'bin',
              'avdmanager.bat',
            ),
          )
          .createSync(recursive: true);

      expect(
        sdk.avdManagerPath,
        fileSystem.path.join(
          sdk.directory.path,
          'cmdline-tools',
          'latest',
          'bin',
          'avdmanager.bat',
        ),
      );
    });

    testWithoutContext("returns avdmanager path under tools if cmdline doesn't exist", () {
      final platform = FakePlatform();
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
        config: config,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
      )!;
      fileSystem
          .file(fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager'))
          .createSync(recursive: true);

      expect(
        sdk.avdManagerPath,
        fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager'),
      );
    });

    testWithoutContext(
      "returns avdmanager path under tools if cmdline doesn't exist on windows",
      () {
        final platform = FakePlatform(operatingSystem: 'windows');
        final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
        config.setValue('android-sdk', sdkDir.path);

        final AndroidSdk sdk = AndroidSdk.locateAndroidSdk(
          config: config,
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: FakeProcessManager.any(),
        )!;
        fileSystem
            .file(fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager.bat'))
            .createSync(recursive: true);

        expect(
          sdk.avdManagerPath,
          fileSystem.path.join(sdk.directory.path, 'tools', 'bin', 'avdmanager.bat'),
        );
      },
    );

    testWithoutContext(
      'does not initialize sdkVersions or latestVersion during constructor instantiation',
      () {
        final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem);
        final sdk = AndroidSdk(
          sdkDir,
          config: config,
          logger: logger,
          processManager: FakeProcessManager.any(),
        );

        // Constructor did not scan build-tools or platforms.
        // We verify by modifying the directory before first access.
        fileSystem
            .directory(fileSystem.path.join(sdkDir.path, 'platforms', 'android-22'))
            .deleteSync(recursive: true);

        // First access to latestVersion triggers initialization and sees only remaining platforms.
        expect(sdk.latestVersion, isNotNull);
        expect(sdk.latestVersion!.sdkLevel, 23);
        expect(sdk.sdkVersions.length, 1);
      },
    );

    testWithoutContext('evaluates sdkVersions and latestVersion lazily on first access', () {
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem);

      // Accessing latestVersion triggers initialization.
      final sdk1 = AndroidSdk(
        sdkDir,
        config: config,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );
      expect(sdk1.latestVersion, isNotNull);
      expect(sdk1.latestVersion!.sdkLevel, 23);
      expect(sdk1.sdkVersions.length, 2);

      // Accessing sdkVersions triggers initialization independently.
      final sdk2 = AndroidSdk(
        sdkDir,
        config: config,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );
      expect(sdk2.sdkVersions.length, 2);
      expect(sdk2.latestVersion, isNotNull);
      expect(sdk2.latestVersion!.sdkLevel, 23);
    });

    testWithoutContext(
      'reinitialize updates sdkVersions and latestVersion when new platforms are installed',
      () {
        final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem);
        final sdk = AndroidSdk(
          sdkDir,
          config: config,
          logger: logger,
          processManager: FakeProcessManager.any(),
        );

        expect(sdk.latestVersion!.sdkLevel, 23);

        // Add android-34 platform.
        fileSystem
            .directory(fileSystem.path.join(sdkDir.path, 'platforms', 'android-34'))
            .createSync(recursive: true);

        sdk.reinitialize();

        expect(sdk.latestVersion!.sdkLevel, 34);
        expect(sdk.sdkVersions.length, 3);
      },
    );
  });

  const llvmHostDirectoryName = <String, String>{
    'macos': 'darwin-x86_64',
    'linux': 'linux-x86_64',
    'windows': 'windows-x86_64',
  };

  for (final operatingSystem in <String>['windows', 'linux', 'macos']) {
    final FileSystem fileSystem;
    final String extension;
    if (operatingSystem == 'windows') {
      fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
      extension = '.exe';
    } else {
      fileSystem = MemoryFileSystem.test();
      extension = '';
    }
    testWithoutContext('ndk executables $operatingSystem', () {
      final Platform platform = FakePlatform(operatingSystem: operatingSystem);
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      config.setValue('android-sdk', sdkDir.path);

      final sdk = AndroidSdk(sdkDir);
      late File clang;
      late File ar;
      late File ld;
      const versions = <String>['22.1.7171670', '24.0.8215888'];
      for (final version in versions) {
        final Directory binDir =
            sdk.directory
                .childDirectory('ndk')
                .childDirectory(version)
                .childDirectory('toolchains')
                .childDirectory('llvm')
                .childDirectory('prebuilt')
                .childDirectory(llvmHostDirectoryName[operatingSystem]!)
                .childDirectory('bin')
              ..createSync(recursive: true);
        // Save the last version.
        clang = binDir.childFile('clang$extension')..createSync();
        ar = binDir.childFile('llvm-ar$extension')..createSync();
        ld = binDir.childFile('ld.lld$extension')..createSync();
      }
      // Check the last NDK version is used.
      expect(sdk.getNdkClangPath(platform: platform, config: config), clang.path);
      expect(sdk.getNdkArPath(platform: platform, config: config), ar.path);
      expect(sdk.getNdkLdPath(platform: platform, config: config), ld.path);
    });

    for (final envVar in <String>[kAndroidNdkHome, kAndroidNdkPath, kAndroidNdkRoot]) {
      final Directory ndkDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_mock_android_ndk.',
      );
      testWithoutContext('ndk executables with $operatingSystem $envVar', () {
        final Platform platform = FakePlatform(
          operatingSystem: operatingSystem,
          environment: <String, String>{envVar: ndkDir.path},
        );
        final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
        config.setValue('android-sdk', sdkDir.path);

        final Directory binDir =
            ndkDir
                .childDirectory('toolchains')
                .childDirectory('llvm')
                .childDirectory('prebuilt')
                .childDirectory(llvmHostDirectoryName[operatingSystem]!)
                .childDirectory('bin')
              ..createSync(recursive: true);
        final File clang = binDir.childFile('clang$extension')..createSync();
        final File ar = binDir.childFile('llvm-ar$extension')..createSync();
        final File ld = binDir.childFile('ld.lld$extension')..createSync();

        final sdk = AndroidSdk(sdkDir);
        expect(sdk.getNdkClangPath(platform: platform, config: config), clang.path);
        expect(sdk.getNdkArPath(platform: platform, config: config), ar.path);
        expect(sdk.getNdkLdPath(platform: platform, config: config), ld.path);
      });
    }

    testWithoutContext('ndk executables with config override $operatingSystem', () {
      final Platform platform = FakePlatform(operatingSystem: operatingSystem);
      final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
      final Directory ndkDir = fileSystem.systemTempDirectory.createTempSync(
        'flutter_mock_android_ndk.',
      );
      config.setValue('android-sdk', sdkDir.path);
      config.setValue('android-ndk', ndkDir.path);

      final Directory binDir =
          ndkDir
              .childDirectory('toolchains')
              .childDirectory('llvm')
              .childDirectory('prebuilt')
              .childDirectory(llvmHostDirectoryName[operatingSystem]!)
              .childDirectory('bin')
            ..createSync(recursive: true);
      final File clang = binDir.childFile('clang$extension')..createSync();
      final File ar = binDir.childFile('llvm-ar$extension')..createSync();
      final File ld = binDir.childFile('ld.lld$extension')..createSync();

      final sdk = AndroidSdk(sdkDir);
      expect(sdk.getNdkClangPath(platform: platform, config: config), clang.path);
      expect(sdk.getNdkArPath(platform: platform, config: config), ar.path);
      expect(sdk.getNdkLdPath(platform: platform, config: config), ld.path);
    });

    testWithoutContext(
      'ndk executables with config override fall back to SDK NDK $operatingSystem',
      () {
        final Platform platform = FakePlatform(operatingSystem: operatingSystem);
        final Directory sdkDir = createSdkDirectory(fileSystem: fileSystem, platform: platform);
        final Directory brokenNdkDir = fileSystem.systemTempDirectory.createTempSync(
          'flutter_mock_android_ndk.',
        );
        config.setValue('android-sdk', sdkDir.path);
        config.setValue('android-ndk', brokenNdkDir.path);

        final Directory binDir =
            sdkDir
                .childDirectory('ndk')
                .childDirectory('24.0.8215888')
                .childDirectory('toolchains')
                .childDirectory('llvm')
                .childDirectory('prebuilt')
                .childDirectory(llvmHostDirectoryName[operatingSystem]!)
                .childDirectory('bin')
              ..createSync(recursive: true);
        final File clang = binDir.childFile('clang$extension')..createSync();
        final File ar = binDir.childFile('llvm-ar$extension')..createSync();
        final File ld = binDir.childFile('ld.lld$extension')..createSync();

        final sdk = AndroidSdk(sdkDir);
        expect(sdk.getNdkClangPath(platform: platform, config: config), clang.path);
        expect(sdk.getNdkArPath(platform: platform, config: config), ar.path);
        expect(sdk.getNdkLdPath(platform: platform, config: config), ld.path);
      },
    );
  }
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

void _createSdkFile(Directory dir, String filePath, {String? contents}) {
  final File file = dir.childFile(filePath);
  file.createSync(recursive: true);
  if (contents != null) {
    file.writeAsStringSync(contents, flush: true);
  }
}

Directory createSdkDirectory({
  required FileSystem fileSystem,
  String buildProp = _buildProp,
  String directoryName = 'flutter_mock_android_sdk.',
  Platform? platform,
  bool withAndroidN = false,
  bool withBuildTools = true,
  bool withPlatformTools = true,
  bool withSdkManager = true,
}) {
  platform ??= FakePlatform();
  final Directory dir = fileSystem.systemTempDirectory.createTempSync(directoryName);
  final exe = platform.isWindows ? '.exe' : '';
  final bat = platform.isWindows ? '.bat' : '';

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
    _createSdkFile(dir, 'platforms/android-N/build.prop', contents: buildProp);
  }

  if (withSdkManager) {
    _createSdkFile(dir, 'cmdline-tools/latest/bin/sdkmanager$bat');
  }
  return dir;
}

const _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
