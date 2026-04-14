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
  // Want to test the powershell (update_engine_version.ps1) file, but running
  // a macOS or Linux machine? You can install powershell and then opt-in to
  // running `pwsh bin/internal/update_engine_version.ps1`.
  //
  // macOS: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos
  // linux: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
  //
  // Then, set this variable to true:
  final bool usePowershellOnPosix = () {
    // Intentionally not a const so that linting doesn't go wild across the test.
    return false;
  }();

  const FileSystem localFs = LocalFileSystem();
  final flutterRoot = _FlutterRootUnderTest.findWithin(forcePowershell: usePowershellOnPosix);

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

  io.ProcessResult run(String executable, List<String> args) {
    final io.ProcessResult result = io.Process.runSync(
      executable,
      args,
      environment: environment,
      workingDirectory: testRoot.root.absolute.path,
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
      print(
        'Using Powershell (${(result.stdout as String).trim()}) on POSIX for local debugging and testing',
      );
    }
  });

  /// Initializes a blank git repo in [testRoot.root].
  void initGitRepoWithBlankInitialCommit() {
    run('git', <String>['init', '--initial-branch', 'master']);
    run('git', <String>['config', '--local', 'user.email', 'test@example.com']);
    run('git', <String>['config', '--local', 'user.name', 'Test User']);
    run('git', <String>['add', '.']);
    run('git', <String>['commit', '--allow-empty', '-m', 'Initial commit']);
  }

  late int commitCount;

  setUp(() async {
    commitCount = 0;

    tmpDir = localFs.systemTempDirectory.createTempSync('last_engine_commit_test.');
    testRoot = _FlutterRootUnderTest.fromPath(
      tmpDir.childDirectory('flutter').path,
      forcePowershell: usePowershellOnPosix,
    );

    environment = <String, String>{};

    if (const LocalPlatform().isWindows || usePowershellOnPosix) {
      // Copy a minimal set of environment variables needed to run the update_engine_version script in PowerShell.
      const powerShellVariables = <String>['SYSTEMROOT', 'PATH', 'PATHEXT'];
      for (final key in powerShellVariables) {
        final String? value = io.Platform.environment[key];
        if (value != null) {
          environment[key] = value;
        }
      }
    }

    // Copy the update_engine_version script and create a rough directory structure.
    flutterRoot.binInternalLastEngineCommit.copySyncRecursive(
      testRoot.binInternalLastEngineCommit.path,
    );

    initGitRepoWithBlankInitialCommit();
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  /// Runs `bin/internal/last_engine_commit.{sh|ps1}` and returns the stdout.
  ///
  /// - On Windows, `powershell` is used (to run `last_engine_commit.ps1`);
  /// - On POSIX, if [usePowershellOnPosix] is set, `pwsh` is used (to run `last_engine_commit.ps1`);
  /// - Otherwise, `last_engine_commit.sh` is used.
  String getLastEngineCommit() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[testRoot.binInternalLastEngineCommit.path];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalLastEngineCommit.path];
    } else {
      executable = testRoot.binInternalLastEngineCommit.path;
      args = <String>[];
    }
    return (run(executable, args).stdout as String).trim();
  }

  /// Gets the latest commit on the current branch.
  String getLastCommit() {
    return (run('git', <String>['rev-parse', 'HEAD']).stdout as String).trim();
  }

  void writeCommit(Iterable<String> files) {
    commitCount++;
    for (final relativePath in files) {
      localFs.file(localFs.path.join(testRoot.root.path, relativePath))
        ..createSync(recursive: true)
        ..writeAsStringSync('$commitCount');
    }
    run('git', <String>['add', '.']);
    run('git', <String>['commit', '-m', 'Wrote ${files.length} files']);
  }

  test('returns the last engine commit', () {
    writeCommit(<String>['bin/internal/release-candidate-branch.version']);
    writeCommit(<String>['DEPS', 'engine/README.md']);

    final String lastEngine = getLastEngineCommit();
    expect(lastEngine, isNotEmpty);

    writeCommit(<String>['CHANGELOG.md', 'dev/folder/called/engine/README.md']);
    expect(getLastEngineCommit(), lastEngine);
  });

  test('considers DEPS an engine change', () {
    writeCommit(<String>['bin/internal/release-candidate-branch.version']);
    writeCommit(<String>['DEPS', 'engine/README.md']);

    final String lastEngineA = getLastEngineCommit();
    expect(lastEngineA, isNotEmpty);

    writeCommit(<String>['DEPS']);
    final String lastEngineB = getLastEngineCommit();
    expect(lastEngineB, allOf(isNotEmpty, isNot(equals(lastEngineA))));
  });

  test('if there have been no engine changes, uses the first commit since the branch point', () {
    final String initialStartingCommit = getLastCommit();

    // Make an engine change *before* the branch.
    writeCommit(<String>['engine/README.md']);
    final String engineCommitPreBranch = getLastCommit();

    // Write the branch file.
    writeCommit(<String>['bin/internal/release-candidate-branch.version']);
    final String initialBranchCommit = getLastCommit();

    // Write another commit to make sure we don't always use the latest.
    writeCommit(<String>['CHANGELOG.md']);
    final String latestCommitIgnore = getLastCommit();

    // Get the engine commit, which should fallback to HEAD~2 (in this case).
    final String lastCommitToEngine = getLastEngineCommit();
    expect(
      lastCommitToEngine,
      initialBranchCommit,
      reason:
          'The git history for this simulation looks like this:\n'
          'master                    | $initialStartingCommit\n'
          'master                    | $engineCommitPreBranch\n'
          'release                   | $initialBranchCommit\n'
          'release                   | $latestCommitIgnore\n'
          '\n'
          'We expected our script to select HEAD~2, $initialBranchCommit, but '
          'instead it selected $lastCommitToEngine, which is incorrect. See '
          'the table above to help debug.',
    );
  });
}

