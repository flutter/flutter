// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import './git.dart';
import './globals.dart' as globals;
import './stdio.dart';
import './version.dart';

/// A source code repository.
class Repository {
  Repository({
    @required this.name,
    @required this.upstream,
    @required this.processManager,
    @required this.stdio,
    @required this.platform,
    @required this.fileSystem,
    @required this.parentDirectory,
    this.localUpstream = false,
    this.useExistingCheckout = false,
  })  : git = Git(processManager),
        assert(localUpstream != null),
        assert(useExistingCheckout != null);

  final String name;
  final String upstream;
  final Git git;
  final ProcessManager processManager;
  final Stdio stdio;
  final Platform platform;
  final FileSystem fileSystem;
  final Directory parentDirectory;
  final bool useExistingCheckout;

  /// If the repository will be used as an upstream for a test repo.
  final bool localUpstream;

  Directory _checkoutDirectory;

  /// Lazily-loaded directory for the repository checkout.
  ///
  /// Cloning a repository is time-consuming, thus the repository is not cloned
  /// until this getter is called.
  Directory get checkoutDirectory {
    if (_checkoutDirectory != null) {
      return _checkoutDirectory;
    }
    _checkoutDirectory = parentDirectory.childDirectory(name);
    if (checkoutDirectory.existsSync() && !useExistingCheckout) {
      deleteDirectory();
    }
    if (!checkoutDirectory.existsSync()) {
      stdio.printTrace('Cloning $name to ${checkoutDirectory.path}...');
      git.run(
        <String>['clone', '--', upstream, checkoutDirectory.path],
        'Cloning $name repo',
        workingDirectory: parentDirectory.path,
      );
      if (localUpstream) {
        // These branches must exist locally for the repo that depends on it
        // to fetch and push to.
        for (final String channel in globals.kReleaseChannels) {
          git.run(
            <String>['checkout', channel, '--'],
            'check out branch $channel locally',
            workingDirectory: checkoutDirectory.path,
          );
        }
      }
    } else {
      stdio.printTrace(
        'Using existing $name repo at ${checkoutDirectory.path}...',
      );
    }
    return _checkoutDirectory;
  }

  void deleteDirectory() {
    if (!checkoutDirectory.existsSync()) {
      stdio.printTrace(
        'Tried to delete ${checkoutDirectory.path} but it does not exist.',
      );
      return;
    }
    stdio.printTrace('Deleting $name from ${checkoutDirectory.path}...');
    checkoutDirectory.deleteSync(recursive: true);
  }

  /// The URL of the remote named [remoteName].
  String remoteUrl(String remoteName) {
    assert(remoteName != null);
    return git.getOutput(
      <String>['remote', 'get-url', remoteName],
      'verify the URL of the $remoteName remote',
      workingDirectory: checkoutDirectory.path,
    );
  }

  /// Verify the repository's git checkout is clean.
  bool gitCheckoutClean() {
    final String output = git.getOutput(
      <String>['status', '--porcelain'],
      'check that the git checkout is clean',
      workingDirectory: checkoutDirectory.path,
    );
    return output == '';
  }

