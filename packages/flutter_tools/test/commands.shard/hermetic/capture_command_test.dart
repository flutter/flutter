// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/capture.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('flutter screenshot (backward compat)', () {
    testUsingContext('requires device for device type', () async {
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );
    });

    testUsingContext('rejects VM Service URI for device type', () async {
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot', '--vm-service-url=http://localhost:8181']),
        throwsToolExit(message: 'VM Service URI cannot be provided for screenshot type device'),
      );
    });

    testUsingContext('requires VM Service URI for skia type', () async {
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot', '--type=skia']),
        throwsToolExit(message: 'VM Service URI must be specified for screenshot type skia'),
      );
    });

    testUsingContext('skia type does not require a device', () async {
      openChannelForTesting =
          (String url, {CompressionOptions? compression, Logger? logger}) async {
            expect(url, 'ws://localhost:8181/ws');
            throw Exception('dummy');
          };

      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot', '--type=skia', '--vm-service-url=http://localhost:8181']),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'message',
            contains('dummy'),
          ),
        ),
      );
    });

    testUsingContext('takes a screenshot', () async {
      await createTestCommandRunner(
        ScreenshotCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['screenshot']);

      expect(testLogger.statusText, contains('Screenshot written to'));
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[_CaptureDevice(id: '123', name: 'TestDevice')],
    });

    testUsingContext('rejects unsupported device', () async {
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot']),
        throwsToolExit(message: 'Screenshot not supported'),
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(id: '123', name: 'NoScreenshot', supportsScreenshot: false),
        ],
    });

    testUsingContext('should not throw for single device unsupported for project', () async {
      await createTestCommandRunner(
        ScreenshotCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['screenshot']);
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(id: '123', name: 'Device 1', isSupportedForProject: false),
        ],
    });

    testUsingContext('should tool exit for multiple devices unsupported for project', () async {
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );

      expect(
        testLogger.statusText,
        contains('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

Device 1 (mobile) • 123 • android • 1.2.3
Device 2 (mobile) • 456 • android • 1.2.3
'''),
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(id: '123', name: 'Device 1', isSupportedForProject: false),
          _CaptureDevice(id: '456', name: 'Device 2', isSupportedForProject: false),
        ],
    });
  });

  group('capture screenshot', () {
    testUsingContext('requires a connected device', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );
    });

    testUsingContext('takes a screenshot', () async {
      await createTestCommandRunner(
        CaptureCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['capture', 'screenshot']);

      expect(testLogger.statusText, contains('Screenshot written to'));
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[_CaptureDevice(id: '123', name: 'TestDevice')],
    });

    testUsingContext('supports --type and --vm-service-url', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'screenshot', '--type=skia']),
        throwsToolExit(message: 'VM Service URI must be specified for screenshot type skia'),
      );
    });
  });

  group('capture recording', () {
    testUsingContext('requires a connected device', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'recording']),
        throwsToolExit(message: 'No connected device found'),
      );
    });

    testUsingContext('rejects device that does not support recording', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'recording']),
        throwsToolExit(message: 'Screen recording not supported'),
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(
            id: '123',
            name: 'NoRecord',
            supportsScreenRecording: false,
          ),
        ],
    });

    testUsingContext('records video with a single device', () async {
      await createTestCommandRunner(
        CaptureCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['capture', 'recording']);

      expect(testLogger.statusText, contains('Recording written to'));
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(
            id: '123',
            name: 'TestDevice',
            supportsScreenRecording: true,
          ),
        ],
    });

    testUsingContext('shows duration message when duration specified', () async {
      await createTestCommandRunner(
        CaptureCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['capture', 'recording', '-d', '5']);

      expect(testLogger.statusText, contains('5 seconds'));
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(
            id: '123',
            name: 'TestDevice',
            supportsScreenRecording: true,
          ),
        ],
    });

    testUsingContext('rejects invalid duration', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'recording', '-d', 'abc']),
        throwsToolExit(message: 'Invalid duration'),
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(
            id: '123',
            name: 'TestDevice',
            supportsScreenRecording: true,
          ),
        ],
    });
  });

  group('Screenshot file validation', () {
    testWithoutContext('successful in pwd', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();
      fs.directory('sub_dir').createSync();
      fs.file('sub_dir/test.png').createSync();

      expect(() => ScreenshotMixin.checkOutput(fs.file('test.png'), fs), returnsNormally);
      expect(() => ScreenshotMixin.checkOutput(fs.file('sub_dir/test.png'), fs), returnsNormally);
    });

    testWithoutContext('failed in pwd', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('sub_dir').createSync();

      expect(
        () => ScreenshotMixin.checkOutput(fs.file('test.png'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotMixin.checkOutput(fs.file('../'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotMixin.checkOutput(fs.file('.'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotMixin.checkOutput(fs.file('/'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotMixin.checkOutput(fs.file('sub_dir/test.png'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
    });
  });

  group('Screenshot output validation', () {
    testWithoutContext('successful', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();

      expect(
        () => ScreenshotMixin.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
        returnsNormally,
      );
    });

    testWithoutContext('failed', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').writeAsStringSync('{"jsonrpc":"2.0", "error":"something"}');

      expect(
        () => ScreenshotMixin.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
        throwsToolExit(
          message: 'It appears the output file contains an error message, not valid output.',
        ),
      );
    });
  });
}

class _CaptureDevice extends Fake implements Device {
  _CaptureDevice({
    required this.id,
    required this.name,
    this.supportsScreenshot = true,
    this.supportsScreenRecording = false,
    bool isSupportedForProject = true,
  }) : _isSupportedForProject = isSupportedForProject;

  @override
  final String name;

  @override
  String get displayName => name;

  @override
  final String id;

  @override
  bool supportsScreenshot;

  @override
  bool supportsScreenRecording;

  final bool _isSupportedForProject;

  @override
  bool get isConnected => true;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool ephemeral = true;

  @override
  DeviceConnectionInterface connectionInterface = DeviceConnectionInterface.attached;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => _isSupportedForProject;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    outputFile.writeAsBytesSync(<int>[1, 2, 3, 4]);
  }

  @override
  Future<void> startScreenRecording(File outputFile, {Duration? duration}) async {
    outputFile.writeAsBytesSync(<int>[1, 2, 3, 4]);
  }

  @override
  Future<String> get targetPlatformDisplayName async => 'android';

  @override
  Future<String> get sdkNameAndVersion async => '1.2.3';

  @override
  Future<TargetPlatform> get targetPlatform => Future<TargetPlatform>.value(TargetPlatform.android);

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Category get category => Category.mobile;
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
