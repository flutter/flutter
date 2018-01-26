// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:process/process.dart';
import 'package:logging/logging.dart';

import 'dart/fuchsia_dart_vm.dart';
import 'fuchsia_device_command_runner.dart';

final String ipv4Loopback = InternetAddress.LOOPBACK_IP_V4.address;

final Logger _log = new Logger('flutter_fuchsia::flutter_views');

final ProcessManager _processManager = new LocalProcessManager();

/// Persistent VM service cache to avoid repeating handshakes across function
/// calls.
final HashMap<int, FuchsiaDartVm> _fuchsiaDartVmCache =
    new HashMap<int, FuchsiaDartVm>();

/// Returns a list of flutter views for the given [ipv4Address].
/// TODO(awdavies): just returns flutter view names. Needs to return
/// FlutterView objects of some kind that contain a JSON RPC peer.
Future<List<String>> getFlutterViews(
    String ipv4Address, String fuchsiaRoot, String buildType) async {
  final List<String> views = <FlutterView>[];
  final List<_ForwardedPort> ports =
      await _forwardLocalPortsToDeviceServicePorts(
          ipv4Address, fuchsiaRoot, buildType);
  if (ports.isEmpty) {
    return views;
  }
  for (_ForwardedPort fp in ports) {
    if (!await _checkPort(fp.port)) continue;
    final FuchsiaDartVm vmService = await _getFuchsiaDartVm(fp.port);
    List<String> viewNames = await vmService.listFlutterViewsByName();
    views.addAll(viewNames);
  }
  await Future.wait(ports.map((_ForwardedPort fp) => fp.stop()));
  return views;
}

Future<bool> _checkPort(int port) async {
  bool connected = true;
  Socket s;
  try {
    s = await Socket.connect(ipv4Loopback, port);
  } catch (_) {
    connected = false;
  }
  if (s != null) await s.close();
  return connected;
}

Future<FuchsiaDartVm> _getFuchsiaDartVm(int port) async {
  if (!_fuchsiaDartVmCache.containsKey(port)) {
    final String addr = 'http://$ipv4Loopback:$port';
    final Uri uri = Uri.parse(addr);
    final FuchsiaDartVm fuchsiaDartVm = FuchsiaDartVm.connect(uri);
    _fuchsiaDartVmCache[port] = fuchsiaDartVm;
  }
  return _fuchsiaDartVmCache[port];
}

/// Forwards a series of local device ports to the [deviceIpv4Address] using SSH
/// port forwarding. Returns a [List] of [_ForwardedPort] objects that the caller
/// must close when done using. Needs [fuchsiaRoot] and [buildType] to
/// determine the path for the SSH config.
Future<List<_ForwardedPort>> _forwardLocalPortsToDeviceServicePorts(
    String deviceIpv4Address, String fuchsiaRoot, String buildType) async {
  final String config = '$fuchsiaRoot/out/$buildType/ssh-keys/ssh_config';
  final List<int> servicePorts =
      await getDeviceServicePorts(deviceIpv4Address, fuchsiaRoot, buildType);
  return Future.wait(servicePorts.map((int deviceServicePort) {
    return _ForwardedPort.start(config, deviceIpv4Address, deviceServicePort);
  }));
}

/// Returns a list of the device service ports on success, else returns an empty
/// list.
Future<List<int>> getDeviceServicePorts(
    String ipv4Address, String fuchsiaRoot, String buildType) async {
  final FuchsiaDeviceCommandRunner runner = new FuchsiaDeviceCommandRunner(
    ipv4Address: ipv4Address,
    fuchsiaRoot: fuchsiaRoot,
    buildType: buildType,
  );
  final List<String> lsOutput = await runner.run('ls /tmp/dart.services');
  final List<int> ports = <int>[];
  for (String s in lsOutput) {
    final String trimmed = s.trim();
    final int lastSpace = trimmed.lastIndexOf(' ');
    final String lastWord = trimmed.substring(lastSpace + 1);
    if ((lastWord != '.') && (lastWord != '..')) {
      final int value = int.parse(lastWord, onError: (_) => null);
      if (value != null) ports.add(value);
    }
  }
  return ports;
}

// Instances of this class represent a running ssh tunnel from the host to a
// VM service running on a Fuchsia device. [process] is the ssh process running
// the tunnel and [port] is the local port.
class _ForwardedPort {
  final String _remoteAddress;
  final int _remotePort;
  final int _localPort;
  final Process _process;
  final String _sshConfig;

  _ForwardedPort._(this._remoteAddress, this._remotePort, this._localPort,
      this._process, this._sshConfig);

  int get port => _localPort;

  static Future<_ForwardedPort> start(
      String sshConfig, String address, int remotePort) async {
    final int localPort = await _potentiallyAvailablePort();
    if (localPort == 0) {
      printStatus(
          '_ForwardedPort failed to find a local port for $address:$remotePort');
      return new _ForwardedPort._(null, 0, 0, null, null);
    }
    final List<String> command = <String>[
      'ssh',
      '-F',
      sshConfig,
      '-nNT',
      '-L',
      '$localPort:$ipv4Loopback:$remotePort',
      address
    ];
    _log.fine("_ForwardedPort running '${command.join(' ')}'");
    final Process process = await _processManager.start(command);
    process.exitCode.then((int c) {
      _log.fine("'${command.join(' ')}' exited with exit code $c");
    });
    _log.fine('Set up forwarding from $localPort to $address:$remotePort');
    return new _ForwardedPort._(
        address, remotePort, localPort, process, sshConfig);
  }

  Future<Null> stop() async {
    // Kill the original ssh process if it is still around.
    if (_process != null) {
      _log.fine('_ForwardedPort killing ${_process.pid} for port $_localPort');
      _process.kill();
    }
    // Cancel the forwarding request.
    final List<String> command = <String>[
      'ssh',
      '-F',
      _sshConfig,
      '-O',
      'cancel',
      '-L',
      '$_localPort:$ipv4Loopback:$_remotePort',
      _remoteAddress
    ];
    final ProcessResult result = await _processManager.run(command);
    _log.fine(command.join(' '));
    if (result.exitCode != 0) {
      _log.severe(
          'Command failed:\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
    }
  }

  static Future<int> _potentiallyAvailablePort() async {
    int port = 0;
    ServerSocket s;
    try {
      s = await ServerSocket.bind(ipv4Loopback, 0);
      port = s.port;
    } catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      _log.severe('_potentiallyAvailablePort failed: $e');
    }
    if (s != null) await s.close();
    return port;
  }
}
