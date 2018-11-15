// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockProcess extends Mock implements Process {}

void main() {
  final FakePlatform osx = FakePlatform.fromPlatform(const LocalPlatform());
  osx.operatingSystem = 'macos';

  group('getAttachedDevices', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
    });

    testUsingContext('return no devices if Xcode is not installed', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(false);
      expect(await IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value(''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('10.3.2'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('Puits sans fond'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('11.0'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices and ignores devices that cannot be found by ideviceinfo', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenThrow(IOSDeviceNotFoundError('Device not found'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(1));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });

  group('decodeSyslog', () {
    test('decodes a syslog-encoded line', () {
      final String decoded = decodeSyslog(r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog \M-B\M-/\134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');
      expect(decoded, r'I ❤️ syslog ¯\_(ツ)_/¯ 솠!');
    });

    test('passes through un-decodeable lines as-is', () {
      final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');
      expect(decoded, r'I \M-b\M^O syslog!');
    });
  });
  group('logging', () {
    MockIMobileDevice mockIMobileDevice;
    MockIosProject mockIosProject;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
      mockIosProject = MockIosProject();
    });

    testUsingContext('suppresses non-Flutter lines from output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: A is for ari
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
  Runner(Flutter)[297] <Notice>: I is for ichigo
  Runner(UIKit)[297] <Notice>: E is for enpitsu"
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('includes multi-line Flutter logs in the output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });
}
