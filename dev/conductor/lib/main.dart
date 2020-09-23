// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './git.dart';
import './globals.dart';
import './repository.dart';
import './stdio.dart';
import './version.dart';

/// Main script execution.
///
/// Returns true if publishing was successful, else false.
bool run({
  @required String usage,
  @required ArgResults argResults,
  @required Git git,
  @required Stdio stdio,
  @required Platform platform,
  @required FileSystem fileSystem,
  @required Repository repository,
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
    stdio.printStatus(
        'roll_dev.dart --increment=level --commit=hash • update the version tags '
        'and roll a new dev build.\n$usage');
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
        'https://github.com/flutter/flutter/wiki/Release-process');
  }

  if (git.getOutput('status --porcelain', 'check status of your local checkout') != '') {
    throw Exception(
        'Your git repository is not clean. Try running "git clean -fd". Warning, '
        'this will delete files! Run with -n to find out which ones.');
  }

  git.run('fetch $origin', 'fetch $origin');

  final Version lastVersion = Version.fromString(git.getFullTag(origin));

  final Version version = skipTagging ? lastVersion : Version.increment(lastVersion, level);

  if (git.getOutput(
        'rev-parse $lastVersion',
        'check if commit is already on dev',
      ).contains(commit.trim())) {
    throw Exception(
        'Commit $commit is already on the dev branch as $lastVersion.');
  }

  if (justPrint) {
    stdio.printStatus(version.toString());
    return false;
  }

  if (skipTagging) {
    git.run(
        'describe --exact-match --tags $commit',
        'verify $commit is already tagged. You can only use the flag '
            '`$kSkipTagging` if the commit has already been tagged.');
  }

  if (!force) {
    git.run(
        'merge-base --is-ancestor $lastVersion $commit',
        'verify $lastVersion is a direct ancestor of $commit. The flag `$kForce`'
        'is required to force push a new release past a cherry-pick',
    );
  }

  git.run('reset $commit --hard', 'reset to the release commit');

  final String hash =
      git.getOutput('rev-parse HEAD', 'Get git hash for $commit');

  // PROMPT

  if (autoApprove) {
    stdio.printStatus('Publishing Flutter $version (${hash.substring(0, 10)}) to the "dev" channel.');
  } else {
    stdio.printStatus('Your tree is ready to publish Flutter $version '
        '(${hash.substring(0, 10)}) to the "dev" channel.');
    stdio.write('Are you? [yes/no] ');
    if (stdio.readLineSync() != 'yes') {
      stdio.printError('The dev roll has been aborted.');
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
  stdio.printStatus(
    'Flutter version $version has been rolled to the "dev" channel!',
  );
  return true;
}
