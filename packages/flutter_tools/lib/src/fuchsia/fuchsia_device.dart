// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';

import 'fuchsia_sdk.dart';
import 'fuchsia_workflow.dart';

final String _ipv4Loopback = InternetAddress.loopbackIPv4.address;

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
    final List<FuchsiaDevice> devices = <FuchsiaDevice>[];
    for (String name in parseFuchsiaDeviceOutput(text)) {
      final String id = await fuchsiaSdk.netaddr(name);
      devices.add(FuchsiaDevice(id, name: name));
    }
    return devices;
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

/// Parses output from the netls tool into fuchsia devices names.
///
/// Example output:
///     $ ./netls
///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
@visibleForTesting
List<String> parseFuchsiaDeviceOutput(String text) {
  final List<String> names = <String>[];
  for (String rawLine in text.trim().split('\n')) {
    final String line = rawLine.trim();
    if (!line.startsWith('device'))
      continue;
    // ['device', 'device name', '(id)']
    final List<String> words = line.split(' ');
    final String name = words[1];
    names.add(name);
  }
  return names;
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

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    return _logReader ??= _FuchsiaLogReader(this);
  }
  _FuchsiaLogReader _logReader;

  @override
  DevicePortForwarder get portForwarder {
    return _portForwarder ??= _FuchsiaPortForwarder(this);
  }
  _FuchsiaPortForwarder _portForwarder;

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => false;

  /// Run `command` on the fuchsia device.
  Future<String> run(String command) => fuchsiaSdk.run(this, command);

  /// Finds the first port running a VM matching `isolateName` on `device`.
  ///
  /// TODO(jonahwilliams): replacing this with the hub will require an update
  /// to the flutter_runner.
  Future<int> servicePort(String isolateName) => fuchsiaSdk.servicePort(this, isolateName);
}

class _FuchsiaPortForwarder extends DevicePortForwarder {
  _FuchsiaPortForwarder(this.device);

  final FuchsiaDevice device;
  Process _process;

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    hostPort ??= 0;
    final List<String> command = <String>[
      'ssh', '-F', fuchsiaSdk.sshConfig.absolute.path, '-nNT', '-vvv', '-f',
      '-L', '$hostPort:$_ipv4Loopback:$devicePort', device.id, 'date',
    ];
    _process = await processManager.start(command);
    _process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(printTrace);
    _process.exitCode.then<void>((int exitCode) { // ignore: unawaited_futures
      printTrace('exited with exit code $exitCode');
    });
    _forwardedPorts.add(ForwardedPort(hostPort, devicePort));
    return hostPort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;
  final List<ForwardedPort> _forwardedPorts = <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    _forwardedPorts.remove(forwardedPort);
    _process.kill();
    final List<String> command = <String>[
        'ssh', '-F', fuchsiaSdk.sshConfig.absolute.path, '-O', 'cancel', '-vvv',
        '-L', '${forwardedPort.hostPort}:$_ipv4Loopback:${forwardedPort.devicePort}', device.id];
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      throwToolExit(result.stderr);
    }
  }
}
