// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../device.dart';
import 'windows_workflow.dart';

/// A device that represents a desktop Windows target.
class WindowsDevice extends Device {
  WindowsDevice() : super('Windows');

  @override
  void clearLogs() {}

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) => NoOpDeviceLogReader('windows');

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
  String get name => 'Windows';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
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
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_x64;

  @override
  Future<bool> uninstallApp(ApplicationPackage app) {
    throw UnimplementedError();
  }
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices() : super('windows devices');

  @override
  bool get supportsPlatform => platform.isWindows;

  @override
  bool get canListAnything => windowsWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      WindowsDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
