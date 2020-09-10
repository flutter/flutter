// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  testWithoutContext('iOS workflow is disabled if feature is disabled', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macOS'),
      xcode: MockXcode(),
      featureFlags: TestFeatureFlags(isIOSEnabled: false),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is disabled on Linux', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'linux'),
      xcode: MockXcode(),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is disabled on windows', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'windows'),
      xcode: MockXcode(),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is enabled on macOS', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macos'),
      xcode: MockXcode(),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, true);
    expect(iosWorkflow.canListEmulators, false);
  });

  testWithoutContext('iOS workflow can launch and list devices when Xcode is set up', () {
    final Xcode xcode = MockXcode();
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macos'),
      xcode: xcode,
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );
    when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
    when(xcode.isSimctlInstalled).thenReturn(true);

    expect(iosWorkflow.canLaunchDevices, true);
    expect(iosWorkflow.canListDevices, true);
  });
}

class MockXcode extends Mock implements Xcode {}