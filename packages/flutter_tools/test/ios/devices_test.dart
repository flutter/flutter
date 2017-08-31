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
    MockXcode mockXcode;

    setUp(() {
      mockXcode = new MockXcode();
    });

    testUsingContext('return no devices if Xcode is not installed', () async {
      when(mockXcode.isInstalled).thenReturn(false);
      expect(await IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(mockXcode.isInstalled).thenReturn(true);
      when(mockXcode.getAvailableDevices()).thenReturn(new Future<String>.value(''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });

    testUsingContext('returns attached devices', () async {
      when(mockXcode.isInstalled).thenReturn(true);
      when(mockXcode.getAvailableDevices()).thenReturn(new Future<String>.value('''
Known Devices:
je-mappelle-horse [ED6552C4-B774-5A4E-8B5A-606710C87C77]
La tele me regarde (10.3.2) [98206e7a4afd4aedaff06e687594e089dede3c44]
Puits sans fond (10.3.2) [f577a7903cc54959be2e34bc4f7f80b7009efcf4]
iPhone 6 Plus (9.3) [FBA880E6-4020-49A5-8083-DCD50CA5FA09] (Simulator)
iPhone 6s (11.0) [E805F496-FC6A-4EA4-92FF-B7901FF4E7CC] (Simulator)
iPhone 7 (11.0) + Apple Watch Series 2 - 38mm (4.0) [60027FDD-4A7A-42BF-978F-C2209D27AD61] (Simulator)
iPhone SE (11.0) [667E8DCD-5DCD-4C80-93A9-60D1D995206F] (Simulator)
'''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });
  });

  group('logging', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = new MockIMobileDevice();
    });

    testUsingContext('suppresses blacklisted lines from output', () async {
      when(mockIMobileDevice.startLogger()).thenAnswer((_) {
        final Process mockProcess = new MockProcess();
        when(mockProcess.stdout).thenReturn(new Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(libsystem_asl.dylib)[297] <Notice>: A is for ari
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
  Runner(libsystem_asl.dylib)[297] <Notice>: I is for ichigo
  '''.codeUnits]));
        when(mockProcess.stderr).thenReturn(const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode).thenReturn(new Future<int>.delayed(Duration.ZERO, () => 0));
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
