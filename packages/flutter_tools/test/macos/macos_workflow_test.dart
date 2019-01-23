// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(MacOSWorkflow, () {
    final MockPlatform mac = MockPlatform();
    final MockPlatform macWithFde = MockPlatform()
      ..environment['FLUTTER_DESKTOP_EMBEDDING'] = 'true';
    final MockPlatform notMac = MockPlatform();
    when(mac.isMacOS).thenReturn(true);
    when(macWithFde.isMacOS).thenReturn(true);
    when(notMac.isMacOS).thenReturn(false);

    testUsingContext('Applies to mac platform', () {
      expect(macOSWorkflow.appliesToHostPlatform, true);
    }, overrides: <Type, Generator>{
      Platform: () => mac,
    });
    testUsingContext('Does not apply to non-mac platform', () {
      expect(macOSWorkflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notMac,
    });

    testUsingContext('defaults', () {
      expect(macOSWorkflow.canListEmulators, false);
      expect(macOSWorkflow.canLaunchDevices, true);
      expect(macOSWorkflow.canListDevices, true);
    }, overrides: <Type, Generator>{
      Platform: () => macWithFde,
    });
  });
}

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{};
}
