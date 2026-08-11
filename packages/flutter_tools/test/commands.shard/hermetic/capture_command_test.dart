// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/capture.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('capture image', () {
    testUsingContext('requires a connected device', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'image']),
        throwsToolExit(message: 'No connected device found'),
      );
    });

    testUsingContext('rejects device that does not support screenshot', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'image']),
        throwsToolExit(message: 'Screenshot not supported'),
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[
          _CaptureDevice(id: '123', name: 'NoScreenshot', supportsScreenshot: false),
        ],
    });

    testUsingContext('takes a screenshot with a single device', () async {
      await createTestCommandRunner(
        CaptureCommand(fs: MemoryFileSystem.test()),
      ).run(<String>['capture', 'image']);

      expect(testLogger.statusText, contains('Screenshot written to'));
    }, overrides: <Type, Generator>{
      DeviceManager: () => _TestDeviceManager(logger: BufferLogger.test())
        ..devices = <Device>[_CaptureDevice(id: '123', name: 'TestDevice')],
    });
  });

  group('capture video', () {
    testUsingContext('requires a connected device', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'video']),
        throwsToolExit(message: 'No connected device found'),
      );
    });

    testUsingContext('rejects device that does not support recording', () async {
      await expectLater(
        () => createTestCommandRunner(
          CaptureCommand(fs: MemoryFileSystem.test()),
        ).run(<String>['capture', 'video']),
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
      ).run(<String>['capture', 'video']);

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
      ).run(<String>['capture', 'video', '-d', '5']);

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
        ).run(<String>['capture', 'video', '-d', 'abc']),
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
}

class _CaptureDevice extends Fake implements Device {
  _CaptureDevice({
    required this.id,
    required this.name,
    this.supportsScreenshot = true,
    this.supportsScreenRecording = false,
  });

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
