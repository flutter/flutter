// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/macos/macos_ipad_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fake_vm_services.dart';
import '../../src/test_flutter_command_runner.dart';

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  isolateFlags: <vm_service.IsolateFlag>[],
  libraries: <vm_service.LibraryRef>[],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
);

void main() {
  tearDown(() {
    MacOSDesignedForIPadDevices.allowDiscovery = false;
  });

  group('attach', () {
    StreamLogger logger;
    FileSystem testFileSystem;

    setUp(() {
      Cache.disableLocking();
      logger = StreamLogger();
      testFileSystem = MemoryFileSystem(
      style: globals.platform.isWindows
          ? FileSystemStyle.windows
          : FileSystemStyle.posix,
      );
      testFileSystem.directory('lib').createSync();
      testFileSystem.file(testFileSystem.path.join('lib', 'main.dart')).createSync();
    });

    group('with one device and no specified target file', () {
      const int devicePort = 499;
      const int hostPort = 42;

      FakeDeviceLogReader fakeLogReader;
      RecordingPortForwarder portForwarder;
      FakeDartDevelopmentService fakeDds;
      FakeAndroidDevice device;

      setUp(() {
        fakeLogReader = FakeDeviceLogReader();
        portForwarder = RecordingPortForwarder(hostPort);
        fakeDds = FakeDartDevelopmentService();
        device = FakeAndroidDevice(id: '1')
          ..portForwarder = portForwarder
          ..dds = fakeDds;
      });

      tearDown(() {
        fakeLogReader.dispose();
      });

      testUsingContext('finds observatory port and forwards', () async {
        device.onGetLogReader = () {
          fakeLogReader.addLine('Foo');
          fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return fakeLogReader;
        };
        testDeviceManager.addDevice(device);
        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[verbose] Observatory URL on device: http://127.0.0.1:$devicePort') {
            // The "Observatory URL on device" message is output by the ProtocolDiscovery when it found the observatory.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand()).run(<String>['attach']);
        await completer.future;

        expect(portForwarder.devicePort, devicePort);
        expect(portForwarder.hostPort, hostPort);

        await fakeLogReader.dispose();
        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('Fails with tool exit on bad Observatory uri', () async {
        device.onGetLogReader = () {
          fakeLogReader.addLine('Foo');
          fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          fakeLogReader.dispose();
          return fakeLogReader;
        };
        testDeviceManager.addDevice(device);
        expect(() => createTestCommandRunner(AttachCommand()).run(<String>['attach']), throwsToolExit());
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('accepts filesystem parameters', () async {
        device.onGetLogReader = () {
          fakeLogReader.addLine('Foo');
          fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return fakeLogReader;
        };
        testDeviceManager.addDevice(device);

        const String filesystemScheme = 'foo';
        const String filesystemRoot = '/build-output/';
        const String projectRoot = '/build-output/project-root';
        const String outputDill = '/tmp/output.dill';

        final FakeHotRunner hotRunner = FakeHotRunner();
        hotRunner.onAttach = (
          Completer<DebugConnectionInfo> connectionInfoCompleter,
          Completer<void> appStartedCompleter,
          bool allowExistingDdsInstance,
          bool enableDevTools,
        ) async => 0;
        hotRunner.exited = false;
        hotRunner.isWaitingForObservatory = false;

        final FakeHotRunnerFactory hotRunnerFactory = FakeHotRunnerFactory()
          ..hotRunner = hotRunner;

        final AttachCommand command = AttachCommand(
          hotRunnerFactory: hotRunnerFactory,
        );
        await createTestCommandRunner(command).run(<String>[
          'attach',
          '--filesystem-scheme',
          filesystemScheme,
          '--filesystem-root',
          filesystemRoot,
          '--project-root',
          projectRoot,
          '--output-dill',
          outputDill,
          '-v', // enables verbose logging
        ]);

        // Validate the attach call built a fake runner with the right
        // project root and output dill.
        expect(hotRunnerFactory.projectRootPath, projectRoot);
        expect(hotRunnerFactory.dillOutputPath, outputDill);
        expect(hotRunnerFactory.devices, hasLength(1));

        // Validate that the attach call built a flutter device with the right
        // output dill, filesystem scheme, and filesystem root.
        final FlutterDevice flutterDevice = hotRunnerFactory.devices.first;

        expect(flutterDevice.buildInfo.fileSystemScheme, filesystemScheme);
        expect(flutterDevice.buildInfo.fileSystemRoots, const <String>[filesystemRoot]);
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('exits when ipv6 is specified and debug-port is not', () async {
        testDeviceManager.addDevice(device);

        final AttachCommand command = AttachCommand();
        await expectLater(
          createTestCommandRunner(command).run(<String>['attach', '--ipv6']),
          throwsToolExit(
            message: 'When the --debug-port or --debug-url is unknown, this command determines '
                     'the value of --ipv6 on its own.',
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },);

      testUsingContext('exits when observatory-port is specified and debug-port is not', () async {
        device.onGetLogReader = () {
          fakeLogReader.addLine('Foo');
          fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return fakeLogReader;
        };
        testDeviceManager.addDevice(device);

        final AttachCommand command = AttachCommand();
        await expectLater(
          createTestCommandRunner(command).run(<String>['attach', '--observatory-port', '100']),
          throwsToolExit(
            message: 'When the --debug-port or --debug-url is unknown, this command does not use '
                     'the value of --observatory-port.',
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },);
    });

    group('forwarding to given port', () {
      const int devicePort = 499;
      const int hostPort = 42;
      RecordingPortForwarder portForwarder;
      FakeAndroidDevice device;

      setUp(() {
        final FakeDartDevelopmentService fakeDds = FakeDartDevelopmentService();
        portForwarder = RecordingPortForwarder(hostPort);
        device = FakeAndroidDevice(id: '1')
          ..portForwarder = portForwarder
          ..dds = fakeDds;
      });

      testUsingContext('succeeds in ipv4 mode', () async {
        testDeviceManager.addDevice(device);

        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[verbose] Connecting to service protocol: http://127.0.0.1:42/') {
            // Wait until resident_runner.dart tries to connect.
            // There's nothing to connect _to_, so that's as far as we care to go.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand())
          .run(<String>['attach', '--debug-port', '$devicePort']);
        await completer.future;
        expect(portForwarder.devicePort, devicePort);
        expect(portForwarder.hostPort, hostPort);

        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('succeeds in ipv6 mode', () async {
        testDeviceManager.addDevice(device);

        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[verbose] Connecting to service protocol: http://[::1]:42/') {
            // Wait until resident_runner.dart tries to connect.
            // There's nothing to connect _to_, so that's as far as we care to go.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand())
          .run(<String>['attach', '--debug-port', '$devicePort', '--ipv6']);
        await completer.future;

        expect(portForwarder.devicePort, devicePort);
        expect(portForwarder.hostPort, hostPort);

        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('skips in ipv4 mode with a provided observatory port', () async {
        testDeviceManager.addDevice(device);

        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[verbose] Connecting to service protocol: http://127.0.0.1:42/') {
            // Wait until resident_runner.dart tries to connect.
            // There's nothing to connect _to_, so that's as far as we care to go.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand()).run(
          <String>[
            'attach',
            '--debug-port',
            '$devicePort',
            '--observatory-port',
            '$hostPort',
            // Ensure DDS doesn't use hostPort by binding to a random port.
            '--dds-port',
            '0',
          ],
        );
        await completer.future;
        expect(portForwarder.devicePort, null);
        expect(portForwarder.hostPort, 42);

        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('skips in ipv6 mode with a provided observatory port', () async {
        testDeviceManager.addDevice(device);

        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[verbose] Connecting to service protocol: http://[::1]:42/') {
            // Wait until resident_runner.dart tries to connect.
            // There's nothing to connect _to_, so that's as far as we care to go.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand()).run(
          <String>[
            'attach',
            '--debug-port',
            '$devicePort',
            '--observatory-port',
            '$hostPort',
            '--ipv6',
            // Ensure DDS doesn't use hostPort by binding to a random port.
            '--dds-port',
            '0',
          ],
        );
        await completer.future;
        expect(portForwarder.devicePort, null);
        expect(portForwarder.hostPort, 42);

        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });
    });

    testUsingContext('exits when no device connected', () async {
      final AttachCommand command = AttachCommand();
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsToolExit(),
      );
      expect(testLogger.statusText, containsIgnoringWhitespace('No supported devices connected'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('fails when targeted device is not Android with --device-user', () async {
      final FakeIOSDevice device = FakeIOSDevice();
      testDeviceManager.addDevice(device);
      expect(createTestCommandRunner(AttachCommand()).run(<String>[
        'attach',
        '--device-user',
        '10',
      ]), throwsToolExit(message: '--device-user is only supported for Android'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('exits when multiple devices connected', () async {
      final AttachCommand command = AttachCommand();
      testDeviceManager.addDevice(FakeAndroidDevice(id: 'xx1'));
      testDeviceManager.addDevice(FakeAndroidDevice(id: 'yy2'));
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsToolExit(),
      );
      expect(testLogger.statusText, containsIgnoringWhitespace('More than one device'));
      expect(testLogger.statusText, contains('xx1'));
      expect(testLogger.statusText, contains('yy2'));
      expect(MacOSDesignedForIPadDevices.allowDiscovery, isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Catches service disappeared error', () async {
      final FakeAndroidDevice device = FakeAndroidDevice(id: '1')
        ..portForwarder = const NoOpDevicePortForwarder()
        ..onGetLogReader = () => NoOpDeviceLogReader('test');
      final FakeHotRunner hotRunner = FakeHotRunner();
      final FakeHotRunnerFactory hotRunnerFactory = FakeHotRunnerFactory()
        ..hotRunner = hotRunner;
      hotRunner.onAttach = (
        Completer<DebugConnectionInfo> connectionInfoCompleter,
        Completer<void> appStartedCompleter,
        bool allowExistingDdsInstance,
        bool enableDevTools,
      ) async {
        await null;
        throw vm_service.RPCError('flutter._listViews', RPCErrorCodes.kServiceDisappeared, '');
      };

      testDeviceManager.addDevice(device);
      testFileSystem.file('lib/main.dart').createSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: hotRunnerFactory);
      await expectLater(createTestCommandRunner(command).run(<String>[
        'attach',
      ]), throwsToolExit(message: 'Lost connection to device.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does not catch generic RPC error', () async {
      final FakeAndroidDevice device = FakeAndroidDevice(id: '1')
        ..portForwarder = const NoOpDevicePortForwarder()
        ..onGetLogReader = () => NoOpDeviceLogReader('test');
      final FakeHotRunner hotRunner = FakeHotRunner();
      final FakeHotRunnerFactory hotRunnerFactory = FakeHotRunnerFactory()
        ..hotRunner = hotRunner;

      hotRunner.onAttach = (
        Completer<DebugConnectionInfo> connectionInfoCompleter,
        Completer<void> appStartedCompleter,
        bool allowExistingDdsInstance,
        bool enableDevTools,
      ) async {
        await null;
        throw vm_service.RPCError('flutter._listViews', RPCErrorCodes.kInvalidParams, '');
      };


      testDeviceManager.addDevice(device);
      testFileSystem.file('lib/main.dart').createSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: hotRunnerFactory);
      await expectLater(createTestCommandRunner(command).run(<String>[
        'attach',
      ]), throwsA(isA<vm_service.RPCError>()));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class FakeHotRunner extends Fake implements HotRunner {
  Future<int> Function(Completer<DebugConnectionInfo>, Completer<void>, bool, bool) onAttach;

  @override
  bool exited = false;

  @override
  bool isWaitingForObservatory = true;

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool allowExistingDdsInstance = false,
    bool enableDevTools = false,
  }) {
    return onAttach(connectionInfoCompleter, appStartedCompleter, allowExistingDdsInstance, enableDevTools);
  }
}

class FakeHotRunnerFactory extends Fake implements HotRunnerFactory {
  HotRunner hotRunner;
  String dillOutputPath;
  String projectRootPath;
  List<FlutterDevice> devices;

  @override
  HotRunner build(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    bool benchmarkMode = false,
    File applicationBinary,
    bool hostIsIde = false,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    FlutterProject flutterProject,
  }) {
    this.devices = devices;
    this.dillOutputPath = dillOutputPath;
    this.projectRootPath = projectRootPath;
    return hotRunner;
  }
}

class RecordingPortForwarder implements DevicePortForwarder {
  RecordingPortForwarder([this.hostPort]);

  int devicePort;
  int hostPort;

  @override
  Future<void> dispose() async { }

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    this.devicePort = devicePort;
    this.hostPort ??= hostPort;
    return this.hostPort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async { }
}

class StreamLogger extends Logger {
  @override
  bool get isVerbose => true;

  @override
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _log('[stderr] $message');
  }

  @override
  void printStatus(
    String message, {
    bool emphasis,
    TerminalColor color,
    bool newline,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _log('[stdout] $message');
  }

  @override
  void printTrace(String message) {
    _log('[verbose] $message');
  }

  @override
  Status startProgress(
    String message, {
    @required Duration timeout,
    String progressId,
    bool multilineOutput = false,
    bool includeTiming = true,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    _log('[progress] $message');
    return SilentStatus(
      stopwatch: Stopwatch(),
    )..start();
  }

  @override
  Status startSpinner({ VoidCallback onFinish }) {
    return SilentStatus(
      stopwatch: Stopwatch(),
      onFinish: onFinish,
    )..start();
  }

  bool _interrupt = false;

  void interrupt() {
    _interrupt = true;
  }

  final StreamController<String> _controller = StreamController<String>.broadcast();

  void _log(String message) {
    _controller.add(message);
    if (_interrupt) {
      _interrupt = false;
      throw const LoggerInterrupted();
    }
  }

  Stream<String> get stream => _controller.stream;

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) { }

  @override
  bool get supportsColor => throw UnimplementedError();

  @override
  bool get hasTerminal => false;

  @override
  void clear() => _log('[stdout] ${globals.terminal.clearScreen()}\n');

  @override
  Terminal get terminal => Terminal.test();
}

class LoggerInterrupted implements Exception {
  const LoggerInterrupted();
}

Future<void> expectLoggerInterruptEndsTask(Future<void> task, StreamLogger logger) async {
  logger.interrupt(); // an exception during the task should cause it to fail...
  await expectLater(
    () => task,
    throwsA(isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', 2)),
  );
}

VMServiceConnector getFakeVmServiceFactory({
  @required Completer<void> vmServiceDoneCompleter,
}) {
  assert(vmServiceDoneCompleter != null);

  return (
    Uri httpUri, {
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    GetSkSLMethod getSkSLMethod,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
    CompressionOptions compression,
    Device device,
    Logger logger,
  }) async {
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        FakeVmServiceRequest(
          method: kListViewsMethod,
          args: null,
          jsonResponse: <String, Object>{
            'views': <Object>[
              <String, Object>{
                'id': '1',
                'isolate': fakeUnpausedIsolate.toJson()
              },
            ],
          },
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          args: null,
          jsonResponse: vm_service.VM.parse(<String, Object>{})
            .toJson(),
        ),
        FakeVmServiceRequest(
          method: '_createDevFS',
          args: <String, Object>{
            'fsName': globals.fs.currentDirectory.absolute.path,
          },
          jsonResponse: <String, Object>{
            'uri': globals.fs.currentDirectory.absolute.path,
          },
        ),
        FakeVmServiceRequest(
          method: kListViewsMethod,
          args: null,
          jsonResponse: <String, Object>{
            'views': <Object>[
              <String, Object>{
                'id': '1',
                'isolate': fakeUnpausedIsolate.toJson()
              },
            ],
          },
        ),
      ],
    );
    return fakeVmServiceHost.vmService;
  };
}

class TestHotRunnerFactory extends HotRunnerFactory {
  HotRunner _runner;

  @override
  HotRunner build(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    bool benchmarkMode = false,
    File applicationBinary,
    bool hostIsIde = false,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    FlutterProject flutterProject,
  }) {
    _runner ??= HotRunner(
      devices,
      target: target,
      debuggingOptions: debuggingOptions,
      benchmarkMode: benchmarkMode,
      applicationBinary: applicationBinary,
      hostIsIde: hostIsIde,
      projectRootPath: projectRootPath,
      dillOutputPath: dillOutputPath,
      stayResident: stayResident,
      ipv6: ipv6,
    );
    return _runner;
  }

  Future<void> exitApp() async {
    assert(_runner != null);
    await _runner.exit();
  }
}

class FakeDartDevelopmentService extends Fake implements DartDevelopmentService {
  @override
  Future<void> get done => noopCompleter.future;
  final Completer<void> noopCompleter = Completer<void>();

  @override
  Future<void> startDartDevelopmentService(
    Uri observatoryUri, {
    @required Logger logger,
    int hostPort,
    bool ipv6,
    bool disableServiceAuthCodes,
  }) async {}

  @override
  Uri get uri => Uri.parse('http://localhost:8181');
}

class FakeAndroidDevice extends Fake implements AndroidDevice {
  FakeAndroidDevice({@required this.id});

  @override
  DartDevelopmentService dds;

  @override
  final String id;

  @override
  String get name => 'd$id';

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get sdkNameAndVersion async => 'Android 46';

  @override
  Future<String> get targetPlatformDisplayName async => 'android';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  bool isSupported() => true;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsFlutterExit => false;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  DevicePortForwarder portForwarder;

  DeviceLogReader Function() onGetLogReader;

  @override
  FutureOr<DeviceLogReader> getLogReader({
    AndroidApk app,
    bool includePastLogs = false,
  }) {
    return onGetLogReader();
  }

  @override
  OverrideArtifacts get artifactOverrides => null;

  @override
  final PlatformType platformType = PlatformType.android;

  @override
  Category get category => Category.mobile;
}

class FakeIOSDevice extends Fake implements IOSDevice {
  FakeIOSDevice({this.dds, this.portForwarder, this.logReader});

  @override
  final DevicePortForwarder portForwarder;

  @override
  final DartDevelopmentService dds;

  final DeviceLogReader logReader;

  @override
  DeviceLogReader getLogReader({
    IOSApp app,
    bool includePastLogs = false,
  }) => logReader;

  @override
  OverrideArtifacts get artifactOverrides => null;

  @override
  final String name = 'name';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  final PlatformType platformType = PlatformType.ios;
}
