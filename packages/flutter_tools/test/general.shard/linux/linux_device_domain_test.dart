// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/extension/device.dart';
import 'package:flutter_tools/src/linux/linux_extension.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  LinuxDeviceDomain deviceDomain;
  MockPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockPlatform();
    deviceDomain = LinuxToolExtension(
      platform: mockPlatform,
    ).deviceDomain;
  });

  test('DeviceDomain returns correct device info on Linux', () async {
    when(mockPlatform.isLinux).thenReturn(true);

    final DeviceList deviceList = await deviceDomain.listDevices();
    final Device device = deviceList.devices.single;

    expect(device.targetArchitecture, TargetArchitecture.x86_64);
    expect(device.targetPlatform, TargetPlatform.linux);
    expect(device.deviceId, 'linux');
    expect(device.deviceName, 'Linux');
    expect(device.sdkNameAndVersion, 'Linux');
    expect(device.category, Category.desktop);
    expect(device.ephemeral, false);
    expect(device.deviceCapabilities.supportsHotReload, true);
    expect(device.deviceCapabilities.supportsHotRestart, true);
    expect(device.deviceCapabilities.supportsScreenshot, false);
    expect(device.deviceCapabilities.supportsStartPaused, true);
  });

  test('DeviceDomain returns no devices on non-Linux platforms', () async {
    when(mockPlatform.isLinux).thenReturn(false);

    final DeviceList deviceList = await deviceDomain.listDevices();
    expect(deviceList.devices, isEmpty);
  });
}

class MockPlatform extends Mock implements Platform {}
