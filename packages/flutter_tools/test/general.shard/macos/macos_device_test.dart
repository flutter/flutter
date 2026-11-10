// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';

final macOS = FakePlatform(operatingSystem: 'macos');

final linux = FakePlatform();

void main() {
  testWithoutContext('default configuration', () async {
    final device = MacOSDevice(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(),
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
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['release/executable'],
            stdout: 'Hello World\n',
            stderr: 'Goodnight, Moon\n',
            completer: completer,
          ),
        ]),
      ),
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
    final featureFlags = TestFeatureFlags(isMacOSEnabled: true);
    expect(
      await MacOSDevices(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: featureFlags,
        macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: linux),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(platform: linux),
      ).devices(),
      isEmpty,
    );
  });

  testWithoutContext(
    'No devices listed if platform is supported and feature is disabled',
    () async {
      final featureFlags = TestFeatureFlags();
      final macOSDevices = MacOSDevices(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: featureFlags,
        macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: macOS),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(platform: macOS),
      );

      expect(await macOSDevices.devices(), isEmpty);
    },
  );

  testWithoutContext('devices listed if platform is supported and feature is enabled', () async {
    final featureFlags = TestFeatureFlags(isMacOSEnabled: true);
    final macOSDevices = MacOSDevices(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: featureFlags,
      macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: macOS),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(platform: macOS),
    );

    expect(await macOSDevices.devices(), hasLength(1));
  });

  testWithoutContext('has a well known device id macos', () async {
    final featureFlags = TestFeatureFlags(isMacOSEnabled: true);
    final macOSDevices = MacOSDevices(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: featureFlags,
      macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: macOS),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(platform: macOS),
    );

    expect(macOSDevices.wellKnownIds, <String>['macos']);
  });

  testWithoutContext('can discover devices with a provided timeout', () async {
    final featureFlags = TestFeatureFlags(isMacOSEnabled: true);
    final macOSDevices = MacOSDevices(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: featureFlags,
      macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: macOS),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(platform: macOS),
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
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(),
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
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(os: fakeOperatingSystemUtils),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-x64');
  });

  testWithoutContext('target platform display name on ARM', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_arm64;
    final device = MacOSDevice(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(os: fakeOperatingSystemUtils),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-arm64');
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(fs: fileSystem),
    );
    fileSystem.file('pubspec.yaml').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final package = FakeMacOSApp();
    final device = MacOSDevice(
      analytics: const NoOpAnalytics(),
      appleContext: FakeAppleContext(),
      featureFlags: TestFeatureFlags(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(),
    );
    const debugPath = 'debug/executable';
    const profilePath = 'profile/executable';
    const releasePath = 'release/executable';

    expect(device.executablePathForDevice(package, BuildInfo.debug), debugPath);
    expect(device.executablePathForDevice(package, BuildInfo.profile), profilePath);
    expect(device.executablePathForDevice(package, BuildInfo.release), releasePath);
  });

  group('TCC privacy crash detection', () {
    const logShowCommand = <String>[
      '/usr/bin/log',
      'show',
      '--last',
      '30s',
      '--style',
      'ndjson',
      '--predicate',
      'processID == 10000 AND eventMessage CONTAINS "${MacOSDevice.kMacOSPrivacyCrashPattern}"',
    ];

    testWithoutContext(
      'detects privacy crash via log show on SIGABRT (-6) exit and awaits check on dispose',
      () async {
        final logger = BufferLogger.test();
        final processCompleter = Completer<void>();
        final logShowCompleter = Completer<void>();
        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['release/executable'],
            exitCode: MacOSDevice.kSigabrtExitCode,
            completer: processCompleter,
          ),
          FakeCommand(
            command: logShowCommand,
            completer: logShowCompleter,
            stdout: <String>[
              jsonEncode(<String, Object?>{
                'processID': 10000,
                'eventMessage':
                    '${MacOSDevice.kMacOSPrivacyCrashPattern}. '
                    "The app's Info.plist must supply an NSSpeechRecognitionUsageDescription key "
                    'with a string value explaining to the user how the app uses this data.',
              }),
              jsonEncode(<String, Object?>{'count': 1, 'finished': 1}),
            ].join('\n'),
          ),
        ]);
        final device = MacOSDevice(
          analytics: const NoOpAnalytics(),
          appleContext: FakeAppleContext(),
          featureFlags: TestFeatureFlags(),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(logger: logger, processManager: processManager),
        );
        final package = FakeMacOSApp();

        final LaunchResult result = await device.startApp(
          package,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          prebuiltApplication: true,
        );
        expect(result.started, true);

        var disposeFinished = false;
        final Future<void> disposeFuture = device.dispose().then((_) {
          disposeFinished = true;
        });
        Timer.run(processCompleter.complete);
        await pumpEventQueue();
        expect(disposeFinished, false);
        expect(logger.errorText, isEmpty);

        logShowCompleter.complete();
        await disposeFuture;
        expect(disposeFinished, true);

        expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
        expect(
          logger.errorText,
          contains(
            'access to protected resources (requiring NSSpeechRecognitionUsageDescription).',
          ),
        );
        expect(
          logger.errorText,
          contains('protected resource requests are made to the parent IDE or\nterminal process'),
        );
        expect(
          logger.errorText,
          contains('Even if NSSpeechRecognitionUsageDescription is already present'),
        );
        expect(
          logger.errorText,
          contains(
            '1. Ensure NSSpeechRecognitionUsageDescription is present in macos/Runner/Info.plist.',
          ),
        );
        expect(
          logger.errorText,
          contains(
            "2. Run the project directly from Xcode, or 'flutter run' using the default macOS Terminal app.",
          ),
        );
        expect(logger.errorText, contains('https://github.com/flutter/flutter/issues/70374'));
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext('detects privacy crash with alternative phrasing', () async {
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['release/executable'],
          exitCode: MacOSDevice.kSigabrtExitCode,
        ),
        FakeCommand(
          command: logShowCommand,
          stdout: jsonEncode(<String, Object?>{
            'processID': 10000,
            'eventMessage':
                '${MacOSDevice.kMacOSPrivacyCrashPattern}. '
                "The app's Info.plist must contain an NSPhotoLibraryUsageDescription key "
                'with a string value explaining to the user how the app uses this data.',
          }),
        ),
      ]);
      final device = MacOSDevice(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: TestFeatureFlags(),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(logger: logger, processManager: processManager),
      );
      final package = FakeMacOSApp();

      final LaunchResult result = await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        prebuiltApplication: true,
      );
      expect(result.started, true);

      await pumpEventQueue();
      await device.dispose();

      expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
      expect(
        logger.errorText,
        contains('access to protected resources (requiring NSPhotoLibraryUsageDescription).'),
      );
      expect(
        logger.errorText,
        contains(
          "2. Run the project directly from Xcode, or 'flutter run' using the default macOS Terminal app.",
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'detects privacy crash without key name and prints fallback diagnostic',
      () async {
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['release/executable'],
            exitCode: MacOSDevice.kSigabrtExitCode,
          ),
          FakeCommand(
            command: logShowCommand,
            stdout: jsonEncode(<String, Object?>{
              'processID': 10000,
              'eventMessage': '${MacOSDevice.kMacOSPrivacyCrashPattern}.',
            }),
          ),
        ]);
        final device = MacOSDevice(
          analytics: const NoOpAnalytics(),
          appleContext: FakeAppleContext(),
          featureFlags: TestFeatureFlags(),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(logger: logger, processManager: processManager),
        );
        final package = FakeMacOSApp();

        await device.startApp(
          package,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          prebuiltApplication: true,
        );
        await pumpEventQueue();
        await device.dispose();

        expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
        expect(logger.errorText, contains('access to protected resources.'));
        expect(logger.errorText, isNot(contains('requiring')));
        expect(
          logger.errorText,
          contains(
            'Even if the usage description key is already present in macos/Runner/Info.plist',
          ),
        );
        expect(
          logger.errorText,
          contains(
            '1. Ensure the required usage description key is present in macos/Runner/Info.plist.',
          ),
        );
        expect(
          logger.errorText,
          contains(
            "2. Run the project directly from Xcode, or 'flutter run' using the default macOS Terminal app.",
          ),
        );
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'does not print diagnostic on SIGABRT (-6) when log show finds no matching TCC entry',
      () async {
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['release/executable'],
            exitCode: MacOSDevice.kSigabrtExitCode,
          ),
          FakeCommand(
            command: logShowCommand,
            stdout: <String>[
              'non-JSON line echoing ${MacOSDevice.kMacOSPrivacyCrashPattern}',
              jsonEncode(<String, Object?>{
                'processID': 99999,
                'eventMessage': '${MacOSDevice.kMacOSPrivacyCrashPattern}.',
              }),
              jsonEncode(<String, Object?>{'count': 0, 'finished': 1}),
            ].join('\n'),
          ),
        ]);
        final device = MacOSDevice(
          analytics: const NoOpAnalytics(),
          appleContext: FakeAppleContext(),
          featureFlags: TestFeatureFlags(),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(logger: logger, processManager: processManager),
        );
        final package = FakeMacOSApp();

        await device.startApp(
          package,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          prebuiltApplication: true,
        );
        await pumpEventQueue();
        await device.dispose();

        expect(logger.errorText, isEmpty);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext('does not run log show on normal exit (0)', () async {
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['release/executable']),
      ]);
      final device = MacOSDevice(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: TestFeatureFlags(),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(logger: logger, processManager: processManager),
      );
      final package = FakeMacOSApp();

      await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        prebuiltApplication: true,
      );
      await pumpEventQueue();
      await device.dispose();

      expect(logger.errorText, isEmpty);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('does not run log show on non-SIGABRT signal (-9)', () async {
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['release/executable'], exitCode: -9),
      ]);
      final device = MacOSDevice(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: TestFeatureFlags(),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(logger: logger, processManager: processManager),
      );
      final package = FakeMacOSApp();

      await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        prebuiltApplication: true,
      );
      await pumpEventQueue();
      await device.dispose();

      expect(logger.errorText, isEmpty);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('skips log show when /usr/bin/log cannot be executed', () async {
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['release/executable'],
          exitCode: MacOSDevice.kSigabrtExitCode,
        ),
      ])..excludedExecutables = <String>{'/usr/bin/log'};
      final device = MacOSDevice(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: TestFeatureFlags(),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(logger: logger, processManager: processManager),
      );
      final package = FakeMacOSApp();

      await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        prebuiltApplication: true,
      );
      await pumpEventQueue();
      await device.dispose();

      expect(logger.errorText, isEmpty);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('handles log show ProcessException gracefully', () async {
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['release/executable'],
          exitCode: MacOSDevice.kSigabrtExitCode,
        ),
        const FakeCommand(
          command: logShowCommand,
          exception: ProcessException('/usr/bin/log', <String>['show']),
        ),
      ]);
      final device = MacOSDevice(
        analytics: const NoOpAnalytics(),
        appleContext: FakeAppleContext(),
        featureFlags: TestFeatureFlags(),
        templateRenderer: FakeTemplateRenderer(),
        toolContext: FakeToolContext(logger: logger, processManager: processManager),
      );
      final package = FakeMacOSApp();

      await device.startApp(
        package,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        prebuiltApplication: true,
      );
      await pumpEventQueue();
      await device.dispose();

      expect(logger.errorText, isNot(contains('macOS Privacy Permission Crash Detected')));
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  group('buildForDevice', () {
    late MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'forwards analytics to buildMacOS',
      () async {
        fileSystem
            .directory(fileSystem.path.join('macos', 'Runner.xcodeproj'))
            .createSync(recursive: true);
        fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app');
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');

        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: fileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );
        final fakeOperatingSystemUtils = FakeOperatingSystemUtils()
          ..hostPlatform = HostPlatform.darwin_arm64;
        final featureFlags = TestFeatureFlags(isMacOSEnabled: true);
        final macOSDevices = MacOSDevices(
          analytics: fakeAnalytics,
          appleContext: FakeAppleContext(),
          featureFlags: featureFlags,
          macOSWorkflow: MacOSWorkflow(featureFlags: featureFlags, platform: macOS),
          templateRenderer: FakeTemplateRenderer(),
          toolContext: FakeToolContext(
            fs: fileSystem,
            os: fakeOperatingSystemUtils,
            platform: macOS,
          ),
        );
        final List<Device> devices = await macOSDevices.devices();
        final device = devices.single as MacOSDevice;

        await device.buildForDevice(buildInfo: BuildInfo.debug);

        expect(
          analyticsTimingEventExists(
            sentEvents: fakeAnalytics.sentEvents,
            workflow: 'build',
            variableName: 'xcode-macos',
          ),
          true,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.empty(),
      },
    );
  });
}

FlutterProject setUpFlutterProject(Directory directory) {
  final flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
    config: FakeConfig(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

class FakeMacOSApp extends Fake implements MacOSApp {
  @override
  String executable(BuildInfo buildInfo) {
    return switch (buildInfo) {
      BuildInfo.debug => 'debug/executable',
      BuildInfo.profile => 'profile/executable',
      BuildInfo.release => 'release/executable',
      _ => throw StateError(''),
    };
  }
}
