// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../application_package.dart';
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
  MacOSDevice() : super('macOS');

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
  String get name => 'macOS';

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
    if (!prebuiltApplication) {
      return LaunchResult.failed();
    }
    final Process process = await processManager.start(<String>[package.executable]);
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
