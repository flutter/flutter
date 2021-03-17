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
abstract class Repository {
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

  /// Directory for the repository checkout.
  ///
  /// Since cloning a repository takes a long time, we do not ensure it is
  /// cloned on the filesystem until this getter is accessed.
  Directory get checkoutDirectory {
    if (_checkoutDirectory != null) {
      return _checkoutDirectory;
    }
    _checkoutDirectory = parentDirectory.childDirectory(name);
    if (!useExistingCheckout && _checkoutDirectory.existsSync()) {
      stdio.printTrace('Deleting $name from ${_checkoutDirectory.path}...');
      _checkoutDirectory.deleteSync(recursive: true);
    } else if (useExistingCheckout && _checkoutDirectory.existsSync()) {
      git.run(
        <String>['checkout', 'master'],
        'Checkout to master branch',
        workingDirectory: _checkoutDirectory.path,
      );
      git.run(
        <String>['pull', '--ff-only'],
        'Updating $name repo',
        workingDirectory: _checkoutDirectory.path,
      );
    }
    if (!_checkoutDirectory.existsSync()) {
      stdio.printTrace(
          'Cloning $name from $upstream to ${_checkoutDirectory.path}...');
      git.run(
        <String>['clone', '--', upstream, _checkoutDirectory.path],
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
            workingDirectory: _checkoutDirectory.path,
          );
        }
      }
    }

    final String revision = reverseParse('HEAD');
    stdio
        .printTrace('Repository $name is checked out at revision "$revision".');
    return _checkoutDirectory;
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

  void checkout(String revision) {
    git.run(
      <String>['checkout', revision],
      'checkout $revision',
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
    ).trim();
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
  Repository cloneRepository(String cloneName);
}

class FrameworkRepository extends Repository {
  FrameworkRepository(
    this.checkouts, {
    String name = 'framework',
    String upstream = FrameworkRepository.defaultUpstream,
    bool localUpstream = false,
    bool useExistingCheckout = false,
  }) : super(
          name: name,
          upstream: upstream,
          fileSystem: checkouts.fileSystem,
          localUpstream: localUpstream,
          parentDirectory: checkouts.directory,
          platform: checkouts.platform,
          processManager: checkouts.processManager,
          stdio: checkouts.stdio,
          useExistingCheckout: useExistingCheckout,
        );

  /// A [FrameworkRepository] with the host conductor's repo set as upstream.
  ///
  /// This is useful when testing a commit that has not been merged upstream
  /// yet.
  factory FrameworkRepository.localRepoAsUpstream(
    Checkouts checkouts, {
    String name = 'framework',
    bool useExistingCheckout = false,
    @required String upstreamPath,
  }) {
    return FrameworkRepository(
      checkouts,
      name: name,
      upstream: 'file://$upstreamPath/',
      localUpstream: false,
      useExistingCheckout: useExistingCheckout,
    );
  }

  final Checkouts checkouts;
  static const String defaultUpstream =
      'https://github.com/flutter/flutter.git';

  String get cacheDirectory => fileSystem.path.join(
        checkoutDirectory.path,
        'bin',
        'cache',
      );

  @override
  Repository cloneRepository(String cloneName) {
    assert(localUpstream);
    cloneName ??= 'clone-of-$name';
    return FrameworkRepository(
      checkouts,
      name: cloneName,
      upstream: 'file://${checkoutDirectory.path}/',
      useExistingCheckout: useExistingCheckout,
    );
  }

  void _ensureToolReady() {
    final File toolsStamp =
        fileSystem.directory(cacheDirectory).childFile('flutter_tools.stamp');
    if (toolsStamp.existsSync()) {
      final String toolsStampHash = toolsStamp.readAsStringSync().trim();
      final String repoHeadHash = reverseParse('HEAD');
      if (toolsStampHash == repoHeadHash) {
        return;
      }
    }

    stdio.printTrace('Building tool...');
    // Build tool
    processManager.runSync(<String>[
      fileSystem.path.join(checkoutDirectory.path, 'bin', 'flutter'),
      'help',
    ]);
  }

  io.ProcessResult runFlutter(List<String> args) {
    _ensureToolReady();

    return processManager.runSync(<String>[
      fileSystem.path.join(checkoutDirectory.path, 'bin', 'flutter'),
      ...args,
    ]);
  }

  @override
  void checkout(String revision) {
    super.checkout(revision);
    // The tool will overwrite old cached artifacts, but not delete unused
    // artifacts from a previous version. Thus, delete the entire cache and
    // re-populate.
    final Directory cache = fileSystem.directory(cacheDirectory);
    if (cache.existsSync()) {
      stdio.printTrace('Deleting cache...');
      cache.deleteSync(recursive: true);
    }
    _ensureToolReady();
  }

  Version flutterVersion() {
    // Check version
    final io.ProcessResult result =
        runFlutter(<String>['--version', '--machine']);
    final Map<String, dynamic> versionJson = jsonDecode(
      globals.stdoutToString(result.stdout),
    ) as Map<String, dynamic>;
    return Version.fromString(versionJson['frameworkVersion'] as String);
  }
}

/// An enum of all the repositories that the Conductor supports.
enum RepositoryType {
  framework,
  engine,
}

class Checkouts {
  Checkouts({
    @required this.fileSystem,
    @required this.platform,
    @required this.processManager,
    @required this.stdio,
    @required Directory parentDirectory,
    String directoryName = 'flutter_conductor_checkouts',
  })  : assert(parentDirectory != null),
        directory = parentDirectory.childDirectory(directoryName) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  final Directory directory;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;
}
