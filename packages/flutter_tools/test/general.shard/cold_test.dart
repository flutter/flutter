// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/hook_runner.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/tracing.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart' hide Event;
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/context.dart';

ColdRunner createColdRunner(
  List<FlutterDevice> flutterDevices, {
  required DebuggingOptions debuggingOptions,
  required String target,
  Analytics? analytics,
  File? applicationBinary,
  Artifacts? artifacts,
  bool awaitFirstFrameWhenTracing = true,
  BuildSystem? buildSystem,
  BuildTargets? buildTargets,
  Cache? cache,
  CommandHelp? commandHelp,
  Config? config,
  FlutterHookRunner? dartBuilder,
  String? dillOutputPath,
  FileSystem? fileSystem,
  FlutterVersion? flutterVersion,
  Logger? logger,
  bool machine = false,
  OperatingSystemUtils? osUtils,
  OutputPreferences? outputPreferences,
  Platform? platform,
  ProcessManager? processManager,
  String? projectRootPath,
  bool stayResident = true,
  Terminal? terminal,
  bool traceStartup = false,
  Xcode? xcode,
}) {
  FileSystem? contextFs;
  Platform? contextPlatform;
  ProcessManager? contextPm;
  Artifacts? contextArtifacts;
  Logger? contextLogger;
  try {
    contextFs = globals.fs;
  } on Object {
    // ignore
  }
  try {
    contextPlatform = globals.platform;
  } on Object {
    // ignore
  }
  try {
    contextPm = globals.processManager;
  } on Object {
    // ignore
  }
  try {
    contextArtifacts = globals.artifacts;
  } on Object {
    // ignore
  }
  try {
    contextLogger = globals.logger;
  } on Object {
    // ignore
  }

  final FileSystem effectiveFs = fileSystem ?? (contextFs ?? MemoryFileSystem.test());
  final Platform effectivePlatform = platform ?? (contextPlatform ?? const LocalPlatform());
  final ProcessManager effectiveProcessManager =
      processManager ?? (contextPm ?? FakeProcessManager.any());
  final Artifacts effectiveArtifacts = artifacts ?? (contextArtifacts ?? Artifacts.test());
  final Logger effectiveLogger = logger ?? (contextLogger ?? BufferLogger.test());

  return ColdRunner(
    flutterDevices,
    debuggingOptions: debuggingOptions,
    target: target,
    analytics: analytics,
    applicationBinary: applicationBinary,
    artifacts: effectiveArtifacts,
    awaitFirstFrameWhenTracing: awaitFirstFrameWhenTracing,
    buildSystem: buildSystem,
    buildTargets: buildTargets,
    cache: cache ?? globals.cache,
    commandHelp: commandHelp,
    config: config ?? globals.config,
    dartBuilder: dartBuilder,
    dillOutputPath: dillOutputPath,
    fileSystem: effectiveFs,
    flutterVersion: flutterVersion,
    logger: effectiveLogger,
    machine: machine,
    osUtils: osUtils ?? globals.os,
    outputPreferences: outputPreferences ?? globals.outputPreferences,
    platform: effectivePlatform,
    processManager: effectiveProcessManager,
    projectRootPath: projectRootPath,
    stayResident: stayResident,
    terminal: terminal ?? globals.terminal,
    traceStartup: traceStartup,
    xcode: xcode,
  );
}

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
      expect(device2.wasDisposed, true);
      expect(device1.wasDisposed, true);
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
              .directory(getBuildDirectory())
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
  });
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeFlutterDevice(this.device);

  @override
  Stream<Uri> get vmServiceUris => const Stream<Uri>.empty();

  @override
  final Device device;

  int stopEchoingDeviceLogCount = 0;

  @override
  Future<void> stopEchoingDeviceLog() async {
    stopEchoingDeviceLogCount += 1;
  }

  @override
  FlutterVmService get vmService => FakeFlutterVmService();

  int runColdCode = 0;

  @override
  Future<int> runCold({ColdRunner? coldRunner, String? route}) async {
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
  }) : super(
         targetPlatform: .unsupported,
         device,
         buildInfo: BuildInfo.debug,
         generator: generator,
         developmentShaderCompiler: const FakeShaderCompiler(),
       );

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    FlutterProject? flutterProject,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    required DebuggingOptions debuggingOptions,
    int? hostVmServicePort,
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
