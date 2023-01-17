// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_ffx.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_vm_services.dart';

final vm_service.Isolate fakeIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[],
  livePorts: 0,
  name: 'wrong name',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

void main() {
  group('fuchsia device', () {
    MemoryFileSystem memoryFileSystem;
    File sshConfig;
    FakeProcessManager processManager;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      sshConfig = memoryFileSystem.file('ssh_config')..writeAsStringSync('\n');
      processManager = FakeProcessManager.empty();
    });

    testWithoutContext('stores the requested id and name', () {
      const String deviceId = 'e80::0000:a00a:f00f:2002/3';
      const String name = 'halfbaked';
      final FuchsiaDevice device = FuchsiaDevice(deviceId, name: name);

      expect(device.id, deviceId);
      expect(device.name, name);
    });

    testWithoutContext('supports all runtime modes besides jitRelease', () {
      const String deviceId = 'e80::0000:a00a:f00f:2002/3';
      const String name = 'halfbaked';
      final FuchsiaDevice device = FuchsiaDevice(deviceId, name: name);

      expect(device.supportsRuntimeMode(BuildMode.debug), true);
      expect(device.supportsRuntimeMode(BuildMode.profile), true);
      expect(device.supportsRuntimeMode(BuildMode.release), true);
      expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
    });

    testWithoutContext('lists nothing when workflow cannot list devices', () async {
      final FakeFuchsiaWorkflow fuchsiaWorkflow = FakeFuchsiaWorkflow(canListDevices: false);
      final FuchsiaDevices fuchsiaDevices = FuchsiaDevices(
        platform: FakePlatform(),
        fuchsiaSdk: FakeFuchsiaSdk(devices: 'ignored'),
        fuchsiaWorkflow: fuchsiaWorkflow,
        logger: BufferLogger.test(),
      );

      expect(fuchsiaDevices.canListAnything, false);
      expect(await fuchsiaDevices.pollingGetDevices(), isEmpty);
    });

    testWithoutContext('can parse ffx output for single device', () async {
      final FakeFuchsiaWorkflow fuchsiaWorkflow = FakeFuchsiaWorkflow();
      final FakeFuchsiaSdk fuchsiaSdk = FakeFuchsiaSdk(devices: '2001:0db8:85a3:0000:0000:8a2e:0370:7334 paper-pulp-bush-angel');
      final FuchsiaDevices fuchsiaDevices = FuchsiaDevices(
        platform: FakePlatform(environment: <String, String>{}),
        fuchsiaSdk: fuchsiaSdk,
        fuchsiaWorkflow: fuchsiaWorkflow,
        logger: BufferLogger.test(),
      );

      final Device device = (await fuchsiaDevices.pollingGetDevices()).single;

      expect(device.name, 'paper-pulp-bush-angel');
      expect(device.id, '192.168.42.10');
    });

    testWithoutContext('can parse ffx output for multiple devices', () async {
      final FakeFuchsiaWorkflow fuchsiaWorkflow = FakeFuchsiaWorkflow();
      final FakeFuchsiaSdk fuchsiaSdk = FakeFuchsiaSdk(devices:
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334 paper-pulp-bush-angel\n'
        '2001:0db8:85a3:0000:0000:8a2e:0370:7335 foo-bar-fiz-buzz'
      );
      final FuchsiaDevices fuchsiaDevices = FuchsiaDevices(
        platform: FakePlatform(),
        fuchsiaSdk: fuchsiaSdk,
        fuchsiaWorkflow: fuchsiaWorkflow,
        logger: BufferLogger.test(),
      );

      final List<Device> devices = await fuchsiaDevices.pollingGetDevices();

      expect(devices.first.name, 'paper-pulp-bush-angel');
      expect(devices.first.id, '192.168.42.10');
      expect(devices.last.name, 'foo-bar-fiz-buzz');
      expect(devices.last.id, '192.168.42.10');
    });

    testWithoutContext('can parse junk output from ffx', () async {
      final FakeFuchsiaWorkflow fuchsiaWorkflow = FakeFuchsiaWorkflow(canListDevices: false);
      final FakeFuchsiaSdk fuchsiaSdk = FakeFuchsiaSdk(devices: 'junk');
      final FuchsiaDevices fuchsiaDevices = FuchsiaDevices(
        platform: FakePlatform(),
        fuchsiaSdk: fuchsiaSdk,
        fuchsiaWorkflow: fuchsiaWorkflow,
        logger: BufferLogger.test(),
      );

      final List<Device> devices = await fuchsiaDevices.pollingGetDevices();

      expect(devices, isEmpty);
    });

    testUsingContext('disposing device disposes the portForwarder', () async {
      final FakePortForwarder portForwarder = FakePortForwarder();
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      device.portForwarder = portForwarder;
      await device.dispose();

      expect(portForwarder.disposed, true);
    });

    testWithoutContext('default capabilities', () async {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      final FlutterProject project = FlutterProject.fromDirectoryTest(memoryFileSystem.currentDirectory);
      memoryFileSystem.directory('fuchsia').createSync(recursive: true);
      memoryFileSystem.file('pubspec.yaml').createSync();

      expect(device.supportsHotReload, true);
      expect(device.supportsHotRestart, false);
      expect(device.supportsFlutterExit, false);
      expect(device.isSupportedForProject(project), true);
    });

    test('is ephemeral', () {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(device.ephemeral, true);
    });

    testWithoutContext('supported for project', () async {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      final FlutterProject project = FlutterProject.fromDirectoryTest(memoryFileSystem.currentDirectory);
      memoryFileSystem.directory('fuchsia').createSync(recursive: true);
      memoryFileSystem.file('pubspec.yaml').createSync();

      expect(device.isSupportedForProject(project), true);
    });

    testWithoutContext('not supported for project', () async {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      final FlutterProject project = FlutterProject.fromDirectoryTest(memoryFileSystem.currentDirectory);
      memoryFileSystem.file('pubspec.yaml').createSync();

      expect(device.isSupportedForProject(project), false);
    });

    testUsingContext('targetPlatform does not throw when sshConfig is missing', () async {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(await device.targetPlatform, TargetPlatform.fuchsia_arm64);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });

    testUsingContext('targetPlatform arm64 works', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', '123', 'uname -m'],
        stdout: 'aarch64',
      ));

      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      expect(await device.targetPlatform, TargetPlatform.fuchsia_arm64);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });

    testUsingContext('targetPlatform x64 works', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', '123', 'uname -m'],
        stdout: 'x86_64',
      ));

      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');
      expect(await device.targetPlatform, TargetPlatform.fuchsia_x64);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });

    testUsingContext('hostAddress parsing works', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', 'id', r'echo $SSH_CONNECTION'],
        stdout: 'fe80::8c6c:2fff:fe3d:c5e1%ethp0003 50666 fe80::5054:ff:fe63:5e7a%ethp0003 22',
      ));

      final FuchsiaDevice device = FuchsiaDevice('id', name: 'device');
      expect(await device.hostAddress, 'fe80::8c6c:2fff:fe3d:c5e1%25ethp0003');
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });

    testUsingContext('hostAddress parsing throws tool error on failure', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', 'id', r'echo $SSH_CONNECTION'],
        exitCode: 1,
      ));

      final FuchsiaDevice device = FuchsiaDevice('id', name: 'device');
      await expectLater(() => device.hostAddress, throwsToolExit());
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });

    testUsingContext('hostAddress parsing throws tool error on empty response', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', 'id', r'echo $SSH_CONNECTION'],
      ));

      final FuchsiaDevice device = FuchsiaDevice('id', name: 'device');
      expect(() async => device.hostAddress, throwsToolExit());
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
      ProcessManager: () => processManager,
    });
  });

  group('displays friendly error when', () {
    File artifactFile;
    FakeProcessManager processManager;

    setUp(() {
      processManager = FakeProcessManager.empty();
      artifactFile = MemoryFileSystem.test().file('artifact');
    });

    testUsingContext('No vmservices found', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/artifact', 'id', 'find /hub -name vmservice-port'],
      ));
      final FuchsiaDevice device = FuchsiaDevice('id', name: 'device');

      await expectLater(device.servicePorts, throwsToolExit(message: 'No Dart Observatories found. Are you running a debug build?'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(
        sshConfig: artifactFile,
        ffx: artifactFile,
      ),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
    });

    group('device logs', () {
      const String exampleUtcLogs = '''
[2018-11-09 01:27:45][3][297950920][log] INFO: example_app.cmx(flutter): Error doing thing
[2018-11-09 01:27:58][46257][46269][foo] INFO: Using a thing
[2018-11-09 01:29:58][46257][46269][foo] INFO: Blah blah blah
[2018-11-09 01:29:58][46257][46269][foo] INFO: other_app.cmx(flutter): Do thing
[2018-11-09 01:30:02][41175][41187][bar] INFO: Invoking a bar
[2018-11-09 01:30:12][52580][52983][log] INFO: example_app.cmx(flutter): Did thing this time

  ''';
      FakeProcessManager processManager;
      File ffx;
      File sshConfig;

      setUp(() {
       processManager = FakeProcessManager.empty();
        final FileSystem memoryFileSystem = MemoryFileSystem.test();
        ffx = memoryFileSystem.file('ffx')..writeAsStringSync('\n');
        sshConfig = memoryFileSystem.file('ssh_config')..writeAsStringSync('\n');
      });

      testUsingContext('can be parsed for an app', () async {
        final Completer<void> lock = Completer<void>();
        processManager.addCommand(FakeCommand(
          command: const <String>['ssh', '-F', '/ssh_config', 'id', 'log_listener --clock Local'],
          stdout: exampleUtcLogs,
          completer: lock,
        ));
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 2) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        await lock.future;
        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
        FuchsiaArtifacts: () =>
            FuchsiaArtifacts(sshConfig: sshConfig, ffx: ffx),
      });

      testUsingContext('cuts off prior logs', () async {
        final Completer<void> lock = Completer<void>();
        processManager.addCommand(FakeCommand(
          command: const <String>['ssh', '-F', '/ssh_config', 'id', 'log_listener --clock Local'],
          stdout: exampleUtcLogs,
          completer: lock,
        ));
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        reader.logLines.listen((String line) {
          logLines.add(line);
          lock.complete();
        });
        expect(logLines, isEmpty);

        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 29, 45)),
        FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig, ffx: ffx),
      });

      testUsingContext('can be parsed for all apps', () async {
        final Completer<void> lock = Completer<void>();
        processManager.addCommand(FakeCommand(
          command: const <String>['ssh', '-F', '/ssh_config', 'id', 'log_listener --clock Local'],
          stdout: exampleUtcLogs,
          completer: lock,
        ));
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader();
        final List<String> logLines = <String>[];
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 3) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:29:58.000] Flutter: Do thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
        FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig, ffx: ffx),
      });
    });
  });

  group('screenshot', () {
    FakeProcessManager processManager;

    setUp(() {
      processManager = FakeProcessManager.empty();
    });

    testUsingContext('is supported on posix platforms', () {
      final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
      expect(device.supportsScreenshot, true);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(),
    });

    testUsingContext('is not supported on Windows', () {
      final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');

      expect(device.supportsScreenshot, false);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(
        operatingSystem: 'windows',
      ),
    });

    test("takeScreenshot throws if file isn't .ppm", () async {
      final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
      await expectLater(
        () => device.takeScreenshot(globals.fs.file('file.invalid')),
        throwsA(isA<Exception>().having(
          (Exception exception) => exception.toString(),
          'message',
          contains('file.invalid must be a .ppm file')
        )),
      );
    });

    testUsingContext('takeScreenshot throws if screencap failed', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'screencap > /tmp/screenshot.ppm',
        ],
        exitCode: 1,
        stderr: '<error-message>'
      ));
      final FuchsiaDevice device = FuchsiaDevice('0.0.0.0', name: 'tester');

      await expectLater(
        () => device.takeScreenshot(globals.fs.file('file.ppm')),
        throwsA(isA<Exception>().having(
          (Exception exception) => exception.toString(),
          'message',
          contains('Could not take a screenshot on device tester:\n<error-message>')
        )),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FUCHSIA_SSH_CONFIG': '/fuchsia/out/default/.ssh',
        },
      ),
    });

    testUsingContext('takeScreenshot throws if scp failed', () async {
      final FuchsiaDevice device = FuchsiaDevice('0.0.0.0', name: 'tester');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'screencap > /tmp/screenshot.ppm',
        ],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'scp',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0:/tmp/screenshot.ppm',
          'file.ppm',
        ],
        exitCode: 1,
        stderr: '<error-message>',
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'rm /tmp/screenshot.ppm',
        ],
      ));

      await expectLater(
        () => device.takeScreenshot(globals.fs.file('file.ppm')),
        throwsA(isA<Exception>().having(
          (Exception exception) => exception.toString(),
          'message',
          contains('Failed to copy screenshot from device:\n<error-message>')
        )),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FUCHSIA_SSH_CONFIG': '/fuchsia/out/default/.ssh',
        },
      ),
    });

    testUsingContext("takeScreenshot prints error if can't delete file from device", () async {
      final FuchsiaDevice device = FuchsiaDevice('0.0.0.0', name: 'tester');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'screencap > /tmp/screenshot.ppm',
        ],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'scp',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0:/tmp/screenshot.ppm',
          'file.ppm',
        ],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'rm /tmp/screenshot.ppm',
        ],
        exitCode: 1,
        stderr: '<error-message>',
      ));

      await device.takeScreenshot(globals.fs.file('file.ppm'));
      expect(
        testLogger.errorText,
        contains('Failed to delete screenshot.ppm from the device:\n<error-message>'),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FUCHSIA_SSH_CONFIG': '/fuchsia/out/default/.ssh',
        },
      ),
    }, testOn: 'posix');

    testUsingContext('takeScreenshot returns', () async {
      final FuchsiaDevice device = FuchsiaDevice('0.0.0.0', name: 'tester');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'screencap > /tmp/screenshot.ppm',
        ],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'scp',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0:/tmp/screenshot.ppm',
          'file.ppm',
        ],
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'ssh',
          '-F',
          '/fuchsia/out/default/.ssh',
          '0.0.0.0',
          'rm /tmp/screenshot.ppm',
        ],
      ));

      expect(() => device.takeScreenshot(globals.fs.file('file.ppm')), returnsNormally);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FUCHSIA_SSH_CONFIG': '/fuchsia/out/default/.ssh',
        },
      ),
    });
  });

  group('portForwarder', () {
    FakeProcessManager processManager;
    File sshConfig;

    setUp(() {
      processManager = FakeProcessManager.empty();
      sshConfig = MemoryFileSystem.test().file('irrelevant')..writeAsStringSync('\n');
    });

    testUsingContext('`unforward` prints stdout and stderr if ssh command failed', () async {
      final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/irrelevant', '-O', 'cancel', '-vvv', '-L', '0:127.0.0.1:1', 'id'],
        exitCode: 1,
        stdout: '<stdout>',
        stderr: '<stderr>',
      ));

      await expectLater(
        () => device.portForwarder.unforward(ForwardedPort(/*hostPort=*/ 0, /*devicePort=*/ 1)),
        throwsToolExit(message: 'Unforward command failed:\nstdout: <stdout>\nstderr: <stderr>'),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
    });
  });


  group('FuchsiaIsolateDiscoveryProtocol', () {
    Future<Uri> findUri(List<FlutterView> views, String expectedIsolateName) async {
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          FakeVmServiceRequest(
            method: kListViewsMethod,
            jsonResponse: <String, Object>{
              'views': <Object>[
                for (FlutterView view in views)
                  view.toJson(),
              ],
            },
          ),
        ],
        httpAddress: Uri.parse('example'),
      );
      final MockFuchsiaDevice fuchsiaDevice = MockFuchsiaDevice('123', const NoOpDevicePortForwarder(), false);
      final FuchsiaIsolateDiscoveryProtocol discoveryProtocol =
        FuchsiaIsolateDiscoveryProtocol(
        fuchsiaDevice,
        expectedIsolateName,
        (Uri uri) async => fakeVmServiceHost.vmService,
        (Device device, Uri uri, bool enableServiceAuthCodes) => null,
        true, // only poll once.
      );
      return discoveryProtocol.uri;
    }

    testUsingContext('can find flutter view with matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Uri uri = await findUri(<FlutterView>[
        // no ui isolate.
        FlutterView(id: '1', uiIsolate: fakeIsolate),
        // wrong name.
        FlutterView(
          id: '2',
          uiIsolate: vm_service.Isolate.parse(<String, dynamic>{
            ...fakeIsolate.toJson(),
            'name': 'Wrong name',
          }),
        ),
        // matching name.
        FlutterView(
          id: '3',
          uiIsolate: vm_service.Isolate.parse(<String, dynamic>{
             ...fakeIsolate.toJson(),
            'name': expectedIsolateName,
          }),
        ),
      ], expectedIsolateName);

      expect(uri.toString(), 'http://${InternetAddress.loopbackIPv4.address}:0/');
    });

    testUsingContext('can handle flutter view without matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<FlutterView>[
        // no ui isolate.
        FlutterView(id: '1', uiIsolate: fakeIsolate),
        // wrong name.
        FlutterView(id: '2', uiIsolate: vm_service.Isolate.parse(<String, Object>{
           ...fakeIsolate.toJson(),
          'name': 'wrong name',
        })),
      ], expectedIsolateName);

      expect(uri, throwsException);
    });

    testUsingContext('can handle non flutter view', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<FlutterView>[
        FlutterView(id: '1', uiIsolate: fakeIsolate), // no ui isolate.
      ], expectedIsolateName);

      expect(uri, throwsException);
    });
  });

  testUsingContext('Correct flutter runner', () async {
    final Cache cache = Cache.test(
      processManager: FakeProcessManager.any(),
    );
    final FileSystem fileSystem = MemoryFileSystem.test();
    final CachedArtifacts artifacts = CachedArtifacts(
      cache: cache,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      operatingSystemUtils: globals.os,
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.debug,
      ),
      contains('flutter_jit_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.profile,
      ),
      contains('flutter_aot_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.release,
      ),
      contains('flutter_aot_product_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.jitRelease,
      ),
      contains('flutter_jit_product_runner'),
    );
  });

  group('sdkNameAndVersion: ', () {
    File sshConfig;
    FakeProcessManager processManager;

    setUp(() {
      sshConfig = MemoryFileSystem.test().file('ssh_config')..writeAsStringSync('\n');
      processManager = FakeProcessManager.empty();
    });

    testUsingContext('does not throw on non-existent ssh config', () async {
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(await device.sdkNameAndVersion, equals('Fuchsia'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
    });

    testUsingContext('returns what we get from the device on success', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', '123', 'cat /pkgfs/packages/build-info/0/data/version'],
        stdout: 'version'
      ));
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(await device.sdkNameAndVersion, equals('Fuchsia version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
    });

    testUsingContext('returns "Fuchsia" when device command fails', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', '123', 'cat /pkgfs/packages/build-info/0/data/version'],
        exitCode: 1,
      ));
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(await device.sdkNameAndVersion, equals('Fuchsia'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
    });

    testUsingContext('returns "Fuchsia" when device gives an empty result', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['ssh', '-F', '/ssh_config', '123', 'cat /pkgfs/packages/build-info/0/data/version'],
      ));
      final FuchsiaDevice device = FuchsiaDevice('123', name: 'device');

      expect(await device.sdkNameAndVersion, equals('Fuchsia'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(),
    });
  });
}

