// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Rolls the dev channel.
// Only tested on Linux.
//
// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';

const String kIncrement = 'increment';
const String kX = 'x';
const String kY = 'y';
const String kZ = 'z';
const String kCommit = 'commit';
const String kOrigin = 'origin';
const String kJustPrint = 'just-print';
const String kYes = 'yes';
const String kHelp = 'help';
const String kForce = 'force';
const String kSkipTagging = 'skip-tagging';

const String kUpstreamRemote = 'git@github.com:flutter/flutter.git';

void main(List<String> args) {
  final ArgParser argParser = ArgParser(allowTrailingOptions: false);

  ArgResults argResults;
  try {
    argResults = parseArguments(argParser, args);
  } on ArgParserException catch (error) {
    print(error.message);
    print(argParser.usage);
    exit(1);
  }

  try {
    run(
      usage: argParser.usage,
      argResults: argResults,
      git: const Git(),
    );
  } on Exception catch (e) {
    print(e.toString());
    exit(1);
  }
}

/// Main script execution.
///
/// Returns true if publishing was successful, else false.
bool run({
  @required String usage,
  @required ArgResults argResults,
  @required Git git,
}) {
  final String level = argResults[kIncrement] as String;
  final String commit = argResults[kCommit] as String;
  final String origin = argResults[kOrigin] as String;
  final bool justPrint = argResults[kJustPrint] as bool;
  final bool autoApprove = argResults[kYes] as bool;
  final bool help = argResults[kHelp] as bool;
  final bool force = argResults[kForce] as bool;
  final bool skipTagging = argResults[kSkipTagging] as bool;

  if (help || level == null || commit == null) {
    print(
      'roll_dev.dart --increment=level --commit=hash • update the version tags '
      'and roll a new dev build.\n$usage'
    );
    return false;
  }

  final String remote = git.getOutput(
    'remote get-url $origin',
    'check whether this is a flutter checkout',
  );
  if (remote != kUpstreamRemote) {
    throw Exception(
      'The remote named $origin is set to $remote, when $kUpstreamRemote was '
      'expected.\nFor more details see: '
      'https://github.com/flutter/flutter/wiki/Release-process'
    );
  }

  if (git.getOutput('status --porcelain', 'check status of your local checkout') != '') {
    throw Exception(
      'Your git repository is not clean. Try running "git clean -fd". Warning, '
      'this will delete files! Run with -n to find out which ones.'
    );
  }

  git.run('fetch $origin', 'fetch $origin');

  final String lastVersion = getFullTag(git, origin);

  final String version = skipTagging
    ? lastVersion
    : incrementLevel(lastVersion, level);

  if (git.getOutput(
    'rev-parse $lastVersion',
    'check if commit is already on dev',
  ).contains(commit.trim())) {
    throw Exception('Commit $commit is already on the dev branch as $lastVersion.');
  }

  if (justPrint) {
    print(version);
    return false;
  }

  if (skipTagging) {
    git.run(
      'describe --exact-match --tags $commit',
      'verify $commit is already tagged. You can only use the flag '
      '`$kSkipTagging` if the commit has already been tagged.'
    );
  }

  if (!force) {
    git.run(
      'merge-base --is-ancestor $lastVersion $commit',
      'verify $lastVersion is a direct ancestor of $commit. The flag `$kForce`'
      'is required to force push a new release past a cherry-pick',
    );
  }

  git.run('reset $commit --hard', 'reset to the release commit');

  final String hash = git.getOutput('rev-parse HEAD', 'Get git hash for $commit');

  // PROMPT

  if (autoApprove) {
    print('Publishing Flutter $version (${hash.substring(0, 10)}) to the "dev" channel.');
  } else {
    print('Your tree is ready to publish Flutter $version (${hash.substring(0, 10)}) '
      'to the "dev" channel.');
    stdout.write('Are you? [yes/no] ');
    if (stdin.readLineSync() != 'yes') {
      print('The dev roll has been aborted.');
      return false;
    }
  }

  if (!skipTagging) {
    git.run('tag $version', 'tag the commit with the version label');
    git.run('push $origin $version', 'publish the version');
  }
  git.run(
    'push ${force ? "--force " : ""}$origin HEAD:dev',
    'land the new version on the "dev" branch',
  );
  print('Flutter version $version has been rolled to the "dev" channel!');
  return true;
}

