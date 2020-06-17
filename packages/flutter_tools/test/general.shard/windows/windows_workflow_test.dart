// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockPlatform windows;
  MockPlatform notWindows;

  setUp(() {
    windows = MockPlatform();
    notWindows = MockPlatform();
    when(windows.isWindows).thenReturn(true);
    when(notWindows.isWindows).thenReturn(false);
    testbed = Testbed(
      overrides: <Type, Generator>{
        Platform: () => windows,
        FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
      },
    );
  });

  test('Windows default workflow values', () => testbed.run(() {
    expect(windowsWorkflow.appliesToHostPlatform, true);
    expect(windowsWorkflow.canListDevices, true);
    expect(windowsWorkflow.canLaunchDevices, true);
    expect(windowsWorkflow.canListEmulators, false);
  }));

  test('Windows defaults on non-windows platform', () => testbed.run(() {
    expect(windowsWorkflow.appliesToHostPlatform, false);
    expect(windowsWorkflow.canListDevices, false);
    expect(windowsWorkflow.canLaunchDevices, false);
    expect(windowsWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    Platform: () => notWindows,
  }));

  test('Windows defaults on non-windows platform', () => testbed.run(() {
    expect(windowsWorkflow.appliesToHostPlatform, false);
    expect(windowsWorkflow.canListDevices, false);
    expect(windowsWorkflow.canLaunchDevices, false);
    expect(windowsWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
  }));
}

class MockPlatform extends Mock implements Platform {
  @override
  final Map<String, String> environment = <String, String>{};
}
