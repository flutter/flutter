// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../desktop.dart';
import '../device.dart';
import 'macos_workflow.dart';

/// A device which represents a desktop MacOS target.
class MacOSDevice extends Device {
  MacOSDevice() : super('MacOS');

  @override
  void clearLogs() {}

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) => NoOpDeviceLogReader('macos');

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
  String get name => 'MacOS';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async {
    final ProcessResult result = await processManager.run(<String>['sw_vers']);
    if (result.exitCode != 0) {
      return 'unknown';
    }
    return parseSoftwareVersions(result.stdout);
  }

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

/// Parses the output from `sw_vers` on MacOS.
///
/// Example output:
///     $ sw_vers
///     > ProductName:	Mac OS X
///       ProductVersion:	11.00.00
///       BuildVersion:	16G3000
@visibleForTesting
String parseSoftwareVersions(String input) {
  final List<String> lines = input.split('\n');
  if (lines.length < 2) {
    return '';
  }
  final String name = lines[0].replaceFirst(RegExp(r'ProductName:\s*'), '');
  final String version = lines[1].replaceFirst(RegExp(r'ProductVersion:\s*'), '');
  return '$name $version';
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
