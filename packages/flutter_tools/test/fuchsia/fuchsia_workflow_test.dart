// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockFile extends Mock implements File {}

void main() {
  bool fxPresent = false;
  final MockOperatingSystemUtils utils = MockOperatingSystemUtils();
  final MockFile file = MockFile();
  when(utils.which('fx')).thenAnswer((Invocation _) => fxPresent ? file : null);

  group('android workflow', () {
    testUsingContext('can not list and launch devices if there is no `fx` command', () {
      fxPresent = false;
      expect(fuchsiaWorkflow.canLaunchDevices, false);
      expect(fuchsiaWorkflow.canListDevices, false);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => utils,
    });

    testUsingContext('can list and launch devices supported if there is a `fx` command', () {
      fxPresent = true;
      expect(fuchsiaWorkflow.canLaunchDevices, true);
      expect(fuchsiaWorkflow.canListDevices, true);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => utils,
    });
  });
}
