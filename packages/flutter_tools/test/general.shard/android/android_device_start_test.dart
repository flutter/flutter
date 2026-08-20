// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/application_package.dart';
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
      final String arch = getCpuArchForName(targetPlatform.getName()).androidArchName;
      final device = AndroidDevice(
        '1234',
        modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      final File apkFile = fileSystem.file('app-release.apk')..createSync();
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
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release, enableDartProfiling: false),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, true);
      expect(processManager, hasNoRemainingExpectations);
    });
  }

  testWithoutContext(
    'AndroidDevice.startApp forwards Impeller and HCPP flags in release mode',
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
      final File apkFile = fileSystem.file('app-release.apk')..createSync();
      final apk = AndroidApk(
        id: 'FlutterApp',
        applicationPackage: apkFile,
        launchActivity: 'FlutterActivity',
        versionCode: 1,
      );

      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
            '--ez',
            'enable-impeller',
            'true',
            '--ez',
            'enable-hcpp-and-surface-control',
            'true',
            'FlutterActivity',
          ],
        ),
      );

      final LaunchResult launchResult = await device.startApp(
        apk,
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(
          BuildInfo.release,
          enableImpeller: ImpellerStatus.enabled,
          enableHcpp: true,
          enableDartProfiling: false,
        ),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, true);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('AndroidDevice.startApp forwards traceSystrace in release mode', () async {
    final device = AndroidDevice(
      '1234',
      modelID: 'TestModel',
      fileSystem: fileSystem,
      processManager: processManager,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      androidSdk: androidSdk,
    );
    final File apkFile = fileSystem.file('app-release.apk')..createSync();
    final apk = AndroidApk(
      id: 'FlutterApp',
      applicationPackage: apkFile,
      launchActivity: 'FlutterActivity',
      versionCode: 1,
    );

    processManager.addCommand(kAdbVersionCommand);
    processManager.addCommand(kStartServer);
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
      ),
    );
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
      ),
    );
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
          '--ez',
          'trace-systrace',
          'true',
          'FlutterActivity',
        ],
      ),
    );

    final LaunchResult launchResult = await device.startApp(
      apk,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.disabled(
        BuildInfo.release,
        traceSystrace: true,
        enableDartProfiling: false,
      ),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, true);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('AndroidDevice.startApp forwards all supported debugging options', () async {
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

    // This command contains all launch arguments.
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
          // The DebuggingOptions arguments go here.
          '--ez', 'enable-dart-profiling', 'true',
          '--ez', 'profile-startup', 'true',
          '--ez', 'enable-software-rendering', 'true',
          '--ez', 'skia-deterministic-rendering', 'true',
          '--ez', 'trace-skia', 'true',
          '--es', 'trace-allowlist', 'bar,baz',
          '--es', 'trace-skia-allowlist', 'skia.a,skia.b',
          '--ez', 'trace-systrace', 'true',
          '--es', 'trace-to-file', 'path/to/trace.binpb',
          '--ez', 'endless-trace-buffer', 'true',
          '--ez', 'profile-microtasks', 'true',
          '--ez', 'purge-persistent-cache', 'true',
          '--ez', 'enable-impeller', 'true',
          '--ez', 'enable-flutter-gpu', 'true',
          '--ez', 'enable-hcpp-and-surface-control', 'true',
          '--ez', 'enable-checked-mode', 'true',
          '--ez', 'verify-entry-points', 'true',
          '--ez', 'start-paused', 'true',
          '--ez', 'disable-service-auth-codes', 'true',
          '--es', 'dart-flags', 'foo',
          '--ez', 'use-test-fonts', 'true',
          '--ez', 'verbose-logging', 'true',
          '--es', 'route', '/custom/route',
          '--user', '10',
          'FlutterActivity',
        ],
      ),
    );

    final LaunchResult launchResult = await device.startApp(
      apk,
      prebuiltApplication: true,
      route: '/custom/route',
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
        enableHcpp: true,
      ),
      platformArgs: <String, dynamic>{},
      userIdentifier: '10',
    );

    // This fails to start due to VM Service discovery issues.
    expect(launchResult.started, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('AndroidDevice.startApp fails when am start returns Error type 3', () async {
    final device = AndroidDevice(
      '1234',
      modelID: 'TestModel',
      fileSystem: fileSystem,
      processManager: processManager,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
      androidSdk: androidSdk,
    );
    final File apkFile = fileSystem.file('app-release.apk')..createSync();
    final apk = AndroidApk(
      id: 'FlutterApp',
      applicationPackage: apkFile,
      launchActivity: 'FlutterActivity',
      versionCode: 1,
    );

    processManager.addCommand(kAdbVersionCommand);
    processManager.addCommand(kStartServer);
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
      ),
    );
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
      ),
    );
    processManager.addCommand(
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
        stdout: 'Error type 3: Activity class {FlutterApp/FlutterActivity} does not exist.',
      ),
    );

    final LaunchResult launchResult = await device.startApp(
      apk,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release, enableDartProfiling: false),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'AndroidDevice.startApp fails when am start returns Security exception',
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
      final File apkFile = fileSystem.file('app-release.apk')..createSync();
      final apk = AndroidApk(
        id: 'FlutterApp',
        applicationPackage: apkFile,
        launchActivity: 'FlutterActivity',
        versionCode: 1,
      );

      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
          stdout: 'Security exception: Permission Denial: starting Intent...',
        ),
      );

      final LaunchResult launchResult = await device.startApp(
        apk,
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release, enableDartProfiling: false),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, false);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  group('release mode engine shell arguments:', () {
    late FakeAndroidBuilder fakeAndroidBuilder;

    setUp(() {
      fakeAndroidBuilder = FakeAndroidBuilder();
    });

    testUsingContext(
      'AndroidDevice.startApp passes route via manifest when --use-application-binary is not used in release mode',
      () async {
        final logger = BufferLogger.test();
        final device = AndroidDevice(
          '1234',
          modelID: 'TestModel',
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          platform: FakePlatform(),
          androidSdk: androidSdk,
        );
        final File apkFile = fileSystem.file('app-release.apk')..createSync();
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
        );

        fileSystem.directory('android').createSync();
        fileSystem.file('android/AndroidManifest.xml').writeAsStringSync('''
        <manifest package="FlutterApp">
          <application>
            <activity android:name="FlutterActivity">
              <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
              </intent-filter>
            </activity>
          </application>
        </manifest>
        ''');

        fileSystem.file('build/app-release.apk').createSync(recursive: true);

        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'build/app-release.apk'],
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
              '--ez',
              'enable-impeller',
              'true',
              '--es',
              'route',
              '/custom/route',
              'FlutterApp/FlutterActivity',
            ],
          ),
        );

        final LaunchResult launchResult = await device.startApp(
          apk,
          route: '/custom/route',
          debuggingOptions: DebuggingOptions.disabled(
            BuildInfo.release,
            enableImpeller: ImpellerStatus.enabled,
            enableDartProfiling: false,
          ),
          platformArgs: <String, dynamic>{},
        );

        expect(launchResult.started, true);
        expect(processManager, hasNoRemainingExpectations);
        expect(fakeAndroidBuilder.lastAndroidBuildInfo?.releaseManifestEngineShellArgs, contains('--route=/custom/route'));
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => fakeAndroidBuilder,
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'AndroidDevice.startApp passes debugging options via manifest when --use-application-binary is not used in release mode',
      () async {
        final logger = BufferLogger.test();
        final device = AndroidDevice(
          '1234',
          modelID: 'TestModel',
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          platform: FakePlatform(),
          androidSdk: androidSdk,
        );
        final File apkFile = fileSystem.file('app-release.apk')..createSync();
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
        );

        fileSystem.directory('android').createSync();
        fileSystem.file('android/AndroidManifest.xml').writeAsStringSync('''
        <manifest package="FlutterApp">
          <application>
            <activity android:name="FlutterActivity">
              <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
              </intent-filter>
            </activity>
          </application>
        </manifest>
        ''');

        fileSystem.file('build/app-release.apk').createSync(recursive: true);

        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'build/app-release.apk'],
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
              '--ez',
              'enable-dart-profiling',
              'true',
              '--ez',
              'trace-systrace',
              'true',
              '--ez',
              'enable-impeller',
              'true',
              'FlutterApp/FlutterActivity',
            ],
          ),
        );

        final LaunchResult launchResult = await device.startApp(
          apk,
          debuggingOptions: DebuggingOptions.disabled(
            BuildInfo.release,
            enableImpeller: ImpellerStatus.enabled,
            traceSystrace: true,
            testFlag: true,
          ),
          platformArgs: <String, dynamic>{},
        );

        expect(launchResult.started, true);
        expect(processManager, hasNoRemainingExpectations);
        expect(fakeAndroidBuilder.lastAndroidBuildInfo, isNotNull);
        expect(
          fakeAndroidBuilder.lastAndroidBuildInfo!.releaseManifestEngineShellArgs,
          containsAll(<String>[
            '--enable-impeller=true',
            '--enable-dart-profiling',
            '--trace-systrace',
            '--test-flag',
          ]),
        );
      },
      overrides: <Type, Generator>{
        AndroidBuilder: () => fakeAndroidBuilder,
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testWithoutContext(
      'AndroidDevice.startApp passes debugging options via Intent when --use-application-binary is used in release mode',
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
        final File apkFile = fileSystem.file('app-release.apk')..createSync();
        final apk = AndroidApk(
          id: 'FlutterApp',
          applicationPackage: apkFile,
          launchActivity: 'FlutterActivity',
          versionCode: 1,
        );

        processManager.addCommand(kAdbVersionCommand);
        processManager.addCommand(kStartServer);
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
            stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
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
              '--ez',
              'enable-impeller',
              'true',
              'FlutterActivity',
            ],
          ),
        );

        final LaunchResult launchResult = await device.startApp(
          apk,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.disabled(
            BuildInfo.release,
            enableImpeller: ImpellerStatus.enabled,
            enableDartProfiling: false,
          ),
          platformArgs: <String, dynamic>{},
        );

        expect(launchResult.started, true);
        expect(processManager, hasNoRemainingExpectations);
        expect(fileSystem.file('android/AndroidManifest.xml').existsSync(), false);
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

class FakeAndroidBuilder extends Fake implements AndroidBuilder {
  AndroidBuildInfo? lastAndroidBuildInfo;

  @override
  Future<void> buildApk({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool isBuildingBundle = false,
    bool configOnly = false,
    List<String> retries = const <String>[],
  }) async {
    lastAndroidBuildInfo = androidBuildInfo;
  }
}
