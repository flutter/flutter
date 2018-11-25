// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/time.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../vmservice.dart';

import 'fuchsia_sdk.dart';
import 'fuchsia_workflow.dart';

final String _ipv4Loopback = InternetAddress.loopbackIPv4.address;
final String _ipv6Loopback = InternetAddress.loopbackIPv6.address;

/// Read the log for a particular device.
class _FuchsiaLogReader extends DeviceLogReader {
  _FuchsiaLogReader(this._device, [this._app]);

  static final RegExp _flutterLogOutput = RegExp(r'INFO: \w+\(flutter\): ');

  FuchsiaDevice _device;
  ApplicationPackage _app;

  @override String get name => _device.name;

  Stream<String> _logLines;
  @override
  Stream<String> get logLines {
    _logLines ??= _processLogs(fuchsiaSdk.syslogs());
    return _logLines;
  }

  Stream<String> _processLogs(Stream<String> lines) {
    // Get the starting time of the log processor to filter logs from before
    // the process attached.
    final DateTime startTime = systemClock.now();
    // Determine if line comes from flutter, and optionally whether it matches
    // the correct fuchsia module.
    final RegExp matchRegExp = _app == null
      ? _flutterLogOutput
      : RegExp('INFO: ${_app.name}\\(flutter\\): ');
    return Stream<String>.eventTransformed(
      lines,
      (Sink<String> outout) => _FuchsiaLogSink(outout, matchRegExp, startTime),
    );
  }

  @override
  String toString() => name;
}

class _FuchsiaLogSink implements EventSink<String> {
  _FuchsiaLogSink(this._outputSink, this._matchRegExp, this._startTime);

  static final RegExp _utcDateOutput = RegExp(r'\d+\-\d+\-\d+ \d+:\d+:\d+');
  final EventSink<String> _outputSink;
  final RegExp _matchRegExp;
  final DateTime _startTime;

  @override
  void add(String line) {
    if (!_matchRegExp.hasMatch(line)) {
      return;
    }
    final String rawDate = _utcDateOutput.firstMatch(line)?.group(0);
    if (rawDate == null) {
      return;
    }
    final DateTime logTime = DateTime.parse(rawDate);
    if (logTime.millisecondsSinceEpoch < _startTime.millisecondsSinceEpoch) {
      return;
    }
    _outputSink.add('[${logTime.toLocal()}] Flutter: ${line.split(_matchRegExp).last}');
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() { _outputSink.close(); }
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
      final String id = await fuchsiaSdk.netaddr();
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
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => false;

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
  DeviceLogReader getLogReader({ApplicationPackage app}) => _logReader ??= _FuchsiaLogReader(this, app);
  _FuchsiaLogReader _logReader;

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= _FuchsiaPortForwarder(this);
  _FuchsiaPortForwarder _portForwarder;

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => false;

  /// List the ports currently running a dart observatory.
  Future<List<int>> servicePorts() async {
    final String lsOutput = await shell('ls /tmp/dart.services');
    return parseFuchsiaDartPortOutput(lsOutput);
  }

  /// Run `command` on the Fuchsia device shell.
  Future<String> shell(String command) async {
    final RunResult result = await runAsync(<String>[
      'ssh', '-F', fuchsiaArtifacts.sshConfig.absolute.path, id, command]);
    if (result.exitCode != 0) {
      if (result.stderr.contains('/tmp/dart.services: No such file or directory')) {
        throwToolExit('No Dart Observatories found. Are you running a debug build?');
      }
      throwToolExit('Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
      return null;
    }
    return result.stdout;
  }

  /// Finds the first port running a VM matching `isolateName` from the
  /// provided set of `ports`.
  ///
  /// Returns null if no isolate port can be found.
  ///
  // TODO(jonahwilliams): replacing this with the hub will require an update
  // to the flutter_runner.
  Future<int> findIsolatePort(String isolateName, List<int> ports) async {
    for (int port in ports) {
      try {
        // Note: The square-bracket enclosure for using the IPv6 loopback
        // didn't appear to work, but when assigning to the IPv4 loopback device,
        // netstat shows that the local port is actually being used on the IPv6
        // loopback (::1).
        final Uri uri = Uri.parse('http://[$_ipv6Loopback]:$port');
        final VMService vmService = await VMService.connect(uri);
        await vmService.getVM();
        await vmService.refreshViews();
        for (FlutterView flutterView in vmService.vm.views) {
          if (flutterView.uiIsolate == null) {
            continue;
          }
          final Uri address = flutterView.owner.vmService.httpAddress;
          if (flutterView.uiIsolate.name.contains(isolateName)) {
            return address.port;
          }
        }
      } on SocketException catch (err) {
        printTrace('Failed to connect to $port: $err');
      }
    }
    throwToolExit('No ports found running $isolateName');
    return null;
  }
}

class _FuchsiaPortForwarder extends DevicePortForwarder {
  _FuchsiaPortForwarder(this.device);

  final FuchsiaDevice device;
  final Map<int, Process> _processes = <int, Process>{};

  @override
  Future<int> forward(int devicePort, {int hostPort}) async {
    hostPort ??= await _findPort();
    // Note: the provided command works around a bug in -N, see US-515
    // for more explanation.
    final List<String> command = <String>[
      'ssh', '-6', '-F', fuchsiaArtifacts.sshConfig.absolute.path, '-nNT', '-vvv', '-f',
      '-L', '$hostPort:$_ipv4Loopback:$devicePort', device.id, 'true'
    ];
    final Process process = await processManager.start(command);
    process.exitCode.then((int exitCode) { // ignore: unawaited_futures
      if (exitCode != 0) {
        throwToolExit('Failed to forward port:$devicePort');
      }
    });
    _processes[hostPort] = process;
    _forwardedPorts.add(ForwardedPort(hostPort, devicePort));
    return hostPort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => _forwardedPorts;
  final List<ForwardedPort> _forwardedPorts = <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    _forwardedPorts.remove(forwardedPort);
    final Process process = _processes.remove(forwardedPort.hostPort);
    process?.kill();
    final List<String> command = <String>[
        'ssh', '-F', fuchsiaArtifacts.sshConfig.absolute.path, '-O', 'cancel', '-vvv',
        '-L', '${forwardedPort.hostPort}:$_ipv4Loopback:${forwardedPort.devicePort}', device.id];
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      throwToolExit(result.stderr);
    }
  }

  static Future<int> _findPort() async {
    int port = 0;
    ServerSocket serverSocket;
    try {
      serverSocket = await ServerSocket.bind(_ipv4Loopback, 0);
      port = serverSocket.port;
    } catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      printTrace('_findPort failed: $e');
    }
    if (serverSocket != null)
      await serverSocket.close();
    return port;
  }
}

class FuchsiaModulePackage extends ApplicationPackage {
  FuchsiaModulePackage({@required this.name}) : super(id: name);

  @override
  final String name;
}

/// Parses output from `dart.services` output on a fuchsia device.
///
/// Example output:
///     $ ls /tmp/dart.services
///     > d  2          0 .
///     > -  1          0 36780
@visibleForTesting
List<int> parseFuchsiaDartPortOutput(String text) {
  final List<int> ports = <int>[];
  if (text == null)
    return ports;
  for (String line in text.split('\n')) {
    final String trimmed = line.trim();
    final int lastSpace = trimmed.lastIndexOf(' ');
    final String lastWord = trimmed.substring(lastSpace + 1);
    if ((lastWord != '.') && (lastWord != '..')) {
      final int value = int.tryParse(lastWord);
      if (value != null) {
        ports.add(value);
      }
    }
  }
  return ports;
}
