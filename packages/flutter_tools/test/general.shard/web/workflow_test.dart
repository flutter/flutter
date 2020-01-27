// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  group('WebWorkflow', () {
    Testbed testbed;
    MockPlatform notSupported;
    MockPlatform windows;
    MockPlatform linux;
    MockPlatform macos;
    MockProcessManager mockProcessManager;
    WebWorkflow workflow;

    setUpAll(() {
      notSupported = MockPlatform(linux: false, windows: false, macos: false);
      windows = MockPlatform(windows: true);
      linux = MockPlatform(linux: true);
      macos = MockPlatform(macos: true);
      workflow = const WebWorkflow();
      mockProcessManager = MockProcessManager();
      testbed = Testbed(setup: () async {
        globals.fs.file('chrome').createSync();
        when(mockProcessManager.canRun('chrome')).thenReturn(true);
      }, overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
        ProcessManager: () => mockProcessManager,
      });
    });

    test('Applies on Linux', () => testbed.run(() {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    }));

    test('Applies on macOS', () => testbed.run(() {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => macos,
    }));

    test('Applies on Windows', () => testbed.run(() {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => windows,
    }));

    test('does not apply on other platforms', () => testbed.run(() {
      expect(workflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notSupported,
    }));

    test('does not apply if feature flag is disabled', () => testbed.run(() {
      expect(workflow.appliesToHostPlatform, false);
      expect(workflow.canLaunchDevices, false);
      expect(workflow.canListDevices, false);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => macos,
      FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
    }));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockPlatform extends Mock implements Platform {
  MockPlatform({
    this.windows = false,
    this.macos = false,
    this.linux = false,
    this.environment = const <String, String>{
      kChromeEnvironment: 'chrome',
    },
  });

  final bool windows;
  final bool macos;
  final bool linux;

  @override
  final Map<String, String> environment;

  @override
  bool get isLinux => linux;

  @override
  bool get isMacOS => macos;

  @override
  bool get isWindows => windows;
}
