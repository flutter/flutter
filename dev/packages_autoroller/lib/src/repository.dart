// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'git.dart';
import 'stdio.dart';

/// Allowed git remote names.
enum RemoteName { upstream, mirror }

/// Git remote locations.
final class Remote {
  const Remote._({required RemoteName name, required this.url}) : _name = name, assert(url != '');

  const Remote.mirror(String url) : this._(name: RemoteName.mirror, url: url);
  const Remote.upstream(String url) : this._(name: RemoteName.upstream, url: url);

  final RemoteName _name;

  /// The name of the remote.
  String get name => switch (_name) {
    RemoteName.upstream => 'upstream',
    RemoteName.mirror => 'mirror',
  };

  /// The URL of the remote.
  final String url;
}

/// A source code repository.
///
/// This class is an abstraction over a git
/// repository on the local disk. Ideally this abstraction would hide from
/// the outside libraries what git calls were needed to either read or update
/// data in the underlying repository. In practice, most of the bugs in the
/// conductor codebase are related to the git calls made from this and its
/// subclasses.
///
/// Two factors that make this code more complicated than it would otherwise
/// need to be are:
/// 1. That any particular invocation of the conductor may or may not already
/// have the git checkout present on disk, depending on what commands were
/// previously run; and
/// 2. The need to provide overrides for integration tests (in particular
/// the ability to mark a [Repository] instance as a [localUpstream] made
/// integration tests more hermetic, at the cost of complexity in the
/// implementation).
///
/// The only way to simplify the first factor would be to change the behavior of
/// the conductor tool to be a long-lived dart process that keeps all of its
/// state in memory and blocks on user input. This would add the constraint that
/// the user would need to keep the process running for the duration of a
/// release, which could potentially take multiple days and users could not
/// manually change the state of the release process (via editing the JSON
/// config file). However, these may be reasonable trade-offs to make the
/// codebase simpler and easier to reason about.
///
/// The way to simplify the second factor would be to not put any special
/// handling in this library for integration tests. This would make integration
/// tests more difficult/less hermetic, but the production code more reliable.
/// This is probably the right trade-off to make, as the integration tests were
/// still not hermetic or reliable, and the main integration test was ultimately
/// deleted in #84354.
abstract class Repository {
  Repository({
    required this.name,
    required this.upstreamRemote,
    required this.processManager,
    required this.stdio,
    required this.platform,
    required this.fileSystem,
    required this.parentDirectory,
    this.initialRef,
    String? previousCheckoutLocation,
    required this.mirrorRemote,
  }) : _previousCheckoutLocation = previousCheckoutLocation,
       git = Git(processManager),
       assert(upstreamRemote.url.isNotEmpty);

  final String name;
  final Remote upstreamRemote;

  /// Remote for user's mirror.
  final Remote mirrorRemote;

  /// The initial ref (branch or commit name) to check out.
  final String? initialRef;
  final Git git;
  final ProcessManager processManager;
  final Stdio stdio;
  final Platform platform;
  final FileSystem fileSystem;
  final Directory parentDirectory;

  Directory? _checkoutDirectory;
  final String? _previousCheckoutLocation;

  /// Directory for the repository checkout.
  ///
  /// Since cloning a repository takes a long time, we do not ensure it is
  /// cloned on the filesystem until this getter is accessed.
  Future<Directory> get checkoutDirectory async {
    if (_checkoutDirectory != null) {
      return _checkoutDirectory!;
    }
    if (_previousCheckoutLocation != null) {
      _checkoutDirectory = fileSystem.directory(_previousCheckoutLocation);
      if (!_checkoutDirectory!.existsSync()) {
        throw Exception(
          'Provided previousCheckoutLocation $_previousCheckoutLocation does not exist on disk!',
        );
      }
      if (initialRef != null) {
        assert(initialRef != '');
        await git.run(
          <String>['fetch', upstreamRemote.name],
          'Fetch ${upstreamRemote.name} to ensure we have latest refs',
          workingDirectory: _checkoutDirectory!.path,
        );
        // If [initialRef] is a remote ref, the checkout will be left in a detached HEAD state.
        await git.run(
          <String>['checkout', initialRef!],
          'Checking out initialRef $initialRef',
          workingDirectory: _checkoutDirectory!.path,
        );
      }

      return _checkoutDirectory!;
    }

    _checkoutDirectory = parentDirectory.childDirectory(name);
    await _lazilyInitialize(_checkoutDirectory!);

    return _checkoutDirectory!;
  }

