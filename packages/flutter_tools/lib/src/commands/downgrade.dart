// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../persistent_tool_state.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

/// The flutter downgrade command returns the SDK to the last recorded version
/// for a particular branch.
///
/// For example, suppose a user on the beta channel upgrades from 1.2.3 to 1.4.6.
/// The tool will record that sha "abcdefg" was the last active beta channel in the
/// persistent tool state. If the user is still on the beta channel and runs
/// flutter downgrade, this will take the user back to "abcdefg". They will not be
/// able to downgrade again, since the tool only records one prior version.
/// Additionally, if they had switched channels to stable before trying to downgrade,
/// the command would fail since there was no previously recorded stable version.
class DowngradeCommand extends FlutterCommand {
  DowngradeCommand({
    PersistentToolState persistentToolState,
    Logger logger,
    ProcessManager processManager,
    FlutterVersion flutterVersion,
    AnsiTerminal terminal,
    Stdio stdio,
    FileSystem fileSystem,
  }) : _terminal = terminal,
       _flutterVersion = flutterVersion,
       _persistentToolState = persistentToolState,
       _processManager = processManager,
       _stdio = stdio,
       _logger = logger,
       _fileSystem = fileSystem {
    argParser.addOption(
      'working-directory',
      hide: true,
      help: 'Override the downgrade working directory for integration testing.'
    );
    argParser.addFlag(
      'prompt',
      defaultsTo: true,
      hide: true,
      help: 'Disable the downgrade prompt for integration testing.'
    );
  }

  AnsiTerminal _terminal;
  FlutterVersion _flutterVersion;
  PersistentToolState _persistentToolState;
  ProcessUtils _processUtils;
  ProcessManager _processManager;
  Logger _logger;
  Stdio _stdio;
  FileSystem _fileSystem;

  @override
  String get description => 'Downgrade Flutter to the last active version for the current channel.';

  @override
  String get name => 'downgrade';

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Note: commands do not necessarily have access to the correct zone injected
    // values when being created. Fields must be lazily instantiated in runCommand,
    // at least until the zone injection is refactored.
    _terminal ??= globals.terminal;
    _logger ??= globals.logger;
    _flutterVersion ??= globals.flutterVersion;
    _persistentToolState ??= globals.persistentToolState;
    _processManager ??= globals.processManager;
    _processUtils ??= ProcessUtils(processManager: _processManager, logger: _logger);
    _stdio ??= globals.stdio;
    _fileSystem ??= globals.fs;
    String workingDirectory = Cache.flutterRoot;
    if (argResults.wasParsed('working-directory')) {
      workingDirectory = stringArg('working-directory');
      _flutterVersion = FlutterVersion(const SystemClock(), workingDirectory);
    }

    final String currentChannel = _flutterVersion.channel;
    final Channel channel = getChannelForName(currentChannel);
    if (channel == null) {
      throwToolExit(
        'Flutter is not currently on a known channel. Use "flutter channel <name>" '
        'to switch to an official channel.',
      );
    }
    final String lastFlutterVesion = _persistentToolState.lastActiveVersion(channel);
    final String currentFlutterVersion = _flutterVersion.frameworkRevision;
    if (lastFlutterVesion == null || currentFlutterVersion == lastFlutterVesion) {
      final String trailing = await _createErrorMessage(workingDirectory, channel);
      throwToolExit(
        'There is no previously recorded version for channel "$currentChannel".\n'
        '$trailing'
      );
    }

    // Detect unkown versions.
    final RunResult parseResult = await _processUtils.run(<String>[
      'git', 'describe', '--tags', lastFlutterVesion,
    ], workingDirectory: workingDirectory);
    if (parseResult.exitCode != 0) {
      throwToolExit('Failed to parse version for downgrade:\n${parseResult.stderr}');
    }
    final String humanReadableVersion = parseResult.stdout;

    // If there is a terminal attached, prompt the user to confirm the downgrade.
    if (_stdio.hasTerminal && boolArg('prompt')) {
      _terminal.usesTerminalUi = true;
      final String result = await _terminal.promptForCharInput(
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
        <String>['git', 'reset', '--hard', lastFlutterVesion],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not update to the version '
        '$humanReadableVersion. This may be due to git not being installed or an '
        'internal error. Please ensure that git is installed on your computer and '
        'retry again.\nError: $error.'
      );
    }
    try {
      await _processUtils.run(
        <String>['git', 'checkout', currentChannel, '--'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not switch to the channel '
        '$currentChannel. This may be due to git not being installed or an '
        'internal error. Please ensure that git is installed on your computer '
        'and retry again.\nError: $error.'
      );
    }
    await FlutterVersion.resetFlutterVersionFreshnessCheck();
    _logger.printStatus('Success');
    return FlutterCommandResult.success();
  }

  // Formats an error message that lists the currently stored versions.
  Future<String> _createErrorMessage(String workingDirectory, Channel currentChannel) async {
    final StringBuffer buffer = StringBuffer();
    for (final Channel channel in Channel.values) {
      if (channel == currentChannel) {
        continue;
      }
      final String sha = _persistentToolState.lastActiveVersion(channel);
      if (sha == null) {
        continue;
      }
      final RunResult parseResult = await _processUtils.run(<String>[
        'git', 'describe', '--tags', sha,
      ], workingDirectory: workingDirectory);
      if (parseResult.exitCode == 0) {
        buffer.writeln('Channel "${getNameForChannel(channel)}" was previously on: ${parseResult.stdout}.');
      }
    }
    return buffer.toString();
  }
}
