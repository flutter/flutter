// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(MacOSDevice, () {
    final MockPlatform notMac = MockPlatform();
    final MacOSDevice device = MacOSDevice();
    final MockProcessManager processManager = MockProcessManager();
    final MockProcessResult processResult = MockProcessResult();
    when(notMac.isMacOS).thenReturn(false);
    when(notMac.environment).thenReturn(const <String, String>{});
    when(processResult.exitCode).thenReturn(0);
    when<String>(processResult.stdout).thenReturn(r'''
ProductName:	Mac OS X
ProductVersion:	10.10.0
BuildVersion:	16G0000
''');
    when(processManager.run(<String>['sw_vers'])).thenAnswer((Invocation invocation) async {
      return processResult;
    });

    testUsingContext('defaults', () async {
      expect(await device.targetPlatform, TargetPlatform.darwin_x64);
      expect(device.name, 'MacOS');
      expect(await device.sdkNameAndVersion, 'Mac OS X 10.10.0');
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    test('unimplemented methods', () {
      expect(() => device.installApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.uninstallApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.isLatestBuildInstalled(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.startApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.stopApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.isAppInstalled(null), throwsA(isInstanceOf<UnimplementedError>()));
    });

    test('noop port forwarding', () async {
      final MacOSDevice device = MacOSDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
      expect(() => portForwarder.forward(1, hostPort: 23), throwsA(isInstanceOf<UnimplementedError>()));
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await MacOSDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notMac,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}

class MockPlatform extends Mock implements Platform {}
