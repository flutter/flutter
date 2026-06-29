// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

@visibleForTesting
String downgradePositionalArgumentErrorMessage(List<String> args) {
  final String argString = args.join(' ');
  final pluralized = args.length > 1 ? 'arguments' : 'argument';

  return 'Unexpected positional $pluralized "$argString".\n\n'
      '"flutter downgrade" does not support specifying a version.\n'
      'It only undoes the last "flutter upgrade" on the current channel.\n\n'
      'To switch to a specific Flutter version, see: '
      'https://flutter.dev/to/switch-flutter-version';
}

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
  DowngradeCommand({bool verboseHelp = false, required ToolContext toolContext})
    : super(toolContext: toolContext) {
    argParser.addOption(
      'working-directory',
      hide: !verboseHelp,
      help:
          'Override the downgrade working directory. '
          'This is only intended to enable integration testing of the tool itself. '
          'It allows one to use the flutter tool from one checkout to downgrade a '
          'different checkout.',
    );
    argParser.addFlag(
      'prompt',
      defaultsTo: true,
      hide: !verboseHelp,
      help: 'Show the downgrade prompt.',
    );
  }

  @override
  String get description => 'Downgrade Flutter to the last active version for the current channel.';

  @override
  String get name => 'downgrade';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults!.rest.isNotEmpty) {
      throwToolExit(downgradePositionalArgumentErrorMessage(argResults!.rest), exitCode: 2);
    }

    String workingDirectory = Cache.flutterRoot!;
    FlutterVersion flutterVersion = this.flutterVersion;
    if (argResults!.wasParsed('working-directory')) {
      workingDirectory = stringArg('working-directory')!;
      flutterVersion = FlutterVersion(fs: fileSystem, flutterRoot: workingDirectory, git: git);
    }

    final String currentChannel = flutterVersion.channel;
    final Channel? channel = getChannelForName(currentChannel);
    if (channel == null) {
      throwToolExit(
        'Flutter is not currently on a known channel. '
        'Use "flutter channel" to switch to an official channel. ',
      );
    }
    final String? lastFlutterVersion = persistentToolState.lastActiveVersion(channel);
    final String currentFlutterVersion = flutterVersion.frameworkRevision;
    if (lastFlutterVersion == null || currentFlutterVersion == lastFlutterVersion) {
      final String trailing = await _createErrorMessage(workingDirectory, channel);
      throwToolExit(
        "It looks like you haven't run "
        '"flutter upgrade" on channel "$currentChannel".\n'
        '\n'
        '"flutter downgrade" undoes the last "flutter upgrade".\n'
        '\n'
        'To switch to a specific Flutter version, see: '
        'https://flutter.dev/to/switch-flutter-version'
        '$trailing',
      );
    }

    // Detect unknown versions.
    final RunResult parseResult = await git.run(<String>[
      'describe',
      '--tags',
      lastFlutterVersion,
    ], workingDirectory: workingDirectory);
    if (parseResult.exitCode != 0) {
      throwToolExit('Failed to parse version for downgrade:\n${parseResult.stderr}');
    }
    final String humanReadableVersion = parseResult.stdout;

    // If there is a terminal attached, prompt the user to confirm the downgrade.
    if (stdio.hasTerminal && boolArg('prompt')) {
      terminal.usesTerminalUi = true;
      final String result = await terminal.promptForCharInput(
        const <String>['y', 'n'],
        prompt: 'Downgrade flutter to version $humanReadableVersion?',
        logger: logger,
      );
      if (result == 'n') {
        return FlutterCommandResult.success();
      }
    } else {
      logger.printStatus('Downgrading Flutter to version $humanReadableVersion');
    }

    // To downgrade the tool, we perform a git checkout --hard, and then
    // switch channels. The version recorded must have existed on that branch
    // so this operation is safe.
    try {
      await git.run(
        <String>['reset', '--hard', lastFlutterVersion],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not update to the version '
        '$humanReadableVersion.\n'
        'Error: $error',
      );
    }
    try {
      await git.run(
        // The `--` bit (because it's followed by nothing) means that we don't actually change
        // anything in the working tree, which avoids the need to first go into detached HEAD mode.
        <String>['checkout', currentChannel, '--'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to downgrade Flutter: The tool could not switch to the channel '
        '$currentChannel.\n'
        'Error: $error',
      );
    }
    await FlutterVersion.resetFlutterVersionFreshnessCheck();
    logger.printStatus('Success');
    return FlutterCommandResult.success();
  }

  // Formats an error message that lists the currently stored versions.
  Future<String> _createErrorMessage(String workingDirectory, Channel currentChannel) async {
    final buffer = StringBuffer();
    for (final Channel channel in Channel.values) {
      if (channel == currentChannel) {
        continue;
      }
      final String? sha = persistentToolState.lastActiveVersion(channel);
      if (sha == null) {
        continue;
      }
      final RunResult parseResult = await git.run(<String>[
        'describe',
        '--tags',
        sha,
      ], workingDirectory: workingDirectory);
      if (parseResult.exitCode == 0) {
        if (buffer.isEmpty) {
          buffer.writeln();
        }
        buffer.writeln();
        buffer.writeln(
          'Channel "${getNameForChannel(channel)}" was previously on: '
          '${parseResult.stdout}.',
        );
      }
    }
    return buffer.toString();
  }
}
