// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop.dart';
import '../device.dart';
import 'linux_workflow.dart';

/// A device which represents a desktop linux target.
class LinuxDevice extends Device {
  LinuxDevice() : super('linux_device');

  @override
  void clearLogs() {}

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) => NoOpDeviceLogReader('linux');

  @override
  Future<bool> installApp(ApplicationPackage app) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) {
    throw UnimplementedError();
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  String get name => 'linux';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => '';

  @override
  Future<LaunchResult> startApp(ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool applicationNeedsRebuild = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) {
    throw UnimplementedError();
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin_x64;

  @override
  Future<bool> uninstallApp(ApplicationPackage app) {
    throw UnimplementedError();
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
    return <Device>[
      LinuxDevice()
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
