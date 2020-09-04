// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const FakeCommand kAdbVersionCommand = FakeCommand(
  command: <String>['adb', 'version'],
  stdout: 'Android Debug Bridge version 1.0.39',
);

const FakeCommand kStartServer = FakeCommand(
  command: <String>['adb', 'start-server'],
);

const FakeCommand kShaCommand = FakeCommand(
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
  FileSystem fileSystem;
  FakeProcessManager processManager;
  AndroidSdk androidSdk;

  setUp(() {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    fileSystem = MemoryFileSystem.test();
    androidSdk = MockAndroidSdk();
    when(androidSdk.adbPath).thenReturn('adb');
    when(androidSdk.licensesAvailable).thenReturn(false);
  });

  for (final TargetPlatform targetPlatform in <TargetPlatform>[
    TargetPlatform.android_arm,
    TargetPlatform.android_arm64,
    TargetPlatform.android_x64,
  ]) {
    testWithoutContext('AndroidDevice.startApp allows release builds on $targetPlatform', () async {
      final String arch = getNameForAndroidArch(
        getAndroidArchForName(getNameForTargetPlatform(targetPlatform)));
      final AndroidDevice device = AndroidDevice('1234', modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        androidSdk: androidSdk,
      );
      final File apkFile = fileSystem.file('app.apk')..createSync();
      final AndroidApk apk = AndroidApk(
        id: 'FlutterApp',
        file: apkFile,
        launchActivity: 'FlutterActivity',
        versionCode: 1,
      );

      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);

      // This configures the target platform of the device.
      processManager.addCommand(FakeCommand(
        command: const <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.product.cpu.abi]: [$arch]',
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', 'FlutterApp'],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'pm', 'list', 'packages', 'FlutterApp'],
      ));
      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);
      processManager.addCommand(const FakeCommand(
        command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app.apk'],
      ));
      processManager.addCommand(kShaCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          'am',
          'start',
          '-a',
          'android.intent.action.RUN',
          '-f',
          '0x20000000',
          '--ez', 'enable-background-compilation', 'true',
          '--ez', 'enable-dart-profiling', 'true',
          'FlutterActivity',
        ],
      ));

      final LaunchResult launchResult = await device.startApp(
        apk,
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(
          BuildInfo.release,
        ),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, true);
      expect(processManager.hasRemainingExpectations, false);
    });
  }

  testWithoutContext('AndroidDevice.startApp does not allow release builds on x86', () async {
    final AndroidDevice device = AndroidDevice('1234', modelID: 'TestModel',
      fileSystem: fileSystem,
      processManager: processManager,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      androidSdk: androidSdk,
    );
    final File apkFile = fileSystem.file('app.apk')..createSync();
    final AndroidApk apk = AndroidApk(
      id: 'FlutterApp',
      file: apkFile,
      launchActivity: 'FlutterActivity',
      versionCode: 1,
    );

    processManager.addCommand(kAdbVersionCommand);
    processManager.addCommand(kStartServer);

    // This configures the target platform of the device.
    processManager.addCommand(const FakeCommand(
      command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
      stdout: '[ro.product.cpu.abi]: [x86]',
    ));

    final LaunchResult launchResult = await device.startApp(
      apk,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.disabled(
        BuildInfo.release,
      ),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, false);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('AndroidDevice.startApp forwards all supported debugging options', () async {
    final AndroidDevice device = AndroidDevice('1234', modelID: 'TestModel',
      fileSystem: fileSystem,
      processManager: processManager,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      androidSdk: androidSdk,
    );
    final File apkFile = fileSystem.file('app.apk')..createSync();
    final AndroidApk apk = AndroidApk(
      id: 'FlutterApp',
      file: apkFile,
      launchActivity: 'FlutterActivity',
      versionCode: 1,
    );

    // These commands are required to install and start the app
    processManager.addCommand(kAdbVersionCommand);
    processManager.addCommand(kStartServer);
    processManager.addCommand(const FakeCommand(
      command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
    ));
    processManager.addCommand(const FakeCommand(
      command: <String>['adb', '-s', '1234', 'shell', 'am', 'force-stop', '--user', '10', 'FlutterApp'],
    ));
    processManager.addCommand(const FakeCommand(
      command: <String>['adb', '-s', '1234', 'shell', 'pm', 'list', 'packages', '--user', '10', 'FlutterApp'],
    ));
    processManager.addCommand(kAdbVersionCommand);
    processManager.addCommand(kStartServer);
    // TODO(jonahwilliams): investigate why this doesn't work.
    // This doesn't work with the current Android log reader implementation.
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'adb',
        '-s',
        '1234',
        'install',
        '-t',
        '-r',
        '--user',
        '10',
        'app.apk'
      ],
      stdout: '\n\nObservatory listening on http://127.0.0.1:456\n\n',
    ));
    processManager.addCommand(kShaCommand);
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'adb',
        '-s',
        '1234',
        'shell',
        '-x',
        'logcat',
        '-v',
        'time',
      ],
    ));

    // This command contains all launch arguments.
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'adb',
        '-s',
        '1234',
        'shell',
        'am',
        'start',
        '-a',
        'android.intent.action.RUN',
        '-f',
        '0x20000000',
        // The DebuggingOptions arguments go here.
        '--ez', 'enable-background-compilation', 'true',
        '--ez', 'enable-dart-profiling', 'true',
        '--ez', 'enable-software-rendering', 'true',
        '--ez', 'skia-deterministic-rendering', 'true',
        '--ez', 'trace-skia', 'true',
        '--ez', 'trace-allowlist', 'bar,baz',
        '--ez', 'trace-systrace', 'true',
        '--ez', 'endless-trace-buffer', 'true',
        '--ez', 'dump-skp-on-shader-compilation', 'true',
        '--ez', 'cache-sksl', 'true',
        '--ez', 'purge-persistent-cache', 'true',
        '--ez', 'enable-checked-mode', 'true',
        '--ez', 'verify-entry-points', 'true',
        '--ez', 'start-paused', 'true',
        '--ez', 'disable-service-auth-codes', 'true',
        '--es', 'dart-flags', 'foo,--null_assertions',
        '--ez', 'use-test-fonts', 'true',
        '--ez', 'verbose-logging', 'true',
        '--user', '10',
        'FlutterActivity',
      ],
    ));

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
        traceSystrace: true,
        endlessTraceBuffer: true,
        dumpSkpOnShaderCompilation: true,
        cacheSkSL: true,
        purgePersistentCache: true,
        useTestFonts: true,
        verboseSystemLogs: true,
        nullAssertions: true,
      ),
      platformArgs: <String, dynamic>{},
      userIdentifier: '10',
    );

    // This fails to start due to observatory discovery issues.
    expect(launchResult.started, false);
    expect(processManager.hasRemainingExpectations, false);
  });
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
