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

// Usage: device-finder <flags> <subcommand> <subcommand args>
//
// Subcommands:
//   commands         list all command names
//   flags            describe all known top-level flags
//   help             describe subcommands and their syntax
//   list             lists all Fuchsia devices on the network
//   resolve          attempts to resolve all passed Fuchsia domain names on the
//                    network

/// A simple wrapper for the Fuchsia SDK's 'device-finder' tool.
class FuchsiaDevFinder {
  FuchsiaDevFinder({
    @required FuchsiaArtifacts fuchsiaArtifacts,
    @required Logger logger,
    @required ProcessManager processManager,
  })
    : _fuchsiaArtifacts = fuchsiaArtifacts,
      _logger = logger,
      _processUtils = ProcessUtils(logger: logger, processManager: processManager);


  final FuchsiaArtifacts _fuchsiaArtifacts;
  final Logger _logger;
  final ProcessUtils _processUtils;

  /// Returns a list of attached devices as a list of strings with entries
  /// formatted as follows:
  ///
  ///     192.168.42.172 scare-cable-skip-joy
  Future<List<String>> list({ Duration timeout }) async {
    if (_fuchsiaArtifacts.devFinder == null ||
        !_fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia device-finder tool not found.');
    }
    final List<String> command = <String>[
      _fuchsiaArtifacts.devFinder.path,
      'list',
      '-full',
      if (timeout != null)
        ...<String>['-timeout', '${timeout.inMilliseconds}ms']
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      // No devices returns error code 1.
      // https://bugs.fuchsia.dev/p/fuchsia/issues/detail?id=48563
      if (!result.stderr.contains('no devices found')) {
        _logger.printError('device-finder failed: ${result.stderr}');
      }
      return null;
    }
    return result.stdout.split('\n');
  }

  /// Returns the address of the named device.
  ///
  /// The string [deviceName] should be the name of the device from the
  /// 'list' command, e.g. 'scare-cable-skip-joy'.
  Future<String> resolve(String deviceName) async {
    if (_fuchsiaArtifacts.devFinder == null ||
        !_fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia device-finder tool not found.');
    }
    final List<String> command = <String>[
      _fuchsiaArtifacts.devFinder.path,
      'resolve',
      '-device-limit', '1',
      deviceName,
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      _logger.printError('device-finder failed: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }
}
