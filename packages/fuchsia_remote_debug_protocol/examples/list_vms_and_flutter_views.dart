// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import '../lib/fuchsia_remote_debug_protocol.dart';
import '../lib/lib_logging.dart' as lib_logging;

/// Runs through a simple usage of the fuchsia_remote_debug_protocol library:
/// connects to a remote machine at the address in argument 1 (interface
/// optional for argument 2) to list all active flutter views and Dart VM's
/// running on said device.
Future<Null> main(List<String> args) async {
  // Log only at info level within the library.
  lib_logging.Logger.globalLevel = lib_logging.LoggingLevel.info;
  final String address = args[0];
  final String interface = args.length > 1 ? args[1] : '';
  // Example ssh config path for the fuchsia device after having made a local
  // build.
  final String sshConfigPath = '../../out/release-x86-64/ssh-keys/ssh_config';
  print('On $address, the following Dart VM ports are running:');
  for (int port in await FuchsiaRemoteConnection.getDeviceServicePorts(
      address, interface, sshConfigPath)) {
    print('\t$port');
  }
  print('');

  final FuchsiaRemoteConnection connection =
      await FuchsiaRemoteConnection.connect(address, interface, sshConfigPath);
  print('The following Flutter views are running:');
  for (FlutterView view in await connection.getFlutterViews()) {
    print('\t${view.name ?? view.id}');
  }
  await connection.stop();
}
