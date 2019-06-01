// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group('WebWorkflow', () {
    MockPlatform noEnvironment;
    MockPlatform notSupported;
    MockPlatform windows;
    MockPlatform linux;
    MockPlatform macos;
    WebWorkflow workflow;

    setUpAll(() {
      noEnvironment = MockPlatform(environment: const <String, String>{});
      notSupported = MockPlatform(linux: false, windows: false, macos: false);
      windows = MockPlatform(windows: true);
      linux = MockPlatform(linux: true);
      macos = MockPlatform(macos: true);
      workflow = const WebWorkflow();
    });

    testUsingContext('does not apply if FLUTTER_WEB is not true', () {
      expect(workflow.appliesToHostPlatform, false);
      expect(workflow.canLaunchDevices, false);
      expect(workflow.canListDevices, false);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => noEnvironment,
    });

    testUsingContext('Applies on Linux', () {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    });

    testUsingContext('Applies on macOS', () {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => macos,
    });

    testUsingContext('Applies on Windows', () {
      expect(workflow.appliesToHostPlatform, true);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => windows,
    });

    testUsingContext('does not apply on other platforms', () {
      expect(workflow.appliesToHostPlatform, false);
      expect(workflow.canLaunchDevices, true);
      expect(workflow.canListDevices, true);
      expect(workflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Platform: () => notSupported,
    });
  });
}

class MockPlatform extends Mock implements Platform {
  MockPlatform(
      {this.windows = false,
      this.macos = false,
      this.linux = false,
      this.environment = const <String, String>{
        'FLUTTER_WEB': 'true',
      }});

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
