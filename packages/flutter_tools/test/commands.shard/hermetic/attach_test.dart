// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_vm_services.dart';
import '../../src/fakes.dart';
import '../../src/mocks.dart';
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
      MockPortForwarder portForwarder;
      MockDartDevelopmentService mockDds;
      MockAndroidDevice device;

      setUp(() {
        fakeLogReader = FakeDeviceLogReader();
        portForwarder = MockPortForwarder();
        device = MockAndroidDevice();
        mockDds = MockDartDevelopmentService();
        when(device.portForwarder)
          .thenReturn(portForwarder);
        when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
        when(portForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(portForwarder.unforward(any))
          .thenAnswer((_) async {});
        when(device.dds).thenReturn(mockDds);
        final Completer<void> noopCompleter = Completer<void>();
        when(mockDds.startDartDevelopmentService(any, any, false, any, logger: anyNamed('logger'))).thenReturn(null);
        when(mockDds.uri).thenReturn(Uri.parse('http://localhost:8181'));
        when(mockDds.done).thenAnswer((_) => noopCompleter.future);

        // We cannot add the device to a device manager because that is
        // only enabled by the context of each testUsingContext call.
        //
        // Instead each test will add the device to the device manager
        // on its own.
      });

      tearDown(() {
        fakeLogReader.dispose();
      });

      testUsingContext('finds observatory port and forwards', () async {
        when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
          .thenAnswer((_) {
            // Now that the reader is used, start writing messages to it.
            fakeLogReader.addLine('Foo');
            fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
            return fakeLogReader;
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
        await fakeLogReader.dispose();
        await expectLoggerInterruptEndsTask(task, logger);
        await loggerSubscription.cancel();
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('Fails with tool exit on bad Observatory uri', () async {
        when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
          .thenAnswer((_) {
            // Now that the reader is used, start writing messages to it.
            fakeLogReader.addLine('Foo');
            fakeLogReader.addLine('Observatory listening on http:/:/127.0.0.1:$devicePort');
            fakeLogReader.dispose();
            return fakeLogReader;
          });
        testDeviceManager.addDevice(device);
        expect(createTestCommandRunner(AttachCommand()).run(<String>['attach']),
               throwsToolExit());
      }, overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
      });

      testUsingContext('accepts filesystem parameters', () async {
        when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
          .thenAnswer((_) {
            // Now that the reader is used, start writing messages to it.
            fakeLogReader.addLine('Foo');
            fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
            return fakeLogReader;
          });
        testDeviceManager.addDevice(device);

        const String filesystemScheme = 'foo';
        const String filesystemRoot = '/build-output/';
        const String projectRoot = '/build-output/project-root';
        const String outputDill = '/tmp/output.dill';

        final MockHotRunner mockHotRunner = MockHotRunner();
        when(mockHotRunner.attach(
          appStartedCompleter: anyNamed('appStartedCompleter'),
          allowExistingDdsInstance: true,
          enableDevTools: anyNamed('enableDevTools'),
        )).thenAnswer((_) async => 0);
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
        when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
          .thenAnswer((_) {
            // Now that the reader is used, start writing messages to it.
            fakeLogReader.addLine('Foo');
            fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
            return fakeLogReader;
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
        when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
          .thenAnswer((_) {
            // Now that the reader is used, start writing messages to it.
            fakeLogReader.addLine('Foo');
            fakeLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
            return fakeLogReader;
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
      final FakeDeviceLogReader fakeLogReader = FakeDeviceLogReader();
      final MockPortForwarder portForwarder = MockPortForwarder();
      final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
      final MockAndroidDevice device = MockAndroidDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder)
        .thenReturn(portForwarder);
      when(device.dds)
        .thenReturn(mockDds);
      final Completer<void> noopCompleter = Completer<void>();
      when(mockDds.done).thenAnswer((_) => noopCompleter.future);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
        .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts)
        .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any))
        .thenAnswer((_) async {});
      when(mockHotRunner.attach(
        appStartedCompleter: anyNamed('appStartedCompleter'),
        allowExistingDdsInstance: true,
        enableDevTools: anyNamed('enableDevTools'),
      )).thenAnswer((_) async => 0);
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
      when(mockDds.startDartDevelopmentService(any, any, false, any, logger: anyNamed('logger'))).thenReturn(null);
      when(mockDds.uri).thenReturn(Uri.parse('http://localhost:8181'));

      testDeviceManager.addDevice(device);
      when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
        .thenAnswer((_) {
          // Now that the reader is used, start writing messages to it.
          fakeLogReader.addLine('Foo');
          fakeLogReader.addLine(
              'Observatory listening on http://127.0.0.1:$devicePort');
          return fakeLogReader;
        });
      final File foo = globals.fs.file('lib/foo.dart')
        ..createSync();

      // Delete the main.dart file to be sure that attach works without it.
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).deleteSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: mockHotRunnerFactory);
      await createTestCommandRunner(command).run(<String>[
        'attach',
        '-t',
        foo.path,
        '-v',
        '--device-user',
        '10',
        '--device-timeout',
        '15',
      ]);
      final VerificationResult verificationResult = verify(
        mockHotRunnerFactory.build(
          captureAny,
          target: foo.path,
          debuggingOptions: anyNamed('debuggingOptions'),
          packagesFilePath: anyNamed('packagesFilePath'),
          flutterProject: anyNamed('flutterProject'),
          ipv6: false,
        ),
      )..called(1);

      final List<FlutterDevice> flutterDevices = verificationResult.captured.first as List<FlutterDevice>;
      expect(flutterDevices, hasLength(1));
      final FlutterDevice flutterDevice = flutterDevices.first;
      expect(flutterDevice.userIdentifier, '10');
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('fallbacks to protocol observatory if MDNS failed on iOS', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final FakeDeviceLogReader fakeLogReader = FakeDeviceLogReader();
      final MockPortForwarder portForwarder = MockPortForwarder();
      final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
      final MockIOSDevice device = MockIOSDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder)
        .thenReturn(portForwarder);
      when(device.dds)
        .thenReturn(mockDds);
      final Completer<void> noopCompleter = Completer<void>();
      when(mockDds.done).thenAnswer((_) => noopCompleter.future);
      when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
        .thenAnswer((_) => fakeLogReader);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
        .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts)
        .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any))
        .thenAnswer((_) async {});
      when(mockHotRunner.attach(
        appStartedCompleter: anyNamed('appStartedCompleter'),
        allowExistingDdsInstance: true,
        enableDevTools: anyNamed('enableDevTools'),
      )).thenAnswer((_) async => 0);
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
      when(mockDds.startDartDevelopmentService(any, any, false, any, logger: anyNamed('logger'))).thenReturn(null);
      when(mockDds.uri).thenReturn(Uri.parse('http://localhost:8181'));

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
    }, skip: Platform.isWindows); // mDNS does not work on Windows.

    group('forwarding to given port', () {
      const int devicePort = 499;
      const int hostPort = 42;
      MockPortForwarder portForwarder;
      MockAndroidDevice device;

      setUp(() {
        portForwarder = MockPortForwarder();
        final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
        device = MockAndroidDevice();

        when(device.portForwarder)
          .thenReturn(portForwarder);
        when(portForwarder.forward(devicePort))
          .thenAnswer((_) async => hostPort);
        when(portForwarder.forwardedPorts)
          .thenReturn(<ForwardedPort>[ForwardedPort(hostPort, devicePort)]);
        when(portForwarder.unforward(any))
          .thenAnswer((_) async {});
        when(device.dds)
          .thenReturn(mockDds);
        when(mockDds.startDartDevelopmentService(any, any, any, any, logger: anyNamed('logger')))
          .thenReturn(null);
        when(mockDds.uri).thenReturn(Uri.parse('http://localhost:8181'));
        final Completer<void> noopCompleter = Completer<void>();
        when(mockDds.done).thenAnswer((_) => noopCompleter.future);
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
            // Ensure DDS doesn't use hostPort by binding to a random port.
            '--dds-port',
            '0',
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
            // Ensure DDS doesn't use hostPort by binding to a random port.
            '--dds-port',
            '0',
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
        throwsToolExit(),
      );
      expect(testLogger.statusText, containsIgnoringWhitespace('No supported devices connected'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('fails when targeted device is not Android with --device-user', () async {
      final MockIOSDevice device = MockIOSDevice();
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
      Device aDeviceWithId(String id) {
        final MockAndroidDevice device = MockAndroidDevice();
        when(device.name).thenReturn('d$id');
        when(device.id).thenReturn(id);
        when(device.isLocalEmulator).thenAnswer((_) async => false);
        when(device.sdkNameAndVersion).thenAnswer((_) async => 'Android 46');
        when(device.targetPlatformDisplayName)
            .thenAnswer((_) async => 'android');

        return device;
      }

      final AttachCommand command = AttachCommand();
      testDeviceManager.addDevice(aDeviceWithId('xx1'));
      testDeviceManager.addDevice(aDeviceWithId('yy2'));
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsToolExit(),
      );
      expect(testLogger.statusText, containsIgnoringWhitespace('More than one device'));
      expect(testLogger.statusText, contains('xx1'));
      expect(testLogger.statusText, contains('yy2'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Catches service disappeared error', () async {
      final MockAndroidDevice device = MockAndroidDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder).thenReturn(const NoOpDevicePortForwarder());

      when(mockHotRunner.attach(
        appStartedCompleter: anyNamed('appStartedCompleter'),
        allowExistingDdsInstance: true,
        enableDevTools: anyNamed('enableDevTools'),
      )).thenAnswer((_) async {
        await null;
        throw vm_service.RPCError('flutter._listViews', RPCErrorCodes.kServiceDisappeared, '');
      });
      when(mockHotRunnerFactory.build(
        any,
        target: anyNamed('target'),
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).thenReturn(mockHotRunner);

      testDeviceManager.addDevice(device);
      when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
        .thenAnswer((_) {
          return NoOpDeviceLogReader('test');
        });
      testFileSystem.file('lib/main.dart').createSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: mockHotRunnerFactory);
      await expectLater(createTestCommandRunner(command).run(<String>[
        'attach',
      ]), throwsToolExit(message: 'Lost connection to device.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does not catch generic RPC error', () async {
      final MockAndroidDevice device = MockAndroidDevice();
      final MockHotRunner mockHotRunner = MockHotRunner();
      final MockHotRunnerFactory mockHotRunnerFactory = MockHotRunnerFactory();
      when(device.portForwarder).thenReturn(const NoOpDevicePortForwarder());

      when(mockHotRunner.attach(
        appStartedCompleter: anyNamed('appStartedCompleter'),
        allowExistingDdsInstance: true,
        enableDevTools: anyNamed('enableDevTools'),
      )).thenAnswer((_) async {
        await null;
        throw vm_service.RPCError('flutter._listViews', RPCErrorCodes.kInvalidParams, '');
      });
      when(mockHotRunnerFactory.build(
        any,
        target: anyNamed('target'),
        debuggingOptions: anyNamed('debuggingOptions'),
        packagesFilePath: anyNamed('packagesFilePath'),
        flutterProject: anyNamed('flutterProject'),
        ipv6: false,
      )).thenReturn(mockHotRunner);

      testDeviceManager.addDevice(device);
      when(device.getLogReader(includePastLogs: anyNamed('includePastLogs')))
        .thenAnswer((_) {
          return NoOpDeviceLogReader('test');
        });
      testFileSystem.file('lib/main.dart').createSync();

      final AttachCommand command = AttachCommand(hotRunnerFactory: mockHotRunnerFactory);
      await expectLater(createTestCommandRunner(command).run(<String>[
        'attach',
      ]), throwsA(isA<vm_service.RPCError>()));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class MockHotRunner extends Mock implements HotRunner {}
class MockHotRunnerFactory extends Mock implements HotRunnerFactory {}
class MockIOSDevice extends Mock implements IOSDevice {}
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

class MockDartDevelopmentService extends Mock implements DartDevelopmentService {}
