// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_devices.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

// The command used to actually launch the app with args in release/profile.
const FakeCommand kLaunchReleaseCommand = FakeCommand(
  command: <String>[
    'HostArtifact.iosDeploy',
    '--id',
    '123',
    '--bundle',
    '/',
    '--no-wifi',
    '--justlaunch',
    // These args are the default on DebuggingOptions.
    '--args',
    '--enable-dart-profiling --disable-service-auth-codes',
  ],
  environment: <String, String>{
    'PATH': '/usr/bin:null',
    'DYLD_LIBRARY_PATH': '/path/to/libraries',
  }
);

// The command used to just launch the app with args in debug.
const FakeCommand kLaunchDebugCommand = FakeCommand(command: <String>[
  'HostArtifact.iosDeploy',
  '--id',
  '123',
  '--bundle',
  '/',
  '--no-wifi',
  '--justlaunch',
  '--args',
  '--enable-dart-profiling --disable-service-auth-codes --enable-checked-mode --verify-entry-points',
], environment: <String, String>{
  'PATH': '/usr/bin:null',
  'DYLD_LIBRARY_PATH': '/path/to/libraries',
});

// The command used to actually launch the app and attach the debugger with args in debug.
FakeCommand attachDebuggerCommand({
  IOSink? stdin,
  Completer<void>? completer,
}) {
  return FakeCommand(
    command: const <String>[
      'script',
      '-t',
      '0',
      '/dev/null',
      'HostArtifact.iosDeploy',
      '--id',
      '123',
      '--bundle',
      '/',
      '--debug',
      '--no-wifi',
      '--args',
      '--enable-dart-profiling --disable-service-auth-codes --enable-checked-mode --verify-entry-points',
    ],
    completer: completer,
    environment: const <String, String>{
      'PATH': '/usr/bin:null',
      'DYLD_LIBRARY_PATH': '/path/to/libraries',
    },
    stdout: '(lldb)     run\nsuccess',
    stdin: stdin,
  );
}

