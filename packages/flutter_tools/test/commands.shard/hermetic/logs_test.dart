// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/logs.dart';
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

    testUsingContext('fail with a bad device id', () async {
      final command = LogsCommand(sigterm: FakeProcessSignal(), sigint: FakeProcessSignal());
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['-d', 'abc123', 'logs']),
        throwsA(
          isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1)),
        ),
      );
    });

    testUsingContext(
      'does not try to complete exitCompleter multiple times',
      () async {
        final fakeDevice = FakeDevice('phone', deviceId);
        deviceManager.attachedDevices.add(fakeDevice);
        final termSignal = FakeProcessSignal();
        final intSignal = FakeProcessSignal();
        final command = LogsCommand(sigterm: termSignal, sigint: intSignal);
        final Future<void> commandFuture = createTestCommandRunner(
          command,
        ).run(<String>['-d', deviceId, 'logs']);
        intSignal.send(1);
        termSignal.send(1);
        await pumpEventQueue(times: 5);
        await commandFuture;
      },
      overrides: <Type, Generator>{Platform: () => platform, DeviceManager: () => deviceManager},
    );
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
