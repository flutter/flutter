// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/screenshot.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Validate screenshot options', () {
    testWithoutContext('rasterizer and skia screenshots do not require a device', () async {
      final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
      final command = ScreenshotCommand(
        toolContext: toolContext,
        vmServiceConnector:
            (
              Uri uri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              CompressionOptions compression = CompressionOptions.compressionDefault,
              Device? device,
              required Logger logger,
            }) async {
              expect(uri.toString(), 'http://localhost:8181');
              throw Exception('dummy');
            },
      );

      await expectLater(
        () => createTestCommandRunner(
          command,
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

    testWithoutContext('rasterizer and skia screenshots require VM Service uri', () async {
      final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(toolContext: toolContext),
        ).run(<String>['screenshot', '--type=skia']),
        throwsToolExit(message: 'VM Service URI must be specified for screenshot type skia'),
      );
    });

    testUsingContext('device screenshots require device', () async {
      final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(toolContext: toolContext),
        ).run(<String>['screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );
    });

    testWithoutContext('device screenshots cannot provide VM Service', () async {
      final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
      await expectLater(
        () => createTestCommandRunner(
          ScreenshotCommand(toolContext: toolContext),
        ).run(<String>['screenshot', '--vm-service-url=http://localhost:8181']),
        throwsToolExit(message: 'VM Service URI cannot be provided for screenshot type device'),
      );
    });
  });

  group('Screenshot file validation', () {
    testWithoutContext('successful in pwd', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();
      fs.directory('sub_dir').createSync();
      fs.file('sub_dir/test.png').createSync();

      expect(() => ScreenshotCommand.checkOutput(fs.file('test.png'), fs), returnsNormally);
      expect(() => ScreenshotCommand.checkOutput(fs.file('sub_dir/test.png'), fs), returnsNormally);
    });

    testWithoutContext('failed in pwd', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('sub_dir').createSync();

      expect(
        () => ScreenshotCommand.checkOutput(fs.file('test.png'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotCommand.checkOutput(fs.file('../'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotCommand.checkOutput(fs.file('.'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotCommand.checkOutput(fs.file('/'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
      expect(
        () => ScreenshotCommand.checkOutput(fs.file('sub_dir/test.png'), fs),
        throwsToolExit(message: 'File was not created, ensure path is valid'),
      );
    });
  });

  group('Screenshot output validation', () {
    testWithoutContext('successful', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();

      expect(
        () => ScreenshotCommand.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
        returnsNormally,
      );
    });

    testWithoutContext('failed', () async {
      final fs = MemoryFileSystem.test();
      fs.file('test.png').writeAsStringSync('{"jsonrpc":"2.0", "error":"something"}');

      expect(
        () => ScreenshotCommand.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
        throwsToolExit(
          message: 'It appears the output file contains an error message, not valid output.',
        ),
      );
    });
  });

  group('Screenshot for devices unsupported for project', () {
    late _TestDeviceManager testDeviceManager;
    late BufferLogger logger;
    late FakeToolContext toolContext;

    setUp(() {
      logger = BufferLogger.test();
      testDeviceManager = _TestDeviceManager(logger: logger);
      toolContext = FakeToolContext(fs: MemoryFileSystem.test(), logger: logger);
    });

    testUsingContext('should not throw for a single device', () async {
      final command = ScreenshotCommand(toolContext: toolContext);

      final deviceUnsupportedForProject = _ScreenshotDevice(
        id: '123',
        name: 'Device 1',
        isSupportedForProject: false,
      );

      testDeviceManager.devices = <Device>[deviceUnsupportedForProject];

      await createTestCommandRunner(command).run(<String>['screenshot']);
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});

    testUsingContext('should tool exit for multiple devices', () async {
      final command = ScreenshotCommand(toolContext: toolContext);

      final devicesUnsupportedForProject = <_ScreenshotDevice>[
        _ScreenshotDevice(id: '123', name: 'Device 1', isSupportedForProject: false),
        _ScreenshotDevice(id: '456', name: 'Device 2', isSupportedForProject: false),
      ];

      testDeviceManager.devices = devicesUnsupportedForProject;

      await expectLater(
        () => createTestCommandRunner(command).run(<String>['screenshot']),
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
    }, overrides: <Type, Generator>{DeviceManager: () => testDeviceManager});
  });

  group('Skia screenshot execution', () {
    testWithoutContext('successful Skia screenshot with custom out', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final toolContext = FakeToolContext(fs: fs, logger: logger);

      final fakeVmService = _FakeFlutterVmService(
        response: vm_service.Response.parse(<String, Object?>{
          'type': 'Response',
          'skp': base64.encode(utf8.encode('valid skp data')),
        }),
      );

      final command = ScreenshotCommand(
        toolContext: toolContext,
        vmServiceConnector:
            (
              Uri uri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              CompressionOptions compression = CompressionOptions.compressionDefault,
              Device? device,
              required Logger logger,
            }) async {
              expect(uri.toString(), 'http://localhost:8181');
              return fakeVmService;
            },
      );

      await createTestCommandRunner(command).run(<String>[
        'screenshot',
        '--type=skia',
        '--vm-service-url=http://localhost:8181',
        '--out=screenshot.skp',
      ]);

      final File outputFile = fs.file('screenshot.skp');
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), 'valid skp data');
      expect(logger.statusText, contains('Screenshot written to screenshot.skp (0kB).'));
    });

    testWithoutContext('failed Skia screenshot when disconnected', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final toolContext = FakeToolContext(fs: fs, logger: logger);

      final fakeVmService = _FakeFlutterVmService();

      final command = ScreenshotCommand(
        toolContext: toolContext,
        vmServiceConnector:
            (
              Uri uri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              CompressionOptions compression = CompressionOptions.compressionDefault,
              Device? device,
              required Logger logger,
            }) async {
              return fakeVmService;
            },
      );

      await createTestCommandRunner(
        command,
      ).run(<String>['screenshot', '--type=skia', '--vm-service-url=http://localhost:8181']);

      expect(
        logger.errorText,
        contains('The Skia picture request failed, probably because the device was disconnected'),
      );
    });
  });
}

class _ScreenshotDevice extends Fake implements Device {
  _ScreenshotDevice({required this.id, required this.name, required bool isSupportedForProject})
    : _isSupportedForProject = isSupportedForProject;

  @override
  final String name;

  @override
  String get displayName => name;

  @override
  final String id;

  final bool _isSupportedForProject;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => _isSupportedForProject;

  @override
  bool supportsScreenshot = true;

  @override
  bool get isConnected => true;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool ephemeral = true;

  @override
  DeviceConnectionInterface connectionInterface = DeviceConnectionInterface.attached;

  @override
  Future<void> takeScreenshot(File outputFile) async {
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

class _FakeFlutterVmService extends Fake implements FlutterVmService {
  _FakeFlutterVmService({this.response});

  final vm_service.Response? response;

  @override
  Future<vm_service.Response?> screenshotSkp() async => response;
}
