// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Convenience methods for Flutter application driving on Fuchsia. Can
/// be run on either a host machine (making a remote connection to a Fuchsia
/// device), or on the target Fuchsia machine.
import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';

import 'error.dart';

// TODO(awdavies): Update this to use the hub.
final Directory _kDartPortDir = Directory('/tmp/dart.services');

class _DummyPortForwarder implements PortForwarder {
  _DummyPortForwarder(this._port, this._remotePort);

  final int _port;
  final int _remotePort;

  @override
  int get port => _port;

  @override
  int get remotePort => _remotePort;

  @override
  Future<void> stop() async {}
}

class _DummySshCommandRunner implements SshCommandRunner {
  _DummySshCommandRunner();

  final Logger _log = Logger('_DummySshCommandRunner');

  @override
  String get sshConfigPath => null;

  @override
  String get address => InternetAddress.loopbackIPv4.address;

  @override
  String get interface => null;

  @override
  Future<List<String>> run(String command) async {
    try {
      return List<String>.of(_kDartPortDir
          .listSync(recursive: false, followLinks: false)
          .map((FileSystemEntity entity) => entity.path
              .replaceAll(entity.parent.path, '')
              .replaceFirst(Platform.pathSeparator, '')));
    } on FileSystemException catch (e) {
      _log.warning('Error listing directory: $e');
    }
    return <String>[];
  }
}

Future<PortForwarder> _dummyPortForwardingFunction(
  String address,
  int remotePort, [
  String interface = '',
  String configFile,
]) async {
  return _DummyPortForwarder(remotePort, remotePort);
}

/// Utility class for creating connections to the Fuchsia Device.
///
/// If executed on a host (non-Fuchsia device), behaves the same as running
/// [FuchsiaRemoteConnection.connect] whereby the `FUCHSIA_REMOTE_URL` and
/// `FUCHSIA_SSH_CONFIG` variables must be set. If run on a Fuchsia device, will
/// connect locally without need for environment variables.
class FuchsiaCompat {
  static void _init() {
    fuchsiaPortForwardingFunction = _dummyPortForwardingFunction;
  }

  /// Restores state to normal if running on a Fuchsia device.
  ///
  /// Noop if running on the host machine.
  static void cleanup() {
    restoreFuchsiaPortForwardingFunction();
  }

  /// Creates a connection to the Fuchsia device's Dart VM's.
  ///
  /// See [FuchsiaRemoteConnection.connect] for more details.
  /// [FuchsiaCompat.cleanup] must be called when the connection is no longer in
  /// use. It is the caller's responsibility to call
  /// [FuchsiaRemoteConnection.stop].
  static Future<FuchsiaRemoteConnection> connect() async {
    FuchsiaCompat._init();
    return FuchsiaRemoteConnection
        .connectWithSshCommandRunner(_DummySshCommandRunner());
  }
}
