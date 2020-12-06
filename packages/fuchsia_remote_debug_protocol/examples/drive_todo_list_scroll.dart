// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:fuchsia_remote_debug_protocol/fuchsia_remote_debug_protocol.dart';
import 'package:fuchsia_remote_debug_protocol/logging.dart';

/// Runs through a simple usage of the fuchsia_remote_debug_protocol library:
/// connects to a remote machine at the address in argument 1 (interface
/// optional for argument 2) to drive an application named 'todo_list' by
/// scrolling up and down on the main scaffold.
///
/// Make sure to set up your application (you can change the name from
/// 'todo_list') follows the setup for testing with the flutter driver:
/// https://flutter.dev/testing/#adding-the-flutter_driver-dependency
///
/// Example usage:
///
///     $ dart examples/driver_todo_list_scroll.dart \
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

  const Pattern isolatePattern = 'todo_list';
  print('Finding $isolatePattern');
  final List<IsolateRef> refs =
      await connection.getMainIsolatesByPattern(isolatePattern);

  final IsolateRef ref = refs.first;
  print('Driving ${ref.name}');
  final FlutterDriver driver = await FlutterDriver.connect(
      dartVmServiceUrl: ref.dartVm.uri.toString(),
      isolateNumber: ref.number,
      printCommunication: true,
      logCommunicationToFile: false);
  for (int i = 0; i < 5; ++i) {
    // Scrolls down 300px.
    await driver.scroll(find.byType('Scaffold'), 0.0, -300.0,
        const Duration(milliseconds: 300));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Scrolls up 300px.
    await driver.scroll(find.byType('Scaffold'), 300.0, 300.0,
        const Duration(milliseconds: 300));
  }
  await driver.close();
  await connection.stop();
}
