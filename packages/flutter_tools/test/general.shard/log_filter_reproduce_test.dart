// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';

import '../src/context.dart';
import '../src/fake_devices.dart';
import '../src/test_flutter_command_runner.dart';
import 'resident_runner_helpers.dart' hide FakeDevice;

void main() {
  Cache.disableLocking();

  group('logs --log-filter option', () {
    late Platform platform;
    late FakeDeviceManager deviceManager;
    const deviceId = 'abc123';

    setUp(() {
      deviceManager = FakeDeviceManager();
      platform = FakePlatform();
    });

    testUsingContext(
      'logs command filters output based on --log-filter option',
      () async {
        final logReader = FakeDeviceLogReader();
        final fakeDevice = FakeDevice('phone', deviceId, deviceLogReader: logReader);
        deviceManager.attachedDevices.add(fakeDevice);
        final termSignal = FakeProcessSignal();
        final intSignal = FakeProcessSignal();
        final command = LogsCommand(sigterm: termSignal, sigint: intSignal);

        // Verify that command runner parses the options.
        final Future<void> commandFuture = createTestCommandRunner(
          command,
        ).run(<String>['-d', deviceId, 'logs', '--log-filter', 'hello']);

        var commandFinished = false;
        unawaited(commandFuture.whenComplete(() => commandFinished = true));

        final bufferLogger = globals.logger as BufferLogger;
        while (!commandFinished && !bufferLogger.statusText.contains('Showing')) {
          await pumpEventQueue();
        }

        logReader.addLine('hello world');
        logReader.addLine('foo bar');
        logReader.addLine('say hello again');

        await pumpEventQueue(times: 5);

        // Terminate the command
        intSignal.send(1);
        await commandFuture;

        // Verify status output only contains lines matching filter
        expect(bufferLogger.statusText, contains('hello world'));
        expect(bufferLogger.statusText, contains('say hello again'));
        expect(bufferLogger.statusText, isNot(contains('foo bar')));
      },
      overrides: <Type, Generator>{
        Platform: () => platform,
        DeviceManager: () => deviceManager,
        Logger: () => BufferLogger.test(),
      },
    );

    testUsingContext('logs command throws ToolExit on invalid RegExp pattern', () async {
      final command = LogsCommand(sigterm: FakeProcessSignal(), sigint: FakeProcessSignal());
      expect(
        () => createTestCommandRunner(
          command,
        ).run(<String>['-d', deviceId, 'logs', '--log-filter', '[invalid']),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Invalid RegExp pattern'),
          ),
        ),
      );
    }, overrides: <Type, Generator>{Platform: () => platform, DeviceManager: () => deviceManager});
  });

  group('run --log-filter option', () {
    late FakeDeviceManager testDeviceManager;
    late MemoryFileSystem fileSystem;

    setUp(() {
      testDeviceManager = FakeDeviceManager();
      fileSystem = MemoryFileSystem.test();
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"configVersion": 2, "packages": []}');
      fileSystem.file('lib/main.dart').createSync(recursive: true);
    });

    testUsingContext(
      'logFilter is populated in DebuggingOptions when --log-filter is provided',
      () async {
        final command = RunCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);
        try {
          await runner.run(<String>['run', '--no-pub', '--log-filter=my-filter']);
        } on ToolExit {
          // Expected to fail because we don't have a device or real project.
        }

        final DebuggingOptions options = await command.createDebuggingOptions();
        expect(options.logFilter, 'my-filter');
      },
      overrides: <Type, Generator>{
        DeviceManager: () => testDeviceManager,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      },
    );

    testUsingContext(
      'run command throws ToolExit on invalid RegExp pattern',
      () async {
        final command = RunCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);
        expect(
          () => runner.run(<String>['run', '--no-pub', '--log-filter=[invalid']),
          throwsA(
            isA<ToolExit>().having(
              (ToolExit e) => e.message,
              'message',
              contains('Invalid RegExp pattern'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        DeviceManager: () => testDeviceManager,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      },
    );
  });

  group('ResidentRunner log filtering', () {
    testUsingContext(
      'startEchoingDeviceLog filters logs based on logFilter in DebuggingOptions',
      () async {
        final logReader = FakeDeviceLogReader();
        final fakeDevice = FakeDevice('phone', 'abc123', deviceLogReader: logReader);

        final flutterDevice = FlutterDevice(
          fakeDevice,
          buildInfo: BuildInfo.debug,
          targetPlatform: TargetPlatform.android,
          generator: FakeResidentCompiler(),
          developmentShaderCompiler: const FakeShaderCompiler(),
        );

        await flutterDevice.startEchoingDeviceLog(
          DebuggingOptions.enabled(BuildInfo.debug, logFilter: 'match-me'),
        );

        logReader.addLine('match-me: yes');
        logReader.addLine('no match');
        logReader.addLine('match-me: also yes');

        await pumpEventQueue(times: 5);

        final bufferLogger = globals.logger as BufferLogger;
        expect(bufferLogger.statusText, contains('match-me: yes'));
        expect(bufferLogger.statusText, contains('match-me: also yes'));
        expect(bufferLogger.statusText, isNot(contains('no match')));

        await flutterDevice.stopEchoingDeviceLog();
      },
      overrides: <Type, Generator>{Logger: () => BufferLogger.test()},
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

class FakeDeviceLogReader extends DeviceLogReader {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get logLines => _controller.stream;

  @override
  String get name => 'FakeDeviceLogReader';

  void addLine(String line) {
    _controller.add(line);
  }

  @override
  void dispose() {}

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}
}
