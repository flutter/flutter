// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/process.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class ChannelCommand extends FlutterCommand {
  ChannelCommand({ bool verboseHelp = false }) {
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Include all the available branches (including local branches) when listing channels.',
      defaultsTo: false,
      hide: !verboseHelp,
    );
  }

  @override
  final String name = 'channel';

  @override
  final String description = 'List or switch flutter channels.';

  @override
  String get invocation => '${runner.executableName} $name [<channel-name>]';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    switch (argResults.rest.length) {
      case 0:
        await _listChannels(
          showAll: argResults['all'],
          verbose: globalResults['verbose'],
        );
        return null;
      case 1:
        await _switchChannel(argResults.rest[0]);
        return null;
      default:
        throw ToolExit('Too many arguments.\n$usage');
    }
  }

  String _formatChannels(String currentBranch, String channel) {
    return channel == currentBranch ? '* $channel' : '  $channel';
  }

  // Sort the channels by stability.
  List<String> _sortOfficialChannelsByStability(List<String> officialChannels) {
    final List<String> result = List<String>(FlutterVersion.officialChannels.length);
    for (String channel in officialChannels) {
      final int index = FlutterVersion.officialChannels.toList().indexOf(channel);
      result[index] = channel;
    }
    return result;
  }

  Future<void> _listChannels({bool showAll, bool verbose}) async {
    // Beware: currentBranch could contain PII. See getBranchName().
    final String currentChannel = FlutterVersion.instance.channel;
    final String currentBranch = FlutterVersion.instance.getBranchName();
    final Set<String> seenChannels = <String>{};
    final List<String> officialChannels = <String>[];
    final List<String> rawOutput = <String>[];

    bool done = false;

    showAll = showAll || currentChannel != currentBranch;

    printStatus('Flutter channels:');
    final int result = await runCommandAndStreamOutput(
      <String>['git', 'branch', '-r'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) {
        if (verbose) {
          rawOutput.add(line);
        }
        final List<String> split = line.split('/');
        if (split.length < 2) {
          return null;
        }
        final String branchName = split[1];
        if (seenChannels.contains(branchName)) {
          return null;
        }
        seenChannels.add(branchName);

        if (!branchName.startsWith('HEAD ')) {
          if (showAll) {
            return '  $branchName';
          }
          if (FlutterVersion.officialChannels.contains(branchName)) {
            officialChannels.add(branchName);
          }
        }

        // It needs to check that the length of officialChannels is correct
        // because it works as an accumulator, plus when printed once
        // we simply skip the rest of the branches it may find.
        if (!done && officialChannels.length == FlutterVersion.officialChannels.length) {
          done = true;
          return _sortOfficialChannelsByStability(officialChannels)
              .map((String channel) => _formatChannels(currentBranch, channel))
              .join('\n');
        }
        return null;
      },
    );
    if (result != 0) {
      final String details = verbose ? '\n${rawOutput.join('\n')}' : '';
      throwToolExit('List channels failed: $result$details', exitCode: result);
    }
  }

  Future<void> _switchChannel(String branchName) {
    printStatus("Switching to flutter channel '$branchName'...");
    if (FlutterVersion.obsoleteBranches.containsKey(branchName)) {
      final String alternative = FlutterVersion.obsoleteBranches[branchName];
      printStatus("This channel is obsolete. Consider switching to the '$alternative' channel instead.");
    } else if (!FlutterVersion.officialChannels.contains(branchName)) {
      printStatus('This is not an official channel. For a list of available channels, try "flutter channel".');
    }
    return _checkout(branchName);
  }

  static Future<void> upgradeChannel() async {
    final String channel = FlutterVersion.instance.channel;
    if (FlutterVersion.obsoleteBranches.containsKey(channel)) {
      final String alternative = FlutterVersion.obsoleteBranches[channel];
      printStatus("Transitioning from '$channel' to '$alternative'...");
      return _checkout(alternative);
    }
  }

  static Future<void> _checkout(String branchName) async {
    // Get latest refs from upstream.
    int result = await runCommandAndStreamOutput(
      <String>['git', 'fetch'],
      workingDirectory: Cache.flutterRoot,
      prefix: 'git: ',
    );

    if (result == 0) {
      result = await runCommandAndStreamOutput(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/$branchName'],
        workingDirectory: Cache.flutterRoot,
        prefix: 'git: ',
      );
      if (result == 0) {
        // branch already exists, try just switching to it
        result = await runCommandAndStreamOutput(
          <String>['git', 'checkout', branchName, '--'],
          workingDirectory: Cache.flutterRoot,
          prefix: 'git: ',
        );
      } else {
        // branch does not exist, we have to create it
        result = await runCommandAndStreamOutput(
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
