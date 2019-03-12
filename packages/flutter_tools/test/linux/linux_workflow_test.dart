// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/linux/linux_workflow.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(LinuxWorkflow, () {
    final MockPlatform linux = MockPlatform();
    final MockPlatform linuxWithFde = MockPlatform()
      ..environment['FLUTTER_DESKTOP_EMBEDDING'] = 'true';
    final MockPlatform notLinux = MockPlatform();
    when(linux.isLinux).thenReturn(true);
    when(linuxWithFde.isLinux).thenReturn(true);
    when(notLinux.isLinux).thenReturn(false);

    testUsingContext('Applies to linux platform', () {
      expect(linuxWorkflow.appliesToHostPlatform, true);
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    });
    testUsingContext('Does not apply to non-linux platform', () {
      expect(linuxWorkflow.appliesToHostPlatform, false);
    }, overrides: <Type, Generator>{
      Platform: () => notLinux,
    });

    testUsingContext('defaults', () {
      expect(linuxWorkflow.canListEmulators, false);
      expect(linuxWorkflow.canLaunchDevices, true);
      expect(linuxWorkflow.canListDevices, true);
    }, overrides: <Type, Generator>{
      Platform: () => linuxWithFde,
    });
  });
}

class MockPlatform extends Mock implements Platform {
  @override
  final Map<String, String> environment = <String, String>{};
}
