// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
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
  /// Returns a list of attached devices as a list of strings with entries
  /// formatted as follows:
  /// 192.168.42.172 scare-cable-skip-joy
  Future<List<String>> list({ Duration timeout }) async {
    if (fuchsiaArtifacts.devFinder == null ||
        !fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia device-finder tool not found.');
    }
    final List<String> command = <String>[
      fuchsiaArtifacts.devFinder.path,
      'list',
      '-full',
      if (timeout != null)
        ...<String>['-timeout', '${timeout.inMilliseconds}ms']
    ];
    final RunResult result = await processUtils.run(command);
    if (result.exitCode != 0) {
      globals.printError('device-finder failed: ${result.stderr}');
      return null;
    }
    return result.stdout.split('\n');
  }

  /// Returns the address of the named device.
  ///
  /// If local is true, then gives the address by which the device reaches the
  /// host.
  ///
  /// The string [deviceName] should be the name of the device from the
  /// 'list' command, e.g. 'scare-cable-skip-joy'.
  Future<String> resolve(String deviceName, {bool local = false}) async {
    if (fuchsiaArtifacts.devFinder == null ||
        !fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia device-finder tool not found.');
    }
    final List<String> command = <String>[
      fuchsiaArtifacts.devFinder.path,
      'resolve',
      if (local) '-local',
      '-device-limit', '1',
      deviceName,
    ];
    final RunResult result = await processUtils.run(command);
    if (result.exitCode != 0) {
      globals.printError('device-finder failed: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }
}
