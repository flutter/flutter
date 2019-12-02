// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice() : super(
      'Linux',
      platformType: PlatformType.linux,
      ephemeral: false,
  );

  @override
  bool isSupported() => true;

  @override
  String get name => 'Linux';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.linux_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.linux.existsSync();
  }

  @override
  Future<void> buildForDevice(
    covariant LinuxApp package, {
    String mainPath,
    BuildInfo buildInfo,
  }) async {
    await buildLinux(
      FlutterProject.current().linux,
      buildInfo,
      target: mainPath,
    );
  }

  @override
  String executablePathForDevice(covariant LinuxApp package, BuildMode buildMode) {
    return package.executable(buildMode);
  }
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices() : super('linux devices');

  @override
  bool get supportsPlatform => platform.isLinux;

  @override
  bool get canListAnything => linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
