// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

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
      style: platform.isWindows
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

      setUp(() {
        mockLogReader = MockDeviceLogReader();
        portForwarder = MockPortForwarder();
        device = MockAndroidDevice();
        when(device.portForwarder)
          .thenReturn(portForwarder);
        when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
        when(portForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(portForwarder.unforward(any))
          .thenAnswer((_) async => null);

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
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          });
          return mockLogReader;
        });
        testDeviceManager.addDevice(device);
        final Completer<void> completer = Completer<void>();
        final StreamSubscription<String> loggerSubscription = logger.stream.listen((String message) {
          if (message == '[stdout] Done.') {
            // The "Done." message is output by the AttachCommand when it's done.
            completer.complete();
          }
        });
        final Future<void> task = createTestCommandRunner(AttachCommand()).run(<String>['attach']);
        await completer.future;
        verify(
          portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')),
        ).called(1);
        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('Fails with tool exit on bad Observatory uri', () async {
        when(device.getLogReader()).thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine('Observatory listening on http:/:/127.0.0.1:$devicePort');
          });
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
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          });
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

        final List<FlutterDevice> flutterDevices = verificationResult.captured.first;
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
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          });
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
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
          });
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

      testDeviceManager.addDevice(device);
      when(device.getLogReader())
        .thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          Timer.run(() {
            mockLogReader.addLine('Foo');
            mockLogReader.addLine(
                'Observatory listening on http://127.0.0.1:$devicePort');
          });
          return mockLogReader;
        });
      final File foo = fs.file('lib/foo.dart')
        ..createSync();

      // Delete the main.dart file to be sure that attach works without it.
      fs.file(fs.path.join('lib', 'main.dart')).deleteSync();

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
    return SilentStatus(timeout: timeout)..start();
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
  void sendNotification(String message, {String progressId}) { }
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
