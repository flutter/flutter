// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:process/process.dart';
import 'package:logging/logging.dart';

/// Runs a command remotely on a Fuchsia device. Requires a fuchsia root and
/// build type (to load the ssh config), and the ipv4 address of the fuchsia
/// device.
class FuchsiaDeviceCommandRunner {
  final Logger log = new Logger('FuchsiaDeviceCommandRunner');
  final ProcessManager processManager = new LocalProcessManager();
  final String ipv4Address;
  final String buildType;
  final String fuchsiaRoot;

  FuchsiaDeviceCommandRunner(
      {this.ipv4Address, this.fuchsiaRoot, this.buildType});

  Future<List<String>> run(String command) async {
    final String config = '$fuchsiaRoot/out/$buildType/ssh-keys/ssh_config';
    final List<String> args = <String>[
      'ssh',
      '-F',
      config,
      ipv4Address,
      command
    ];
    log.fine(args.join(' '));
    final ProcessResult result = await processManager.run(args);
    if (result.exitCode != 0) {
      log.severe(
          'Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
      return null;
    }
    log.fine(result.stdout);
    return result.stdout.split('\n');
  }
}
