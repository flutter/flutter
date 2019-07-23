// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/extension/device.dart' as ext;
import 'package:flutter_tools/src/extension/extension.dart' as ext;
import 'package:flutter_tools/src/extension_host.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/linux_extension.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('ExtensionHost loads linux extension if flutter feature is enabled', () => testbed.run(() {
    final ExtensionHost extensionHost = ExtensionHost();

    expect(extensionHost.toolExtensions, contains(isInstanceOf<LinuxToolExtension>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  }));

  test('ExtensionHost does not load linux extension if flutter feature is disabled', () => testbed.run(() {
    final ExtensionHost extensionHost = ExtensionHost();

    expect(extensionHost.toolExtensions, isNot(contains(isInstanceOf<LinuxToolExtension>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  }));

  test('ExtensionHost creates delegate device', () => testbed.run(() async {
    final MockToolExtension mockToolExtension = MockToolExtension();
    final MockDeviceDomain mockDeviceDomain = MockDeviceDomain();
    when(mockToolExtension.deviceDomain).thenReturn(mockDeviceDomain);
    when(mockToolExtension.logs).thenAnswer((Invocation invocation) {
      return const Stream<ext.Log>.empty();
    }); 
    when(mockDeviceDomain.listDevices()).thenAnswer((Invocation invocation) async {
      return const ext.DeviceList(
        devices: <ext.Device>[
          ext.Device(
            deviceCapabilities: ext.DeviceCapabilities(
              supportsHotReload: true,
              supportsHotRestart: false,
              supportsScreenshot: false,
              supportsStartPaused: true,
            ),
            deviceId: '1234',
            deviceName: 'testy',
            sdkNameAndVersion: 'tester',
            targetArchitecture: ext.TargetArchitecture.arm64_v8a,
            targetPlatform: ext.TargetPlatform.android,
            ephemeral: true,
            category: ext.Category.desktop,
          ),
        ]
      );
    });
    final ExtensionHost extensionHost = ExtensionHost(<ext.ToolExtension>[mockToolExtension]);
    final Device device = await extensionHost.getExtensionDevices().single;   

    expect(device.name, 'testy');
    expect(device.id, '1234');
    expect(await device.sdkNameAndVersion, 'tester');
    expect(await device.targetPlatform, TargetPlatform.android_arm64);
    expect(device.category, Category.desktop);
    expect(device.ephemeral, true);
    expect(device.supportsHotReload, true);
    expect(device.supportsHotRestart, false);
    expect(device.supportsScreenshot, false);
    expect(device.supportsStartPaused, true);
  }));
}

class MockToolExtension extends Mock implements ext.ToolExtension {}
class MockDeviceDomain extends Mock implements ext.DeviceDomain {}
