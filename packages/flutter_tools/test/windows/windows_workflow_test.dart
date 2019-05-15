// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WindowsWorkflow, () {
    final MockPlatform windows = MockPlatform();
    final MockPlatform windowsWithFde = MockPlatform()
      ..environment['ENABLE_FLUTTER_DESKTOP'] = 'true';
    final MockPlatform notWindows = MockPlatform();
    when(windows.isWindows).thenReturn(true);
    when(windowsWithFde.isWindows).thenReturn(true);
    when(notWindows.isWindows).thenReturn(false);

    testUsingContext('Applies to windows platform', () {
      expect(windowsWorkflow.appliesToHostPlatform, true);
    }, overrides: <Type, Generator>{
      Platform: () => windows,
    });
    testUsingContext('Does not apply to non-windows platform', () {
      expect(windowsWorkflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });

    testUsingContext('defaults', () {
      expect(windowsWorkflow.canListEmulators, false);
      expect(windowsWorkflow.canLaunchDevices, true);
      expect(windowsWorkflow.canListDevices, true);
    }, overrides: <Type, Generator>{
      Platform: () => windowsWithFde,
    });
  });
}

class MockPlatform extends Mock implements Platform {
  @override
  final Map<String, String> environment = <String, String>{};
}
