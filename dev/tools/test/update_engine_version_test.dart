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
    tmpDir = localFs.systemTempDirectory.createTempSync('update_engine_version_test.');
    testRoot = _FlutterRootUnderTest.fromPath(
      tmpDir.childDirectory('flutter').path,
      forcePowershell: usePowershellOnPosix,
    );

    environment = <String, String>{};

    if (const LocalPlatform().isWindows || usePowershellOnPosix) {
      // Copy a minimal set of environment variables needed to run the update_engine_version script in PowerShell.
      const powerShellVariables = <String>['SystemRoot', 'Path', 'PATHEXT'];
      for (final key in powerShellVariables) {
        final String? value = io.Platform.environment[key];
        if (value != null) {
          environment[key] = value;
        }
      }
    }

    // Copy the update_engine_version script and create a rough directory structure.
    flutterRoot.binInternalUpdateEngineVersion.copySyncRecursive(
      testRoot.binInternalUpdateEngineVersion.path,
    );

    // Copy the content_aware_hash script and create a rough directory structure.
    flutterRoot.binInternalContentAwareHash.copySyncRecursive(
      testRoot.binInternalContentAwareHash.path,
    );

    // Regression test for https://github.com/flutter/flutter/pull/164396;
    // on a fresh checkout bin/cache does not exist, so avoid trying to create
    // this folder.
    if (testRoot.root.childDirectory('cache').existsSync()) {
      fail('Do not initially create a bin/cache directory, it should be created by the script.');
    }
  });

  tearDown(() {
    // Git adds a lot of files, we don't want to test for them.
    final Directory gitDir = testRoot.root.childDirectory('.git');
    if (gitDir.existsSync()) {
      gitDir.deleteSync(recursive: true);
    }

    // Take a snapshot of files we expect to be created or otherwise exist.
    //
    // This gives a "dirty" check that we did not change the output characteristics
    // of the tool without adding new tests for the new files.
    final expectedFiles = <String>{
      localFs.path.join('bin', 'cache', 'engine.realm'),
      localFs.path.join('bin', 'cache', 'engine.stamp'),
      localFs.path.join(
        'bin',
        'internal',
        localFs.path.basename(testRoot.binInternalUpdateEngineVersion.path),
      ),
      localFs.path.join(
        'bin',
        'internal',
        localFs.path.basename(testRoot.binInternalContentAwareHash.path),
      ),
      localFs.path.join('bin', 'internal', 'engine.version'),
      localFs.path.join('engine', 'src', '.gn'),
      'DEPS',
    };
    final Set<String> currentFiles = tmpDir
        .listSync(recursive: true)
        .whereType<File>()
        .map((File e) => localFs.path.relative(e.path, from: testRoot.root.path))
        .toSet();

    // If this test failed, print out the current directory structure.
    printOnFailure(
      'Files in virtual "flutter" directory when test failed:\n\n${(currentFiles.toList()..sort()).join('\n')}',
    );

    // Now do cleanup so even if the next step fails, we still deleted tmp.
    tmpDir.deleteSync(recursive: true);

    final Set<String> unexpectedFiles = currentFiles.difference(expectedFiles);
    if (unexpectedFiles.isNotEmpty) {
      final message = StringBuffer(
        '\nOne or more files were generated by ${localFs.path.basename(testRoot.binInternalUpdateEngineVersion.path)} that were not expected:\n\n',
      );
      message.writeAll(unexpectedFiles, '\n');
      message.writeln('\n');
      message.writeln(
        'If this was intentional update "expectedFiles" in dev/tools/test/update_engine_version_test.dart and add *new* tests for the new outputs.',
      );
      fail('$message');
    }
  });

  /// Runs `bin/internal/update_engine_version.{sh|ps1}` and returns the process result.
  ///
  /// If the exit code is 0, it is considered a success, and files should exist as a side-effect.
  ///
  /// - On Windows, `powershell` is used (to run `update_engine_version.ps1`);
  /// - On POSIX, if [usePowershellOnPosix] is set, `pwsh` is used (to run `update_engine_version.ps1`);
  /// - Otherwise, `update_engine_version.sh` is used.
  io.ProcessResult runUpdateEngineVersion() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[testRoot.binInternalUpdateEngineVersion.path];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalUpdateEngineVersion.path];
    } else {
      executable = testRoot.binInternalUpdateEngineVersion.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  /// Initializes a blank git repo in [testRoot.root].
  void initGitRepoWithBlankInitialCommit({String? workingPath}) {
    run('git', <String>['init', '--initial-branch', 'master'], workingPath: workingPath);
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
  }

  /// Creates a `bin/internal/engine.version` file in [testRoot].
  ///
  /// If [gitTrack] is `false`, the files are left untracked by git.
  void pinEngineVersionForReleaseBranch({required String engineHash, bool gitTrack = true}) {
    testRoot.binInternalEngineVersion.writeAsStringSync(engineHash);
    if (gitTrack) {
      run('git', <String>['add', '-f', 'bin/internal/engine.version']);
      run('git', <String>['commit', '-m', 'tracking engine.version']);
    }
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

  /// Returns the SHA computed by `content_aware_hash`.
  String gitContentHash({required _FlutterRootUnderTest fileSystem}) {
    final String executable;
    final List<String> args;
    final String script = fileSystem.binInternalContentAwareHash.path;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[script];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[script];
    } else {
      executable = script;
      args = <String>[];
    }
    final io.ProcessResult mergeBaseHeadOrigin = run(executable, args);
    return mergeBaseHeadOrigin.stdout as String;
  }

  group('GIT_DIR', () {
    late Directory externalGit;
    late String externalHead;
    setUp(() {
      externalGit = localFs.systemTempDirectory.createTempSync('GIT_DIR_test.');
      initGitRepoWithBlankInitialCommit(workingPath: externalGit.path);
      setupRemote(remote: 'upstream', rootPath: externalGit.path);

      externalHead =
          (run('git', <String>['rev-parse', 'HEAD'], workingPath: externalGit.path).stdout
                  as String)
              .trim();
    });

    test('un-sets environment variables', () {
      // Needs to happen before GIT_DIR is set
      initGitRepoWithBlankInitialCommit();
      setupRemote(remote: 'upstream');

      environment['GIT_DIR'] = '${externalGit.path}/.git';
      environment['GIT_INDEX_FILE'] = '${externalGit.path}/.git/index';
      environment['GIT_WORK_TREE'] = externalGit.path;

      runUpdateEngineVersion();

      final String engineStamp = testRoot.binCacheEngineStamp.readAsStringSync().trim();
      expect(engineStamp, isNot(equals(externalHead)));
    });

    tearDown(() {
      externalGit.deleteSync(recursive: true);
    });
  });

  group('if FLUTTER_PREBUILT_ENGINE_VERSION is set', () {
    setUp(() {
      environment['FLUTTER_PREBUILT_ENGINE_VERSION'] = '123abc';
      initGitRepoWithBlankInitialCommit();
    });

    test('writes it to cache/engine.stamp with no git interaction', () async {
      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching('123abc'));
    });

    test('takes precedence over bin/internal/engine.version, even if set', () async {
      pinEngineVersionForReleaseBranch(engineHash: '456def');
      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching('123abc'));
    });
  });

  group('if bin/internal/engine.version is set', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
    });

    test('and tracked it is used', () async {
      setupRemote(remote: 'upstream');
      pinEngineVersionForReleaseBranch(engineHash: 'abc123');
      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching('abc123'));
    });

    test('but not tracked, it is ignored', () async {
      setupRemote(remote: 'upstream');
      pinEngineVersionForReleaseBranch(engineHash: 'abc123', gitTrack: false);
      runUpdateEngineVersion();

      expect(
        testRoot.binCacheEngineStamp,
        _hasFileContentsMatching(gitContentHash(fileSystem: testRoot)),
      );
    });
  });

  group('resolves engine artifacts with git merge-base', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
    });

    test('default to upstream/master if available', () async {
      setupRemote(remote: 'upstream');
      runUpdateEngineVersion();

      expect(
        testRoot.binCacheEngineStamp,
        _hasFileContentsMatching(gitContentHash(fileSystem: testRoot)),
      );
    });

    test('fallsback to origin/master', () async {
      setupRemote(remote: 'origin');
      runUpdateEngineVersion();

      expect(
        testRoot.binCacheEngineStamp,
        _hasFileContentsMatching(gitContentHash(fileSystem: testRoot)),
      );
    });
  });

  group('engine.realm', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
      environment['FLUTTER_PREBUILT_ENGINE_VERSION'] = '123abc';
    });

    test('is empty by default', () async {
      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineRealm, _hasFileContentsMatching(''));
    });

    test('is the value in FLUTTER_REALM if set', () async {
      environment['FLUTTER_REALM'] = 'flutter_archives_v2';
      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineRealm, _hasFileContentsMatching('flutter_archives_v2'));
    });
  });
}

