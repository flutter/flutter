// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
  }) : super(
      'linux',
      platformType: PlatformType.linux,
      ephemeral: false,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
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
  LinuxDevices({
    @required Platform platform,
    @required FeatureFlags featureFlags,
    FileSystem fileSystem,
    ProcessManager processManager,
    Logger logger,
  }) : _platform = platform ?? globals.platform, // TODO(jonahwilliams): remove after google3 roll
       _linuxWorkflow = LinuxWorkflow(
          platform: platform,
          featureFlags: featureFlags,
       ),
       _fileSystem = fileSystem ?? globals.fs,
       _logger = logger,
       _processManager = processManager ?? globals.processManager,
       super('linux devices');

  final Platform _platform;
  final LinuxWorkflow _linuxWorkflow;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;

  @override
  bool get supportsPlatform => _platform.isLinux;

  @override
  bool get canListAnything => _linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(
        logger: _logger,
        processManager: _processManager,
        fileSystem: _fileSystem,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