ArgResults parseArguments(ArgParser argParser, List<String> args) {
  argParser.addOption(
    kIncrement,
    help: 'Specifies which part of the x.y.z version number to increment. Required.',
    valueHelp: 'level',
    allowed: <String>[kX, kY, kZ],
    allowedHelp: <String, String>{
      kX: 'Indicates a major development, e.g. typically changed after a big press event.',
      kY: 'Indicates a minor development, e.g. typically changed after a beta release.',
      kZ: 'Indicates the least notable level of change. You normally want this.',
    },
  );
  argParser.addOption(
    kCommit,
    help: 'Specifies which git commit to roll to the dev branch. Required.',
    valueHelp: 'hash',
    defaultsTo: null, // This option is required
  );
  argParser.addOption(
    kOrigin,
    help: 'Specifies the name of the upstream repository',
    valueHelp: 'repository',
    defaultsTo: 'upstream',
  );
  argParser.addFlag(
    kForce,
    abbr: 'f',
    help: 'Force push. Necessary when the previous release had cherry-picks.',
    negatable: false,
  );
  argParser.addFlag(
    kJustPrint,
    negatable: false,
    help:
        "Don't actually roll the dev channel; "
        'just print the would-be version and quit.',
  );
  argParser.addFlag(
    kSkipTagging,
    negatable: false,
    help: 'Do not create tag and push to remote, only update release branch. '
    'For recovering when the script fails trying to git push to the release branch.'
  );
  argParser.addFlag(kYes, negatable: false, abbr: 'y', help: 'Skip the confirmation prompt.');
  argParser.addFlag(kHelp, negatable: false, help: 'Show this help message.', hide: true);

  return argParser.parse(args);
}

/// Obtain the version tag of the previous dev release.
String getFullTag(Git git, String remote) {
  const String glob = '*.*.*-*.*.pre';
  // describe the latest dev release
  final String ref = 'refs/remotes/$remote/dev';
  return git.getOutput(
    'describe --match $glob --exact-match --tags $ref',
    'obtain last released version number',
  );
}

Match parseFullTag(String version) {
  // of the form: x.y.z-m.n.pre
  final RegExp versionPattern = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)-(\d+)\.(\d+)\.pre$');
  return versionPattern.matchAsPrefix(version);
}

String getVersionFromParts(List<int> parts) {
  // where parts correspond to [x, y, z, m, n] from tag
  assert(parts.length == 5);
  final StringBuffer buf = StringBuffer()
    // take x, y, and z
    ..write(parts.take(3).join('.'))
    ..write('-')
    // skip x, y, and z, take m and n
    ..write(parts.skip(3).take(2).join('.'))
    ..write('.pre');
  // return a string that looks like: '1.2.3-4.5.pre'
  return buf.toString();
}

/// A wrapper around git process calls that can be mocked for unit testing.
class Git {
  const Git();

  String getOutput(String command, String explanation) {
    final ProcessResult result = _run(command);
    if ((result.stderr as String).isEmpty && result.exitCode == 0)
      return (result.stdout as String).trim();
    _reportFailureAndExit(result, explanation);
    return null; // for the analyzer's sake
  }

  void run(String command, String explanation) {
    final ProcessResult result = _run(command);
    if (result.exitCode != 0)
      _reportFailureAndExit(result, explanation);
  }

  ProcessResult _run(String command) {
    return Process.runSync('git', command.split(' '));
  }

  void _reportFailureAndExit(ProcessResult result, String explanation) {
    final StringBuffer message = StringBuffer();
    if (result.exitCode != 0) {
      message.writeln('Failed to $explanation. Git exited with error code ${result.exitCode}.');
    } else {
      message.writeln('Failed to $explanation.');
    }
    if ((result.stdout as String).isNotEmpty)
      message.writeln('stdout from git:\n${result.stdout}\n');
    if ((result.stderr as String).isNotEmpty)
      message.writeln('stderr from git:\n${result.stderr}\n');
    throw Exception(message);
  }
}

/// Return a copy of the [version] with [level] incremented by one.
String incrementLevel(String version, String level) {
  final Match match = parseFullTag(version);
  if (match == null) {
    String errorMessage;
    if (version.isEmpty) {
      errorMessage = 'Could not determine the version for this build.';
    } else {
      errorMessage = 'Git reported the latest version as "$version", which '
          'does not fit the expected pattern.';
    }
    throw Exception(errorMessage);
  }

  final List<int> parts = match.groups(<int>[1, 2, 3, 4, 5]).map<int>(int.parse).toList();

  switch (level) {
    case kX:
      parts[0] += 1;
      parts[1] = 0;
      parts[2] = 0;
      parts[3] = 0;
      parts[4] = 0;
      break;
    case kY:
      parts[1] += 1;
      parts[2] = 0;
      parts[3] = 0;
      parts[4] = 0;
      break;
    case kZ:
      parts[2] = 0;
      parts[3] += 1;
      parts[4] = 0;
      break;
    default:
      throw Exception('Unknown increment level. The valid values are "$kX", "$kY", and "$kZ".');
  }
  return getVersionFromParts(parts);
}