  /// RegExp pattern to parse the output of git ls-remote.
  ///
  /// Git output looks like:
  ///
  /// 35185330c6af3a435f615ee8ac2fed8b8bb7d9d4        refs/heads/95159-squash
  /// 6f60a1e7b2f3d2c2460c9dc20fe54d0e9654b131        refs/heads/add-debug-trace
  /// c1436c42c0f3f98808ae767e390c3407787f1a67        refs/heads/add-recipe-field
  /// 4d44dca340603e25d4918c6ef070821181202e69        refs/heads/add-release-channel
  ///
  /// We are interested in capturing what comes after 'refs/heads/'.
  static final RegExp _lsRemotePattern = RegExp(r'.*\s+refs\/heads\/([^\s]+)$');

  /// Parse git ls-remote --heads and return branch names.
  Future<List<String>> listRemoteBranches(String remote) async {
    final String output = await git.getOutput(
      <String>['ls-remote', '--heads', remote],
      'get remote branches',
      workingDirectory: (await checkoutDirectory).path,
    );

    return <String>[
      for (final String line in output.split('\n'))
        if (_lsRemotePattern.firstMatch(line) case final RegExpMatch match) match.group(1)!,
    ];
  }

  /// Ensure the repository is cloned to disk and initialized with proper state.
  Future<void> _lazilyInitialize(Directory checkoutDirectory) async {
    if (checkoutDirectory.existsSync()) {
      stdio.printTrace('Deleting $name from ${checkoutDirectory.path}...');
      checkoutDirectory.deleteSync(recursive: true);
    }

    stdio.printTrace('Cloning $name from ${upstreamRemote.url} to ${checkoutDirectory.path}...');
    await git.run(
      <String>[
        'clone',
        '--origin',
        upstreamRemote.name,
        '--',
        upstreamRemote.url,
        checkoutDirectory.path,
      ],
      'Cloning $name repo',
      workingDirectory: parentDirectory.path,
    );
    await git.run(
      <String>['remote', 'add', mirrorRemote.name, mirrorRemote.url],
      'Adding remote ${mirrorRemote.url} as ${mirrorRemote.name}',
      workingDirectory: checkoutDirectory.path,
    );
    await git.run(
      <String>['fetch', mirrorRemote.name],
      'Fetching git remote ${mirrorRemote.name}',
      workingDirectory: checkoutDirectory.path,
    );

    if (initialRef != null) {
      await git.run(
        <String>['checkout', initialRef!],
        'Checking out initialRef $initialRef',
        workingDirectory: checkoutDirectory.path,
      );
    }
    final String revision = await _reverseParse('HEAD');
    stdio.printTrace('Repository $name is checked out at revision "$revision".');
  }

  /// Get the working tree status.
  ///
  /// Calls `git status --porcelain` which should output in a stable format
  /// across git versions.
  Future<String> gitStatus() async {
    return git.getOutput(
      <String>['status', '--porcelain'],
      'check that the git checkout is clean',
      workingDirectory: (await checkoutDirectory).path,
    );
  }

  /// Verify the repository's git checkout is clean.
  Future<bool> gitCheckoutClean() async {
    return (await gitStatus()).isEmpty;
  }

  /// Create (and checkout) a new branch based on the current HEAD.
  ///
  /// Runs `git checkout -b $branchName`.
  Future<void> newBranch(String branchName) async {
    await git.run(
      <String>['checkout', '-b', branchName],
      'create & checkout new branch $branchName',
      workingDirectory: (await checkoutDirectory).path,
    );
  }

  /// Look up the commit for [ref].
  Future<String> _reverseParse(String ref) async {
    final String revisionHash = await git.getOutput(
      <String>['rev-parse', ref],
      'look up the commit for the ref $ref',
      workingDirectory: (await checkoutDirectory).path,
    );
    assert(revisionHash.isNotEmpty);
    return revisionHash;
  }

  /// Push [commit] to the release channel [branch].
  Future<void> pushRef({
    required String fromRef,
    required String remote,
    required String toRef,
    bool force = false,
    bool dryRun = false,
  }) async {
    final args = <String>['push', if (force) '--force', remote, '$fromRef:$toRef'];
    final String command = <String>['git', ...args].join(' ');
    if (dryRun) {
      stdio.printStatus('About to execute command: `$command`');
    } else {
      await git.run(
        args,
        'update the release branch with the commit',
        workingDirectory: (await checkoutDirectory).path,
      );
      stdio.printStatus('Executed command: `$command`');
    }
  }

