// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';

/// The [FuchsiaSdk] instance.
FuchsiaSdk get fuchsiaSdk => context[FuchsiaSdk];

/// The [FuchsiaArtifacts] instance.
FuchsiaArtifacts get fuchsiaArtifacts => context[FuchsiaArtifacts];

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {
  static const List<String> _netaddrCommand = <String>['fx', 'netaddr', '--fuchsia', '--nowait'];
  static const List<String> _netlsCommand = <String>['fx', 'netls', '--nowait'];
  static const List<String> _syslogCommand = <String>['fx', 'syslog', '--clock', 'Local'];

  /// Invokes the `netaddr` command.
  ///
  /// This returns the network address of an attached fuchsia device. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netaddr --fuchsia --nowait
  ///     > fe80::9aaa:fcff:fe60:d3af%eth1
  Future<String> netaddr() async {
    try {
      final RunResult process = await runAsync(_netaddrCommand);
      return process.stdout.trim();
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }

  /// Returns the fuchsia system logs for an attached device.
  ///
  /// Does not currently support multiple attached devices.
  Stream<String> syslogs() {
    Process process;
    try {
      final StreamController<String> controller = StreamController<String>(onCancel: () {
        process.kill();
      });
      processManager.start(_syslogCommand).then((Process newProcess) {
        if (controller.isClosed) {
          return;
        }
        process = newProcess;
        process.exitCode.whenComplete(controller.close);
        controller.addStream(process.stdout.transform(utf8.decoder).transform(const LineSplitter()));
      });
      return controller.stream;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }

  /// Invokes the `netls` command.
  ///
  /// This lists attached fuchsia devices with their name and address. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netls --nowait
  ///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
  Future<String> netls() async {
    try {
      final RunResult process = await runAsync(_netlsCommand);
      return process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }
}

/// Fuchsia-specific artifacts used to interact with a device.
class FuchsiaArtifacts {
  /// Creates a new [FuchsiaArtifacts].
  ///
  /// May optionally provide a file `sshConfig` file.
  FuchsiaArtifacts({File sshConfig})
    : _sshConfig = sshConfig;

  /// The location of the SSH configuration file used to interact with a
  /// fuchsia device.
  ///
  /// Requires the env variable `BUILD_DIR` to be set if not provided by
  /// the constructor.
  File get sshConfig {
    if (_sshConfig == null) {
      final String buildDirectory = platform.environment['BUILD_DIR'];
      if (buildDirectory == null) {
        throwToolExit('BUILD_DIR must be supplied to locate SSH keys. For example:\n'
          '  export BUILD_DIR=path/to/fuchsia/out/x64\n');
      }
      _sshConfig = fs.file('$buildDirectory/ssh-keys/ssh_config');
    }
    return _sshConfig;
  }
  File _sshConfig;
}
