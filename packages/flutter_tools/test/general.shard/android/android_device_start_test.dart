// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

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
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../commands.shard/hermetic/proxied_devices_test.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../base/error_handling_io_test.dart';

const kAdbVersionCommand = FakeCommand(
  command: <String>['adb', 'version'],
  stdout: 'Android Debug Bridge version 1.0.39',
);

const kStartServer = FakeCommand(command: <String>['adb', 'start-server']);

const kShaCommand = FakeCommand(
  command: <String>[
    'adb',
    '-s',
    '1234',
    'shell',
    'echo',
    '-n',
    '',
    '>',
    '/data/local/tmp/sky.FlutterApp.sha1',
  ],
);

void main() {
  late FileSystem fileSystem;
  late FakeProcessManager processManager;
  late AndroidSdk androidSdk;

  setUp(() {
    processManager = FakeProcessManager.empty();
    fileSystem = MemoryFileSystem.test();
    androidSdk = FakeAndroidSdk();
  });

  for (final targetPlatform in <TargetPlatform>[
    TargetPlatform.android_arm,
    TargetPlatform.android_arm64,
    TargetPlatform.android_x64,
  ]) {
    testWithoutContext('AndroidDevice.startApp allows release builds on $targetPlatform', () async {
      final String arch = getAndroidArchForName(getNameForTargetPlatform(targetPlatform)).archName;
      final device = AndroidDevice(
        '1234',
        modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      final File apkFile = fileSystem.file('app-debug.apk')..createSync();
      final apk = AndroidApk(
        id: 'FlutterApp',
        applicationPackage: apkFile,
        launchActivity: 'FlutterActivity',
        versionCode: 1,
      );

      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);

      // This configures the target platform of the device.
      processManager.addCommand(
        FakeCommand(
          command: const <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.product.cpu.abi]: [$arch]',
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-debug.apk'],
        ),
      );
      processManager.addCommand(kShaCommand);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'start',
            '-a',
            'android.intent.action.MAIN',
            '-c',
            'android.intent.category.LAUNCHER',
            '-f',
            '0x20000000',
            'FlutterActivity',
          ],
        ),
      );

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

  testWithoutContext(
    'AndroidDevice.startApp forwards only the --user flag to the Intent if specified in debugging options',
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
      final File apkFile = fileSystem.file('app-debug.apk')..createSync();
      final apk = AndroidApk(
        id: 'FlutterApp',
        applicationPackage: apkFile,
        launchActivity: 'FlutterActivity',
        versionCode: 1,
      );

      // These commands are required to install and start the app
      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.product.cpu.abi]: [x86_64]',
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'force-stop',
            '--user',
            '10',
            'FlutterApp',
          ],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'install',
            '-t',
            '-r',
            '--user',
            '10',
            'app-debug.apk',
          ],
          stdout: '\n\nThe Dart VM service is listening on http://127.0.0.1:456\n\n',
        ),
      );
      processManager.addCommand(kShaCommand);
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', '-x', 'logcat', '-v', 'time'],
        ),
      );

      // This command contains the user launch arguments.
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'start',
            '-a',
            'android.intent.action.MAIN',
            '-c',
            'android.intent.category.LAUNCHER',
            '-f',
            '0x20000000',
            '--user',
            '10',
            'FlutterActivity',
          ],
        ),
      );

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
    },
  );

  group('startApp handles engine shell arguments from debugging options as expected', () {
    late FakeAndroidBuilder fakeAndroidBuilder;
    late _FakeApplicationPackageFactory fakeApplicationPackageFactory;
    const apkId = 'FlutterApp';
    const apkPath = 'app-debug.apk';
    const apkLaunchActivity = 'FlutterActivity';

    setUp(() {
      fakeAndroidBuilder = FakeAndroidBuilder();
      fakeApplicationPackageFactory = _FakeApplicationPackageFactory(
        apkId,
        apkPath,
        apkLaunchActivity,
      );
    });

    testUsingContext(
      'startApp passes expected engine shell arguments from specified debugging options to build APK',
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
        final File apkFile = fileSystem.file('app-debug.apk')..createSync();
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
        );

        // These commands are required to install and start the app
        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [x86_64]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'force-stop',
              '--user',
              '10',
              apkId,
            ],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', '--user', '10', apkPath],
            stdout: '\n\nThe Dart VM service is listening on http://127.0.0.1:456\n\n',
          ),
        );
        processManager.addCommand(kShaCommand);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', '-x', 'logcat', '-v', 'time'],
          ),
        );

        // This command contains the user launch arguments.
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'start',
              '-a',
              'android.intent.action.MAIN',
              '-c',
              'android.intent.category.LAUNCHER',
              '-f',
              '0x20000000',
              '--user',
              '10',
              apkLaunchActivity,
            ],
          ),
        );

        final allPossibleDebuggingOptions = DebuggingOptions.enabled(
          BuildInfo.debug,
          // ignore: avoid_redundant_argument_values
          enableDartProfiling: true,
          profileStartup: true,
          enableSoftwareRendering: true,
          skiaDeterministicRendering: true,
          traceSkia: true,
          traceAllowlist: 'foo',
          traceSkiaAllowlist: 'skia.a,skia.b',
          traceSystrace: true,
          traceToFile: 'path/to/trace.file',
          endlessTraceBuffer: true,
          profileMicrotasks: true,
          purgePersistentCache: true,
          enableImpeller: ImpellerStatus.disabled,
          enableFlutterGpu: true,
          enableVulkanValidation: true,
          startPaused: true,
          disableServiceAuthCodes: true,
          dartFlags: '--foo',
          enableHcpp: true,
          useTestFonts: true,
          verboseSystemLogs: true,
        );
        const testRoute = 'some/route';
        final allPossiblePlatformArgs = <String, dynamic>{'trace-startup': true};
        final expectedShellArgs = <String>[
          '--enable-dart-profiling',
          '--profile-startup',
          '--enable-software-rendering',
          '--skia-deterministic-rendering',
          '--trace-skia',
          '--trace-allowlist=foo',
          '--trace-skia-allowlist=skia.a,skia.b',
          '--trace-systrace',
          '--trace-to-file=path/to/trace.file',
          '--endless-trace-buffer',
          '--profile-microtasks',
          '--purge-persistent-cache',
          '--enable-impeller=false',
          '--enable-flutter-gpu',
          '--enable-vulkan-validation',
          '--enable-checked-mode',
          '--verify-entry-points',
          '--start-paused',
          '--disable-service-auth-codes',
          '--dart-flags=--foo',
          '--enable-hcpp-and-surface-control',
          '--use-test-fonts',
          '--verbose-logging',
          '--trace-startup',
          '--route=$testRoute',
        ];

        final LaunchResult launchResult = await device.startApp(
          apk,
          // ignore: avoid_redundant_argument_values
          prebuiltApplication: false,
          debuggingOptions: allPossibleDebuggingOptions,
          platformArgs: allPossiblePlatformArgs,
          userIdentifier: '10',
          route: testRoute,
        );

        // This fails to start due to VM Service discovery issues.
        expect(launchResult.started, false);
        expect(processManager, hasNoRemainingExpectations);

        expect(fakeAndroidBuilder.capturedAndroidShellArgs, expectedShellArgs);
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => fakeAndroidBuilder,
        ApplicationPackageFactory: () => fakeApplicationPackageFactory,
      },
    );

    testUsingContext(
      'startApp does not rebuild the APK if engine shell arguments have not changed between invocations',
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
        final File apkFile = fileSystem.file('app-debug.apk')..createSync();
        const testRoute = 'some/route';
        final unchangingEngineShellArguments = <String>{
          '--enable-dart-profiling',
          '--trace-allowlist=foo',
          '--enable-checked-mode',
          '--verify-entry-points',
          '--verbose-logging',
          '--route=$testRoute',
        };
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
          engineShellArgs: unchangingEngineShellArguments,
        );

        // These commands are required to install and start the app
        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [x86_64]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'force-stop',
              '--user',
              '10',
              apkId,
            ],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', '--user', '10', apkPath],
            stdout: '\n\nThe Dart VM service is listening on http://127.0.0.1:456\n\n',
          ),
        );
        processManager.addCommand(kShaCommand);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', '-x', 'logcat', '-v', 'time'],
          ),
        );

        // This command contains the user launch arguments.
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'start',
              '-a',
              'android.intent.action.MAIN',
              '-c',
              'android.intent.category.LAUNCHER',
              '-f',
              '0x20000000',
              '--user',
              '10',
              apkLaunchActivity,
            ],
          ),
        );

        final debuggingOptions = DebuggingOptions.enabled(
          BuildInfo.debug,
          traceAllowlist: 'foo',
          verboseSystemLogs: true,
        );

        final LaunchResult launchResult = await device.startApp(
          apk,
          prebuiltApplication: true,
          debuggingOptions: debuggingOptions,
          userIdentifier: '10',
          route: testRoute,
        );

        expect(launchResult.started, false);
        expect(launchResult.started, false);
        expect(processManager, hasNoRemainingExpectations);

        // We expected AndroidBuilder.buildApk to never be called, since we are
        // starting a prebuilt application with unchanged engine shell arguments
        // from the previous invocation.
        expect(fakeAndroidBuilder.capturedAndroidShellArgs, isNull);
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => fakeAndroidBuilder,
        ApplicationPackageFactory: () => fakeApplicationPackageFactory,
      },
    );

    testUsingContext(
      'startApp rebuilds APK if engine shell arguments have changed between invocations',
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
        final File apkFile = fileSystem.file('app-debug.apk')..createSync();
        const testRoute = 'some/route';
        final previousEngineShellArguments = <String>{
          '--enable-dart-profiling',
          '--trace-allowlist=foo',
          '--enable-checked-mode',
          '--verify-entry-points',
          '--verbose-logging',
          '--route=$testRoute',
        };
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
          engineShellArgs: previousEngineShellArguments,
        );

        // These commands are required to install and start the app
        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [x86_64]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'force-stop',
              '--user',
              '10',
              apkId,
            ],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', '--user', '10', apkPath],
            stdout: '\n\nThe Dart VM service is listening on http://127.0.0.1:456\n\n',
          ),
        );
        processManager.addCommand(kShaCommand);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', '-x', 'logcat', '-v', 'time'],
          ),
        );

        // This command contains the user launch arguments.
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'adb',
              '-s',
              '1234',
              'shell',
              'am',
              'start',
              '-a',
              'android.intent.action.MAIN',
              '-c',
              'android.intent.category.LAUNCHER',
              '-f',
              '0x20000000',
              '--user',
              '10',
              apkLaunchActivity,
            ],
          ),
        );

        final debuggingOptions = DebuggingOptions.enabled(
          BuildInfo.debug,
          traceAllowlist: 'foo2',
          verboseSystemLogs: true,
        );
        final expectedShellArgs = <String>[
          '--enable-dart-profiling',
          '--trace-allowlist=foo2',
          '--enable-checked-mode',
          '--verify-entry-points',
          '--verbose-logging',
          '--route=$testRoute',
        ];

        final LaunchResult launchResult = await device.startApp(
          apk,
          prebuiltApplication: true,
          debuggingOptions: debuggingOptions,
          userIdentifier: '10',
          route: testRoute,
        );

        expect(launchResult.started, false);
        expect(launchResult.started, false);
        expect(fakeAndroidBuilder.capturedAndroidShellArgs, expectedShellArgs);
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => fakeAndroidBuilder,
        ApplicationPackageFactory: () => fakeApplicationPackageFactory,
      },
    );
  });
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';

  @override
  bool get licensesAvailable => false;
}

