// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/tracing.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import 'resident_runner_helpers.dart' show createColdRunner;

void main() {
  testUsingContext('Exits with code 2 when HttpException is thrown '
      'during VM service connection', () async {
    final residentCompiler = FakeResidentCompiler();
    final device = FakeDevice()
      ..supportsHotReload = true
      ..supportsHotRestart = false;

    final devices = <FlutterDevice>[
      TestFlutterDevice(
        device: device,
        generator: residentCompiler,
        exception: const HttpException(
          'Connection closed before full header was received, '
          'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws',
        ),
        vmServiceUri: Future<Uri>.value(Uri.parse('http://127.0.0.1:63394/5ZmLv8A59xY=/ws')),
      ),
    ];

    final int exitCode = await createColdRunner(
      devices,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
    ).attach();
    expect(exitCode, 2);
  });

  group('cleanupAtFinish()', () {
    testUsingContext('disposes each device', () async {
      final device1 = FakeDevice();
      final device2 = FakeDevice();
      final flutterDevice1 = FakeFlutterDevice(device1);
      final flutterDevice2 = FakeFlutterDevice(device2);

      final devices = <FlutterDevice>[flutterDevice1, flutterDevice2];

      await createColdRunner(
        devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).cleanupAtFinish();

      expect(flutterDevice1.stopEchoingDeviceLogCount, 1);
      expect(flutterDevice2.stopEchoingDeviceLogCount, 1);
      expect(flutterDevice1.wasDisposed, true);
      expect(flutterDevice2.wasDisposed, true);
      expect(device2.wasDisposed, true);
      expect(device1.wasDisposed, true);
    });

    testWithoutContext('destroys devFS when present', () async {
      final fs = MemoryFileSystem.test();
      final devFS = FakeDevFS();
      final device = FakeDevice();
      final flutterDevice = FakeFlutterDevice(device)..devFS = devFS;
      final ColdRunner runner = createColdRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        stayResident: false,
        target: 'main.dart',
        toolContext: FakeToolContext(
          cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
          fs: fs,
        ),
      );

      await runner.cleanupAtFinish();

      expect(devFS.wasDestroyed, true);
      expect(flutterDevice.wasDisposed, true);
      expect(device.wasDisposed, true);
    });
  });

  group('cold restart', () {
    testWithoutContext('supportsRestart reflects device supportsColdRestart', () {
      final fs = MemoryFileSystem.test();
      final toolContext = FakeToolContext(
        cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
        fs: fs,
      );
      final nativeDevice = FakeFlutterDevice(FakeDevice());
      final coldRestartDevice = FakeFlutterDevice(FakeDevice())..supportsColdRestart = true;

      expect(
        createColdRunner(
          <FlutterDevice>[nativeDevice],
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          target: 'main.dart',
          toolContext: toolContext,
        ).supportsRestart,
        false,
      );
      expect(
        createColdRunner(
          <FlutterDevice>[coldRestartDevice],
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          target: 'main.dart',
          toolContext: toolContext,
        ).supportsRestart,
        true,
      );
      expect(
        createColdRunner(
          <FlutterDevice>[nativeDevice, coldRestartDevice],
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          target: 'main.dart',
          toolContext: toolContext,
        ).supportsRestart,
        false,
      );
    });

    testWithoutContext('restart invokes restartCold and handles ToolExit and Exception', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final flutterDevice = FakeFlutterDevice(FakeDevice())..supportsColdRestart = true;
      final ColdRunner runner = createColdRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        stayResident: false,
        target: 'main.dart',
        toolContext: FakeToolContext(
          cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
          fs: fs,
          logger: logger,
        ),
      );

      final OperationResult okResult = await runner.restart(fullRestart: true);
      expect(okResult.code, 0);
      expect(flutterDevice.restartColdCount, 1);
      expect(logger.statusText, contains('Restarted application in'));

      flutterDevice.onRestartCold = () => throwToolExit('compile failed');
      final OperationResult compileFailure = await runner.restart(fullRestart: true);
      expect(compileFailure.code, 1);
      expect(compileFailure.message, 'Failed to recompile application.');
      expect(compileFailure.fatal, false);

      flutterDevice.onRestartCold = () => throw Exception('wip disconnected');
      final OperationResult reloadFailure = await runner.restart(fullRestart: true);
      expect(reloadFailure.code, 1);
      expect(reloadFailure.message, contains('wip disconnected'));
      expect(reloadFailure.fatal, true);
    });

    testWithoutContext('restart rejects concurrent and post-exit requests', () async {
      final fs = MemoryFileSystem.test();
      final completer = Completer<void>();
      final flutterDevice = FakeFlutterDevice(FakeDevice())
        ..supportsColdRestart = true
        ..onRestartCold = () => completer.future;
      final ColdRunner runner = createColdRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        stayResident: false,
        target: 'main.dart',
        toolContext: FakeToolContext(
          cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
          fs: fs,
        ),
      );

      final Future<OperationResult> first = runner.restart(fullRestart: true);
      final OperationResult concurrent = await runner.restart(fullRestart: true);
      expect(concurrent.code, 1);
      expect(concurrent.message, 'A restart is already in progress.');

      completer.complete();
      expect((await first).code, 0);

      await runner.exit();
      final OperationResult exited = await runner.restart(fullRestart: true);
      expect(exited.code, 1);
      expect(exited.message, 'Application has exited.');
    });
  });

  group('cold run', () {
    late MemoryFileSystem memoryFileSystem;
    late FakePlatform fakePlatform;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      fakePlatform = FakePlatform(environment: <String, String>{});
    });

    testUsingContext('calls runCold on attached device', () async {
      final device = FakeDevice();
      final flutterDevice = FakeFlutterDevice(device)..runColdCode = 1;
      final devices = <FlutterDevice>[flutterDevice];
      final File applicationBinary = MemoryFileSystem.test().file('binary');
      final int result = await createColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).run();

      expect(result, 1);
    });

    testUsingContext(
      'with traceStartup, no env variable',
      () async {
        final device = FakeDevice();
        final flutterDevice = FakeFlutterDevice(device);
        final devices = <FlutterDevice>[flutterDevice];
        final File applicationBinary = MemoryFileSystem.test().file('binary');
        final int result = await createColdRunner(
          devices,
          applicationBinary: applicationBinary,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          traceStartup: true,
        ).run();

        expect(result, 0);
        expect(
          memoryFileSystem
              .directory(getBuildDirectory(Config.test(), memoryFileSystem))
              .childFile('start_up_info.json')
              .existsSync(),
          true,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'with traceStartup, env variable',
      () async {
        fakePlatform.environment[kFlutterTestOutputsDirEnvName] = 'test_output_dir';

        final device = FakeDevice();
        final flutterDevice = FakeFlutterDevice(device);
        final devices = <FlutterDevice>[flutterDevice];
        final File applicationBinary = MemoryFileSystem.test().file('binary');
        final int result = await createColdRunner(
          devices,
          applicationBinary: applicationBinary,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          traceStartup: true,
        ).run();

        expect(result, 0);
        expect(
          memoryFileSystem
              .directory('test_output_dir')
              .childFile('start_up_info.json')
              .existsSync(),
          true,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => fakePlatform,
      },
    );

    testWithoutContext(
      'calls appFailedToStart and rethrows when runCold throws ToolExit',
      () async {
        final fs = MemoryFileSystem.test();
        final flutterDevice = FakeFlutterDevice(FakeDevice())
          ..onRunCold = () => throwToolExit('device launch failed');
        final ColdRunner runner = createColdRunner(
          <FlutterDevice>[flutterDevice],
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          stayResident: false,
          target: 'main.dart',
          toolContext: FakeToolContext(
            cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
            fs: fs,
          ),
        );

        await expectLater(runner.run(), throwsToolExit(message: 'device launch failed'));
        expect(await runner.waitForAppToFinish(), 1);
      },
    );
  });
}

