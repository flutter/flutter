// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}

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
      expect(IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(mockXcode.isInstalled).thenReturn(true);
      when(mockXcode.getAvailableDevices()).thenReturn('');
      final List<IOSDevice> devices = IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });

    testUsingContext('returns attached devices', () async {
      when(mockXcode.isInstalled).thenReturn(true);
      when(mockXcode.getAvailableDevices()).thenReturn('''
Known Devices:
je-mappelle-horse [ED6552C4-B774-5A4E-8B5A-606710C87C77]
La tele me regarde (10.3.2) [98206e7a4afd4aedaff06e687594e089dede3c44]
Puits sans fond (10.3.2) [f577a7903cc54959be2e34bc4f7f80b7009efcf4]
iPhone 6 Plus (9.3) [FBA880E6-4020-49A5-8083-DCD50CA5FA09] (Simulator)
iPhone 6s (11.0) [E805F496-FC6A-4EA4-92FF-B7901FF4E7CC] (Simulator)
iPhone 7 (11.0) + Apple Watch Series 2 - 38mm (4.0) [60027FDD-4A7A-42BF-978F-C2209D27AD61] (Simulator)
iPhone SE (11.0) [667E8DCD-5DCD-4C80-93A9-60D1D995206F] (Simulator)
''');
      final List<IOSDevice> devices = IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      Xcode: () => mockXcode,
    });
  });

}
