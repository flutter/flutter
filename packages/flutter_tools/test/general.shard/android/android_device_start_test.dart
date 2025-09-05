// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

void main() {
  const kFakeDeviceId = '1234';
  const kFakeModelId = 'TestModel';
  const kFakeMainActivity = '.MainActivity';
  const kFakeFlutterActivity = 'FlutterActivity';
  const kFakeApkPath = 'app-debug.apk';
  const kFakeDummyApkPath = 'dummy.apk';
  const kAnotherFakeAppId = 'FlutterApp';
  const kFakeAppId = 'com.example.app';

  late FileSystem fileSystem;
  late FakeProcessManager processManager;
  late AndroidSdk androidSdk;
  late FakeAndroidBuilder androidBuilder;
  late ApplicationPackageFactory applicationPackageFactory;

  setUp(() {
    processManager = FakeProcessManager.empty();
    fileSystem = MemoryFileSystem.test();
    androidSdk = FakeAndroidSdk();
    androidBuilder = FakeAndroidBuilder();
    applicationPackageFactory = FakeApplicationPackageFactory(
      kFakeAppId,
      kFakeDummyApkPath,
      kFakeMainActivity,
    );
  });

  List<FakeCommand> buildAdbVersionCommand({String version = '1.0.40'}) {
    return <FakeCommand>[
      FakeCommand(
        command: const <String>['adb', 'version'],
        stdout: 'Android Debug Bridge version $version',
      ),
      const FakeCommand(command: <String>['adb', 'start-server']),
    ];
  }

  List<FakeCommand> buildDeviceSetupCommands(
    String deviceId, {
    String cpuAbi = 'arm64-v8a',
    String androidVersion = '99',
    String appId = 'com.example.app',
    String? user,
  }) {
    return <FakeCommand>[
      FakeCommand(
        command: <String>['adb', '-s', deviceId, 'shell', 'getprop'],
        stdout: '[ro.product.cpu.abi]: [$cpuAbi]\n[ro.build.version.sdk]: [$androidVersion]',
      ),
      FakeCommand(
        command: <String>[
          'adb',
          '-s',
          deviceId,
          'shell',
          'am',
          'force-stop',
          if (user != null) ...<String>['--user', user],
          appId,
        ],
      ),
    ];
  }

  List<FakeCommand> buildApkInstallCommands(
    String deviceId, {
    String apkPath = kFakeDummyApkPath,
    String appId = 'com.example.app',
    String? user,
    String stdout = '',
  }) {
    final sha1Path = '/data/local/tmp/sky.$appId.sha1';
    return <FakeCommand>[
      FakeCommand(
        command: <String>[
          'adb',
          '-s',
          deviceId,
          'install',
          '-t',
          '-r',
          if (user != null) ...<String>['--user', user],
          apkPath,
        ],
        stdout: stdout,
      ),
      FakeCommand(
        command: <String>['adb', '-s', deviceId, 'shell', 'echo', '-n', '', '>', sha1Path],
      ),
    ];
  }

  List<FakeCommand> buildAmStartCommands(
    String deviceId, {
    String activity = kFakeMainActivity,
    List<String> extraArgs = const [],
    bool withLogcat = false,
    String? user,
  }) {
    return <FakeCommand>[
      if (withLogcat)
        FakeCommand(
          command: <String>[
            'adb',
            '-s',
            deviceId,
            'shell',
            '-x',
            'logcat',
            '-v',
            'time',
            '-T',
            '0',
          ],
        ),
      FakeCommand(
        command: <String>[
          'adb',
          '-s',
          deviceId,
          'shell',
          'am',
          'start',
          '-a',
          'android.intent.action.MAIN',
          '-c',
          'android.intent.category.LAUNCHER',
          '-f',
          '0x20000000',
          ...extraArgs,
          if (user != null) ...<String>['--user', user],
          activity,
        ],
      ),
    ];
  }

  for (final targetPlatform in <TargetPlatform>[
    TargetPlatform.android_arm,
    TargetPlatform.android_arm64,
    TargetPlatform.android_x64,
  ]) {
    testWithoutContext('AndroidDevice.startApp allows release builds on $targetPlatform', () async {
      final String arch = getAndroidArchForName(getNameForTargetPlatform(targetPlatform)).archName;
      final device = AndroidDevice(
        kFakeDeviceId,
        modelID: kFakeModelId,
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      final File apkFile = fileSystem.file(kFakeApkPath)..createSync();
      final apk = AndroidApk(
        id: kAnotherFakeAppId,
        applicationPackage: apkFile,
        launchActivity: kFakeFlutterActivity,
        versionCode: 1,
      );

      processManager.addCommands(<FakeCommand>[
        ...buildAdbVersionCommand(version: '1.0.39'),
        ...buildDeviceSetupCommands(kFakeDeviceId, cpuAbi: arch, appId: kAnotherFakeAppId),
        ...buildApkInstallCommands(kFakeDeviceId, apkPath: kFakeApkPath, appId: kAnotherFakeAppId),
        ...buildAmStartCommands(
          kFakeDeviceId,
          activity: kFakeFlutterActivity,
          extraArgs: <String>['--ez', 'enable-dart-profiling', 'true'],
        ),
      ]);

      final LaunchResult launchResult = await device.startApp(
        apk,
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, true);
      expect(processManager, hasNoRemainingExpectations);
    });
  }

  testWithoutContext('AndroidDevice.startApp forwards all supported debugging options', () async {
    final device = AndroidDevice(
      kFakeDeviceId,
      modelID: kFakeModelId,
      fileSystem: fileSystem,
      processManager: processManager,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      androidSdk: androidSdk,
    );
    final File apkFile = fileSystem.file(kFakeApkPath)..createSync();
    final apk = AndroidApk(
      id: kAnotherFakeAppId,
      applicationPackage: apkFile,
      launchActivity: kFakeFlutterActivity,
      versionCode: 1,
    );

    processManager.addCommands(<FakeCommand>[
      ...buildAdbVersionCommand(version: '1.0.39'),
      ...buildDeviceSetupCommands(
        kFakeDeviceId,
        cpuAbi: 'x86_64',
        appId: kAnotherFakeAppId,
        user: '10',
      ),
      ...buildApkInstallCommands(
        kFakeDeviceId,
        apkPath: kFakeApkPath,
        appId: kAnotherFakeAppId,
        user: '10',
        stdout: '\n\nThe Dart VM service is listening on http://127.0.0.1:456\n\n',
      ),
      ...buildAmStartCommands(
        kFakeDeviceId,
        activity: kFakeFlutterActivity,
        user: '10',
        withLogcat: true,
        extraArgs: <String>[
          '--ez',
          'enable-dart-profiling',
          'true',
          '--ez',
          'profile-startup',
          'true',
          '--ez',
          'enable-software-rendering',
          'true',
          '--ez',
          'skia-deterministic-rendering',
          'true',
          '--ez',
          'trace-skia',
          'true',
          '--es',
          'trace-allowlist',
          'bar,baz',
          '--es',
          'trace-skia-allowlist',
          'skia.a,skia.b',
          '--ez',
          'trace-systrace',
          'true',
          '--es',
          'trace-to-file',
          'path/to/trace.binpb',
          '--ez',
          'endless-trace-buffer',
          'true',
          '--ez',
          'profile-microtasks',
          'true',
          '--ez',
          'purge-persistent-cache',
          'true',
          '--ez',
          'enable-impeller',
          'true',
          '--ez',
          'enable-flutter-gpu',
          'true',
          '--ez',
          'enable-checked-mode',
          'true',
          '--ez',
          'verify-entry-points',
          'true',
          '--ez',
          'start-paused',
          'true',
          '--ez',
          'disable-service-auth-codes',
          'true',
          '--es',
          'dart-flags',
          'foo',
          '--ez',
          'use-test-fonts',
          'true',
          '--ez',
          'verbose-logging',
          'true',
        ],
      ),
    ]);

    final LaunchResult launchResult = await device.startApp(
      apk,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
        startPaused: true,
        disableServiceAuthCodes: true,
        dartFlags: 'foo',
        enableSoftwareRendering: true,
        skiaDeterministicRendering: true,
        traceSkia: true,
        traceAllowlist: 'bar,baz',
        traceSkiaAllowlist: 'skia.a,skia.b',
        traceSystrace: true,
        traceToFile: 'path/to/trace.binpb',
        endlessTraceBuffer: true,
        profileMicrotasks: true,
        purgePersistentCache: true,
        useTestFonts: true,
        verboseSystemLogs: true,
        enableImpeller: ImpellerStatus.enabled,
        enableFlutterGpu: true,
        profileStartup: true,
      ),
      platformArgs: <String, dynamic>{},
      userIdentifier: '10',
    );

    // This fails to start due to VM Service discovery issues.
    expect(launchResult.started, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext(
    'calls gradle install when enableGradleManagedInstall is true',
    () async {
      final device = AndroidDevice(
        '1234',
        modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      processManager.addCommands(<FakeCommand>[
        ...buildAdbVersionCommand(),
        ...buildDeviceSetupCommands(device.id),
        ...buildAmStartCommands(
          device.id,
          withLogcat: true,
          extraArgs: <String>[
            '--ez',
            'enable-dart-profiling',
            'true',
            '--ez',
            'enable-checked-mode',
            'true',
            '--ez',
            'verify-entry-points',
            'true',
          ],
        ),
      ]);

      await device.startApp(
        null,
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(BuildMode.debug, '', treeShakeIcons: false, packageConfigPath: ''),
          enableGradleManagedInstall: true,
        ),
      );

      expect(androidBuilder.usedInstallApp, isTrue);
      expect(androidBuilder.usedBuildApk, isFalse);
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => androidBuilder,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      ApplicationPackageFactory: () => applicationPackageFactory,
      FlutterProjectFactory: () =>
          FlutterProjectFactory(fileSystem: fileSystem, logger: BufferLogger.test()),
    },
  );

  testUsingContext(
    'calls gradle build apk when enableGradleManagedInstall is false',
    () async {
      final device = AndroidDevice(
        '1234',
        modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      processManager.addCommands(<FakeCommand>[
        ...buildAdbVersionCommand(),
        ...buildDeviceSetupCommands(device.id),
        ...buildApkInstallCommands(device.id),
        ...buildAmStartCommands(
          device.id,
          withLogcat: true,
          extraArgs: <String>[
            '--ez',
            'enable-dart-profiling',
            'true',
            '--ez',
            'enable-checked-mode',
            'true',
            '--ez',
            'verify-entry-points',
            'true',
          ],
        ),
      ]);

      await device.startApp(
        null,
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            '',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );

      expect(androidBuilder.usedInstallApp, isFalse);
      expect(androidBuilder.usedBuildApk, isTrue);
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => androidBuilder,
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      ApplicationPackageFactory: () => applicationPackageFactory,
      FlutterProjectFactory: () =>
          FlutterProjectFactory(fileSystem: fileSystem, logger: BufferLogger.test()),
    },
  );
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';

  @override
  bool get licensesAvailable => false;
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeApplicationPackageFactory(this.appId, this.dummyApkPath, this.mainActivity);

  final String appId;
  final String dummyApkPath;
  final String mainActivity;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    return AndroidApk(
      id: appId,
      applicationPackage: MemoryFileSystem.test().file(dummyApkPath)..createSync(),
      launchActivity: mainActivity,
      versionCode: 1,
    );
  }
}

class FakeAndroidBuilder extends Fake implements AndroidBuilder {
  var usedInstallApp = false;
  var usedBuildApk = false;

  @override
  Future<void> installApp({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String deviceId,
    String? userIdentifier,
  }) async {
    usedInstallApp = true;
  }

  @override
  Future<void> buildApk({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool configOnly = false,
  }) async {
    usedBuildApk = true;
  }
}