class FakeDevFS extends Fake implements DevFS {
  bool wasDestroyed = false;

  @override
  Future<void> destroy() async {
    wasDestroyed = true;
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeFlutterDevice(this.device);

  @override
  Future<Uri>? get vmServiceUri => null;

  @override
  final Device device;

  @override
  DevFS? devFS;

  @override
  TargetPlatform get targetPlatform => TargetPlatform.tester;

  @override
  bool supportsColdRestart = false;

  bool wasDisposed = false;
  int restartColdCount = 0;
  Future<void> Function()? onRestartCold;

  @override
  Future<void> dispose() async {
    wasDisposed = true;
  }

  @override
  Future<void> restartCold({required ColdRunner coldRunner}) async {
    restartColdCount += 1;
    await onRestartCold?.call();
  }

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {}

  int stopEchoingDeviceLogCount = 0;

  @override
  Future<void> stopEchoingDeviceLog() async {
    stopEchoingDeviceLogCount += 1;
  }

  @override
  FlutterVmService get vmService => FakeFlutterVmService();

  int runColdCode = 0;
  Future<int> Function()? onRunCold;

  @override
  Future<int> runCold({ColdRunner? coldRunner, String? route}) async {
    if (onRunCold != null) {
      return onRunCold!();
    }
    return runColdCode;
  }
}

class FakeDevice extends Fake implements Device {
  @override
  Future<bool> isSupported() async => true;

