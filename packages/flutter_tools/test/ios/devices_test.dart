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
import 'package:test/test.dart';

import '../src/context.dart';

class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockProcess extends Mock implements Process {}

void main() {
  final FakePlatform osx = new FakePlatform.fromPlatform(const LocalPlatform());
  osx.operatingSystem = 'macos';

  group('getAttachedDevices', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = new MockIMobileDevice();
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
          .thenAnswer((Invocation invocation) => new Future<String>.value(''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => new Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName')).thenReturn('La tele me regarde');
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'ProductVersion')).thenReturn('10.3.2');
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName')).thenReturn('Puits sans fond');
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'ProductVersion')).thenReturn('11.0');
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
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

    setUp(() {
      mockIMobileDevice = new MockIMobileDevice();
    });

    testUsingContext('suppresses non-Flutter lines from output', () async {
      when(mockIMobileDevice.startLogger()).thenAnswer((Invocation invocation) {
        final Process mockProcess = new MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            new Stream<List<int>>.fromIterable(<List<int>>['''
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
            .thenAnswer((Invocation invocation) => new Future<int>.delayed(Duration.zero, () => 0));
        return new Future<Process>.value(mockProcess);
      });

      final IOSDevice device = new IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: new BuildableIOSApp(projectBundleId: 'bundleId'),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });
}
