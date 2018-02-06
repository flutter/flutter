// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:process/process.dart';

import 'common/logging.dart';
import 'dart/dart_vm.dart';
import 'runners/ssh_command_runner.dart';

final String _ipv4Loopback = InternetAddress.LOOPBACK_IP_V4.address;

/// Fallback hostname in the event that the standard loopback fails.
final String _ipv4SocketFallback = 'localhost';

final ProcessManager _processManager = const LocalProcessManager();

final Logger _log = new Logger('FuchsiaRemoteConnection');

/// Manages a remote connection to a Fuchsia Device.
///
/// Provides affordances to observe and connect to Flutter views, isolates, and
/// perform actions on the Fuchsia device's various VM services.
///
/// Note that this class can be connected to several instances of the Fuchsia
/// device's Dart VM at any given time.
class FuchsiaRemoteConnection {
  final String _address;
  // TODO(awdavies): Remove this, and change it to an optional string pointing
  // to an SSH config.
  final String _fuchsiaRoot;
  final String _buildType;
  final List<_ForwardedPort> _forwardedVmServicePorts;

  /// VM service cache to avoid repeating handshakes across function
  /// calls. Keys a forwarded port to a DartVm connection instance.
  final HashMap<int, DartVm> _dartVmCache = <int, DartVm>{};

  FuchsiaRemoteConnection._(this._address, this._fuchsiaRoot, this._buildType,
      this._forwardedVmServicePorts);

  /// Opens a connection to a Fuchsia device.
  ///
  /// Accepts an `ipv4Address` to a Fuchsia device, and requires a root
  /// directory in which the Fuchsia Device was built (along with the
  /// `buildType`) in order to open the associated ssh_config for port
  /// forwarding.
  ///
  /// Once this function is called, the instance of `FuchsiaRemoteConnection`
  /// returned will keep all associated DartVM connections opened over the
  /// lifetime of the object.
  ///
  /// At its current state Dart VM connections will not be added or removed.
  ///
  /// TODO(awdavies): Remove this fuchsiaRoot and buildType nonsense.
  static Future<FuchsiaRemoteConnection> connect(
      String ipv4Address, String fuchsiaRoot, String buildType) async {
    final List<_ForwardedPort> ports =
        await _forwardLocalPortsToDeviceServicePorts(
            ipv4Address, fuchsiaRoot, buildType);

    return new FuchsiaRemoteConnection._(
        ipv4Address, fuchsiaRoot, buildType, ports);
  }

  /// Closes all open connections.
  Future<Null> stop() async {
    for (_ForwardedPort fp in _forwardedVmServicePorts) {
      // Closes VM service first to ensure that the connection is closed cleanly
      // on the target before shutting down the forwarding itself.
      final DartVm vmService = _dartVmCache[fp.port];
      _dartVmCache[fp.port] = null;
      await vmService?.stop();
      await fp.stop();
    }
  }

  /// Returns a list of `FlutterView` objects.
  ///
  /// This is across all connected DartVM connections that this class is
  /// managing.
  Future<List<FlutterView>> getFlutterViews() async {
    final List<FlutterView> views = <FlutterView>[];
    if (_forwardedVmServicePorts.isEmpty) {
      return views;
    }
    for (_ForwardedPort fp in _forwardedVmServicePorts) {
      _checkPort(fp.port);
      final DartVm vmService = await _getDartVm(fp.port);
      views.addAll(await vmService.getAllFlutterViews());
    }
    return views;
  }

  /// Attempts to create then close a socket. Throws an exception if the port
  /// cannot be opened.
  Future<Null> _checkPort(int port) async {
    Socket s;
    // First attempts to connect to IPV4 Loopback.
    try {
      s = await Socket.connect(_ipv4Loopback, port);
    } catch (e) {
      _log.warning(
          'Unable to create a socket, attempting fallback after err: $e');
    }
    if (s == null) {
      try {
        s = await Socket.connect(_ipv4SocketFallback, port);
      } catch (_) {
        _log.severe('Fallback failed to connect. Giving up.');
        await s?.close();
        s?.destroy();
        rethrow;
      }
    }
    await s?.close();
    s?.destroy();
  }