extension on File {
  void copySyncRecursive(String newPath) {
    fileSystem.directory(fileSystem.path.dirname(newPath)).createSync(recursive: true);
    copySync(newPath);
  }
}

/// A FrUT, or "Flutter Root"-Under Test (parallel to a SUT, System Under Test).
///
/// For the intent of this test case, the "Flutter Root" is a directory
/// structure with the following elements:
///
/// ```txt
/// ├── DEPS
/// ├── engine/
/// ├── bin/
/// │   ├── internal/
/// │   │   └── last_engine_commit.{sh|ps1}
/// ```
final class _FlutterRootUnderTest {
  /// Creates a root-under test using [path] as the root directory.
  ///
  /// It is assumed the files already exist or will be created if needed.
  factory _FlutterRootUnderTest.fromPath(
    String path, {
    FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
    bool forcePowershell = false,
  }) {
    final Directory root = fileSystem.directory(path);
    return _FlutterRootUnderTest._(
      root,
      depsFile: root.childFile('DEPS'),
      engineDirectory: root.childDirectory('engine'),
      binInternalLastEngineCommit: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'last_engine_commit.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
        ),
      ),
    );
  }

  factory _FlutterRootUnderTest.findWithin({
    String? path,
    FileSystem fileSystem = const LocalFileSystem(),
    bool forcePowershell = false,
  }) {
    path ??= fileSystem.currentDirectory.path;
    Directory current = fileSystem.directory(path);
    while (!current.childFile('DEPS').existsSync()) {
      if (current.path == current.parent.path) {
        throw ArgumentError.value(path, 'path', 'Could not resolve flutter root');
      }
      current = current.parent;
    }
    return _FlutterRootUnderTest.fromPath(current.path, forcePowershell: forcePowershell);
  }

  const _FlutterRootUnderTest._(
    this.root, {
    required this.binInternalLastEngineCommit,
    required this.depsFile,
    required this.engineDirectory,
  });

  final Directory root;

  /// `DEPS`.
  final File depsFile;

  /// The `engine/` directory.
  final Directory engineDirectory;

  /// `bin/internal/last_engine_commit.{sh|ps1}`.
  final File binInternalLastEngineCommit;
}
