// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('attach', () {
    final FileSystem testFileSystem = new MemoryFileSystem(
      style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle
          .posix,
    );

    setUpAll(() {
      Cache.disableLocking();
      testFileSystem.directory('lib').createSync();
      testFileSystem.file('lib/main.dart').createSync();
    });

    testUsingContext('finds observatory port and forwards', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockDeviceLogReader mockLogReader = new MockDeviceLogReader();
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();
      when(device.getLogReader()).thenAnswer((_) {
        // Now that the reader is used, start writing messages to it.
        Timer.run(() {
          mockLogReader.addLine('Foo');
          mockLogReader.addLine(
              'Observatory listening on http://127.0.0.1:$devicePort');
        });

        return mockLogReader;
      });
      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts).thenReturn(
          <ForwardedPort>[new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any)).thenAnswer((_) async => null);
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(<String>['attach']);

      verify(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .called(1);

      mockLogReader.dispose();
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    },
    );

    testUsingContext('selects specified target', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockDeviceLogReader mockLogReader = new MockDeviceLogReader();
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();
      final MockHotRunnerFactory mockHotRunnerFactory = new MockHotRunnerFactory();
      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort')))
          .thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts).thenReturn(
          <ForwardedPort>[new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any)).thenAnswer((_) async => null);
      when(mockHotRunnerFactory.build(any,
          target: anyNamed('target'),
          debuggingOptions: anyNamed('debuggingOptions'),
          packagesFilePath: anyNamed('packagesFilePath'),
          usesTerminalUI: anyNamed('usesTerminalUI'))).thenReturn(
          new MockHotRunner());

      testDeviceManager.addDevice(device);
      when(device.getLogReader()).thenAnswer((_) {
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

      final AttachCommand command = new AttachCommand(
          hotRunnerFactory: mockHotRunnerFactory);
      await createTestCommandRunner(command).run(
          <String>['attach', '-t', foo.path, '-v']);

      verify(mockHotRunnerFactory.build(any,
          target: foo.path,
          debuggingOptions: anyNamed('debuggingOptions'),
          packagesFilePath: anyNamed('packagesFilePath'),
          usesTerminalUI: anyNamed('usesTerminalUI'))).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    },);

    testUsingContext('forwards to given port', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();

      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort)).thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts).thenReturn(
          <ForwardedPort>[new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward(any)).thenAnswer((_) async => null);
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(
          <String>['attach', '--debug-port', '$devicePort']);

      verify(portForwarder.forward(devicePort)).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    },);

    testUsingContext('exits when no device connected', () async {
      final AttachCommand command = new AttachCommand();
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsA(isInstanceOf<ToolExit>()),
      );
      expect(testLogger.statusText, contains('No connected devices'));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    },);

    testUsingContext('exits when multiple devices connected', () async {
      Device aDeviceWithId(String id) {
        final MockAndroidDevice device = new MockAndroidDevice();
        when(device.name).thenReturn('d$id');
        when(device.id).thenReturn(id);
        when(device.isLocalEmulator).thenAnswer((_) async => false);
        when(device.sdkNameAndVersion).thenAnswer((_) async => 'Android 46');
        return device;
      }

      final AttachCommand command = new AttachCommand();
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
    },);
  });
}

class MockPortForwarder extends Mock implements DevicePortForwarder {}

class MockHotRunner extends Mock implements HotRunner {}

class MockHotRunnerFactory extends Mock implements HotRunnerFactory {}
