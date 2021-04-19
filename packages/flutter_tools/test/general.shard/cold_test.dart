// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/tracing.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('Exits with code 2 when when HttpException is thrown '
    'during VM service connection', () async {
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
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
      target: 'main.dart',
    ).attach(
      enableDevTools: false,
    );
    expect(exitCode, 2);
  });

  group('cleanupAtFinish()', () {
    MockFlutterDevice mockFlutterDeviceFactory(Device device) {
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
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
        target: 'main.dart',
      ).cleanupAtFinish();

      verify(mockDevice1.dispose());
      expect(mockFlutterDevice1.stopEchoingDeviceLogCount, 1);
      verify(mockDevice2.dispose());
      expect(mockFlutterDevice2.stopEchoingDeviceLogCount, 1);
    });
  });

  group('cold run', () {
    MemoryFileSystem memoryFileSystem;
    FakePlatform fakePlatform;
    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      fakePlatform = FakePlatform(environment: <String, String>{});
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
      final File applicationBinary = MemoryFileSystem.test().file('binary');
      final int result = await ColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).run(
        enableDevTools: false,
      );

      expect(result, 1);
      verify(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route'),
      ));
    });

    testUsingContext('with traceStartup, no env variable', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route')
      )).thenAnswer((Invocation invocation) => Future<int>.value(0));
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final File applicationBinary = MemoryFileSystem.test().file('binary');
      final int result = await ColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        traceStartup: true,
      ).run(
        enableDevTools: false,
      );

      expect(result, 0);
      expect(memoryFileSystem.directory(getBuildDirectory()).childFile('start_up_info.json').existsSync(), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => fakePlatform,
    });

    testUsingContext('with traceStartup, env variable', () async {
      fakePlatform.environment[kFlutterTestOutputsDirEnvName] = 'test_output_dir';

      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route')
      )).thenAnswer((Invocation invocation) => Future<int>.value(0));
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final File applicationBinary = MemoryFileSystem.test().file('binary');
      final int result = await ColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        traceStartup: true,
      ).run(
        enableDevTools: false,
      );

      expect(result, 0);
      expect(memoryFileSystem.directory('test_output_dir').childFile('start_up_info.json').existsSync(), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => fakePlatform,
    });
  });
}

class MockFlutterDevice extends Mock implements FlutterDevice {
  int stopEchoingDeviceLogCount = 0;

  @override
  Future<void> stopEchoingDeviceLog() async {
    stopEchoingDeviceLogCount += 1;
  }

  @override
  FlutterVmService get vmService => FakeFlutterVmService();
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
    @required ResidentCompiler generator,
  })  : assert(exception != null),
        super(device, buildInfo: BuildInfo.debug, generator: generator);

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    GetSkSLMethod getSkSLMethod,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
    bool disableDds = false,
    bool disableServiceAuthCodes = false,
    int hostVmServicePort,
    int ddsPort,
    bool ipv6 = false,
    bool allowExistingDdsInstance = false,
  }) async {
    throw exception;
  }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {}

class FakeFlutterVmService extends Fake implements FlutterVmService {
  @override
  VmService get service => FakeVmService();

  @override
  Future<List<FlutterView>> getFlutterViews({bool returnEarly = false, Duration delay = const Duration(milliseconds: 50)}) async {
    return <FlutterView>[];
  }

  @override
  Future<bool> flutterAlreadyPaintedFirstUsefulFrame({String isolateId}) async => true;

  @override
  Future<Response> getTimeline() async {
    return Response.parse(<String, dynamic>{
      'traceEvents': <dynamic>[
        <String, dynamic>{
          'name': kFlutterEngineMainEnterEventName,
          'ts': 123,
        },
        <String, dynamic>{
          'name': kFirstFrameBuiltEventName,
          'ts': 124,
        },
        <String, dynamic>{
          'name': kFirstFrameRasterizedEventName,
          'ts': 124,
        },
      ],
    });
  }

  @override
  Future<void> setTimelineFlags(List<String> recordedStreams) async {}
}

class FakeVmService extends Fake implements VmService {
  @override
  Future<Success> streamListen(String streamId) async => Success();

  @override
  Stream<Event> get onExtensionEvent {
    return Stream<Event>.fromIterable(<Event>[
      Event(kind: 'Extension', extensionKind: 'Flutter.FirstFrame', timestamp: 1),
    ]);
  }
}
