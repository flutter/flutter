// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../device.dart';

import 'fuchsia_sdk.dart';
import 'fuchsia_workflow.dart';

/// Read the log for a particular device.
class _FuchsiaLogReader extends DeviceLogReader {
  _FuchsiaLogReader(this._device);

  FuchsiaDevice _device;

  @override String get name => _device.name;

  Stream<String> _logLines;
  @override
  Stream<String> get logLines {
    _logLines ??= const Stream<String>.empty();
    return _logLines;
  }

  @override
  String toString() => name;
}

class FuchsiaDevices extends PollingDeviceDiscovery {
  FuchsiaDevices() : super('Fuchsia devices');

  @override
  bool get supportsPlatform => platform.isLinux || platform.isMacOS;

  @override
  bool get canListAnything => fuchsiaWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!fuchsiaWorkflow.canListDevices) {
      return <Device>[];
    }
    final String text = await fuchsiaSdk.netls();
    return parseFuchsiaDeviceOutput(text);
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

/// Parses output from the netls tool into fuchsia devices.
///
/// Example output:
///     $ ./netls
///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
@visibleForTesting
List<FuchsiaDevice> parseFuchsiaDeviceOutput(String text) {
  final List<FuchsiaDevice> devices = <FuchsiaDevice>[];
  for (String rawLine in text.trim().split('\n')) {
    final String line = rawLine.trim();
    if (!line.startsWith('device'))
      continue;
    // ['device', 'device name', '(id)']
    final List<String> words = line.split(' ');
    final String name = words[1];
    final String id = words[2].substring(1, words[2].length - 1);
    devices.add(FuchsiaDevice(id, name: name));
  }
  return devices;
}

class FuchsiaDevice extends Device {
  FuchsiaDevice(String id, { this.name }) : super(id);

  @override
  bool get supportsHotMode => true;

  @override
  final String name;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) => Future<bool>.value(false);

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool applicationNeedsRebuild = false,
    bool usesTerminalUi = false,
    bool ipv6 = false,
  }) => Future<void>.error('unimplemented');

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on Fuchsia.
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia;

  @override
  Future<String> get sdkNameAndVersion async => 'Fuchsia';

  _FuchsiaLogReader _logReader;
  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    _logReader ??= _FuchsiaLogReader(this);
    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder => null;

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => false;
}
