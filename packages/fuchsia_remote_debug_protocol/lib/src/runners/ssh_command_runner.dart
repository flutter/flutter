// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import '../common/logging.dart';
import 'package:process/process.dart';

/// Runs a command remotely on a Fuchsia device. Requires a fuchsia root and
/// build type (to load the ssh config), and the ipv4 address of the fuchsia
/// device.
class SshCommandRunner {
  final Logger _log = new Logger('SshCommandRunner');

  final ProcessManager _processManager = const LocalProcessManager();

  /// The IPv4 address to access the Fuchsia machine over SSH.
  final String ipv4Address;

  /// The path to the SSH config (optional).
  final String sshConfigPath;

  /// Instantiates the command runner, pointing to an `ipv4Address` as well as
  /// an optional SSH config file.
  SshCommandRunner({this.ipv4Address, this.sshConfigPath = null});

  /// Runs a command on a Fuchsia device through an SSH tunnel. If an error is
  /// encountered, returns null, else a list of lines of stdout from running the
  /// command.
  Future<List<String>> run(String command) async {
    List<String> args;
    if (sshConfigPath != null) {
      args = <String>['ssh', '-F', sshConfigPath, ipv4Address, command];
    } else {
      args = <String>['ssh', ipv4Address, command];
    }
    _log.fine(args.join(' '));
    final ProcessResult result = await _processManager.run(args);
    if (result.exitCode != 0) {
      _log.severe(
          'Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
      return null;
    }
    _log.fine(result.stdout);
    return result.stdout.split('\n');
  }
}
