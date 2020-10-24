// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

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
  @required Stdio stdio,
  @required Platform platform,
  @required FileSystem fileSystem,
  @required Repository repository,
}) {
  final String level = argResults[kIncrement] as String;
  final String commit = argResults[kCommit] as String;
  final String remoteName = argResults[kRemoteName] as String;
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

  final String remoteUrl = repository.remoteUrl(remoteName);

  if (!repository.gitCheckoutClean()) {
    throw Exception(
      'Your git repository is not clean. Try running "git clean -fd". Warning, '
      'this will delete files! Run with -n to find out which ones.');
  }

  repository.fetch(remoteName);

  // Verify [commit] is valid
  repository.reverseParse(commit);

  stdio.printStatus('remoteName is $remoteName');
  final Version lastVersion = Version.fromString(repository.getFullTag(remoteName));

  final Version version = skipTagging ? lastVersion : Version.increment(lastVersion, level);
  final String tagName = version.toString();

  if (repository.reverseParse(lastVersion.toString()).contains(commit.trim())) {
    throw Exception(
        'Commit $commit is already on the dev branch as $lastVersion.');
  }

  if (justPrint) {
    stdio.printStatus(tagName);
    return false;
  }

  if (skipTagging && !repository.isCommitTagged(commit)) {
    throw Exception('The $kSkipTagging flag is only supported for tagged commits.');
  }

  if (!force && !repository.isAncestor(commit, lastVersion.toString())) {
    throw Exception(
        'The previous dev tag $lastVersion is not a direct ancestor of $commit.\n'
        'The flag "$kForce" is required to force push a new release past a cherry-pick.'
    );
  }

  final String hash = repository.reverseParse(commit);

  // [commit] can be a prefix for [hash].
  assert(hash.startsWith(commit));

  // PROMPT

  if (autoApprove) {
    stdio.printStatus('Publishing Flutter $version ($hash) to the "dev" channel.');
  } else {
    stdio.printStatus('Your tree is ready to publish Flutter $version '
        '($hash) to the "dev" channel.');
    stdio.write('Are you? [yes/no] ');
    if (stdio.readLineSync() != 'yes') {
      stdio.printError('The dev roll has been aborted.');
      return false;
    }
  }

  if (!skipTagging) {
    repository.tag(commit, version.toString(), remoteName);
  }

  repository.updateChannel(commit, remoteName, 'dev');

  stdio.printStatus(
    'Flutter version $version has been rolled to the "dev" channel at $remoteUrl.',
  );
  return true;
}
