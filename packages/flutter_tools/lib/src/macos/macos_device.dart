// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../cache.dart';
import '../desktop.dart';
import '../device.dart';
import '../globals.dart';
import '../macos/application_package.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends Device {
  MacOSDevice() : super(
      'macOS',
      category: Category.desktop,
      platformType: PlatformType.macos,
      ephemeral: false,
  );

  @override
  void clearLogs() { }

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    return _deviceLogReader;
  }
  final DesktopLogReader _deviceLogReader = DesktopLogReader();

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  bool isSupported() => true;

  @override
  String get name => 'macOS';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;

  @override
  Future<LaunchResult> startApp(
    covariant MacOSApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    // Stop any running applications with the same executable.
    if (!prebuiltApplication) {
      Cache.releaseLockEarly();
      await buildMacOS(
        flutterProject: FlutterProject.current(),
        buildInfo: debuggingOptions?.buildInfo,
        targetOverride: mainPath,
      );
    }

    // Ensure that the executable is locatable.
    final String executable = package.executable(debuggingOptions?.buildInfo?.mode);
    if (executable == null) {
      printError('Unable to find executable to run');
      return LaunchResult.failed();
    }

    // Make sure to call stop app after we've built.
    _lastBuiltMode = debuggingOptions?.buildInfo?.mode;
    await stopApp(package);
    final Process process = await processManager.start(<String>[
      executable
    ]);
    if (debuggingOptions?.buildInfo?.isRelease == true) {
      return LaunchResult.succeeded();
    }
    _deviceLogReader.initializeProcess(process);
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(_deviceLogReader);
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      // Bring app to foreground.
      await processManager.run(<String>[
        'open', package.applicationBundle(debuggingOptions?.buildInfo?.mode),
      ]);
      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  // TODO(jonahwilliams): implement using process manager.
  // currently we rely on killing the isolate taking down the application.
  @override
  Future<bool> stopApp(covariant MacOSApp app) async {
    return killProcess(app.executable(_lastBuiltMode));
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin_x64;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.macos.existsSync();
  }

  // Track the last built mode from startApp.
  BuildMode _lastBuiltMode;
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices() : super('macOS devices');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => macOSWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      MacOSDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
