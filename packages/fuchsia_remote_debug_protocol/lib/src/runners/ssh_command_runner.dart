// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import '../common/logging.dart';
import 'package:process/process.dart';

/// An error raised when a command fails to run within the `SshCommandRunner`.
///
/// Note that this occurs for both connection failures, and for failure to
/// running the command on the remote device. This error is raised when the
/// subprocess running the SSH command returns a nonzero exit code.
class SshCommandError extends Error {
  SshCommandError(String msg) : super(msg);
}

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
  ///
  /// If the SSH config path is supplied as an empty string, behavior is
  /// undefined.
  SshCommandRunner({this.ipv4Address, this.sshConfigPath = null});

  /// Runs a command on a Fuchsia device through an SSH tunnel.
  ///
  /// If the subprocess creating the SSH tunnel returns a nonzero exit status,
  /// then an `SshCommandError` is raised.
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
      throw new SshCommandError(
          'Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
    }
    _log.fine(result.stdout);
    return result.stdout.split('\n');
  }
}
