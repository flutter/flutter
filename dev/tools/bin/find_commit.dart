// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This script looks at the current commit and branch of the git repository in
// which it was run, and finds the contemporary commit in the master branch of
// another git repository, whose path is provided on the command line. The
// contemporary commit is the one that was public at the time of the last commit
// on the master branch before the current commit's branch was created.

import 'dart:io';

const bool debugLogging = false;

void log(String message) {
  if (debugLogging)
    print(message);
}

class Commit {
  Commit(this.hash, this.timestamp);

  final String hash;
  final DateTime timestamp;

  static String formatArgument = '--format=%H %cI';

  static Commit parse(String line) {
    final int space = line.indexOf(' ');
    return Commit(line.substring(0, space), DateTime.parse(line.substring(space+1, line.length).trimRight()));
  }

  static List<Commit> parseList(String lines) {
    return lines.split('\n').where((String line) => line.isNotEmpty).map(parse).toList().reversed.toList();
  }
}

String findCommit({
  required String primaryRepoDirectory,
  required String primaryBranch,
  required String primaryTrunk,
  required String secondaryRepoDirectory,
  required String secondaryBranch,
}) {
  final Commit anchor;
  if (primaryBranch == primaryTrunk) {
    log('on $primaryTrunk, using last commit as anchor');
    anchor = Commit.parse(git(primaryRepoDirectory, <String>['log', Commit.formatArgument, '--max-count=1', primaryBranch, '--']));
  } else {
    final List<Commit> branchCommits = Commit.parseList(git(primaryRepoDirectory, <String>['log', Commit.formatArgument, primaryBranch, '--']));
    final List<Commit> trunkCommits = Commit.parseList(git(primaryRepoDirectory, <String>['log', Commit.formatArgument, primaryTrunk, '--']));
    if (branchCommits.isEmpty || trunkCommits.isEmpty || branchCommits.first.hash != trunkCommits.first.hash)
      throw StateError('Branch $primaryBranch does not seem to have a common history with trunk $primaryTrunk.');
    if (branchCommits.last.hash == trunkCommits.last.hash) {
      log('$primaryBranch is even with $primaryTrunk, using last commit as anchor');
      anchor = trunkCommits.last;
    } else {
      int index = 0;
      while (branchCommits.length > index && trunkCommits.length > index && branchCommits[index].hash == trunkCommits[index].hash)
        index += 1;
      log('$primaryBranch branched from $primaryTrunk ${branchCommits.length - index} commits ago, trunk has advanced by ${trunkCommits.length - index} commits since then.');
      anchor = trunkCommits[index - 1];
    }
  }
  return git(secondaryRepoDirectory, <String>[
    'log',
    '--format=%H',
    '--until=${anchor.timestamp.toIso8601String()}',
    '--max-count=1',
    secondaryBranch,
    '--',
  ]);
}

String git(String workingDirectory, List<String> arguments) {
  final ProcessResult result = Process.runSync('git', arguments, workingDirectory: workingDirectory);
  if (result.exitCode != 0 || '${result.stderr}'.isNotEmpty)
    throw ProcessException('git', arguments, '${result.stdout}${result.stderr}', result.exitCode);
  return '${result.stdout}';
}

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2 || arguments.contains('--help') || arguments.contains('-h')) {
    print(
      'Usage: dart find_commit.dart [<path-to-primary-repo>] <path-to-secondary-repo>\n'
      'This script will find the commit in the secondary repo that was contemporary\n'
      'when the commit in the primary repo was created. If that commit is on a\n'
      "branch, then the date of the branch's creation is used instead.\n"
      'If <path-to-primary-repo> is omitted, the current directory is used for the\n'
      'primary repo.'
    );
  } else {
    final String primaryRepo = arguments.length == 1 ? '.' : arguments.first;
    final String secondaryRepo = arguments.last;
    print(findCommit(
      primaryRepoDirectory: primaryRepo,
      primaryBranch: git(primaryRepo, <String>['rev-parse', '--abbrev-ref', 'HEAD']).trim(),
      primaryTrunk: 'master',
      secondaryRepoDirectory: secondaryRepo,
      secondaryBranch: 'master',
    ).trim());
  }
}
