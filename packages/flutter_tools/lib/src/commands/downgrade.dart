// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../persistent_tool_state.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

/// The flutter downgrade command returns the SDK to the last recorded version
/// for a particular branch.
///
/// For example, suppose a user on the beta channel upgrades from 1.2.3 to 1.4.6.
/// The tool will record that 1.2.3 was the last active beta channel in the
/// persistent tool state. If the user is still on the beta channel and runs
/// flutter downgrade, this will take the user back to 1.2.3. They will not be
/// able to downgrade again, since the tool only records one prior version.
/// Additionally, if they had switch channels to stable before trying to downgrade,
/// the command would fail since there was no previously recorded stable version.
class DowngradeCommand extends FlutterCommand {
  DowngradeCommand({
    PersistentToolState persistentToolState,
    Logger logger,
    ProcessManager processManager,
    FlutterVersion flutterVersion,
    AnsiTerminal ansiTerminal,
    Stdio stdio,
  }) : _ansiTerminal = ansiTerminal,
       _flutterVersion = flutterVersion,
       _persistentToolState = persistentToolState,
       _processManager = processManager,
       _stdio = stdio,
       _logger = logger;

  AnsiTerminal _ansiTerminal;
  FlutterVersion _flutterVersion;
  PersistentToolState _persistentToolState;
  ProcessUtils _processUtils;
  ProcessManager _processManager;
  Logger _logger;
  Stdio _stdio;

  @override
  String get description => 'downgrade Flutter to the last active version for the current channel.';

  @override
  String get name => 'downgrade';

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Note: commands do not necessarily have access to the correct zone injected
    // values when being created. Fields must be lazily instantiated in runCommand,
    // at least until the zone injection is refactored.
    _ansiTerminal ??= globals.terminal;
    _logger ??= globals.logger;
    _flutterVersion ??= globals.flutterVersion;
    _persistentToolState ??= globals.persistentToolState;
    _processManager ??= globals.processManager;
    _processUtils ??= ProcessUtils(processManager: _processManager, logger: _logger);
    _stdio ??= globals.stdio;

    final String currentChannel = _flutterVersion.channel;
    final Channel channel = getChannelForName(currentChannel);
    if (channel == null) {
      throwToolExit(
        'Flutter is not currently on a known channel. Use "flutter channel <name>" '
        'to switch to an official channel.');
    }
    final GitTagVersion lastFlutterVesion = _persistentToolState.lastActiveVersion(channel);
    final GitTagVersion currentFlutterVersion = GitTagVersion.determine();
    if (lastFlutterVesion == null || currentFlutterVersion == lastFlutterVesion) {
      throwToolExit(
        'There is no previously recorded version for channel "$currentChannel."'
      );
    }

    // If there is a terminal attached, prompt the user to confirm the downgrade.
    final String humanReadableVersion = lastFlutterVesion.frameworkVersionFor(lastFlutterVesion.hash);
    if (_stdio.hasTerminal) {
      _ansiTerminal.usesTerminalUi = true;
      final String result = await _ansiTerminal.promptForCharInput(
        const <String>['y', 'n'],
        prompt: 'Downgrade flutter to version $humanReadableVersion?',
        logger: _logger,
      );
      if (result == 'n') {
        return FlutterCommandResult.success();
      }
    } else {
      _logger.printStatus('Downgrading Flutter to version $humanReadableVersion');
    }

    // To downgrade the tool, we perform a git checkout --hard, and then
    // switch channels. The version recorded must have existed on that branch
    // so this operation is safe.
    try {
      await _processUtils.run(
        <String>['git', 'reset', '--hard', lastFlutterVesion.hash],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not update to the version ${lastFlutterVesion.hash}. '
        'This may be due to git not being installed or an internal error. '
        'Please ensure that git is installed on your computer and retry again.'
        '\nError: $error.'
      );
    }
    try {
      await _processUtils.run(
        <String>['git', 'checkout', currentChannel, '--'],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not switch to the channel $currentChannel. '
        'This may be due to git not being installed or an internal error. '
        'Please ensure that git is installed on your computer and retry again.'
        '\nError: $error.'
      );
    }
    await FlutterVersion.resetFlutterVersionFreshnessCheck();
    _logger.printStatus('Success');
    return FlutterCommandResult.success();
  }
}
