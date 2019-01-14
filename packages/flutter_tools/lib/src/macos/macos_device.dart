// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/application_package.dart';

import 'package:flutter_tools/src/build_info.dart';

import '../base/platform.dart';
import '../device.dart';
import 'macos_workflow.dart';

/// A device which represents a desktop MacOS target.
class MacOSDevice extends Device {
  MacOSDevice() : super('macos_device');

  @override
  void clearLogs() {}

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) => _NoOpDeviceLogReader();

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
  String get name => 'macos';

  @override
  DevicePortForwarder get portForwarder => const _NoOpDevicePortForwarder();

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

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices() : super('Macos devices');

  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => macOSWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    return <Device>[
      MacOSDevice()
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

class _NoOpDeviceLogReader implements DeviceLogReader {
  _NoOpDeviceLogReader();

  @override
  int appPid;

  @override
  Stream<String> get logLines => const Stream<String>.empty();

  @override
  String get name => 'macos';
}

class _NoOpDevicePortForwarder implements DevicePortForwarder {
  const _NoOpDevicePortForwarder();

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    if (hostPort != null) {
      throw UnimplementedError();
    }
    return devicePort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {}
}