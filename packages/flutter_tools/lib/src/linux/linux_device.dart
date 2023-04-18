// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice({
    required final ProcessManager processManager,
    required final Logger logger,
    required final FileSystem fileSystem,
    required final OperatingSystemUtils operatingSystemUtils,
  })  : _operatingSystemUtils = operatingSystemUtils,
        super(
          'linux',
          platformType: PlatformType.linux,
          ephemeral: false,
          logger: logger,
          processManager: processManager,
          fileSystem: fileSystem,
          operatingSystemUtils: operatingSystemUtils,
        );

  final OperatingSystemUtils _operatingSystemUtils;

  @override
  bool isSupported() => true;

  @override
  String get name => 'Linux';

  @override
  late final Future<TargetPlatform> targetPlatform = () async {
    if (_operatingSystemUtils.hostPlatform == HostPlatform.linux_x64) {
      return TargetPlatform.linux_x64;
    }
    return TargetPlatform.linux_arm64;
  }();

  @override
  bool isSupportedForProject(final FlutterProject flutterProject) {
    return flutterProject.linux.existsSync();
  }

  @override
  Future<void> buildForDevice({
    final String? mainPath,
    required final BuildInfo buildInfo,
  }) async {
    await buildLinux(
      FlutterProject.current().linux,
      buildInfo,
      target: mainPath,
      targetPlatform: await targetPlatform,
    );
  }

  @override
  String executablePathForDevice(covariant final LinuxApp package, final BuildInfo buildInfo) {
    return package.executable(buildInfo.mode);
  }
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices({
    required final Platform platform,
    required final FeatureFlags featureFlags,
    required final OperatingSystemUtils operatingSystemUtils,
    required final FileSystem fileSystem,
    required final ProcessManager processManager,
    required final Logger logger,
  }) : _platform = platform,
       _linuxWorkflow = LinuxWorkflow(
          platform: platform,
          featureFlags: featureFlags,
       ),
       _fileSystem = fileSystem,
       _logger = logger,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       super('linux devices');

  final Platform _platform;
  final LinuxWorkflow _linuxWorkflow;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  bool get supportsPlatform => _platform.isLinux;

  @override
  bool get canListAnything => _linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({ final Duration? timeout }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(
        logger: _logger,
        processManager: _processManager,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['linux'];
}
