// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

    test('parse netls log output', () {
      const String example = 'device lilia-shore-only-last (fe80::0000:a00a:f00f:2002/3)';
      final List<String> names = parseFuchsiaDeviceOutput(example);

      expect(names.length, 1);
      expect(names.first, 'lilia-shore-only-last');
    });

    test('parse ls tmp/dart.servies output', () {
      const String example = '''
d  2          0 .
'-  1          0 36780
''';
      final List<int> ports = parseFuchsiaDartPortOutput(example);
      expect(ports.length, 1);
      expect(ports.single, 36780);
    });
  });

  group('displays friendly error when', () {
    final MockProcessManager mockProcessManager = MockProcessManager();
    final MockProcessResult mockProcessResult = MockProcessResult();
    final MockFuchsiaArtifacts mockFuchsiaArtifacts = MockFuchsiaArtifacts();
    final MockFile mockFile = MockFile();
    when(mockProcessManager.run(
      any,
      environment: anyNamed('environment'),
      workingDirectory: anyNamed('workingDirectory'),
    )).thenAnswer((Invocation invocation) => Future<ProcessResult>.value(mockProcessResult));
    when(mockProcessResult.exitCode).thenReturn(1);
    when<String>(mockProcessResult.stdout).thenReturn('');
    when<String>(mockProcessResult.stderr).thenReturn('ls: lstat /tmp/dart.services: No such file or directory');
    when(mockFuchsiaArtifacts.sshConfig).thenReturn(mockFile);
    when(mockFile.absolute).thenReturn(mockFile);
    when(mockFile.path).thenReturn('');

    testUsingContext('No BUILD_DIR set', () async {
      final FuchsiaDevice device = FuchsiaDevice('id');
      ToolExit toolExit;
      try {
        await device.servicePorts();
      } on ToolExit catch (err) {
        toolExit = err;
      }
      expect(toolExit.message, contains('BUILD_DIR must be supplied to locate SSH keys'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('with BUILD_DIR set', () async {
      final FuchsiaDevice device = FuchsiaDevice('id');
      ToolExit toolExit;
      try {
        await device.servicePorts();
      } on ToolExit catch (err) {
        toolExit = err;
      }
      expect(toolExit.message, 'No Dart Observatories found. Are you running a debug build?');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      FuchsiaArtifacts: () => mockFuchsiaArtifacts,
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
}

class MockFuchsiaArtifacts extends Mock implements FuchsiaArtifacts {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}

class MockFile extends Mock implements File {}

class MockProcess extends Mock implements Process {}
