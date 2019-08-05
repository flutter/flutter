// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('cold attach', () {
    MockResidentCompiler residentCompiler;
    BufferLogger mockLogger;

    setUp(() {
      mockLogger = BufferLogger();
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
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws')
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
          exception: const HttpException(', uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws')
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
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    @required Device device,
    @required this.exception,
    @required ResidentCompiler generator
  })  : assert(exception != null),
        super(device, buildMode: BuildMode.debug, generator: generator, trackWidgetCreation: false);

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
  }) async {
    throw exception;
  }
}
