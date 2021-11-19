// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../version.dart';

class ChannelCommand extends FlutterCommand {
  ChannelCommand({ bool verboseHelp = false }) {
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Include all the available branches (including local branches) when listing channels.',
      hide: !verboseHelp,
    );
  }

  @override
  final String name = 'channel';

  @override
  final String description = 'List or switch Flutter channels.';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  String get invocation => '${runner?.executableName} $name [<channel-name>]';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> rest = argResults?.rest ?? <String>[];
    switch (rest.length) {
      case 0:
        await _listChannels(
          showAll: boolArg('all'),
          verbose: globalResults?['verbose'] == true,
        );
        return FlutterCommandResult.success();
      case 1:
        await _switchChannel(rest[0]);
        return FlutterCommandResult.success();
      default:
        throw ToolExit('Too many arguments.\n$usage');
    }
  }

  Future<void> _listChannels({ required bool showAll, required bool verbose }) async {
    // Beware: currentBranch could contain PII. See getBranchName().
    final String currentChannel = globals.flutterVersion.channel;
    final String currentBranch = globals.flutterVersion.getBranchName();
    final Set<String> seenUnofficialChannels = <String>{};
    final List<String> rawOutput = <String>[];

    showAll = showAll || currentChannel != currentBranch;

    globals.printStatus('Flutter channels:');
    final int result = await globals.processUtils.stream(
      <String>['git', 'branch', '-r'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) {
        rawOutput.add(line);
        return null;
      },
    );
    if (result != 0) {
      final String details = verbose ? '\n${rawOutput.join('\n')}' : '';
      throwToolExit('List channels failed: $result$details', exitCode: result);
    }

    final List<String> officialChannels = kOfficialChannels.toList();
    final List<bool> availableChannels = List<bool>.filled(officialChannels.length, false);

    for (final String line in rawOutput) {
      final List<String> split = line.split('/');
      final String branch = split[1];
      if (split.length > 1) {
        final int index = officialChannels.indexOf(branch);

        if (index != -1) { // Mark all available channels official channels from output
          availableChannels[index] = true;
        } else if (showAll && !seenUnofficialChannels.contains(branch)) {
        // add other branches to seenUnofficialChannels if --all flag is given (to print later)
          seenUnofficialChannels.add(branch);
        }
      }
    }

    // print all available official channels in sorted manner
    for (int i = 0; i < officialChannels.length; i++) {
      // only print non-missing channels
      if (availableChannels[i]) {
        String currentIndicator = ' ';
        if (officialChannels[i] == currentChannel) {
          currentIndicator = '*';
        }
        globals.printStatus('$currentIndicator ${officialChannels[i]}');
      }
    }

    // print all remaining channels if showAll is true
    if (showAll) {
      for (final String branch in seenUnofficialChannels) {
        if (currentBranch == branch) {
          globals.printStatus('* $branch');
        } else if (!branch.startsWith('HEAD ')) {
          globals.printStatus('  $branch');
        }
      }
    }

    if (currentChannel == 'unknown') {
      globals.printStatus('');
      globals.printStatus('Currently not on an official channel.');
    }
  }

  Future<void> _switchChannel(String branchName) async {
    globals.printStatus("Switching to flutter channel '$branchName'...");
    if (!kOfficialChannels.contains(branchName)) {
      globals.printStatus('This is not an official channel. For a list of available channels, try "flutter channel".');
    }
    await _checkout(branchName);
    globals.printStatus("Successfully switched to flutter channel '$branchName'.");
    globals.printStatus("To ensure that you're on the latest build from this channel, run 'flutter upgrade'");
  }

  static Future<void> _checkout(String branchName) async {
    // Get latest refs from upstream.
    int result = await globals.processUtils.stream(
      <String>['git', 'fetch'],
      workingDirectory: Cache.flutterRoot,
      prefix: 'git: ',
    );

    if (result == 0) {
      result = await globals.processUtils.stream(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/$branchName'],
        workingDirectory: Cache.flutterRoot,
        prefix: 'git: ',
      );
      if (result == 0) {
        // branch already exists, try just switching to it
        result = await globals.processUtils.stream(
          <String>['git', 'checkout', branchName, '--'],
          workingDirectory: Cache.flutterRoot,
          prefix: 'git: ',
        );
      } else {
        // branch does not exist, we have to create it
        result = await globals.processUtils.stream(
          <String>['git', 'checkout', '--track', '-b', branchName, 'origin/$branchName'],
          workingDirectory: Cache.flutterRoot,
          prefix: 'git: ',
        );
      }
    }
    if (result != 0) {
      throwToolExit('Switching channels failed with error code $result.', exitCode: result);
    } else {
      // Remove the version check stamp, since it could contain out-of-date
      // information that pertains to the previous channel.
      await FlutterVersion.resetFlutterVersionFreshnessCheck();
    }
  }
}
