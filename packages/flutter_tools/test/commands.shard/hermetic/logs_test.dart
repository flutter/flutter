// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('logs', () {
    late BufferLogger logger;
    late Platform platform;
    late FakeDeviceManager deviceManager;
    late FakeToolContext toolContext;
    const deviceId = 'abc123';

    setUp(() {
      Cache.disableLocking();
      logger = BufferLogger.test();
      deviceManager = FakeDeviceManager();
      platform = FakePlatform();
      toolContext = FakeToolContext(logger: logger, platform: platform);
    });

    tearDown(() {
      Cache.enableLocking();
    });

    testUsingContext('fail with a bad device id', () async {
      final command = LogsCommand(
        toolContext: toolContext,
        sigterm: FakeProcessSignal(),
        sigint: FakeProcessSignal(),
      );
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['-d', 'abc123', 'logs']),
        throwsA(
          isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1)),
        ),
      );
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});

    testUsingContext('does not try to complete exitCompleter multiple times', () async {
      final fakeDevice = FakeDevice('phone', deviceId);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final command = LogsCommand(toolContext: toolContext, sigterm: termSignal, sigint: intSignal);
      final Future<void> commandFuture = createTestCommandRunner(
        command,
      ).run(<String>['-d', deviceId, 'logs']);
      intSignal.send(1);
      termSignal.send(1);
      await pumpEventQueue(times: 5);
      await commandFuture;
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});

    testUsingContext('clears logs when --clear flag is specified', () async {
      final fakeDevice = _LoggingFakeDevice('phone', deviceId);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final command = LogsCommand(toolContext: toolContext, sigterm: termSignal, sigint: intSignal);
      final Future<void> commandFuture = createTestCommandRunner(
        command,
      ).run(<String>['-d', deviceId, 'logs', '--clear']);
      termSignal.send(1);
      await pumpEventQueue(times: 5);
      await commandFuture;

      expect(fakeDevice.clearLogsCalled, isTrue);
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});

    testUsingContext('streams log lines to logger', () async {
      final logReader = FakeDeviceLogReader();
      final fakeDevice = _LoggingFakeDevice('phone', deviceId, deviceLogReader: logReader);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final command = LogsCommand(toolContext: toolContext, sigterm: termSignal, sigint: intSignal);
      final Future<void> commandFuture = createTestCommandRunner(
        command,
      ).run(<String>['-d', deviceId, 'logs']);
      await pumpEventQueue(times: 5);

      logReader.addLine('App started successfully');
      await pumpEventQueue(times: 5);

      expect(logger.statusText, contains('App started successfully'));

      intSignal.send(1);
      await pumpEventQueue(times: 5);
      await commandFuture;
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});

    testUsingContext('handles applicationPackageFactory when passed', () async {
      final logReader = FakeDeviceLogReader();
      final fakeDevice = _LoggingFakeDevice('phone', deviceId, deviceLogReader: logReader);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final fakePackageFactory = FakeApplicationPackageFactory();
      final command = LogsCommand(
        toolContext: toolContext,
        applicationPackageFactory: fakePackageFactory,
        sigterm: termSignal,
        sigint: intSignal,
      );
      final Future<void> commandFuture = createTestCommandRunner(
        command,
      ).run(<String>['-d', deviceId, 'logs']);
      await pumpEventQueue(times: 5);

      expect(fakePackageFactory.getPackageForPlatformCalled, isTrue);

      intSignal.send(1);
      await pumpEventQueue(times: 5);
      await commandFuture;
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});

    testUsingContext('throws ToolExit on log reader error', () async {
      final logReader = _ErrorDeviceLogReader();
      final fakeDevice = _LoggingFakeDevice('phone', deviceId, deviceLogReader: logReader);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final command = LogsCommand(toolContext: toolContext, sigterm: termSignal, sigint: intSignal);
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['-d', deviceId, 'logs']),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit error) => error.message,
            'message',
            contains('Error listening to'),
          ),
        ),
      );
    }, overrides: <Type, Generator>{DeviceManager: () => deviceManager, Platform: () => platform});
  });
}

class _LoggingFakeDevice extends FakeDevice {
  _LoggingFakeDevice(super.name, super.id, {super.deviceLogReader});

  bool clearLogsCalled = false;

  @override
  void clearLogs() {
    clearLogsCalled = true;
  }
}

class _ErrorDeviceLogReader extends FakeDeviceLogReader {
  final _errorController = StreamController<String>.broadcast();

  @override
  Stream<String> get logLines {
    scheduleMicrotask(() {
      _errorController.addError(1);
    });
    return _errorController.stream;
  }

  @override
  Future<void> dispose() async {
    await _errorController.close();
    await super.dispose();
  }
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  bool getPackageForPlatformCalled = false;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    getPackageForPlatformCalled = true;
    return null;
  }
}

class FakeProcessSignal extends Fake implements ProcessSignal {
  late final _controller = StreamController<ProcessSignal>();

  @override
  Stream<ProcessSignal> watch() => _controller.stream;

  @override
  bool send(int pid) {
    _controller.add(this);
    return true;
  }
}
