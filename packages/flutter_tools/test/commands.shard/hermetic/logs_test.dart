// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('logs', () {
    late Platform platform;
    late FakeDeviceManager deviceManager;
    const deviceId = 'abc123';

    setUp(() {
      Cache.disableLocking();
      deviceManager = FakeDeviceManager();
      platform = FakePlatform();
    });

    tearDown(() {
      Cache.enableLocking();
    });

    LogsCommand createLogsCommand({required ProcessSignal sigint, required ProcessSignal sigterm}) {
      return LogsCommand(
        deviceManager: deviceManager,
        sigint: sigint,
        sigterm: sigterm,
        toolContext: FakeToolContext(logger: testLogger, platform: platform),
      );
    }

    testUsingContext('resolves dependencies from the injected ToolContext and parameters', () {
      final fakeLogger = BufferLogger.test();
      final fakePlatform = FakePlatform();
      final fakeDeviceManager = FakeDeviceManager();
      final toolContext = FakeToolContext(logger: fakeLogger, platform: fakePlatform);
      final command = LogsCommand(
        deviceManager: fakeDeviceManager,
        sigint: FakeProcessSignal(),
        sigterm: FakeProcessSignal(),
        toolContext: toolContext,
      );

      expect(command.logger, same(fakeLogger));
      expect(command.platform, same(fakePlatform));
      expect(command.deviceManager, same(fakeDeviceManager));
    });

    testUsingContext('fail with a bad device id', () async {
      final LogsCommand command = createLogsCommand(
        sigterm: FakeProcessSignal(),
        sigint: FakeProcessSignal(),
      );
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['-d', 'abc123', 'logs']),
        throwsA(
          isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1)),
        ),
      );
    });

    testUsingContext('does not try to complete exitCompleter multiple times', () async {
      final fakeDevice = FakeDevice('phone', deviceId);
      deviceManager.attachedDevices.add(fakeDevice);
      final termSignal = FakeProcessSignal();
      final intSignal = FakeProcessSignal();
      final LogsCommand command = createLogsCommand(sigterm: termSignal, sigint: intSignal);
      final Future<void> commandFuture = createTestCommandRunner(
        command,
      ).run(<String>['-d', deviceId, 'logs']);
      intSignal.send(1);
      termSignal.send(1);
      await pumpEventQueue(times: 5);
      await commandFuture;
    }, overrides: <Type, Generator>{Platform: () => platform, DeviceManager: () => deviceManager});
  });
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

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({required this.logger, required this.platform});

  @override
  final Logger logger;

  @override
  final Platform platform;
}
