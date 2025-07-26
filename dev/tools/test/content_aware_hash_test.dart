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

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('content_aware_hash.');
    testRoot = _FlutterRootUnderTest.fromPath(tmpDir.childDirectory('flutter').path);

    environment = <String, String>{};

    if (const LocalPlatform().isWindows) {
      // Copy a minimal set of environment variables needed to run the update_engine_version script in PowerShell.
      const List<String> powerShellVariables = <String>['SystemRoot', 'Path', 'PATHEXT'];
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
      args = <String>[testRoot.contentAwareHashPs1.path];
    } else {
      executable = testRoot.contentAwareHashSh.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  /// Initializes a blank git repo in [testRoot.root].
  void initGitRepoWithBlankInitialCommit({String? workingPath}) {
    run('git', <String>['init', '--initial-branch', 'master'], workingPath: workingPath);
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
  }

  void writeFileAndCommit(File file, String contents) {
    file.writeAsStringSync(contents);
    run('git', <String>['add', '--all']);
    run('git', <String>['commit', '--all', '-m', 'changed ${file.basename} to $contents']);
  }

  test('generates a hash', () async {
    initGitRepoWithBlankInitialCommit();
    expect(runContentAwareHash(), processStdout('3bbeb6a394378478683ece4f8e8663c42f8dc814'));
  });

  group('generates a different hash when', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
    });

    test('DEPS is changed', () async {
      writeFileAndCommit(testRoot.deps, 'deps changed');
      expect(runContentAwareHash(), processStdout('f049fdcd4300c8c0d5041b5e35b3d11c2d289bdf'));
    });

    test('an engine file changes', () async {
      writeFileAndCommit(testRoot.engineReadMe, 'engine file changed');
      expect(runContentAwareHash(), processStdout('49e58f425cb039e745614d7ea10c369387c43681'));
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
      expect(runContentAwareHash(), processStdout('3b81cd2164f26a8db3271d46c7022c159193417d'));
    });
  });

  test('does not hash non-engine files', () async {
    initGitRepoWithBlankInitialCommit();
    testRoot.flutterReadMe.writeAsStringSync('codefu was here');
    expect(runContentAwareHash(), processStdout('3bbeb6a394378478683ece4f8e8663c42f8dc814'));
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