class FakeAndroidBuilder implements AndroidBuilder {
  Set<String>? capturedAndroidShellArgs;

  @override
  Future<void> buildAar({
    required FlutterProject project,
    required Set<AndroidBuildInfo> androidBuildInfo,
    required String target,
    required Future<void> Function(FlutterProject, {required bool releaseMode}) generateTooling,
    String? outputDirectoryPath,
    required String buildNumber,
  }) async {}

  @override
  Future<void> buildApk({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    Set<String>? androidShellArguments,
    bool configOnly = false,
  }) async {
    capturedAndroidShellArgs = androidShellArguments;
  }

  @override
  Future<void> buildAab({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool validateDeferredComponents = true,
    bool deferredComponentsEnabled = false,
    bool configOnly = false,
  }) async {}

  @override
  Future<List<String>> getBuildVariants({required FlutterProject project}) async =>
      const <String>[];

  @override
  Future<String> outputsAppLinkSettings(
    String buildVariant, {
    required FlutterProject project,
  }) async => '/';
}

class _FakeApplicationPackageFactory implements ApplicationPackageFactory {
  _FakeApplicationPackageFactory(this.apkId, this.apkPath, this.apkLaunchActivity);

  final String apkId;
  final String apkPath;
  final String apkLaunchActivity;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    return _FakeAndroidApk(apkId, apkPath, apkLaunchActivity);
  }
}

class _FakeAndroidApk extends Fake implements AndroidApk {
  _FakeAndroidApk(this._id, this.applicationPackagePath, this._launchActivity);

  final String applicationPackagePath;
  final String _id;
  final String _launchActivity;

  @override
  String get id => _id;

  @override
  String get name => 'fakeApkName';

  @override
  FileSystemEntity get applicationPackage => FakeFile(applicationPackagePath);

  @override
  String get launchActivity => _launchActivity;
}

class FakeFile extends Fake implements File {
  FakeFile(this.path);

  @override
  final String path;

  @override
  bool existsSync() {
    return true;
  }

  @override
  String readAsStringSync({Encoding encoding = utf8ForTesting}) {
    return 'literally whatever';
  }
}
