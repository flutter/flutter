// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import 'fuchsia_sdk.dart';

// Usage: ffx [-c <config>] [-e <env>] [-t <target>] [-T <timeout>] [-v] [<command>] [<args>]

// Fuchsia's developer tool

// Options:
//   -c, --config      override default configuration
//   -e, --env         override default environment settings
//   -t, --target      apply operations across single or multiple targets
//   -T, --timeout     override default proxy timeout
//   -v, --verbose     use verbose output
//   --help            display usage information

// Commands:
//   config            View and switch default and user configurations
//   daemon            Interact with/control the ffx daemon
//   target            Interact with a target device or emulator

/// A simple wrapper for the Fuchsia SDK's 'ffx' tool.
class FuchsiaFfx {
  FuchsiaFfx({
    @required FuchsiaArtifacts fuchsiaArtifacts,
    @required Logger logger,
    @required ProcessManager processManager,
  })  : _fuchsiaArtifacts = fuchsiaArtifacts,
        _logger = logger,
        _processUtils =
            ProcessUtils(logger: logger, processManager: processManager);

  final FuchsiaArtifacts _fuchsiaArtifacts;
  final Logger _logger;
  final ProcessUtils _processUtils;

  /// Returns a list of attached devices as a list of strings with entries
  /// formatted as follows:
  ///
  /// abcd::abcd:abc:abcd:abcd%qemu scare-cable-skip-joy
  Future<List<String>> list({Duration timeout}) async {
    if (_fuchsiaArtifacts.ffx == null || !_fuchsiaArtifacts.ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      _fuchsiaArtifacts.ffx.path,
      if (timeout != null)
        ...<String>['-T', '${timeout.inSeconds}'],
      'target',
      'list',
      '--format',
      's'
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      _logger.printError('ffx failed: ${result.stderr}');
      return null;
    }
    if (result.stderr.contains('No devices found')) {
      return null;
    }
    return result.stdout.split('\n');
  }

  /// Returns the address of the named device.
  ///
  /// The string [deviceName] should be the name of the device from the
  /// 'list' command, e.g. 'scare-cable-skip-joy'.
  Future<String> resolve(String deviceName) async {
    if (_fuchsiaArtifacts.ffx == null || !_fuchsiaArtifacts.ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      _fuchsiaArtifacts.ffx.path,
      'target',
      'list',
      '--format',
      'a',
      deviceName,
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      _logger.printError('ffx failed: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }
}
