// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
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
//   session           Control the current session. See
//                     https://fuchsia.dev/fuchsia-src/concepts/session/introduction
//                     for details.

/// A simple wrapper for the Fuchsia SDK's 'ffx' tool.
class FuchsiaFfx {
  FuchsiaFfx({
    FuchsiaArtifacts? fuchsiaArtifacts,
    Logger? logger,
    ProcessManager? processManager,
  })  : _fuchsiaArtifacts = fuchsiaArtifacts ?? globals.fuchsiaArtifacts,
        _logger = logger ?? globals.logger,
        _processUtils = ProcessUtils(
            logger: logger ?? globals.logger,
            processManager: processManager ?? globals.processManager);

  final FuchsiaArtifacts? _fuchsiaArtifacts;
  final Logger _logger;
  final ProcessUtils _processUtils;

  /// Returns a list of attached devices as a list of strings with entries
  /// formatted as follows:
  ///
  /// abcd::abcd:abc:abcd:abcd%qemu scare-cable-skip-joy
  Future<List<String>?> list({Duration? timeout}) async {
    final File? ffx = _fuchsiaArtifacts?.ffx;
    if (ffx == null || !ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      ffx.path,
      if (timeout != null) ...<String>['-T', '${timeout.inSeconds}'],
      'target',
      'list',
      // TODO(akbiggs): Revert -f back to --format once we've verified that
      // analytics spam is coming from here.
      '-f',
      's',
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
  Future<String?> resolve(String deviceName) async {
    final File? ffx = _fuchsiaArtifacts?.ffx;
    if (ffx == null || !ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      ffx.path,
      'target',
      'list',
      '-f',
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

  /// Show information about the current session
  ///
  /// Returns `null` if the command failed, which can be interpreted as there is
  /// no usable session.
  Future<String?> sessionShow() async {
    final File? ffx = _fuchsiaArtifacts?.ffx;
    if (ffx == null || !ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      ffx.path,
      'session',
      'show',
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      _logger.printError('ffx failed: ${result.stderr}');
      return null;
    }
    return result.stdout;
  }

  /// Add an element to the current session
  ///
  /// [url] should be formatted as a Fuchsia-style package URL, e.g.:
  ///     fuchsia-pkg://fuchsia.com/flutter_gallery#meta/flutter_gallery.cmx
  /// Returns true on success and false on failure.
  Future<bool> sessionAdd(String url) async {
    final File? ffx = _fuchsiaArtifacts?.ffx;
    if (ffx == null || !ffx.existsSync()) {
      throwToolExit('Fuchsia ffx tool not found.');
    }
    final List<String> command = <String>[
      ffx.path,
      'session',
      'add',
      url,
    ];
    final RunResult result = await _processUtils.run(command);
    if (result.exitCode != 0) {
      _logger.printError('ffx failed: ${result.stderr}');
      return false;
    }
    return true;
  }
}
