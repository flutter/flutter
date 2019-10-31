// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/features.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/linux/linux_workflow.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  MockPlatform linux;
  MockPlatform notLinux;
  Testbed testbed;

  setUp(() {
    linux = MockPlatform();
    notLinux = MockPlatform();
    when(linux.isLinux).thenReturn(true);
    when(notLinux.isLinux).thenReturn(false);
    testbed = Testbed(
      overrides: <Type, Generator>{
        Platform: () => linux,
        FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
      },
    );
  });

  test('Applies to linux platform', () => testbed.run(() {
    expect(linuxWorkflow.appliesToHostPlatform, true);
    expect(linuxWorkflow.canLaunchDevices, true);
    expect(linuxWorkflow.canListDevices, true);
    expect(linuxWorkflow.canListEmulators, false);
  }));

  test('Does not apply to non-linux platform', () => testbed.run(() {
    expect(linuxWorkflow.appliesToHostPlatform, false);
    expect(linuxWorkflow.canLaunchDevices, false);
    expect(linuxWorkflow.canListDevices, false);
    expect(linuxWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    Platform: () => notLinux,
  }));

  test('Does not apply when feature is disabled', () => testbed.run(() {
    expect(linuxWorkflow.appliesToHostPlatform, false);
    expect(linuxWorkflow.canLaunchDevices, false);
    expect(linuxWorkflow.canListDevices, false);
    expect(linuxWorkflow.canListEmulators, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  }));
}

class MockPlatform extends Mock implements Platform {
  @override
  final Map<String, String> environment = <String, String>{};
}
