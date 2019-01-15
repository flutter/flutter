// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../macos/application_package.dart';
import '../protocol_discovery.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends Device {
  MacOSDevice() : super('MacOS');

  @override
  void clearLogs() {}

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) => NoOpDeviceLogReader('macos');

  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  String get name => 'MacOS';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;

  @override
  Future<LaunchResult> startApp(covariant MacOSApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool applicationNeedsRebuild = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication || !debuggingOptions.buildInfo.isDebug) {
      return LaunchResult.failed();
    }
    // The location of these files is based on the examples in the flutter
    // desktop embedding repo and may not be final.
    final String location = fs.path.join(package.deviceBundlePath, 'Contents', 'MacOS', package.name.replaceFirst('.app', ''));
    if (! await fs.file(location).exists()) {
      throwToolExit('Could not find MacOS binary at $location');
    }
    final Process process = await processManager.start(<String>[location]);
    final MacOSLogReader logReader = MacOSLogReader(package, process);
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(logReader);
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin_x64;

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices() : super('macos devices');

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
      MacOSDevice()
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

class MacOSLogReader extends DeviceLogReader {
  MacOSLogReader(this.macOSApp, this.process);

  final MacOSApp macOSApp;
  final Process process;

  @override
  Stream<String> get logLines {
    return process.stdout.transform(utf8.decoder);
  }

  @override
  String get name => macOSApp.displayName;
}