void main() {
  testWithoutContext('disposing device disposes the portForwarder and logReader', () async {
    final IOSDevice device = setUpIOSDevice();
    final FakeDevicePortForwarder devicePortForwarder = FakeDevicePortForwarder();
    final FakeDeviceLogReader deviceLogReader = FakeDeviceLogReader();
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: MemoryFileSystem.test().directory('bundle'),
      applicationPackage: MemoryFileSystem.test().directory('bundle'),
    );

    device.portForwarder = devicePortForwarder;
    device.setLogReader(iosApp, deviceLogReader);
    await device.dispose();

    expect(deviceLogReader.disposed, true);
    expect(devicePortForwarder.disposed, true);
  });

  testWithoutContext('IOSDevice.startApp attaches in debug mode via log reading on iOS 13+', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      attachDebuggerCommand(),
    ]);
    final IOSDevice device = setUpIOSDevice(
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: fileSystem.currentDirectory,
      applicationPackage: fileSystem.currentDirectory,
    );
    final FakeDeviceLogReader deviceLogReader = FakeDeviceLogReader();

    device.portForwarder = const NoOpDevicePortForwarder();
    device.setLogReader(iosApp, deviceLogReader);

    // Start writing messages to the log reader.
    Timer.run(() {
      deviceLogReader.addLine('Foo');
      deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
    });

    final LaunchResult launchResult = await device.startApp(iosApp,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, true);
    expect(launchResult.hasObservatory, true);
    expect(await device.stopApp(iosApp), false);
  });

  testWithoutContext('IOSDevice.startApp launches in debug mode via log reading on <iOS 13', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      kLaunchDebugCommand,
    ]);
    final IOSDevice device = setUpIOSDevice(
      sdkVersion: '12.4.4',
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: fileSystem.currentDirectory,
      applicationPackage: fileSystem.currentDirectory,
    );
    final FakeDeviceLogReader deviceLogReader = FakeDeviceLogReader();

    device.portForwarder = const NoOpDevicePortForwarder();
    device.setLogReader(iosApp, deviceLogReader);

    // Start writing messages to the log reader.
    Timer.run(() {
      deviceLogReader.addLine('Foo');
      deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
    });

    final LaunchResult launchResult = await device.startApp(iosApp,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, true);
    expect(launchResult.hasObservatory, true);
    expect(await device.stopApp(iosApp), false);
  });

  testWithoutContext('IOSDevice.startApp prints warning message if discovery takes longer than configured timeout', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final CompleterIOSink stdin = CompleterIOSink();
    final Completer<void> completer = Completer<void>();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      attachDebuggerCommand(stdin: stdin, completer: completer),
    ]);
    final IOSDevice device = setUpIOSDevice(
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: fileSystem.currentDirectory,
      applicationPackage: fileSystem.currentDirectory,
    );
    final FakeDeviceLogReader deviceLogReader = FakeDeviceLogReader();

    device.portForwarder = const NoOpDevicePortForwarder();
    device.setLogReader(iosApp, deviceLogReader);

    // Start writing messages to the log reader.
    deviceLogReader.addLine('Foo');
    deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');

    final LaunchResult launchResult = await device.startApp(iosApp,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      platformArgs: <String, dynamic>{},
      discoveryTimeout: Duration.zero,
    );

    expect(launchResult.started, true);
    expect(launchResult.hasObservatory, true);
    expect(await device.stopApp(iosApp), false);
    expect(logger.errorText, contains('iOS Observatory not discovered after 30 seconds. This is taking much longer than expected...'));
    expect(utf8.decoder.convert(stdin.writes.first), contains('process interrupt'));
    completer.complete();
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('IOSDevice.startApp succeeds in release mode', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      kLaunchReleaseCommand,
    ]);
    final IOSDevice device = setUpIOSDevice(
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: fileSystem.currentDirectory,
      applicationPackage: fileSystem.currentDirectory,
    );

    final LaunchResult launchResult = await device.startApp(iosApp,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, true);
    expect(launchResult.hasObservatory, false);
    expect(await device.stopApp(iosApp), false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('IOSDevice.startApp forwards all supported debugging options', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          'script',
          '-t',
          '0',
          '/dev/null',
          'HostArtifact.iosDeploy',
          '--id',
          '123',
          '--bundle',
          '/',
          '--debug',
          '--no-wifi',
          // The arguments below are determined by what is passed into
          // the debugging options argument to startApp.
          '--args',
          <String>[
            '--enable-dart-profiling',
            '--disable-service-auth-codes',
            '--disable-observatory-publication',
            '--start-paused',
            '--dart-flags="--foo,--null_assertions"',
            '--enable-checked-mode',
            '--verify-entry-points',
            '--enable-software-rendering',
            '--trace-systrace',
            '--skia-deterministic-rendering',
            '--trace-skia',
            '--endless-trace-buffer',
            '--dump-skp-on-shader-compilation',
            '--verbose-logging',
            '--cache-sksl',
            '--purge-persistent-cache',
            '--enable-impeller',
          ].join(' '),
        ],
        environment: const <String, String>{
          'PATH': '/usr/bin:null',
          'DYLD_LIBRARY_PATH': '/path/to/libraries',
        },
        stdout: '(lldb)     run\nsuccess',
      ),
    ]);
    final IOSDevice device = setUpIOSDevice(
      sdkVersion: '13.3',
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final IOSApp iosApp = PrebuiltIOSApp(
      projectBundleId: 'app',
      bundleName: 'Runner',
      uncompressedBundle: fileSystem.currentDirectory,
      applicationPackage: fileSystem.currentDirectory,
    );
    final FakeDeviceLogReader deviceLogReader = FakeDeviceLogReader();

    device.portForwarder = const NoOpDevicePortForwarder();
    device.setLogReader(iosApp, deviceLogReader);

    // Start writing messages to the log reader.
    Timer.run(() {
      deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:1234');
    });

    final LaunchResult launchResult = await device.startApp(iosApp,
      prebuiltApplication: true,
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
        startPaused: true,
        disableServiceAuthCodes: true,
        disablePortPublication: true,
        dartFlags: '--foo',
        enableSoftwareRendering: true,
        skiaDeterministicRendering: true,
        traceSkia: true,
        traceSystrace: true,
        endlessTraceBuffer: true,
        dumpSkpOnShaderCompilation: true,
        cacheSkSL: true,
        purgePersistentCache: true,
        verboseSystemLogs: true,
        nullAssertions: true,
        enableImpeller: true,
      ),
      platformArgs: <String, dynamic>{},
    );

    expect(launchResult.started, true);
    expect(await device.stopApp(iosApp), false);
    expect(processManager, hasNoRemainingExpectations);
  });
}

IOSDevice setUpIOSDevice({
  String sdkVersion = '13.0.1',
  FileSystem? fileSystem,
  Logger? logger,
  ProcessManager? processManager,
  IOSDeploy? iosDeploy,
}) {
  final Artifacts artifacts = Artifacts.test();
  final FakePlatform macPlatform = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{},
  );

  final Cache cache = Cache.test(
    platform: macPlatform,
    artifacts: <ArtifactSet>[
      FakeDyldEnvironmentArtifact(),
    ],
    processManager: FakeProcessManager.any(),
  );
  logger ??= BufferLogger.test();
  return IOSDevice('123',
    name: 'iPhone 1',
    sdkVersion: sdkVersion,
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    platform: macPlatform,
    iProxy: IProxy.test(logger: logger, processManager: processManager ?? FakeProcessManager.any()),
    logger: logger,
    iosDeploy: iosDeploy ??
        IOSDeploy(
          logger: logger,
          platform: macPlatform,
          processManager: processManager ?? FakeProcessManager.any(),
          artifacts: artifacts,
          cache: cache,
        ),
    iMobileDevice: IMobileDevice(
      logger: logger,
      processManager: processManager ?? FakeProcessManager.any(),
      artifacts: artifacts,
      cache: cache,
    ),
    cpuArchitecture: DarwinArch.arm64,
    interfaceType: IOSDeviceConnectionInterface.usb,
  );
}

class FakeDevicePortForwarder extends Fake implements DevicePortForwarder {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
