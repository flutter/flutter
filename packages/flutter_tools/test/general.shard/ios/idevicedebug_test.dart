// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/idevicedebug.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main () {
  BufferLogger logger;

  // This setup is required to inject the context.
  setUp(() {
    logger = BufferLogger.test();
  });

  testWithoutContext('IDeviceDebug.runApp calls idevicedebug with correct arguments and returns 0 on success', () async {
    const String deviceId = '123';
    const String bundleId = 'com.example.app';
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'script',
          '-t',
          '0',
          '/dev/null',
          'idevicedebug',
          '--udid',
          deviceId,
          '--debug',
          '--network',
          'run',
          bundleId,
          '--enable-dart-profiling',
          '--enable-service-port-fallback',
        ], environment: <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libs'},
      )
    ]);
    final IDeviceDebug iDeviceDebug = IDeviceDebug.test(logger: logger, processManager: processManager);
    final IDeviceDebugRun run = await iDeviceDebug.runApp(
      deviceId: deviceId,
      bundleIdentifier: bundleId,
        launchArguments: <String>['--enable-dart-profiling', '--enable-service-port-fallback'],
        interfaceType: IOSDeviceInterface.network,
    );

    expect(await run.status, 0);
    expect(processManager.hasRemainingExpectations, false);
    expect(logger.traceText, contains('idevicedebug exited with code 0'));
  });

  testWithoutContext('IDeviceDebug.runApp returns non-zero exit code when idevicedebug does the same', () async {
    const String deviceId = '123';
    const String bundleId = 'com.example.app';
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'script',
          '-t',
          '0',
          '/dev/null',
          'idevicedebug',
          '--udid',
          deviceId,
          '--debug',
          'run',
          bundleId,
          '--enable-dart-profiling',
          '--enable-service-port-fallback',
        ], environment: <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libs'},
        exitCode: 1
      )
    ]);
    final IDeviceDebug iDeviceDebug = IDeviceDebug.test(logger: logger, processManager: processManager);
    final IDeviceDebugRun run = await iDeviceDebug.runApp(
      deviceId: deviceId,
      bundleIdentifier: bundleId,
      launchArguments: <String>['--enable-dart-profiling', '--enable-service-port-fallback'],
      interfaceType: IOSDeviceInterface.usb,
    );

    expect(await run.status, 1);
    expect(processManager.hasRemainingExpectations, false);
    expect(logger.traceText, contains('idevicedebug exited with code 1'));
  });

  testWithoutContext('IDeviceDebug.runApp reports when the process has launched, before the process exits', () async {
    const String deviceId = '123';
    const String bundleId = 'com.example.app';

    // Don't let the process complete until after the app has "launched".
    final Completer<void> completer = Completer<void>();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'script',
          '-t',
          '0',
          '/dev/null',
          'idevicedebug',
          '--udid',
          deviceId,
          '--debug',
          'run',
          bundleId,
        ],
        stdout: 'Entering run loop',
        completer: completer,
      )
    ]);
    final IDeviceDebug iDeviceDebug = IDeviceDebug.test(logger: logger, processManager: processManager);
    final IDeviceDebugRun run = await iDeviceDebug.runApp(
      deviceId: deviceId,
      bundleIdentifier: bundleId,
      launchArguments: <String>[],
      interfaceType: IOSDeviceInterface.usb,
    );

    expect(await run.status, 0);
    expect(logger.traceText, isNot(contains('idevicedebug exited')));
    expect(processManager.hasRemainingExpectations, false);
    completer.complete();
  });
}
