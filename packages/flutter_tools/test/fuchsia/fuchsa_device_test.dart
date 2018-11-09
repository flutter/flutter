// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

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

    group('displays friendly error when no observatories found', () {
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
        FuchsiaArtifacts: () => mockFuchsiaArtifacts
      });
    });
  });
}

class MockFuchsiaArtifacts extends Mock implements FuchsiaArtifacts {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}

class MockFile extends Mock implements File {}