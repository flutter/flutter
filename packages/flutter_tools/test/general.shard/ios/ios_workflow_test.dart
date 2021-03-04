// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  testWithoutContext('iOS workflow is disabled if feature is disabled', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macOS'),
      xcode: Xcode.test(processManager: FakeProcessManager.any()),
      featureFlags: TestFeatureFlags(isIOSEnabled: false),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is disabled on Linux', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'linux'),
      xcode: Xcode.test(processManager: FakeProcessManager.any()),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is disabled on windows', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'windows'),
      xcode: Xcode.test(processManager: FakeProcessManager.any()),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('iOS workflow is enabled on macOS', () {
    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macos'),
      xcode: Xcode.test(processManager: FakeProcessManager.any()),
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    expect(iosWorkflow.appliesToHostPlatform, true);
    expect(iosWorkflow.canListEmulators, false);
  });

  testWithoutContext('iOS workflow can launch and list devices when Xcode is set up', () {
    final Xcode xcode = Xcode.test(
      processManager: FakeProcessManager.any(),
      xcodeProjectInterpreter: XcodeProjectInterpreter.test(
        processManager: FakeProcessManager.any(),
        majorVersion: 1000,
        minorVersion: 0,
        patchVersion: 0,
      ),
    );

    final IOSWorkflow iosWorkflow = IOSWorkflow(
      platform: FakePlatform(operatingSystem: 'macos'),
      xcode: xcode,
      featureFlags: TestFeatureFlags(isIOSEnabled: true),
    );

    // Make sure we're testing the right Xcode state.
    expect(xcode.isInstalledAndMeetsVersionCheck, true);
    expect(xcode.isSimctlInstalled, true);
    expect(iosWorkflow.canLaunchDevices, true);
    expect(iosWorkflow.canListDevices, true);
  });
}
