// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

final macOS = FakePlatform(operatingSystem: 'macos');

final linux = FakePlatform();

void main() {
  testWithoutContext('default configuration', () async {
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.any(),
    );
    final package = FakeMacOSApp();

    expect(await device.targetPlatform, TargetPlatform.darwin);
    expect(device.name, 'macOS');
    expect(await device.installApp(package), true);
    expect(await device.uninstallApp(package), true);
    expect(await device.isLatestBuildInstalled(package), true);
    expect(await device.isAppInstalled(package), true);
    expect(device.category, Category.desktop);

    expect(device.supportsRuntimeMode(BuildMode.debug), true);
    expect(device.supportsRuntimeMode(BuildMode.profile), true);
    expect(device.supportsRuntimeMode(BuildMode.release), true);
    expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('Attaches to log reader when running in release mode', () async {
    final completer = Completer<void>();
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>['release/executable'],
          stdout: 'Hello World\n',
          stderr: 'Goodnight, Moon\n',
          completer: completer,
        ),
      ]),
    );
    final package = FakeMacOSApp();

    final LaunchResult result = await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      prebuiltApplication: true,
    );

    expect(result.started, true);

    final DeviceLogReader logReader = device.getLogReader(app: package);

    expect(logReader.logLines, emitsInAnyOrder(<String>['Hello World', 'Goodnight, Moon']));
    completer.complete();
  });

  testWithoutContext('No devices listed if platform is unsupported', () async {
    expect(
      await MacOSDevices(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        macOSWorkflow: MacOSWorkflow(
          featureFlags: TestFeatureFlags(isMacOSEnabled: true),
          platform: linux,
        ),
        operatingSystemUtils: FakeOperatingSystemUtils(),
        platform: linux,
        processManager: FakeProcessManager.any(),
      ).devices(),
      isEmpty,
    );
  });

  testWithoutContext(
    'No devices listed if platform is supported and feature is disabled',
    () async {
      final macOSDevices = MacOSDevices(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        macOSWorkflow: MacOSWorkflow(featureFlags: TestFeatureFlags(), platform: macOS),
        operatingSystemUtils: FakeOperatingSystemUtils(),
        platform: macOS,
        processManager: FakeProcessManager.any(),
      );

      expect(await macOSDevices.devices(), isEmpty);
    },
  );

  testWithoutContext('devices listed if platform is supported and feature is enabled', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      platform: macOS,
      processManager: FakeProcessManager.any(),
    );

    expect(await macOSDevices.devices(), hasLength(1));
  });

  testWithoutContext('has a well known device id macos', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      platform: macOS,
      processManager: FakeProcessManager.any(),
    );

    expect(macOSDevices.wellKnownIds, <String>['macos']);
  });

  testWithoutContext('can discover devices with a provided timeout', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      platform: macOS,
      processManager: FakeProcessManager.any(),
    );

    // Timeout ignored.
    final List<Device> devices = await macOSDevices.discoverDevices(
      timeout: const Duration(seconds: 10),
    );

    expect(devices, hasLength(1));
  });

  testWithoutContext('isSupportedForProject is true with editable host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.any(),
    );

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('macos').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), true);
  });

  testWithoutContext('target platform display name on x86_64', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_x64;
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: fakeOperatingSystemUtils,
      processManager: FakeProcessManager.any(),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-x64');
  });

  testWithoutContext('target platform display name on ARM', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_arm64;
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: fakeOperatingSystemUtils,
      processManager: FakeProcessManager.any(),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-arm64');
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.any(),
    );
    fileSystem.file('pubspec.yaml').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final package = FakeMacOSApp();
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.any(),
    );
    const debugPath = 'debug/executable';
    const profilePath = 'profile/executable';
    const releasePath = 'release/executable';

    expect(device.executablePathForDevice(package, BuildInfo.debug), debugPath);
    expect(device.executablePathForDevice(package, BuildInfo.profile), profilePath);
    expect(device.executablePathForDevice(package, BuildInfo.release), releasePath);
  });

  testUsingContext('startApp in debug mode launches via open and parses VM Service URI', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final completer = Completer<void>();

    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <Pattern>[
            'open',
            '-n',
            '-a',
            'release/bundle.app',
            '--args',
            '--enable-dart-profiling=true',
            '--enable-checked-mode=true',
            '--verify-entry-points=true',
            RegExp(r'^--write-service-info=(.*)$'),
          ],
          onRun: (List<String> command) {
            // Extract the path passed to --write-service-info and write a mock VM Service JSON file
            // to simulate Dart VM writing connection info on startup.
            final String writeServiceInfoArg = command.firstWhere(
              (String arg) => arg.startsWith('--write-service-info='),
            );
            final String filePath = writeServiceInfoArg.substring('--write-service-info='.length);
            fileSystem
                .file(filePath)
                .writeAsStringSync('{"uri":"http://127.0.0.1:12345/auth_code/"}');
            completer.complete();
          },
        ),
      ]),
    );

    final package = FakeMacOSApp(bundle: 'release/bundle.app');

    final LaunchResult result = await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      prebuiltApplication: true,
    );

    expect(result.started, true);
    expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:12345/auth_code/'));

    await completer.future;
  });

  testUsingContext(
    'startApp writes VM Service info file in sandboxed container tmp directory when Info.plist exists',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final completer = Completer<void>();

      fileSystem.file('/release/bundle.app/Contents/Info.plist').createSync(recursive: true);

      String? writtenFilePath;
      final device = MacOSDevice(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <Pattern>[
              'open',
              '-n',
              '-a',
              '/release/bundle.app',
              '--args',
              '--enable-dart-profiling=true',
              '--enable-checked-mode=true',
              '--verify-entry-points=true',
              RegExp(r'^--write-service-info=(.*)$'),
            ],
            onRun: (List<String> command) {
              final String writeServiceInfoArg = command.firstWhere(
                (String arg) => arg.startsWith('--write-service-info='),
              );
              writtenFilePath = writeServiceInfoArg.substring('--write-service-info='.length);
              if (writtenFilePath case final String path) {
                fileSystem
                    .file(path)
                    .writeAsStringSync('{"uri":"http://127.0.0.1:54321/auth_code/"}');
              }
              completer.complete();
            },
          ),
        ]),
      );

      final package = FakeMacOSApp(bundle: '/release/bundle.app');

      final LaunchResult result = await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        prebuiltApplication: true,
      );

      expect(result.started, true);
      expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:54321/auth_code/'));
      expect(writtenFilePath, contains('/Library/Containers/com.example.testApp/Data/tmp/'));

      await completer.future;
    },
    overrides: <Type, Generator>{
      FileSystemUtils: () => FileSystemUtils(
        fileSystem: MemoryFileSystem.test(),
        platform: FakePlatform(environment: <String, String>{'HOME': '/Users/testuser'}),
      ),
      PlistParser: () => FakePlistParser(<String, Object>{
        PlistParser.kCFBundleIdentifierKey: 'com.example.testApp',
      }),
    },
  );

  testWithoutContext('stopApp uses pkill for all build modes', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['pkill', '-f', 'debug/executable']),
      ]),
    );

    final package = FakeMacOSApp();
    fileSystem.file('debug/executable').createSync(recursive: true);

    final bool result = await device.stopApp(package);

    expect(result, true);
  });

  testWithoutContext('stopApp succeeds if no process matching pattern is running', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['pkill', '-f', 'debug/executable'], exitCode: 1),
      ]),
    );

    final package = FakeMacOSApp();
    fileSystem.file('debug/executable').createSync(recursive: true);

    final bool result = await device.stopApp(package);

    expect(result, true);
  });

  testUsingContext('startApp prints warning if Dart VM not found within timeframe in CI', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <Pattern>[
            'open',
            '-n',
            '-a',
            'bundle',
            '--args',
            '--enable-dart-profiling=true',
            '--enable-checked-mode=true',
            '--verify-entry-points=true',
            RegExp(r'^--write-service-info=(.*)$'),
          ],
        ),
        const FakeCommand(command: <String>['pgrep', '-f', 'debug/executable'], exitCode: 1),
      ]),
    );

    final package = FakeMacOSApp();

    final LaunchResult result = await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, usingCISystem: true),
      prebuiltApplication: true,
    );

    expect(result.started, false);
    expect(
      logger.errorText,
      contains('Ensure sandboxing is disabled by checking the set CODE_SIGN_ENTITLEMENTS'),
    );
  }, overrides: <Type, Generator>{BotDetector: () => const FakeBotDetector(true)});
}

FlutterProject setUpFlutterProject(Directory directory) {
  final flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

class FakeMacOSApp extends Fake implements MacOSApp {
  FakeMacOSApp({this.bundle = 'bundle'});

  final String? bundle;

  @override
  String get name => 'app';

  @override
  String? applicationBundle(BuildInfo buildInfo) => bundle;

  @override
  String executable(BuildInfo buildInfo) {
    return switch (buildInfo.mode) {
      BuildMode.debug => 'debug/executable',
      BuildMode.profile => 'profile/executable',
      BuildMode.release => 'release/executable',
      BuildMode.jitRelease => 'jitRelease/executable',
    };
  }
}
