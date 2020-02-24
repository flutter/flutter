// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/features.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  MockPlatform mac;
  MockPlatform notMac;
  Testbed testbed;

  setUp(() {
    mac = MockPlatform();
    notMac = MockPlatform();
    when(mac.isMacOS).thenReturn(true);
    when(notMac.isMacOS).thenReturn(false);
    testbed = Testbed(overrides: <Type, Generator>{
      Platform: () => mac,
      FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    });
  });

  test('Applies to macOS platform', () => testbed.run(() {
    expect(macOSWorkflow.appliesToHostPlatform, true);
    expect(macOSWorkflow.canListDevices, true);
    expect(macOSWorkflow.canLaunchDevices, true);
    expect(macOSWorkflow.canListEmulators, false);
  }));

  test('Does not apply to non-macOS platform', () => testbed.run(() {
    expect(macOSWorkflow.appliesToHostPlatform, false);
    expect(macOSWorkflow.canListDevices, false);
    expect(macOSWorkflow.canLaunchDevices, false);
    expect(macOSWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    Platform: () => notMac,
  }));

  test('Does not apply when feature is disabled', () => testbed.run(() {
    expect(macOSWorkflow.appliesToHostPlatform, false);
    expect(macOSWorkflow.canListDevices, false);
    expect(macOSWorkflow.canLaunchDevices, false);
    expect(macOSWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  }));
}

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{};
}

class MockProcessManager extends Mock implements ProcessManager {}
