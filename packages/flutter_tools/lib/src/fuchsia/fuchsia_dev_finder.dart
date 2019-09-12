// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/process.dart';
import '../globals.dart';
import 'fuchsia_sdk.dart';

// Usage: dev_finder <flags> <subcommand> <subcommand args>
//
// Subcommands:
//   commands         list all command names
//   flags            describe all known top-level flags
//   help             describe subcommands and their syntax
//   list             lists all Fuchsia devices on the network
//   resolve          attempts to resolve all passed Fuchsia domain names on the
//                    network

/// A simple wrapper for the Fuchsia SDK's 'dev_finder' tool.
class FuchsiaDevFinder {
  /// Returns a list of attached devices as a list of strings with entries
  /// formatted as follows:
  /// 192.168.42.172 scare-cable-skip-joy
  Future<List<String>> list() async {
    if (fuchsiaArtifacts.devFinder == null ||
        !fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia dev_finder tool not found.');
    }
    final List<String> command = <String>[
      fuchsiaArtifacts.devFinder.path,
      'list',
      '-full'
    ];
    final RunResult result = await processUtils.run(command);
    if (result.exitCode != 0) {
      printError('dev_finder failed: ${result.stderr}');
      return null;
    }
    return result.stdout.split('\n');
  }

  /// Returns the host address by which the device [deviceName] should use for
  /// the host.
  ///
  /// The string [deviceName] should be the name of the device from the
  /// 'list' command, e.g. 'scare-cable-skip-joy'.
  Future<String> resolve(String deviceName) async {
    if (fuchsiaArtifacts.devFinder == null ||
        !fuchsiaArtifacts.devFinder.existsSync()) {
      throwToolExit('Fuchsia dev_finder tool not found.');
    }
    final List<String> command = <String>[
      fuchsiaArtifacts.devFinder.path,
      'resolve',
      '-local',
      '-device-limit', '1',
      deviceName
    ];
    final RunResult result = await processUtils.run(command);
    if (result.exitCode != 0) {
      printError('dev_finder failed: ${result.stderr}');
      return null;
    }
    return result.stdout.trim();
  }
}