  Future<DartVm> _getDartVm(int port) async {
    if (!_dartVmCache.containsKey(port)) {
      final String addr = 'http://$_ipv4Loopback:$port';
      final Uri uri = Uri.parse(addr);
      final DartVm dartVm = await DartVm.connect(uri);
      _dartVmCache[port] = dartVm;
    }
    return _dartVmCache[port];
  }

  /// Forwards a series of local device ports to the [deviceIpv4Address] using SSH
  /// port forwarding. Returns a [List] of [_ForwardedPort] objects that the caller
  /// must close when done using. Needs [fuchsiaRoot] and [buildType] to
  /// determine the path for the SSH config.
  static Future<List<_ForwardedPort>> _forwardLocalPortsToDeviceServicePorts(
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
  static Future<List<int>> getDeviceServicePorts(
      String ipv4Address, String fuchsiaRoot, String buildType) async {
    final SshCommandRunner runner = new SshCommandRunner(
      ipv4Address: ipv4Address,
      fuchsiaRoot: fuchsiaRoot,
      buildType: buildType,
    );
    final List<String> lsOutput = await runner.run('ls /tmp/dart.services');
    final List<int> ports = <int>[];

    // The output of lsOutput is a list of available ports as the Fuchsia dart
    // service advertises. An example lsOutput would look like:
    //
    // [ '31782\n', '1234\n', '11967' ]
    for (String s in lsOutput) {
      final String trimmed = s.trim();
      final int lastSpace = trimmed.lastIndexOf(' ');
      final String lastWord = trimmed.substring(lastSpace + 1);
      if ((lastWord != '.') && (lastWord != '..')) {
        final int value = int.parse(lastWord, onError: (_) => null);
        if (value != null) {
          ports.add(value);
        }
      }
    }
    return ports;
  }
}

/// Instances of this class represent a running ssh tunnel.
///
/// The SSH tunnel is from the host to a VM service running on a Fuchsia device.
/// `process` is the ssh process running the tunnel and [port] is the local
/// port.
class _ForwardedPort {
  final String _remoteAddress;
  final int _remotePort;
  final int _localPort;
  final Process _process;
  final String _sshConfig;

  _ForwardedPort._(this._remoteAddress, this._remotePort, this._localPort,
      this._process, this._sshConfig);

  /// Gets the port on the localhost machine through which the SSH tunnel is
  /// being forwarded.
  int get port => _localPort;

  /// Starts SSH forwarding through a subprocess, and returns an instance of
  /// `_ForwardedPort`.
  static Future<_ForwardedPort> start(
      String sshConfig, String address, int remotePort) async {
    final int localPort = await _potentiallyAvailablePort();
    if (localPort == 0) {
      _log.warning(
          '_ForwardedPort failed to find a local port for $address:$remotePort');
      return new _ForwardedPort._(null, 0, 0, null, null);
    }
    final List<String> command = <String>[
      'ssh',
      '-F',
      sshConfig,
      '-nNT',
      '-L',
      '$localPort:$_ipv4Loopback:$remotePort',
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

  /// Kills the SSH forwarding command, then to ensure no ports are forwarded,
  /// runs the ssh 'cancel' command to shut down port forwarding completely.
  Future<Null> stop() async {
    // Kill the original ssh process if it is still around.
    _process?.kill();
    // Cancel the forwarding request.
    final List<String> command = <String>[
      'ssh',
      '-F',
      _sshConfig,
      '-O',
      'cancel',
      '-L',
      '$_localPort:$_ipv4Loopback:$_remotePort',
      _remoteAddress
    ];
    final ProcessResult result = await _processManager.run(command);
    _log.fine(command.join(' '));
    if (result.exitCode != 0) {
      _log.warning(
          'Command failed:\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
    }
  }

  static Future<int> _potentiallyAvailablePort() async {
    int port = 0;
    ServerSocket s;
    try {
      s = await ServerSocket.bind(_ipv4Loopback, 0);
      port = s.port;
    } catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      _log.warning('_potentiallyAvailablePort failed: $e');
    }
    await s?.close();
    return port;
  }
}
