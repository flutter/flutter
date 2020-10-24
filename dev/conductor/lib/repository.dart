// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './git.dart';
import './globals.dart' as globals;
import './stdio.dart';

class Repository {
  Repository({
    @required this.name,
    @required this.upstream,
    @required this.git,
    @required this.stdio,
    @required this.platform,
    @required this.fileSystem,
    @required this.parentDirectory,
    this.localUpstream = false,
  }) : checkoutDirectory = parentDirectory.childDirectory(name) {
    ensureCloned();
    if (localUpstream) {
      for (final String channel in globals.kReleaseChannels) {
        git.run(
          <String>['checkout', channel, '--'],
          'check out branch $channel locally',
          workingDirectory: checkoutDirectory.path,
        );
      }
    }
  }

  final String name;
  final String upstream;
  final Git git;
  final Stdio stdio;
  final Platform platform;
  final FileSystem fileSystem;
  final Directory parentDirectory;
  final Directory checkoutDirectory;

  /// If the repository's upstream is a local directory.
  final bool localUpstream;

  void ensureCloned() {
    stdio.printTrace('About to check if $name exists...');
    if (!checkoutDirectory.existsSync()) {
      stdio.printTrace('About to clone repo $name');
      git.run(
        <String>['clone', '--', upstream, checkoutDirectory.path],
        'Cloning $name repo',
        workingDirectory: parentDirectory.path,
      );
    } else {
      stdio.printTrace('Repo $name already exists');
    }
  }

  String remoteUrl(String remoteName) => git.getOutput(
    <String>['remote', 'get-url', remoteName],
    'verify the URL of the $remoteName remote',
    workingDirectory: checkoutDirectory.path,
  );

  /// Verifies the repository's git checkout is clean.
  bool gitCheckoutClean() {
    final String output = git.getOutput(
      <String>['status', '--porcelain'],
      'check that the git checkout is clean',
      workingDirectory: checkoutDirectory.path,
    );
    return output == '';
  }

  void fetch(String remoteName) {
    git.run(
      <String>['fetch', remoteName],
      'fetch $remoteName',
      workingDirectory: checkoutDirectory.path,
    );
  }

  /// Obtain the version tag of the previous dev release.
  String getFullTag(String remoteName) {
    const String glob = '*.*.*-*.*.pre';
    // describe the latest dev release
    final String ref = 'refs/remotes/$remoteName/dev';
    return git.getOutput(
      <String>['describe', '--match', glob, '--exact-match', '--tags', ref],
      'obtain last released version number',
      workingDirectory: checkoutDirectory.path,
    );
  }

  String reverseParse(String ref) {
    final String revisionHash = git.getOutput(
      <String>['rev-parse', ref],
      'look up the commit for the ref $ref',
      workingDirectory: checkoutDirectory.path,
    );
    assert(revisionHash.isNotEmpty);
    return revisionHash;
  }

  bool isAncestor(String possibleAncestor, String target) {
    final int exitcode = git.run(
      <String>['merge-base', '--is-ancestor', target, possibleAncestor],
      'verify $possibleAncestor is a direct ancestor of $target. The flag '
      '`${globals.kForce}` is required to override this check.',
      allowNonZeroExitCode: true,
      workingDirectory: checkoutDirectory.path,
    );
    return exitcode == 0;
  }

  bool isCommitTagged(String commit) {
    final int exitcode = git.run(
      <String>['describe', '--exact-match', '--tags', commit],
      'verify $commit is already tagged',
      allowNonZeroExitCode: true,
      workingDirectory: checkoutDirectory.path,
    );
    return exitcode == 0;
  }

  void reset(String commit) {
    git.run(
      <String>['reset', commit, '--hard'],
      'reset to the release commit',
      workingDirectory: checkoutDirectory.path,
    );
  }

  /// Tag [commit] and push the tag to the remote.
  void tag(String commit, String tagName, String remote) {
    git.run(
      <String>['tag', tagName, commit],
      'tag the commit with the version label',
      workingDirectory: checkoutDirectory.path,
    );
    git.run(
      <String>['push', remote, tagName],
      'publish the tag to the repo',
      workingDirectory: checkoutDirectory.path,
    );
  }

  /// Push [commit] to the release channel [branch].
  void updateChannel(
    String commit,
    String remote,
    String branch, {
    bool force = false,
  }) {
    git.run(
      <String>[
        'push',
        if (force) '--force',
        remote,
        '$commit:$branch',
      ],
      'update the release branch with the commit',
      workingDirectory: checkoutDirectory.path,
    );
  }

  String authorEmptyCommit([String message = 'An empty commit']) {
    git.run(
      <String>['commit', '--allow-empty', '-m', '\'$message\''],
      'create an empty commit',
      workingDirectory: checkoutDirectory.path,
    );
    return reverseParse('HEAD');
  }
}

class Checkouts {
  Checkouts({
    @required Platform platform,
    @required FileSystem fileSystem,
    @required Git git,
    Directory parentDirectory,
    String directoryName = 'checkouts',
    bool cleanFirst = false,
  }) {
    if (parentDirectory != null) {
      directory = parentDirectory.childDirectory(directoryName);
    } else {
      String filePath;
      // If a test
      if (platform.script.scheme == 'data') {
        final RegExp pattern = RegExp(
            r'(file:\/\/[^"]*[/\\]conductor[/\\][^"]+\.dart)',
            multiLine: true,
        );
        final Match match = pattern.firstMatch(Uri.decodeFull(platform.script.path));
        if (match == null) {
          throw Exception('Cannot determine path of script!');
        }
        filePath = Uri.parse(match.group(1)).path;
      } else {
        filePath = platform.script.toFilePath();
      }
      final String checkoutsDirname = fileSystem.path.normalize(
          fileSystem.path.join(
              fileSystem.path.dirname(filePath),
              '..',
              'checkouts',
          ),
      );
      directory = fileSystem.directory(checkoutsDirname);
    }
    // This should always exist.
    assert(directory.existsSync());
    if (cleanFirst) {
      git.run(
        <String>['clean', '-xffd', '--', directory.path],
        'clean checkouts directory'
      );
    }
  }

  Directory directory;
  List<Repository> repositories = <Repository>[];

  Repository addRepo({
    @required String name,
    @required String upstream,
    @required Git git,
    @required Stdio stdio,
    @required Platform platform,
    @required FileSystem fileSystem,
    bool localUpstream = false,
  }) {
    final Repository repo = Repository(
      name: name,
      upstream: upstream,
      git: git,
      stdio: stdio,
      platform: platform,
      fileSystem: fileSystem,
      parentDirectory: directory,
      localUpstream: localUpstream,
    );
    repositories.add(repo);
    return repo;
  }
}
