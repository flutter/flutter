// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';

import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';


void main() {
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

      MockDeviceLogReader mockLogReader;
      MockPortForwarder portForwarder;
      MockAndroidDevice device;
      MockProcessManager mockProcessManager;
      MockHttpClient httpClient;
      Completer<void> vmServiceDoneCompleter;

      setUp(() {
        mockProcessManager = MockProcessManager();
        mockLogReader = MockDeviceLogReader();
        portForwarder = MockPortForwarder();
        device = MockAndroidDevice();
        vmServiceDoneCompleter = Completer<void>();
        when(device.portForwarder)
          .thenReturn(portForwarder);
        when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
        when(portForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(portForwarder.unforward(any))
          .thenAnswer((_) async => null);

        final HttpClientRequest httpClientRequest = MockHttpClientRequest();
        httpClient = MockHttpClient();
        when(httpClient.putUrl(any))
          .thenAnswer((_) => Future<HttpClientRequest>.value(httpClientRequest));
        when(httpClientRequest.headers).thenReturn(MockHttpHeaders());
        when(httpClientRequest.close())
          .thenAnswer((_) => Future<HttpClientResponse>.value(MockHttpClientResponse()));

        // We cannot add the device to a device manager because that is
        // only enabled by the context of each testUsingContext call.
        //
        // Instead each test will add the device to the device manager
        // on its own.
      });

      tearDown(() {
        mockLogReader.dispose();
      });

      testUsingContext('finds observatory port and forwards', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return mockLogReader;
        });
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
        verify(
          portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')),
        ).called(1);
        await mockLogReader.dispose();
        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('finds all observatory ports and forwards them', () async {
        testFileSystem.file(testFileSystem.path.join('.packages')).createSync();
        testFileSystem.file(testFileSystem.path.join('lib', 'main.dart')).createSync();
        testFileSystem
          .file(testFileSystem.path.join('build', 'flutter_assets', 'AssetManifest.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');

        when(device.name).thenReturn('MockAndroidDevice');
        when(device.getLogReader()).thenReturn(mockLogReader);

        final Process dartProcess = MockProcess();
        final StreamController<List<int>> compilerStdoutController = StreamController<List<int>>();

        when(dartProcess.stdout).thenAnswer((_) => compilerStdoutController.stream);
        when(dartProcess.stderr)
          .thenAnswer((_) => Stream<List<int>>.fromFuture(Future<List<int>>.value(const <int>[])));

        when(dartProcess.stdin).thenAnswer((_) => MockStdIn());

        final Completer<int> dartProcessExitCode = Completer<int>();
        when(dartProcess.exitCode).thenAnswer((_) => dartProcessExitCode.future);
        when(mockProcessManager.start(any)).thenAnswer((_) => Future<Process>.value(dartProcess));

        testDeviceManager.addDevice(device);

        final List<String> observatoryLogs = <String>[];

        await FakeAsync().run((FakeAsync time) {
          unawaited(runZoned(() async {
            final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
              // The "Observatory URL on device" message is output by the ProtocolDiscovery when it found the observatory.
              if (message.startsWith('[verbose] Observatory URL on device')) {
                observatoryLogs.add(message);
              }
              if (message == '[stdout] Waiting for a connection from Flutter on MockAndroidDevice...') {
                observatoryLogs.add(message);
              }
              if (message == '[stdout] Lost connection to device.') {
                observatoryLogs.add(message);
              }
              if (message.contains('Hot reload.')) {
                observatoryLogs.add(message);
              }
              if (message.contains('Hot restart.')) {
                observatoryLogs.add(message);
              }
            });

            final TestHotRunnerFactory testHotRunnerFactory = TestHotRunnerFactory();
            final Future<void> task = createTestCommandRunner(
                AttachCommand(hotRunnerFactory: testHotRunnerFactory)
              ).run(<String>['attach']);

            // First iteration of the attach loop.
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:0001');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:1234');

            time.elapse(const Duration(milliseconds: 200));

            compilerStdoutController
              .add(utf8.encode('result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'));
            time.flushMicrotasks();

            // Second iteration of the attach loop.
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:0002');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:1235');

            time.elapse(const Duration(milliseconds: 200));

            compilerStdoutController
              .add(utf8.encode('result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'));
            time.flushMicrotasks();

            dartProcessExitCode.complete(0);

            await loggerSubscription.cancel();
            await testHotRunnerFactory.exitApp();
            await task;
          }));
        });

        expect(observatoryLogs.length, 9);
        expect(observatoryLogs[0], '[stdout] Waiting for a connection from Flutter on MockAndroidDevice...');
        expect(observatoryLogs[1], '[verbose] Observatory URL on device: http://127.0.0.1:1234');
        expect(observatoryLogs[2], '[stdout] Lost connection to device.');
        expect(observatoryLogs[3].contains('Hot reload.'), isTrue);
        expect(observatoryLogs[4].contains('Hot restart.'), isTrue);
        expect(observatoryLogs[5], '[verbose] Observatory URL on device: http://127.0.0.1:1235');
        expect(observatoryLogs[6], '[stdout] Lost connection to device.');
        expect(observatoryLogs[7].contains('Hot reload.'), isTrue);
        expect(observatoryLogs[8].contains('Hot restart.'), isTrue);

        verify(portForwarder.forward(1234, hostPort: anyNamed('hostPort'))).called(1);
        verify(portForwarder.forward(1235, hostPort: anyNamed('hostPort'))).called(1);

      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        HttpClientFactory: () => () => httpClient,
        ProcessManager: () => mockProcessManager,
        Logger: () => logger,
        VMServiceConnector: () => getFakeVmServiceFactory(
          vmServiceDoneCompleter: vmServiceDoneCompleter,
        ),
      });

      testUsingContext('Fails with tool exit on bad Observatory uri', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http:/:/127.0.0.1:$devicePort');
          mockLogReader.dispose();
          return mockLogReader;
        });
        testDeviceManager.addDevice(device);
        expect(createTestCommandRunner(AttachCommand()).run(<String>['attach']),
               throwsA(isA<ToolExit>()));
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('accepts filesystem parameters', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return mockLogReader;
        });
        testDeviceManager.addDevice(device);

        const String filesystemScheme = 'foo';
        const String filesystemRoot = '/build-output/';
        const String projectRoot = '/build-output/project-root';
        const String outputDill = '/tmp/output.dill';

        final MockHotRunner mockHotRunner = MockHotRunner();
        when(mockHotRunner.attach(appStartedCompleter: anyNamed('appStartedCompleter')))
            .thenAnswer((_) async => 0);
        when(mockHotRunner.exited).thenReturn(false);
        when(mockHotRunner.isWaitingForObservatory).thenReturn(false);

        final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
        when(
          mockHotRunnerFactory.build(
            any,
            target: anyNamed('target'),
            projectRootPath: anyNamed('projectRootPath'),
            dillOutputPath: anyNamed('dillOutputPath'),
            debuggingOptions: anyNamed('debuggingOptions'),
            packagesFilePath: anyNamed('packagesFilePath'),
            flutterProject: anyNamed('flutterProject'),
            ipv6: false,
          ),
        ).thenReturn(mockHotRunner);

        final AttachCommand command = AttachCommand(
          hotRunnerFactory: mockHotRunnerFactory,
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

        // Validate the attach call built a mock runner with the right
        // project root and output dill.
        final VerificationResult verificationResult = verify(
          mockHotRunnerFactory.build(
            captureAny,
            target: anyNamed('target'),
            projectRootPath: projectRoot,
            dillOutputPath: outputDill,
            debuggingOptions: anyNamed('debuggingOptions'),
            packagesFilePath: anyNamed('packagesFilePath'),
            flutterProject: anyNamed('flutterProject'),
            ipv6: false,
          ),
        )..called(1);

        final List<FlutterDevice> flutterDevices = verificationResult.captured.first as List<FlutterDevice>;
        expect(flutterDevices, hasLength(1));

        // Validate that the attach call built a flutter device with the right
        // output dill, filesystem scheme, and filesystem root.
        final FlutterDevice flutterDevice = flutterDevices.first;

        expect(flutterDevice.fileSystemScheme, filesystemScheme);
        expect(flutterDevice.fileSystemRoots, const <String>[filesystemRoot]);
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('exits when ipv6 is specified and debug-port is not', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return mockLogReader;
        });
        testDeviceManager.addDevice(device);

        final AttachCommand command = AttachCommand();
        await expectLater(
          createTestCommandRunner(command).run(<String>['attach', '--ipv6']),
          throwsToolExit(
            message: 'When the --debug-port or --debug-uri is unknown, this command determines '
                     'the value of --ipv6 on its own.',
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },);

      testUsingContext('exits when observatory-port is specified and debug-port is not', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          return mockLogReader;
        });
        testDeviceManager.addDevice(device);

        final AttachCommand command = AttachCommand();
        await expectLater(
          createTestCommandRunner(command).run(<String>['attach', '--observatory-port', '100']),
          throwsToolExit(
            message: 'When the --debug-port or --debug-uri is unknown, this command does not use '
                     'the value of --observatory-port.',
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },);
    });

    testUsingContext('selects specified target', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
      final MockPortForwarder portForwarder = MockPortForwarder();
      final MockAndroidDevice device = MockAndroidDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder)
        .thenReturn(portForwarder);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
        .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts)
        .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any))
        .thenAnswer((_) async => null);
      when(mockHotRunner.attach(appStartedCompleter: anyNamed('appStartedCompleter')))
        .thenAnswer((_) async => 0);
      when(mockHotRunnerFactory.build(
        any,
        target: anyNamed('target'),
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).thenReturn(mockHotRunner);
      when(mockHotRunner.exited).thenReturn(false);
      when(mockHotRunner.isWaitingForObservatory).thenReturn(false);

      testDeviceManager.addDevice(device);
      when(device.getLogReader())
        .thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          mockLogReader.addLine('Foo');
          mockLogReader.addLine(
              'Observatory listening on http://127.0.0.1:$devicePort');
          return mockLogReader;
        });
      final File foo = globals.fs.file('lib/foo.dart')
        ..createSync();

      // Delete the main.dart file to be sure that attach works without it.
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).deleteSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: mockHotRunnerFactory);
      await createTestCommandRunner(command).run(<String>['attach', '-t', foo.path, '-v']);

      verify(mockHotRunnerFactory.build(
        any,
        target: foo.path,
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('fallbacks to protocol observatory if MDNS failed on iOS', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
      final MockPortForwarder portForwarder = MockPortForwarder();
      final MockIOSDevice device = MockIOSDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder).thenReturn(portForwarder);
      when(device.getLogReader()).thenAnswer((_) => mockLogReader);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
        .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts)
        .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any))
        .thenAnswer((_) async => null);
      when(mockHotRunner.attach(appStartedCompleter: anyNamed('appStartedCompleter')))
        .thenAnswer((_) async => 0);
      when(mockHotRunnerFactory.build(
        any,
        target: anyNamed('target'),
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).thenReturn(mockHotRunner);
      when(mockHotRunner.exited).thenReturn(false);
      when(mockHotRunner.isWaitingForObservatory).thenReturn(false);

      testDeviceManager.addDevice(device);

      final File foo = globals.fs.file('lib/foo.dart')..createSync();

      // Delete the main.dart file to be sure that attach works without it.
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).deleteSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: mockHotRunnerFactory);
      await createTestCommandRunner(command).run(<String>['attach', '-t', foo.path, '-v']);

      verify(mockHotRunnerFactory.build(
        any,
        target: foo.path,
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('forwarding to given port', () {
      const int devicePort = 499;
      const int hostPort = 42;
      MockPortForwarder portForwarder;
      MockAndroidDevice device;

      setUp(() {
        portForwarder = MockPortForwarder();
        device = MockAndroidDevice();

        when(device.portForwarder)
          .thenReturn(portForwarder);
        when(portForwarder.forward(devicePort))
          .thenAnswer((_) async => hostPort);
        when(portForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(portForwarder.unforward(any))
          .thenAnswer((_) async => null);
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
        verify(portForwarder.forward(devicePort)).called(1);

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
        verify(portForwarder.forward(devicePort)).called(1);

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
          ],
        );
        await completer.future;
        verifyNever(portForwarder.forward(devicePort));

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
          ],
        );
        await completer.future;
        verifyNever(portForwarder.forward(devicePort));

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
        throwsA(isInstanceOf<ToolExit>()),
      );
      expect(testLogger.statusText, contains('No supported devices connected'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('exits when multiple devices connected', () async {
      Device aDeviceWithId(String id) {
        final MockAndroidDevice device = MockAndroidDevice();
        when(device.name).thenReturn('d$id');
        when(device.id).thenReturn(id);
        when(device.isLocalEmulator).thenAnswer((_) async => false);
        when(device.sdkNameAndVersion).thenAnswer((_) async => 'Android 46');
        return device;
      }

      final AttachCommand command = AttachCommand();
      testDeviceManager.addDevice(aDeviceWithId('xx1'));
      testDeviceManager.addDevice(aDeviceWithId('yy2'));
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsA(isInstanceOf<ToolExit>()),
      );
      expect(testLogger.statusText, contains('More than one device'));
      expect(testLogger.statusText, contains('xx1'));
      expect(testLogger.statusText, contains('yy2'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class MockHotRunner extends Mock implements HotRunner {}
class MockHotRunnerFactory extends Mock implements HotRunnerFactory {}
class MockIOSDevice extends Mock implements IOSDevice {}
class MockMDnsObservatoryDiscovery extends Mock implements MDnsObservatoryDiscovery {}
class MockPortForwarder extends Mock implements DevicePortForwarder {}

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
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    _log('[progress] $message');
    return SilentStatus(timeout: timeout, timeoutConfiguration: timeoutConfiguration)..start();
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
}

class LoggerInterrupted implements Exception {
  const LoggerInterrupted();
}

Future<void> expectLoggerInterruptEndsTask(Future<void> task, StreamLogger logger) async {
  logger.interrupt(); // an exception during the task should cause it to fail...
  try {
    await task;
    expect(false, isTrue); // (shouldn't reach here)
  } on ToolExit catch (error) {
    expect(error.exitCode, 2); // ...with exit code 2.
  }
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
    ReloadMethod reloadMethod,
    CompressionOptions compression,
    Device device,
  }) async {
    final VMService vmService = VMServiceMock();
    final VM vm = VMMock();

    when(vmService.vm).thenReturn(vm);
    when(vmService.isClosed).thenReturn(false);
    when(vmService.done).thenAnswer((_) {
      return Future<void>.value(null);
    });

    when(vm.refreshViews(waitForViews: anyNamed('waitForViews')))
      .thenAnswer((_) => Future<void>.value(null));
    when(vm.views)
      .thenReturn(<FlutterView>[FlutterViewMock()]);
    when(vm.createDevFS(any))
      .thenAnswer((_) => Future<Map<String, dynamic>>.value(<String, dynamic>{'uri': '/',}));

    return vmService;
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
      packagesFilePath: packagesFilePath,
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

class VMMock extends Mock implements VM {}
class VMServiceMock extends Mock implements VMService {}
class FlutterViewMock extends Mock implements FlutterView {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
