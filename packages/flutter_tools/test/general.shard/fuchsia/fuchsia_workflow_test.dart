// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  final FileSystem fileSystem = MemoryFileSystem.test();
  final File sshConfig = fileSystem.file('ssh_config');
  final File ffx = fileSystem.file('ffx');

  testWithoutContext('Fuchsia workflow does not apply to host platform if feature is disabled', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(),
      fuchsiaArtifacts: FuchsiaArtifacts(ffx: ffx, sshConfig: sshConfig),
      platform: FakePlatform(),
    );

    expect(fuchsiaWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('Fuchsia workflow does not apply to host platform on Windows', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(isFuchsiaEnabled: true),
      fuchsiaArtifacts: FuchsiaArtifacts(ffx: ffx, sshConfig: sshConfig),
      platform: FakePlatform(operatingSystem: 'windows'),
    );

    expect(fuchsiaWorkflow.appliesToHostPlatform, false);
  });

  testWithoutContext('Fuchsia workflow can not list and launch devices if there is no ffx when using default workflow', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(),
      fuchsiaArtifacts: FuchsiaArtifacts(sshConfig: sshConfig),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(fuchsiaWorkflow.canLaunchDevices, false);
    expect(fuchsiaWorkflow.canListDevices, false);
    expect(fuchsiaWorkflow.canListEmulators, false);
  });

  testWithoutContext('Fuchsia workflow can not launch devices if there is no ssh config when using default workflow', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(),
      fuchsiaArtifacts: FuchsiaArtifacts(ffx: ffx),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(fuchsiaWorkflow.canLaunchDevices, false);
    expect(fuchsiaWorkflow.canListDevices, true);
    expect(fuchsiaWorkflow.canListEmulators, false);
  });

  testWithoutContext('Fuchsia workflow can list and launch devices supported with sufficient SDK artifacts when using default workflow', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(),
      fuchsiaArtifacts: FuchsiaArtifacts(sshConfig: sshConfig, ffx: ffx),
      platform: FakePlatform(environment: <String, String>{}),
    );

    expect(fuchsiaWorkflow.canLaunchDevices, true);
    expect(fuchsiaWorkflow.canListDevices, true);
    expect(fuchsiaWorkflow.canListEmulators, false);
  });

  testWithoutContext('Fuchsia workflow can list and launch devices supported with sufficient SDK artifacts on macOS', () {
    final FuchsiaWorkflow fuchsiaWorkflow = FuchsiaWorkflow(
      featureFlags: TestFeatureFlags(),
      fuchsiaArtifacts: FuchsiaArtifacts(sshConfig: sshConfig, ffx: ffx),
      platform: FakePlatform(operatingSystem: 'macOS', environment: <String, String>{}),
    );

    expect(fuchsiaWorkflow.canLaunchDevices, true);
    expect(fuchsiaWorkflow.canListDevices, true);
    expect(fuchsiaWorkflow.canListEmulators, false);
  });
}
