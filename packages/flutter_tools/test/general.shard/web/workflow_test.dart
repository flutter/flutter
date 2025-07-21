// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/web/workflow.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  testWithoutContext('WebWorkflow applies on Linux', () {
    final workflow = WebWorkflow(
      platform: FakePlatform(),
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );

    expect(workflow.appliesToHostPlatform, true);
    expect(workflow.canLaunchDevices, true);
    expect(workflow.canListDevices, true);
    expect(workflow.canListEmulators, false);
  });

  testWithoutContext('WebWorkflow applies on macOS', () {
    final workflow = WebWorkflow(
      platform: FakePlatform(operatingSystem: 'macos'),
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );

    expect(workflow.appliesToHostPlatform, true);
    expect(workflow.canLaunchDevices, true);
    expect(workflow.canListDevices, true);
    expect(workflow.canListEmulators, false);
  });

  testWithoutContext('WebWorkflow applies on Windows', () {
    final workflow = WebWorkflow(
      platform: FakePlatform(operatingSystem: 'windows'),
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );

    expect(workflow.appliesToHostPlatform, true);
    expect(workflow.canLaunchDevices, true);
    expect(workflow.canListDevices, true);
    expect(workflow.canListEmulators, false);
  });

  testWithoutContext('WebWorkflow does not apply on other platforms', () {
    final workflow = WebWorkflow(
      platform: FakePlatform(operatingSystem: 'fuchsia'),
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );

    expect(workflow.appliesToHostPlatform, false);
  });

  testWithoutContext('WebWorkflow does not apply if feature flag is disabled', () {
    final workflow = WebWorkflow(platform: FakePlatform(), featureFlags: TestFeatureFlags());

    expect(workflow.appliesToHostPlatform, false);
    expect(workflow.canLaunchDevices, false);
    expect(workflow.canListDevices, false);
    expect(workflow.canListEmulators, false);
  });
}
