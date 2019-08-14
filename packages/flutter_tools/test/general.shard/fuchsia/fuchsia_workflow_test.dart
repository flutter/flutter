// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockFile extends Mock implements File {}

void main() {
  group('Fuchsia workflow', () {
    final MockFile devFinder = MockFile();
    final MockFile sshConfig = MockFile();
    when(devFinder.absolute).thenReturn(devFinder);
    when(sshConfig.absolute).thenReturn(sshConfig);

    testUsingContext(
        'can not list and launch devices if there is not ssh config and dev finder',
        () {
      expect(fuchsiaWorkflow.canLaunchDevices, false);
      expect(fuchsiaWorkflow.canListDevices, false);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () =>
          FuchsiaArtifacts(devFinder: null, sshConfig: null),
    });

    testUsingContext(
        'can not list and launch devices if there is not ssh config and dev finder',
        () {
      expect(fuchsiaWorkflow.canLaunchDevices, false);
      expect(fuchsiaWorkflow.canListDevices, true);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () =>
          FuchsiaArtifacts(devFinder: devFinder, sshConfig: null),
    });

    testUsingContext(
        'can list and launch devices supported with sufficient SDK artifacts',
        () {
      expect(fuchsiaWorkflow.canLaunchDevices, true);
      expect(fuchsiaWorkflow.canListDevices, true);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () =>
          FuchsiaArtifacts(devFinder: devFinder, sshConfig: sshConfig),
    });
  });
}
