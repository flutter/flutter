// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('cold attach', () {
    MockResidentCompiler residentCompiler;
    BufferLogger mockLogger;

    setUp(() {
      mockLogger = BufferLogger(
        terminal: AnsiTerminal(
          stdio: null,
          platform: const LocalPlatform(),
        ),
        outputPreferences: OutputPreferences.test(),
    );
      residentCompiler = MockResidentCompiler();
    });

    testUsingContext('Prints message when HttpException is thrown - 1', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation _) async => 'Android 10');

      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: mockDevice,
          generator: residentCompiler,
          exception: const HttpException('Connection closed before full header was received, '
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await ColdRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).attach();
      expect(exitCode, 2);
      expect(mockLogger.statusText, contains('If you are using an emulator running Android Q Beta, '
          'consider using an emulator running API level 29 or lower.'));
      expect(mockLogger.statusText, contains('Learn more about the status of this issue on '
          'https://issuetracker.google.com/issues/132325318'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
    });

    testUsingContext('Prints message when HttpException is thrown - 2', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation _) async => 'Android 10');

      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: mockDevice,
          generator: residentCompiler,
          exception: const HttpException(', uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await ColdRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).attach();
      expect(exitCode, 2);
      expect(mockLogger.statusText, contains('If you are using an emulator running Android Q Beta, '
          'consider using an emulator running API level 29 or lower.'));
      expect(mockLogger.statusText, contains('Learn more about the status of this issue on '
          'https://issuetracker.google.com/issues/132325318'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
    });
  });

  group('cleanupAtFinish()', () {
    MockFlutterDevice mockFlutterDeviceFactory(Device device) {
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(mockFlutterDevice.device).thenReturn(device);
      return mockFlutterDevice;
    }

    testUsingContext('disposes each device', () async {
      final MockDevice mockDevice1 = MockDevice();
      final MockDevice mockDevice2 = MockDevice();
      final MockFlutterDevice mockFlutterDevice1 = mockFlutterDeviceFactory(mockDevice1);
      final MockFlutterDevice mockFlutterDevice2 = mockFlutterDeviceFactory(mockDevice2);

      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice1, mockFlutterDevice2];

      await ColdRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).cleanupAtFinish();

      verify(mockDevice1.dispose());
      verify(mockFlutterDevice1.stopEchoingDeviceLog());
      verify(mockDevice2.dispose());
      verify(mockFlutterDevice2.stopEchoingDeviceLog());
    });
  });

  group('cold run', () {
    testUsingContext('returns 1 if not prebuilt mode & mainPath does not exist', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final int result = await ColdRunner(devices).run();

      expect(result, 1);
      expect(testLogger.errorText, matches(r'Tried to run .*, but that file does not exist\.'));
      expect(testLogger.errorText, matches(r'Consider using the -t option to specify the Dart file to start\.'));
    });

    testUsingContext('calls runCold on attached device', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route')
      )).thenAnswer((Invocation invocation) => Future<int>.value(1));
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final MockFile applicationBinary = MockFile();
      final int result = await ColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).run();

      expect(result, 1);
      verify(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route'),
      ));
    });
  });
}

class MockFile extends Mock implements File {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    @required Device device,
    @required this.exception,
    @required ResidentCompiler generator,
  })  : assert(exception != null),
        super(device, buildMode: BuildMode.debug, generator: generator, trackWidgetCreation: false);

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
  }) async {
    throw exception;
  }
}
