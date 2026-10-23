// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/capture.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

FakeToolContext _testToolContext({FileSystem? fs, Logger? logger, Signals? signals}) =>
    FakeToolContext(
      fs: fs ?? MemoryFileSystem.test(),
      logger: logger ?? BufferLogger.test(),
      platform: FakePlatform(),
      signals: signals,
    );

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('capture screenshot', () {
    testUsingContext(
      'takes a screenshot on connected device',
      () async {
        final logger = BufferLogger.test();
        await createTestCommandRunner(CaptureCommand(toolContext: _testToolContext(logger: logger)))
            .run(<String>['capture', 'screenshot']);

        expect(logger.statusText, contains('Screenshot written to'));
      },
      overrides: <Type, Generator>{
        DeviceManager: () =>
            _TestDeviceManager(logger: BufferLogger.test())
              ..devices = <Device>[_CaptureDevice(id: '123', name: 'TestDevice')],
      },
    );

    testUsingContext(
      'rejects unsupported device',
      () async {
        await expectLater(
          () =>
              createTestCommandRunner(CaptureCommand(toolContext: _testToolContext()))
                  .run(<String>['capture', 'screenshot']),
          throwsToolExit(message: 'Screenshot not supported'),
        );
      },
      overrides: <Type, Generator>{
        DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
          ..devices = <Device>[
            _CaptureDevice(id: '123', name: 'NoScreenshot', supportsScreenshot: false),
          ],
      },
    );
  });

  group('capture recording', () {
    late _TestDeviceManager testDeviceManager;

    setUp(() {
      testDeviceManager = _TestDeviceManager(logger: BufferLogger.test());
    });

    for (final invalidDuration in <String>['abc', '0', '-5']) {
      testWithoutContext(
        'rejects invalid duration "$invalidDuration" without device lookup',
        () async {
          await expectLater(
            () =>
                createTestCommandRunner(CaptureCommand(toolContext: _testToolContext()))
                    .run(<String>['capture', 'recording', '--duration', invalidDuration]),
            throwsToolExit(
              message: 'Invalid duration: "$invalidDuration". Must be a positive integer.',
            ),
          );
        },
      );
    }

    testUsingContext('requires a connected device', () async {
      await expectLater(
        () =>
            createTestCommandRunner(CaptureCommand(toolContext: _testToolContext()))
                .run(<String>['capture', 'recording']),
        throwsToolExit(message: 'No connected device found'),
      );
    });

    testUsingContext('rejects device that does not support recording', () async {
      testDeviceManager.devices = <Device>[_CaptureDevice(id: '123', name: 'NoRecord')];
      await expectLater(
        () =>
            createTestCommandRunner(CaptureCommand(toolContext: _testToolContext()))
                .run(<String>['capture', 'recording']),
        throwsToolExit(message: 'Screen recording not supported'),
      );
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('records video with default options', () async {
      final logger = BufferLogger.test();
      final device = _CaptureDevice(id: '123', name: 'TestDevice', supportsScreenRecording: true);
      testDeviceManager.devices = <Device>[device];

      await createTestCommandRunner(CaptureCommand(toolContext: _testToolContext(logger: logger)))
          .run(<String>['capture', 'recording']);

      expect(logger.statusText, contains('Recording TestDevice... Press Ctrl-C to stop.'));
      expect(logger.statusText, contains('Recording written to'));
      expect(device.lastRecordingDuration, isNull);
      expect(device.lastRecordingOutputFile, isNotNull);
      expect(device.lastRecordingOutputFile!.basename, 'flutter_01.mp4');
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('passes --duration and --out to device', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final device = _CaptureDevice(id: '123', name: 'TestDevice', supportsScreenRecording: true);
      testDeviceManager.devices = <Device>[device];

      await createTestCommandRunner(
        CaptureCommand(
          toolContext: _testToolContext(fs: fs, logger: logger),
        ),
      ).run(<String>['capture', 'recording', '--duration', '5', '--out', 'custom.mp4']);

      expect(logger.statusText, contains('Recording TestDevice for 5 seconds...'));
      expect(logger.statusText, contains('Recording written to custom.mp4'));
      expect(device.lastRecordingDuration, const Duration(seconds: 5));
      expect(device.lastRecordingOutputFile!.path, 'custom.mp4');
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('-d selects target device when multiple devices connected', () async {
      final logger = BufferLogger.test();
      final device1 = _CaptureDevice(id: '123', name: 'Device 1', supportsScreenRecording: true);
      final device2 = _CaptureDevice(id: '456', name: 'Device 2', supportsScreenRecording: true);
      testDeviceManager.devices = <Device>[device1, device2];

      await createTestCommandRunner(CaptureCommand(toolContext: _testToolContext(logger: logger)))
          .run(<String>['capture', 'recording', '-d', '456']);

      expect(logger.statusText, contains('Recording Device 2... Press Ctrl-C to stop.'));
      expect(device1.lastRecordingOutputFile, isNull);
      expect(device2.lastRecordingOutputFile, isNotNull);
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('throws ToolExit when recording file was not created', () async {
      final device = _CaptureDevice(
        id: '123',
        name: 'TestDevice',
        supportsScreenRecording: true,
        createOutputFileOnRecord: false,
      );
      testDeviceManager.devices = <Device>[device];

      await expectLater(
        () =>
            createTestCommandRunner(CaptureCommand(toolContext: _testToolContext()))
                .run(<String>['capture', 'recording', '--out', 'nonexistent.mp4']),
        throwsToolExit(message: 'Recording file was not created, ensure path is valid'),
      );
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('stops recording on SIGINT signal using signals handler', () async {
      final fakeSignals = _FakeSignals();
      final logger = BufferLogger.test();
      final device = _CaptureDevice(
        id: '123',
        name: 'TestDevice',
        supportsScreenRecording: true,
        completeImmediately: false,
      );
      testDeviceManager.devices = <Device>[device];

      final CommandRunner<void> runner = createTestCommandRunner(
        CaptureCommand(
          toolContext: _testToolContext(logger: logger, signals: fakeSignals),
        ),
      );

      final Future<void> commandFuture = runner.run(<String>['capture', 'recording']);
      await Future<void>.delayed(Duration.zero);

      expect(fakeSignals.handlers[ProcessSignal.sigint], hasLength(2));
      expect(fakeSignals.handlers[ProcessSignal.sigterm], hasLength(2));

      await fakeSignals.sendSignal(ProcessSignal.sigint);
      expect(logger.statusText, contains('Recording written to'));
      await commandFuture;

      expect(device.currentRecording!.stopped, isTrue);
      expect(fakeSignals.handlers[ProcessSignal.sigint], hasLength(1));
      expect(fakeSignals.handlers[ProcessSignal.sigterm], hasLength(1));
      expect(logger.statusText, contains('Recording written to'));
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('throws ToolExit when recording file is empty (0 bytes)', () async {
      final fs = MemoryFileSystem.test();
      final device = _CaptureDevice(
        id: '123',
        name: 'TestDevice',
        supportsScreenRecording: true,
        createOutputFileOnRecord: false,
      );
      testDeviceManager.devices = <Device>[device];

      final File emptyFile = fs.file('empty.mp4')..createSync();
      expect(emptyFile.lengthSync(), 0);

      await expectLater(
        () =>
            createTestCommandRunner(CaptureCommand(toolContext: _testToolContext(fs: fs)))
                .run(<String>['capture', 'recording', '--out', emptyFile.path]),
        throwsToolExit(message: 'Recording file was not created, ensure path is valid'),
      );
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('handles double SIGINT without re-entrancy issues', () async {
      final fakeSignals = _FakeSignals();
      final logger = BufferLogger.test();
      final device = _CaptureDevice(
        id: '123',
        name: 'TestDevice',
        supportsScreenRecording: true,
        completeImmediately: false,
      );
      testDeviceManager.devices = <Device>[device];

      final CommandRunner<void> runner = createTestCommandRunner(
        CaptureCommand(
          toolContext: _testToolContext(logger: logger, signals: fakeSignals),
        ),
      );

      final Future<void> commandFuture = runner.run(<String>['capture', 'recording']);
      await Future<void>.delayed(Duration.zero);

      await fakeSignals.sendSignal(ProcessSignal.sigint);
      await fakeSignals.sendSignal(ProcessSignal.sigint);
      await commandFuture;

      expect(device.currentRecording!.stopped, isTrue);
      expect(logger.statusText, contains('Recording written to'));
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});
  });
}

class _CaptureDevice extends Fake implements Device {
  _CaptureDevice({
    required this.id,
    required this.name,
    this.supportsScreenshot = true,
    this.supportsScreenRecording = false,
    this.createOutputFileOnRecord = true,
    this.completeImmediately = true,
    Future<TargetPlatform>? targetPlatform,
  }) : targetPlatform = targetPlatform ?? Future<TargetPlatform>.value(TargetPlatform.android);

  @override
  final String name;

  @override
  String get displayName => name;

  @override
  final String id;

  @override
  final bool supportsScreenshot;

  @override
  final bool supportsScreenRecording;

  final bool createOutputFileOnRecord;
  final bool completeImmediately;

  File? lastScreenshotOutputFile;
  File? lastRecordingOutputFile;
  Duration? lastRecordingDuration;
  _FakeScreenRecording? currentRecording;

  @override
  bool get isConnected => true;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool ephemeral = true;

  @override
  DeviceConnectionInterface connectionInterface = DeviceConnectionInterface.attached;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    lastScreenshotOutputFile = outputFile;
    outputFile.writeAsBytesSync(<int>[1, 2, 3, 4]);
  }

  @override
  Future<ScreenRecording> startScreenRecording(File outputFile, {Duration? duration}) async {
    lastRecordingOutputFile = outputFile;
    lastRecordingDuration = duration;
    if (createOutputFileOnRecord) {
      outputFile.writeAsBytesSync(<int>[1, 2, 3, 4]);
    }
    final recording = _FakeScreenRecording(autoComplete: completeImmediately);
    currentRecording = recording;
    return recording;
  }

  @override
  Future<String> get targetPlatformDisplayName async => 'android';

  @override
  Future<String> get sdkNameAndVersion async => '1.2.3';

  @override
  final Future<TargetPlatform> targetPlatform;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Category get category => Category.mobile;
}

class _FakeScreenRecording implements ScreenRecording {
  _FakeScreenRecording({bool autoComplete = true}) {
    if (autoComplete) {
      _doneCompleter.complete();
    }
  }

  final Completer<void> _doneCompleter = Completer<void>();
  bool stopped = false;

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  Future<void> stop() async {
    stopped = true;
    if (!_doneCompleter.isCompleted) {
      unawaited(
        Future<void>.delayed(Duration.zero).then((_) {
          if (!_doneCompleter.isCompleted) {
            _doneCompleter.complete();
          }
        }),
      );
    }
    await done;
  }
}

class _TestDeviceManager extends DeviceManager {
  _TestDeviceManager({required super.logger});
  List<Device> devices = <Device>[];

  @override
  List<DeviceDiscovery> get deviceDiscoverers {
    final discoverer = FakePollingDeviceDiscovery();
    devices.forEach(discoverer.addDevice);
    return <DeviceDiscovery>[discoverer];
  }
}

class _FakeSignals implements Signals {
  final Map<ProcessSignal, List<SignalHandler>> handlers = <ProcessSignal, List<SignalHandler>>{};

  @override
  Object addHandler(ProcessSignal signal, SignalHandler handler) {
    handlers.putIfAbsent(signal, () => <SignalHandler>[]).add(handler);
    return handler;
  }

  @override
  Future<bool> removeHandler(ProcessSignal signal, Object token) async {
    return handlers[signal]?.remove(token) ?? false;
  }

  Future<void> sendSignal(ProcessSignal signal) async {
    final List<SignalHandler>? list = handlers[signal];
    if (list != null) {
      for (final SignalHandler handler in list.toList()) {
        await handler(signal);
      }
    }
  }

  @override
  Stream<Object> get errors => const Stream<Object>.empty();
}
