// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('fuchsia device', () {
    testUsingContext('stores the requested id and name', () {
      const String deviceId = 'e80::0000:a00a:f00f:2002/3';
      const String name = 'halfbaked';
      final FuchsiaDevice device = FuchsiaDevice(deviceId, name: name);
      expect(device.id, deviceId);
      expect(device.name, name);
    });

    test('parse dev_finder output', () {
      const String example = '192.168.42.56 paper-pulp-bush-angel';
      final List<FuchsiaDevice> names = parseListDevices(example);

      expect(names.length, 1);
      expect(names.first.name, 'paper-pulp-bush-angel');
      expect(names.first.id, '192.168.42.56');
    });

    test('parse junk dev_finder output', () {
      const String example = 'junk';
      final List<FuchsiaDevice> names = parseListDevices(example);

      expect(names.length, 0);
    });

    test('default capabilities', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');

      expect(device.supportsHotReload, true);
      expect(device.supportsHotRestart, false);
      expect(device.supportsStopApp, false);
      expect(await device.stopApp(null), false);
    });
  });

  group('displays friendly error when', () {
    final MockProcessManager mockProcessManager = MockProcessManager();
    final MockProcessResult mockProcessResult = MockProcessResult();
    final MockFile mockFile = MockFile();
    when(mockProcessManager.run(
      any,
      environment: anyNamed('environment'),
      workingDirectory: anyNamed('workingDirectory'),
    )).thenAnswer((Invocation invocation) => Future<ProcessResult>.value(mockProcessResult));
    when(mockProcessResult.exitCode).thenReturn(1);
    when<String>(mockProcessResult.stdout).thenReturn('');
    when<String>(mockProcessResult.stderr).thenReturn('');
    when(mockFile.absolute).thenReturn(mockFile);
    when(mockFile.path).thenReturn('');

    final MockProcessManager emptyStdoutProcessManager = MockProcessManager();
    final MockProcessResult emptyStdoutProcessResult = MockProcessResult();
    when(emptyStdoutProcessManager.run(
      any,
      environment: anyNamed('environment'),
      workingDirectory: anyNamed('workingDirectory'),
    )).thenAnswer((Invocation invocation) => Future<ProcessResult>.value(emptyStdoutProcessResult));
    when(emptyStdoutProcessResult.exitCode).thenReturn(0);
    when<String>(emptyStdoutProcessResult.stdout).thenReturn('');
    when<String>(emptyStdoutProcessResult.stderr).thenReturn('');

    testUsingContext('No vmservices found', () async {
      final FuchsiaDevice device = FuchsiaDevice('id');
      ToolExit toolExit;
      try {
        await device.servicePorts();
      } on ToolExit catch (err) {
        toolExit = err;
      }
      expect(toolExit.message, contains('No Dart Observatories found. Are you running a debug build?'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => emptyStdoutProcessManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(
        sshConfig: mockFile,
        devFinder: mockFile,
      ),
    });

    group('device logs', () {
      const String exampleUtcLogs = '''
[2018-11-09 01:27:45][3][297950920][log] INFO: example_app(flutter): Error doing thing
[2018-11-09 01:27:58][46257][46269][foo] INFO: Using a thing
[2018-11-09 01:29:58][46257][46269][foo] INFO: Blah blah blah
[2018-11-09 01:29:58][46257][46269][foo] INFO: other_app(flutter): Do thing
[2018-11-09 01:30:02][41175][41187][bar] INFO: Invoking a bar
[2018-11-09 01:30:12][52580][52983][log] INFO: example_app(flutter): Did thing this time

  ''';
      final MockProcessManager mockProcessManager = MockProcessManager();
      final MockProcess mockProcess = MockProcess();
      Completer<int> exitCode;
      StreamController<List<int>> stdout;
      StreamController<List<int>> stderr;
      when(mockProcessManager.start(any)).thenAnswer((Invocation _) => Future<Process>.value(mockProcess));
      when(mockProcess.exitCode).thenAnswer((Invocation _) => exitCode.future);
      when(mockProcess.stdout).thenAnswer((Invocation _) => stdout.stream);
      when(mockProcess.stderr).thenAnswer((Invocation _) => stderr.stream);

      setUp(() {
        stdout = StreamController<List<int>>(sync: true);
        stderr = StreamController<List<int>>(sync: true);
        exitCode = Completer<int>();
      });

      tearDown(() {
        exitCode.complete(0);
      });

      testUsingContext('can be parsed for an app', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 2) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
      });

      testUsingContext('cuts off prior logs', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          lock.complete();
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 29, 45)),
      });

      testUsingContext('can be parsed for all apps', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader();
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 3) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:29:58.000] Flutter: Do thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
      });
    });
  });

  group(FuchsiaIsolateDiscoveryProtocol, () {
    Future<Uri> findUri(List<MockFlutterView> views, String expectedIsolateName) {
      final MockPortForwarder portForwarder = MockPortForwarder();
      final MockVMService vmService = MockVMService();
      final MockVM vm = MockVM();
      vm.vmService = vmService;
      vmService.vm = vm;
      vm.views = views;
      for (MockFlutterView view in views) {
        view.owner = vm;
      }
      final MockFuchsiaDevice fuchsiaDevice = MockFuchsiaDevice('123', portForwarder, false);
      final FuchsiaIsolateDiscoveryProtocol discoveryProtocol = FuchsiaIsolateDiscoveryProtocol(
        fuchsiaDevice,
        expectedIsolateName,
        (Uri uri) async => vmService,
        true // only poll once.
      );
      when(fuchsiaDevice.servicePorts()).thenAnswer((Invocation invocation) async => <int>[1]);
      when(portForwarder.forward(1)).thenAnswer((Invocation invocation) async => 2);
      when(vmService.getVM()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(vmService.refreshViews()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(vmService.httpAddress).thenReturn(Uri.parse('example'));
      return discoveryProtocol.uri;
    }
    testUsingContext('can find flutter view with matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Uri uri = await findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
        MockFlutterView(MockIsolate('wrong name')), // wrong name.
        MockFlutterView(MockIsolate(expectedIsolateName)), // matching name.
      ], expectedIsolateName);
      expect(uri.toString(), 'http://${InternetAddress.loopbackIPv4.address}:0/');
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
    });

    testUsingContext('can handle flutter view without matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
        MockFlutterView(MockIsolate('wrong name')), // wrong name.
      ], expectedIsolateName);
      expect(uri, throwsException);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
    });

    testUsingContext('can handle non flutter view', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
      ], expectedIsolateName);
      expect(uri, throwsException);
    }, overrides: <Type, Generator>{
      Logger: () => StdoutLogger(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}

class MockFile extends Mock implements File {}

class MockProcess extends Mock implements Process {}

class MockFuchsiaDevice extends Mock implements FuchsiaDevice {
  MockFuchsiaDevice(this.id, this.portForwarder, this.ipv6);

  @override
  final bool ipv6;
  @override
  final String id;
  @override
  final DevicePortForwarder portForwarder;
}

class MockPortForwarder extends Mock implements DevicePortForwarder {}

class MockVMService extends Mock implements VMService {
  @override
  VM vm;
}

class MockVM extends Mock implements VM {
  @override
  VMService vmService;

  @override
  List<FlutterView> views;
}

class MockFlutterView extends Mock implements FlutterView {
  MockFlutterView(this.uiIsolate);

  @override
  final Isolate uiIsolate;

  @override
  ServiceObjectOwner owner;
}

class MockIsolate extends Mock implements Isolate {
  MockIsolate(this.name);

  @override
  final String name;
}
