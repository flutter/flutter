// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:process/process.dart';
import 'package:logging/logging.dart';

/// Runs a command remotely on a Fuchsia device. Requires a fuchsia root and
/// build type (to load the ssh config), and the ipv4 address of the fuchsia
/// device.
class SshCommandRunner {
  final Logger _log = new Logger('SshCommandRunner');

  final ProcessManager _processManager = const LocalProcessManager();

  /// The IPv4 address to access the Fuchsia machine over SSH.
  final String ipv4Address;

  /// The build type for the Fuchsia instance. Defaults to 'release-x86-64'.
  final String buildType;

  /// The root directory for the fuchsia build.
  final String fuchsiaRoot;

  /// Instantiates the command runner, pointing to an `ipv4Address` as well as
  /// the root directory and build type in order to access the ssh-keys
  /// directory. The directory is defined under the fuchsia root as
  /// out/$buildType/ssh-keys/ssh_config.
  SshCommandRunner(
      {this.ipv4Address, this.fuchsiaRoot, this.buildType = 'release-x86-64'});

  /// Runs a command on a Fuchsia device through an SSH tunnel. If an error is
  /// encountered, returns null, else a list of lines of stdout from running the
  /// command.
  ///
  /// TODO(awdavies): Make the SSH config location optional.
  Future<List<String>> run(String command) async {
    final String config = '$fuchsiaRoot/out/$buildType/ssh-keys/ssh_config';
    final List<String> args = <String>[
      'ssh',
      '-F',
      config,
      ipv4Address,
      command
    ];
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
