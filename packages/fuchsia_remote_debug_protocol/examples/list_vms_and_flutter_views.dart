// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';
import 'package:fuchsia_remote_debug_protocol/logging.dart';

/// Runs through a simple usage of the fuchsia_remote_debug_protocol library:
/// connects to a remote machine at the address in argument 1 (interface
/// optional for argument 2) to list all active flutter views and Dart VMs
/// running on said device. This uses an SSH config file (optional, depending
/// on your setup).
///
/// Example usage:
///
///     $ dart examples/list_vms_and_flutter_views.dart \
///         fe80::8eae:4cff:fef4:9247 eno1
Future<void> main(List<String> args) async {
  // Log only at info level within the library. If issues arise, this can be
  // changed to [LoggingLevel.all] or [LoggingLevel.fine] to see more
  // information.
  Logger.globalLevel = LoggingLevel.info;
  if (args.isEmpty) {
    print('Expects an IP address and/or network interface');
    return;
  }
  final String address = args[0];
  final String interface = args.length > 1 ? args[1] : '';
  // Example ssh config path for the Fuchsia device after having made a local
  // build.
  const String sshConfigPath =
      '../../../fuchsia/out/x64rel/ssh-keys/ssh_config';
  final FuchsiaRemoteConnection connection =
      await FuchsiaRemoteConnection.connect(address, interface, sshConfigPath);
  print('On $address, the following Dart VM ports are running:');
  for (final int port in await connection.getDeviceServicePorts()) {
    print('\t$port');
  }
  print('');

  print('The following Flutter views are running:');
  for (final FlutterView view in await connection.getFlutterViews()) {
    print('\t${view.name ?? view.id}');
  }
  await connection.stop();
}
