// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

//////////////////////////////////////////////////////////////////////
//                                                                  //
//  ✨ THINKING OF MOVING/REFACTORING THIS FILE? READ ME FIRST! ✨  //
//                                                                  //
//  There is a link to this file in //docs/tool/Engine-artfiacts.md //
//  and it would be very kind of you to update the link, if needed. //
//                                                                  //
//////////////////////////////////////////////////////////////////////

void main() {
  // Want to test the powershell (content_aware_hash.ps1) file, but running
  // a macOS or Linux machine? You can install powershell and then opt-in to
  // running `pwsh bin/internal/content_aware_hash.ps1`.
  //
  // macOS: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos
  // linux: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
  //
  // Then, set this variable to true:
  final bool usePowershellOnPosix = io.Platform.environment['FORCE_POWERSHELL'] == 'true';

  print('env: ${io.Platform.environment}');

  const FileSystem localFs = LocalFileSystem();
  final _FlutterRootUnderTest flutterRoot = _FlutterRootUnderTest.findWithin();

  late Directory tmpDir;
  late _FlutterRootUnderTest testRoot;
  late Map<String, String> environment;

  void printIfNotEmpty(String prefix, String string) {
    if (string.isNotEmpty) {
      string.split(io.Platform.lineTerminator).forEach((String s) {
        print('$prefix:>$s<');
      });
    }
  }

  io.ProcessResult run(String executable, List<String> args, {String? workingPath}) {
    print('Running "$executable ${args.join(" ")}"${workingPath != null ? ' $workingPath' : ''}');
    final io.ProcessResult result = io.Process.runSync(
      executable,
      args,
      environment: environment,
      workingDirectory: workingPath ?? testRoot.root.absolute.path,
      includeParentEnvironment: false,
    );
    if (result.exitCode != 0) {
      fail(
        'Failed running "$executable $args" (exit code = ${result.exitCode}),'
        '\nstdout: ${result.stdout}'
        '\nstderr: ${result.stderr}',
      );
    }
    printIfNotEmpty('stdout', (result.stdout as String).trim());
    printIfNotEmpty('stderr', (result.stderr as String).trim());
    return result;
  }

  setUpAll(() async {
    if (usePowershellOnPosix) {
      final io.ProcessResult result = io.Process.runSync('pwsh', <String>['--version']);
      print('Using Powershell (${result.stdout}) on POSIX for local debugging and testing');
    }
  });

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('content_aware_hash.');
    testRoot = _FlutterRootUnderTest.fromPath(tmpDir.childDirectory('flutter').path);

    environment = <String, String>{};

    if (const LocalPlatform().isWindows || usePowershellOnPosix) {
      // Copy a minimal set of environment variables needed to run the update_engine_version script in PowerShell.
      const List<String> powerShellVariables = <String>['SystemRoot', 'PATH', 'PATHEXT'];
      for (final String key in powerShellVariables) {
        final String? value = io.Platform.environment[key];
        if (value != null) {
          environment[key] = value;
        }
      }
    }

    // Make a slim copy of the flutterRoot.
    flutterRoot.copyTo(testRoot);

    // Generate blank files for what otherwise would exist in the engine.
    testRoot
      ..engineReadMe.createSync(recursive: true)
      ..flutterReadMe.createSync(recursive: true)
      ..deps.createSync(recursive: true);
  });

  tearDown(() {
    // Git adds a lot of files, we don't want to test for them.
    final Directory gitDir = testRoot.root.childDirectory('.git');
    if (gitDir.existsSync()) {
      gitDir.deleteSync(recursive: true);
    }

    // Now do cleanup so even if the next step fails, we still deleted tmp.
    tmpDir.deleteSync(recursive: true);
  });

  /// Runs `bin/internal/content_aware_hash.{sh|ps1}` and returns the process result.
  ///
  /// If the exit code is 0, it is considered a success, and files should exist as a side-effect.
  ///   - On Windows, `powershell` is used (to run `update_engine_version.ps1`);
  ///   - Otherwise, `update_engine_version.sh` is used.
  io.ProcessResult runContentAwareHash() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      // "ExecutionPolicy Bypass" is required to execute scripts from temp
      // folders on Windows 11 machines.
      args = <String>['-ExecutionPolicy', 'Bypass', '-File', testRoot.contentAwareHashPs1.path];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.contentAwareHashPs1.path];
    } else {
      executable = testRoot.contentAwareHashSh.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  /// Sets up and fetches a [remote] (such as `upstream` or `origin`) for [testRoot.root].
  ///
  /// The remote points at itself (`testRoot.root.path`) for ease of testing.
  void setupRemote({required String remote, String? rootPath}) {
    run('git', <String>[
      'remote',
      'add',
      remote,
      rootPath ?? testRoot.root.path,
    ], workingPath: rootPath);
    run('git', <String>['fetch', remote], workingPath: rootPath);
  }

  /// Initializes a blank git repo in [testRoot.root].
  void initGitRepoWithBlankInitialCommit({
    String? workingPath,
    String branch = 'master',
    String remote = 'upstream',
  }) {
    run('git', <String>['init', '--initial-branch', branch], workingPath: workingPath);
    // autocrlf is very important for tests to work on windows.
    run('git', 'config --local core.autocrlf true'.split(' '), workingPath: workingPath);
    run('git', <String>[
      'config',
      '--local',
      'user.email',
      'test@example.com',
    ], workingPath: workingPath);
    run('git', <String>['config', '--local', 'user.name', 'Test User'], workingPath: workingPath);
    run('git', <String>['add', '.'], workingPath: workingPath);
    run('git', <String>[
      'commit',
      '--allow-empty',
      '-m',
      'Initial commit',
    ], workingPath: workingPath);

    setupRemote(remote: remote, rootPath: workingPath);
  }

  String gitShaFor(String ref, {String? workingPath}) {
    return (run('git', <String>['rev-parse', ref], workingPath: workingPath).stdout as String)
        .trim();
  }

  void writeFileAndCommit(File file, String contents) {
    file.writeAsStringSync(contents);
    run('git', <String>['add', '--all']);
    run('git', <String>['commit', '--all', '-m', 'changed ${file.basename} to $contents']);
  }

  void gitSwitchBranch(String branch, {bool create = true}) {
    run('git', <String>['switch', if (create) '-c', branch]);
  }

  // Downstream flutter user tests: (origin|upstream)/(main|master), stable, and
  // beta should work.

  test('generates a hash or upstream/master', () async {
    initGitRepoWithBlankInitialCommit();
    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  test('generates a hash for origin/master', () {
    initGitRepoWithBlankInitialCommit(remote: 'origin');
    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  test('generates a hash for origin/main', () {
    initGitRepoWithBlankInitialCommit(remote: 'origin', branch: 'main');
    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  test('generates a hash for upstream/main', () {
    initGitRepoWithBlankInitialCommit(branch: 'main');
    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  test('generates a hash for CI/CD from HEAD', () {
    // This test validates the workflow with LUCI recipes in which the git sha
    // is checked out, not the branch.
    initGitRepoWithBlankInitialCommit(branch: 'main');
    writeFileAndCommit(testRoot.deps, 'deps changed');

    final String headSha = gitShaFor('HEAD');
    run('git', <String>['checkout', '-f', headSha]);
    run('git', <String>['--no-pager', 'log', '--decorate=short', '--pretty=oneline']);
    expect(
      (run('git', <String>['rev-parse', '--abbrev-ref', 'HEAD']).stdout as String).trim(),
      equals('HEAD'),
    );

    // Simulate being in a LUCI environment.
    environment['LUCI_CONTEXT'] = 'true';
    expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
  });

  test('generates a hash based on merge-base in local detached HEAD', () {
    // This test validates the workflow with a detached HEAD, which is common
    // when working with jj.
    initGitRepoWithBlankInitialCommit(branch: 'main');
    writeFileAndCommit(testRoot.deps, 'deps changed');

    final String headSha = gitShaFor('HEAD');
    run('git', <String>['checkout', '-f', headSha]);
    run('git', <String>['--no-pager', 'log', '--decorate=short', '--pretty=oneline']);
    expect(
      (run('git', <String>['rev-parse', '--abbrev-ref', 'HEAD']).stdout as String).trim(),
      equals('HEAD'),
    );

    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  group('stable branches calculate hash locally', () {
    test('with no changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('stable');
      expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
    });

    test('with engine changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('stable');
      writeFileAndCommit(testRoot.deps, 'deps changed');

      expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
    });
  });

  group('beta branches calculate hash locally', () {
    test('with no changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('beta');
      expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
    });

    test('with engine changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('beta');
      writeFileAndCommit(testRoot.deps, 'deps changed');

      expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
    });
  });

  group('release branches calculate hash locally', () {
    test('with no changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('flutter-4.35-candidate.2');
      expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
    });

    test('with engine changes', () {
      initGitRepoWithBlankInitialCommit(branch: 'main');
      gitSwitchBranch('flutter-4.35-candidate.2');
      writeFileAndCommit(testRoot.deps, 'deps changed');

      expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
    });
  });

  test('github special merge group branches calculate hash locally', () {
    initGitRepoWithBlankInitialCommit(
      remote: 'origin',
      branch: 'gh-readonly-queue/master/pr-1234-abcd',
    );
    writeFileAndCommit(testRoot.deps, 'deps changed');

    expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
  });

  test('generates a hash for shallow clones', () {
    initGitRepoWithBlankInitialCommit(remote: 'origin', branch: 'blip');
    final String headSha = gitShaFor('HEAD');
    testRoot.root
        .childFile(localFs.path.joinAll('.git/shallow'.split('/')))
        .writeAsStringSync(headSha);
    writeFileAndCommit(testRoot.deps, 'deps changed');
    expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
  });

  group('ignores local engine for', () {
    test('upstream', () {
      initGitRepoWithBlankInitialCommit();
      gitSwitchBranch('engineTest');
      testRoot.deps.writeAsStringSync('deps changed');
      expect(
        runContentAwareHash(),
        processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'),
        reason: 'content hash from master for non-committed file',
      );

      writeFileAndCommit(testRoot.deps, 'deps changed');
      expect(
        runContentAwareHash(),
        processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'),
        reason: 'content hash from master for committed file',
      );
    });

    test('origin', () {
      initGitRepoWithBlankInitialCommit(remote: 'origin');
      gitSwitchBranch('engineTest');
      testRoot.deps.writeAsStringSync('deps changed');
      expect(
        runContentAwareHash(),
        processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'),
        reason: 'content hash from master for non-committed file',
      );

      writeFileAndCommit(testRoot.deps, 'deps changed');
      expect(
        runContentAwareHash(),
        processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'),
        reason: 'content hash from master for committed file',
      );
    });
  });

  group('generates a different hash when', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
    });

    test('DEPS is changed', () async {
      writeFileAndCommit(testRoot.deps, 'deps changed');
      expect(runContentAwareHash(), processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'));
    });

    test('an engine file changes', () async {
      writeFileAndCommit(testRoot.engineReadMe, 'engine file changed');
      expect(runContentAwareHash(), processStdout('bc993ee46320d3831092bc2c3dd86881d5c15d5f'));
    });

    test('a new engine file is added', () async {
      final List<String> gibberish = ('_abcdefghijklmnopqrstuvqxyz0123456789' * 20).split('')
        ..shuffle();
      final String newFileName = gibberish.take(20).join();

      writeFileAndCommit(
        testRoot.engineReadMe.parent.childFile(newFileName),
        '$newFileName file added',
      );

      expect(
        runContentAwareHash(),
        isNot(processStdout('e9d1f7dc1718dac8e8189791a8073e38abdae1cf')),
      );
    });

    test('bin/internal/release-candidate-branch.version is present', () {
      writeFileAndCommit(
        testRoot.contentAwareHashPs1.parent.childFile('release-candidate-branch.version'),
        'sup',
      );
      expect(runContentAwareHash(), processStdout('ec994692b9e9610655484436cecd691cecee4c78'));
    });
  });

  test('does not hash non-engine files', () async {
    initGitRepoWithBlankInitialCommit();
    testRoot.flutterReadMe.writeAsStringSync('codefu was here');
    expect(runContentAwareHash(), processStdout('fa69812cddffc076be3aa477a93942cb8d233ccc'));
  });

  test('missing merge-base defaults to HEAD', () {
    initGitRepoWithBlankInitialCommit();

    run('git', <String>['branch', '-m', 'no-merge-base'], workingPath: testRoot.root.path);
    run('git', <String>['remote', 'remove', 'upstream'], workingPath: testRoot.root.path);

    writeFileAndCommit(testRoot.deps, 'deps changed');
    expect(
      runContentAwareHash(),
      processStdout('63a6c6dc494d9a2fc3e78e8505e878d129429246'),
      reason: 'content hash from HEAD when no merge-base',
    );
  });
}

/// A FrUT, or "Flutter Root"-Under Test (parallel to a SUT, System Under Test).
///
/// For the intent of this test case, the "Flutter Root" is a directory
/// structure with a minimal set of files.
final class _FlutterRootUnderTest {
  /// Creates a root-under test using [path] as the root directory.
  ///
  /// It is assumed the files already exist or will be created if needed.
  factory _FlutterRootUnderTest.fromPath(
    String path, {
    FileSystem fileSystem = const LocalFileSystem(),
  }) {
    final Directory root = fileSystem.directory(path);
    return _FlutterRootUnderTest._(
      root,
      contentAwareHashPs1: root.childFile(
        fileSystem.path.joinAll('bin/internal/content_aware_hash.ps1'.split('/')),
      ),
      contentAwareHashSh: root.childFile(
        fileSystem.path.joinAll('bin/internal/content_aware_hash.sh'.split('/')),
      ),
      engineReadMe: root.childFile(fileSystem.path.joinAll('engine/README.md'.split('/'))),
      deps: root.childFile(fileSystem.path.join('DEPS')),
      flutterReadMe: root.childFile(
        fileSystem.path.joinAll('packages/flutter/README.md'.split('/')),
      ),
    );
  }

  factory _FlutterRootUnderTest.findWithin({
    String? path,
    FileSystem fileSystem = const LocalFileSystem(),
  }) {
    path ??= fileSystem.currentDirectory.path;
    Directory current = fileSystem.directory(path);
    while (!current.childFile('DEPS').existsSync()) {
      if (current.path == current.parent.path) {
        throw ArgumentError.value(path, 'path', 'Could not resolve flutter root');
      }
      current = current.parent;
    }
    return _FlutterRootUnderTest.fromPath(current.path);
  }

  const _FlutterRootUnderTest._(
    this.root, {
    required this.deps,
    required this.contentAwareHashPs1,
    required this.contentAwareHashSh,
    required this.engineReadMe,
    required this.flutterReadMe,
  });

  final Directory root;

  final File deps;
  final File contentAwareHashPs1;
  final File contentAwareHashSh;
  final File engineReadMe;
  final File flutterReadMe;

  /// Copies files under test to the [testRoot].
  void copyTo(_FlutterRootUnderTest testRoot) {
    contentAwareHashPs1.copySyncRecursive(testRoot.contentAwareHashPs1.path);
    contentAwareHashSh.copySyncRecursive(testRoot.contentAwareHashSh.path);
  }
}

extension on File {
  void copySyncRecursive(String newPath) {
    fileSystem.directory(fileSystem.path.dirname(newPath)).createSync(recursive: true);
    copySync(newPath);
  }
}

/// Returns a matcher, that, given [stdout]:
///
/// 1. Process exists with code 0
/// 2. Stdout is a String
/// 3. Stdout contents, after applying [collapseWhitespace], is the same as
///    [stdout], after applying [collapseWhitespace].
Matcher processStdout(String stdout) {
  return _ProcessSucceedsAndOutputs(stdout);
}

final class _ProcessSucceedsAndOutputs extends Matcher {
  _ProcessSucceedsAndOutputs(String stdout) : _expected = collapseWhitespace(stdout);

  final String _expected;

  @override
  bool matches(Object? item, _) {
    if (item is! io.ProcessResult || item.exitCode != 0 || item.stdout is! String) {
      return false;
    }
    final String actual = item.stdout as String;
    return collapseWhitespace(actual) == collapseWhitespace(_expected);
  }

  @override
  Description describe(Description description) {
    return description.add(
      'The process exists normally and stdout (ignoring whitespace): $_expected',
    );
  }

  @override
  Description describeMismatch(Object? item, Description mismatch, _, _) {
    if (item is! io.ProcessResult) {
      return mismatch.add('is not a process result (${item.runtimeType})');
    }
    if (item.exitCode != 0) {
      return mismatch.add('exit code is not zero (${item.exitCode})');
    }
    if (item.stdout is! String) {
      return mismatch.add('stdout is not String (${item.stdout.runtimeType})');
    }
    return mismatch
        .add('is ')
        .addDescriptionOf(collapseWhitespace(item.stdout as String))
        .add(' with whitespace compressed');
  }
}