  @override
  bool supportsHotReload = false;

  @override
  bool supportsHotRestart = false;

  @override
  Future<String> get sdkNameAndVersion async => 'Android 10';

  @override
  String get name => 'test';

  @override
  String get displayName => name;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  @override
  DartDevelopmentService get dds => FakeDartDevelopmentService();

  bool wasDisposed = false;

  @override
  Future<void> dispose() async {
    wasDisposed = true;
  }
}

class FakeDartDevelopmentService extends Fake implements DartDevelopmentService {
  @override
  late Future<void> done;

  @override
  Uri? uri;

  @override
  Uri? devToolsUri;

  @override
  Uri? dtdUri;

  @override
  Future<void> startDartDevelopmentService(
    Uri vmServiceUri, {
    Artifacts? artifacts,
    String? appName = 'Fake App',
    int? ddsPort,
    FlutterDevice? device,
    bool? ipv6,
    bool? disableServiceAuthCodes,
    bool enableDevTools = false,
    bool cacheStartupProfile = false,
    String? google3WorkspaceRoot,
    Uri? devToolsServerAddress,
  }) async {}

  @override
  Future<void> shutdown() async {}
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    required Device device,
    required this.exception,
    required ResidentCompiler generator,
    Future<Uri>? vmServiceUri,
  }) : super(
         device,
         toolContext: DelegatingToolContext(artifacts: Artifacts.test()),
         targetPlatform: .unsupported,
         buildInfo: BuildInfo.debug,
         generator: generator,
         developmentShaderCompiler: const FakeShaderCompiler(),
       ) {
    this.vmServiceUri = vmServiceUri;
  }

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    required Uri vmServiceUri,
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    required DebuggingOptions debuggingOptions,
  }) async {
    throw exception;
  }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {}

class FakeFlutterVmService extends Fake implements FlutterVmService {
  @override
  VmService get service => FakeVmService();

  @override
  Future<List<FlutterView>> getFlutterViews({
    bool returnEarly = false,
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    return <FlutterView>[];
  }

  @override
  Future<bool> flutterAlreadyPaintedFirstUsefulFrame({String? isolateId}) async => true;

  @override
  Future<Response?> getTimeline() async {
    return Response.parse(<String, dynamic>{
      'traceEvents': <dynamic>[
        <String, dynamic>{'name': kFlutterEngineMainEnterEventName, 'ts': 123},
        <String, dynamic>{'name': kFirstFrameBuiltEventName, 'ts': 124},
        <String, dynamic>{'name': kFirstFrameRasterizedEventName, 'ts': 124},
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

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(TargetPlatform? platform) {}

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }

  @override
  bool areDependenciesModified(DevFSContent shaderContent) => false;
}