class FuchsiaModulePackage extends ApplicationPackage {
  FuchsiaModulePackage({@required this.name}) : super(id: name);

  @override
  final String name;
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class MockFuchsiaDevice extends Fake implements FuchsiaDevice {
  MockFuchsiaDevice(this.id, this.portForwarder, this._ipv6);

  final bool _ipv6;

  @override
  bool get ipv6 => _ipv6;

  @override
  final String id;

  @override
  final DevicePortForwarder portForwarder;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia_arm64;

  @override
  String get name => 'fuchsia';

  @override
  Future<List<int>> servicePorts() async => <int>[1];

  @override
  DartDevelopmentService get dds => FakeDartDevelopmentService();
}

class FakePortForwarder extends Fake implements DevicePortForwarder {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeFuchsiaFfx implements FuchsiaFfx {
  @override
  Future<List<String>> list({Duration timeout}) async {
    return <String>['192.168.42.172 scare-cable-skip-ffx'];
  }

  @override
  Future<String> resolve(String deviceName) async {
    return '192.168.42.10';
  }
}

class FakeFuchsiaSdk extends Fake implements FuchsiaSdk {
  FakeFuchsiaSdk({
    FuchsiaPM pm,
    FuchsiaKernelCompiler compiler,
    FuchsiaFfx ffx,
    String devices,
  }) : fuchsiaPM = pm,
       fuchsiaKernelCompiler = compiler,
       fuchsiaFfx = ffx ?? FakeFuchsiaFfx(),
       _devices = devices;

  @override
  final FuchsiaPM fuchsiaPM;

  @override
  final FuchsiaKernelCompiler fuchsiaKernelCompiler;

  @override
  final FuchsiaFfx fuchsiaFfx;

  final String _devices;

  @override
  Future<String> listDevices({Duration timeout}) async {
    return _devices;
  }
}

class FakeDartDevelopmentService extends Fake implements DartDevelopmentService {
  @override
  Future<void> startDartDevelopmentService(
    Uri observatoryUri, {
    @required Logger logger,
    int hostPort,
    bool ipv6,
    bool disableServiceAuthCodes,
    bool cacheStartupProfile = false,
  }) async {}

  @override
  Uri get uri => Uri.parse('example');
}

class FakeFuchsiaWorkflow implements FuchsiaWorkflow {
  FakeFuchsiaWorkflow({
    this.appliesToHostPlatform = true,
    this.canLaunchDevices = true,
    this.canListDevices = true,
    this.canListEmulators = true,
  });

  @override
  bool appliesToHostPlatform;

  @override
  bool canLaunchDevices;

  @override
  bool canListDevices;

  @override
  bool canListEmulators;
}