/// A FrUT, or "Flutter Root"-Under Test (parallel to a SUT, System Under Test).
///
/// For the intent of this test case, the "Flutter Root" is a directory
/// structure with the following elements:
///
/// ```txt
/// ├── bin
/// │   ├── internal
/// │   │   └── update_engine_version.{sh|ps1}
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
      binInternalEngineVersion: root.childFile(
        fileSystem.path.join('bin', 'internal', 'engine.version'),
      ),
      binCacheEngineRealm: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.realm')),
      binCacheEngineStamp: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.stamp')),
      binInternalUpdateEngineVersion: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'update_engine_version.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
        ),
      ),
      binInternalContentAwareHash: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'content_aware_hash.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
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
    required this.binCacheEngineStamp,
    required this.binInternalEngineVersion,
    required this.binCacheEngineRealm,
    required this.binInternalUpdateEngineVersion,
    required this.binInternalContentAwareHash,
  });

  final Directory root;

  /// `bin/internal/engine.version`.
  ///
  /// This file contains a pinned SHA of which engine binaries to download.
  ///
  /// If omitted, the file is ignored.
  final File binInternalEngineVersion;

  /// `bin/cache/engine.stamp`.
  ///
  /// This file contains a _computed_ SHA of which engine binaries to download.
  final File binCacheEngineStamp;

  /// `bin/cache/engine.realm`.
  ///
  /// If non-empty, the value comes from the environment variable `FLUTTER_REALM`,
  /// which instructs the tool where the SHA stored in [binCacheEngineStamp]
  /// should be fetched from (it differs for presubmits run for flutter/flutter
  /// and builds downloaded by end-users or by postsubmits).
  final File binCacheEngineRealm;

  /// `bin/internal/update_engine_version.{sh|ps1}`.
  ///
  /// This file contains a shell script that conditionally writes, on execution:
  /// - [binInternalEngineVersion]
  /// - [binInternalEngineRealm]
  final File binInternalUpdateEngineVersion;

  /// `bin/internal/content_aware_hash.{sh|ps1}`.
  ///
  /// This file contains a shell script that computes the content hash
  final File binInternalContentAwareHash;
}