  /// Fetch all branches and associated commits and tags from [remoteName].
  void fetch(String remoteName) {
    git.run(
      <String>['fetch', remoteName, '--tags'],
      'fetch $remoteName --tags',
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

  /// Look up the commit for [ref].
  String reverseParse(String ref) {
    final String revisionHash = git.getOutput(
      <String>['rev-parse', ref],
      'look up the commit for the ref $ref',
      workingDirectory: checkoutDirectory.path,
    );
    assert(revisionHash.isNotEmpty);
    return revisionHash;
  }

  /// Determines if one ref is an ancestor for another.
  bool isAncestor(String possibleAncestor, String possibleDescendant) {
    final int exitcode = git.run(
      <String>[
        'merge-base',
        '--is-ancestor',
        possibleDescendant,
        possibleAncestor
      ],
      'verify $possibleAncestor is a direct ancestor of $possibleDescendant.',
      allowNonZeroExitCode: true,
      workingDirectory: checkoutDirectory.path,
    );
    return exitcode == 0;
  }

  /// Determines if a given commit has a tag.
  bool isCommitTagged(String commit) {
    final int exitcode = git.run(
      <String>['describe', '--exact-match', '--tags', commit],
      'verify $commit is already tagged',
      allowNonZeroExitCode: true,
      workingDirectory: checkoutDirectory.path,
    );
    return exitcode == 0;
  }

  /// Resets repository HEAD to [commit].
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

  Version flutterVersion() {
    // Build tool
    processManager.runSync(<String>[
      fileSystem.path.join(checkoutDirectory.path, 'bin', 'flutter'),
      'help',
    ]);
    // Check version
    final io.ProcessResult result = processManager.runSync(<String>[
      fileSystem.path.join(checkoutDirectory.path, 'bin', 'flutter'),
      '--version',
      '--machine',
    ]);
    final Map<String, dynamic> versionJson = jsonDecode(
      globals.stdoutToString(result.stdout),
    ) as Map<String, dynamic>;
    return Version.fromString(versionJson['frameworkVersion'] as String);
  }

  /// Create an empty commit and return the revision.
  @visibleForTesting
  String authorEmptyCommit([String message = 'An empty commit']) {
    git.run(
      <String>[
        '-c',
        'user.name=Conductor',
        '-c',
        'user.email=conductor@flutter.dev',
        'commit',
        '--allow-empty',
        '-m',
        '\'$message\'',
      ],
      'create an empty commit',
      workingDirectory: checkoutDirectory.path,
    );
    return reverseParse('HEAD');
  }

  /// Create a new clone of the current repository.
  ///
  /// The returned repository will inherit all properties from this one, except
  /// for the upstream, which will be the path to this repository on disk.
  ///
  /// This method is for testing purposes.
  @visibleForTesting
  Repository cloneRepository(String cloneName) {
    assert(localUpstream);
    cloneName ??= 'clone-of-$name';
    return Repository(
      fileSystem: fileSystem,
      name: cloneName,
      parentDirectory: parentDirectory,
      platform: platform,
      processManager: processManager,
      stdio: stdio,
      upstream: 'file://${checkoutDirectory.path}/',
      useExistingCheckout: useExistingCheckout,
    );
  }
}

/// An enum of all the repositories that the Conductor supports.
enum RepositoryType {
  framework,
  engine,
}

class Checkouts {
  Checkouts({
    @required Platform platform,
    @required this.fileSystem,
    @required this.processManager,
    Directory parentDirectory,
    String directoryName = 'checkouts',
  }) {
    if (parentDirectory != null) {
      directory = parentDirectory.childDirectory(directoryName);
    } else {
      String filePath;
      // If a test
      if (platform.script.scheme == 'data') {
        final RegExp pattern = RegExp(
          r'(file:\/\/[^"]*[/\\]dev\/tools[/\\][^"]+\.dart)',
          multiLine: true,
        );
        final Match match =
            pattern.firstMatch(Uri.decodeFull(platform.script.path));
        if (match == null) {
          throw Exception(
            'Cannot determine path of script!\n${platform.script.path}',
          );
        }
        filePath = Uri.parse(match.group(1)).path.replaceAll(r'%20', ' ');
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
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  Directory directory;
  final FileSystem fileSystem;
  final ProcessManager processManager;

  Repository addRepo({
    @required RepositoryType repoType,
    @required Stdio stdio,
    @required Platform platform,
    FileSystem fileSystem,
    String upstream,
    String name,
    bool localUpstream = false,
    bool useExistingCheckout = false,
  }) {
    switch (repoType) {
      case RepositoryType.framework:
        name ??= 'framework';
        upstream ??= 'https://github.com/flutter/flutter.git';
        break;
      case RepositoryType.engine:
        name ??= 'engine';
        upstream ??= 'https://github.com/flutter/engine.git';
        break;
    }
    return Repository(
      name: name,
      upstream: upstream,
      stdio: stdio,
      platform: platform,
      fileSystem: fileSystem,
      parentDirectory: directory,
      processManager: processManager,
      localUpstream: localUpstream,
      useExistingCheckout: useExistingCheckout,
    );
  }
}
