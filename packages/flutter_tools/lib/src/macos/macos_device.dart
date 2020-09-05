// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../macos/application_package.dart';
import '../project.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _processManager = processManager,
       _logger = logger,
       super(
        'macos',
        platformType: PlatformType.macos,
        ephemeral: false,
        processManager: processManager,
        logger: logger,
      );

  final ProcessManager _processManager;
  final Logger _logger;

  @override
  bool isSupported() => true;

  @override
  String get name => 'macOS';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.macos.existsSync();
  }

  @override
  Future<void> buildForDevice(
    covariant MacOSApp package, {
    String mainPath,
    BuildInfo buildInfo,
  }) async {
    await buildMacOS(
      flutterProject: FlutterProject.current(),
      buildInfo: buildInfo,
      targetOverride: mainPath,
      verboseLogging: _logger.isVerbose,
    );
  }

  @override
  String executablePathForDevice(covariant MacOSApp package, BuildMode buildMode) {
    return package.executable(buildMode);
  }

  @override
  void onAttached(covariant MacOSApp package, BuildMode buildMode, Process process) {
    // Bring app to foreground. Ideally this would be done post-launch rather
    // than post-attach, since this won't run for release builds, but there's
    // no general-purpose way of knowing when a process is far enoug along in
    // the launch process for 'open' to foreground it.
    _processManager.run(<String>[
      'open', package.applicationBundle(buildMode),
    ]).then((ProcessResult result) {
      if (result.exitCode != 0) {
        print('Failed to foreground app; open returned ${result.exitCode}');
      }
    });
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    @required Platform platform,
    @required MacOSWorkflow macOSWorkflow,
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _logger = logger,
       _platform = platform,
       _macOSWorkflow = macOSWorkflow,
       _processManager = processManager,
       super('macOS devices');

  final MacOSWorkflow _macOSWorkflow;
  final Platform _platform;
  final ProcessManager _processManager;
  final Logger _logger;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything => _macOSWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      MacOSDevice(processManager: _processManager, logger: _logger),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