  Future<String> commit(String message, {bool addFirst = false, String? author}) async {
    if (addFirst) {
      final bool hasChanges = (await git.getOutput(
        <String>['status', '--porcelain'],
        'check for uncommitted changes',
        workingDirectory: (await checkoutDirectory).path,
      )).trim().isNotEmpty;
      if (!hasChanges) {
        throw Exception('Tried to commit with message $message but no changes were present');
      }
      await git.run(
        <String>['add', '--all'],
        'add all changes to the index',
        workingDirectory: (await checkoutDirectory).path,
      );
    }
    String? authorArg;
    if (author != null) {
      if (author.contains('"')) {
        throw FormatException('Commit author cannot contain character \'"\', received $author');
      }
      // verify [author] matches git author convention, e.g. "Jane Doe <jane.doe@email.com>"
      if (!RegExp(r'.+<.*>').hasMatch(author)) {
        throw FormatException('Commit author appears malformed: "$author"');
      }
      authorArg = '--author="$author"';
    }
    final commitCmd = <String>['commit', '--message', message, ?authorArg];
    stdio.printTrace('Executing git $commitCmd...');
    final io.ProcessResult commitResult = await git.run(
      commitCmd,
      'commit changes',
      workingDirectory: (await checkoutDirectory).path,
    );
    final stdout = commitResult.stdout as String;
    if (stdout.isNotEmpty) {
      stdio.printTrace(stdout);
    }
    final stderr = commitResult.stderr as String;
    if (stderr.isNotEmpty) {
      stdio.printTrace(stderr);
    }

    return _reverseParse('HEAD');
  }
}

final class FrameworkRepository extends Repository {
  FrameworkRepository(
    this.checkouts, {
    super.name = 'framework',
    super.upstreamRemote = const Remote.upstream(FrameworkRepository.defaultUpstream),
    super.previousCheckoutLocation,
    String super.initialRef = FrameworkRepository.defaultBranch,
    required super.mirrorRemote,
  }) : super(
         fileSystem: checkouts.fileSystem,
         parentDirectory: checkouts.directory,
         platform: checkouts.platform,
         processManager: checkouts.processManager,
         stdio: checkouts.stdio,
       );

  final Checkouts checkouts;
  static const String defaultUpstream = 'git@github.com:flutter/flutter.git';
  static const String defaultBranch = 'master';

  Future<void> streamDart(List<String> args, {String? workingDirectory}) async {
    final String repoWorkingDirectory = (await checkoutDirectory).path;

    await _streamProcess(<String>[
      fileSystem.path.join(repoWorkingDirectory, 'bin', 'dart'),
      ...args,
    ], workingDirectory: workingDirectory ?? repoWorkingDirectory);
  }

  Future<io.Process> streamFlutter(
    List<String> args, {
    void Function(String)? stdoutCallback,
    void Function(String)? stderrCallback,
    String? workingDirectory,
  }) async {
    final String repoWorkingDirectory = (await checkoutDirectory).path;

    return _streamProcess(<String>[
      fileSystem.path.join(repoWorkingDirectory, 'bin', 'flutter'),
      ...args,
    ], workingDirectory: workingDirectory ?? repoWorkingDirectory);
  }

  Future<io.Process> _streamProcess(
    List<String> cmd, {
    void Function(String)? stdoutCallback,
    void Function(String)? stderrCallback,
    String? workingDirectory,
  }) async {
    stdio.printTrace('Executing $cmd...');
    final io.Process process = await processManager.start(cmd, workingDirectory: workingDirectory);
    final StreamSubscription<String> stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stdoutCallback ?? stdio.printTrace);
    final StreamSubscription<String> stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrCallback ?? stdio.printError);
    await Future.wait<void>(<Future<void>>[stdoutSub.asFuture<void>(), stderrSub.asFuture<void>()]);
    unawaited(stdoutSub.cancel());
    unawaited(stderrSub.cancel());

    final int exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw io.ProcessException(cmd.first, cmd.sublist(1), 'Process failed', exitCode);
    }
    return process;
  }
}

/// Represents the environment in which a command is being executed.
@immutable
final class Checkouts {
  Checkouts({
    required this.platform,
    required this.processManager,
    required this.stdio,
    required Directory parentDirectory,
    String directoryName = 'package_autoroller_checkouts',
  }) : directory = parentDirectory.childDirectory(directoryName) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  /// Which directory is be used to checkout code.
  final Directory directory;

  /// The file system used to access the checkout path.
  FileSystem get fileSystem => directory.fileSystem;

  /// The platform being executed on.
  final Platform platform;

  /// Ability to spawn processes on the current system.
  final ProcessManager processManager;

  /// Standard I/O facade.
  final Stdio stdio;
}
