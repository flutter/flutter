// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/features.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/linux/linux_workflow.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  final Platform linux = FakePlatform(
    operatingSystem: 'linux',
    environment: <String, String>{},
  );
  final Platform notLinux = FakePlatform(
    operatingSystem: 'windows',
    environment: <String, String>{},
  );
  final FeatureFlags enabledFlags = TestFeatureFlags(
    isLinuxEnabled: true,
  );
  final FeatureFlags disabledFlags = TestFeatureFlags(isLinuxEnabled: false);

  test('Applies to linux platform', () {
    final LinuxWorkflow linuxWorkflow = LinuxWorkflow(
      platform: linux,
      featureFlags: enabledFlags,
    );

    expect(linuxWorkflow.appliesToHostPlatform, true);
    expect(linuxWorkflow.canLaunchDevices, true);
    expect(linuxWorkflow.canListDevices, true);
    expect(linuxWorkflow.canListEmulators, false);
  });

  test('Does not apply to non-linux platform', () {
    final LinuxWorkflow linuxWorkflow = LinuxWorkflow(
      platform: notLinux,
      featureFlags: enabledFlags,
    );

    expect(linuxWorkflow.appliesToHostPlatform, false);
    expect(linuxWorkflow.canLaunchDevices, false);
    expect(linuxWorkflow.canListDevices, false);
    expect(linuxWorkflow.canListEmulators, false);
  });

  test('Does not apply when feature is disabled', () {
    final LinuxWorkflow linuxWorkflow = LinuxWorkflow(
      platform: linux,
      featureFlags: disabledFlags,
    );

    expect(linuxWorkflow.appliesToHostPlatform, false);
    expect(linuxWorkflow.canLaunchDevices, false);
    expect(linuxWorkflow.canListDevices, false);
    expect(linuxWorkflow.canListEmulators, false);
  });
}