extension on File {
  void copySyncRecursive(String newPath) {
    fileSystem.directory(fileSystem.path.dirname(newPath)).createSync(recursive: true);
    copySync(newPath);
  }
}

/// Returns a matcher, that, given [contents]:
///
/// 1. Asserts the 'actual' entity is a [File];
/// 2. Asserts that the file exists;
/// 3. Asserts that the file's contents, after applying [collapseWhitespace], is the same as
///    [contents], after applying [collapseWhitespace].
///
/// This replaces multiple other matchers, and still provides a high-quality error message
/// when it fails.
Matcher _hasFileContentsMatching(String contents) {
  return _ExistsWithStringContentsIgnoringWhitespace(contents);
}

final class _ExistsWithStringContentsIgnoringWhitespace extends Matcher {
  _ExistsWithStringContentsIgnoringWhitespace(String contents)
    : _expected = collapseWhitespace(contents);

  final String _expected;

  @override
  bool matches(Object? item, _) {
    if (item is! File || !item.existsSync()) {
      return false;
    }
    final String actual = item.readAsStringSync();
    return collapseWhitespace(actual) == collapseWhitespace(_expected);
  }

  @override
  Description describe(Description description) {
    return description.add('a file exists that matches (ignoring whitespace): $_expected');
  }

  @override
  Description describeMismatch(Object? item, Description mismatch, _, _) {
    if (item is! File) {
      return mismatch.add('is not a file (${item.runtimeType})');
    }
    if (!item.existsSync()) {
      return mismatch.add('does not exist');
    }
    return mismatch
        .add('is ')
        .addDescriptionOf(collapseWhitespace(item.readAsStringSync()))
        .add(' with whitespace compressed');
  }
}
