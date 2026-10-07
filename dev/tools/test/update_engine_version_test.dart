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
  // Then, set FORCE_POWERSHELL=true in the environment:
  final usePowershellOnPosix = io.Platform.environment['FORCE_POWERSHELL'] == 'true';

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
      const powerShellVariables = <String>[
        'SystemRoot',
        'PATH',
        'Path',
        'PATHEXT',
        'TEMP',
        'TMP',
        'USERPROFILE',
      ];
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

    // Copy the update_dart_sdk script and create a rough directory structure.
    flutterRoot.binInternalUpdateDartSdk.copySyncRecursive(testRoot.binInternalUpdateDartSdk.path);

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
      localFs.path.join('bin', 'cache', 'engine_fallback.stamp'),
      localFs.path.join('bin', 'cache', 'engine-dart-sdk.stamp'),
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
      localFs.path.join(
        'bin',
        'internal',
        localFs.path.basename(testRoot.binInternalUpdateDartSdk.path),
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
      args = <String>[
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        testRoot.binInternalUpdateEngineVersion.path,
      ];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalUpdateEngineVersion.path];
    } else {
      executable = testRoot.binInternalUpdateEngineVersion.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  /// Runs `bin/internal/update_dart_sdk.{sh|ps1}` and returns the process result
  /// without failing on non-zero exit codes so tests can assert failure cases.
  Future<io.ProcessResult> runUpdateDartSdk() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        testRoot.binInternalUpdateDartSdk.path,
      ];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalUpdateDartSdk.path];
    } else {
      executable = testRoot.binInternalUpdateDartSdk.path;
      args = <String>[];
    }
    final env = <String, String>{
      for (final String key in const <String>[
        'PATH',
        'Path',
        'SystemRoot',
        'PATHEXT',
        'TEMP',
        'TMP',
        'USERPROFILE',
      ])
        if (io.Platform.environment[key] != null) key: io.Platform.environment[key]!,
      ...environment,
    };
    return io.Process.run(
      executable,
      args,
      environment: env,
      workingDirectory: testRoot.root.absolute.path,
      includeParentEnvironment: false,
    );
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
  String gitContentHash({required _FlutterRootUnderTest fileSystem, String? ref}) {
    final String executable;
    final List<String> args;
    final String script = fileSystem.binInternalContentAwareHash.path;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[script, ?ref];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[script, ?ref];
    } else {
      executable = script;
      args = <String>[?ref];
    }
    final io.ProcessResult mergeBaseHeadOrigin = run(executable, args);
    return (mergeBaseHeadOrigin.stdout as String).trim();
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

  group('resolves engine artifacts with content_aware_hash', () {
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

  group('engine_fallback.stamp and strict mode', () {
    late String baseContentHash;
    late String headContentHash;

    setUp(() {
      initGitRepoWithBlankInitialCommit();
      setupRemote(remote: 'upstream');
      baseContentHash = gitContentHash(fileSystem: testRoot);

      // Make a local engine change on a feature branch.
      run('git', <String>['switch', '-c', 'feature']);
      testRoot.root.childFile('DEPS')
        ..createSync(recursive: true)
        ..writeAsStringSync('deps changed');
      run('git', <String>['add', 'DEPS']);
      run('git', <String>['commit', '-m', 'local engine change']);
      headContentHash = gitContentHash(fileSystem: testRoot);
      expect(headContentHash, isNot(equals(baseContentHash)));
    });

    test('reuses fallback hash from engine_fallback.stamp when target hash matches HEAD', () {
      testRoot.binCacheEngineFallbackStamp
        ..createSync(recursive: true)
        ..writeAsStringSync('$headContentHash:$baseContentHash\n');

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(baseContentHash));
      expect(
        testRoot.binCacheEngineFallbackStamp,
        _hasFileContentsMatching('$headContentHash:$baseContentHash'),
      );
    });

    test('invalidates engine_fallback.stamp when HEAD content hash changes', () {
      testRoot.binCacheEngineFallbackStamp
        ..createSync(recursive: true)
        ..writeAsStringSync('stale_target_hash:$baseContentHash\n');

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));
      expect(testRoot.binCacheEngineFallbackStamp.existsSync(), isFalse);
    });

    test('ignores and removes engine_fallback.stamp when FLUTTER_STRICT_ENGINE_VERSION=true', () {
      testRoot.binCacheEngineFallbackStamp
        ..createSync(recursive: true)
        ..writeAsStringSync('$headContentHash:$baseContentHash\n');
      environment['FLUTTER_STRICT_ENGINE_VERSION'] = 'true';

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));
      expect(testRoot.binCacheEngineFallbackStamp.existsSync(), isFalse);
    });

    test('defaults to strict mode when LUCI_CONTEXT is set unless overridden', () {
      testRoot.binCacheEngineFallbackStamp
        ..createSync(recursive: true)
        ..writeAsStringSync('$headContentHash:$baseContentHash\n');
      environment['LUCI_CONTEXT'] = '/path/to/luci_context.json';

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));
      expect(testRoot.binCacheEngineFallbackStamp.existsSync(), isFalse);

      // Explicit FLUTTER_STRICT_ENGINE_VERSION=false overrides LUCI_CONTEXT.
      testRoot.binCacheEngineFallbackStamp
        ..createSync(recursive: true)
        ..writeAsStringSync('$headContentHash:$baseContentHash\n');
      environment['FLUTTER_STRICT_ENGINE_VERSION'] = 'false';

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(baseContentHash));
      expect(
        testRoot.binCacheEngineFallbackStamp,
        _hasFileContentsMatching('$headContentHash:$baseContentHash'),
      );
    });

    test(
      'update_dart_sdk falls back to merge-base and writes engine_fallback.stamp on 404',
      () async {
        final io.HttpServer server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final requestedPaths = <String>[];
        server.listen((io.HttpRequest request) {
          requestedPaths.add(request.uri.path);
          request.response.statusCode = io.HttpStatus.notFound;
          request.response.close();
        });

        environment['FLUTTER_STORAGE_BASE_URL'] = 'http://127.0.0.1:${server.port}';
        runUpdateEngineVersion();
        expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));

        // Simulate that the merge-base Dart SDK is already installed in bin/cache/dart-sdk.
        testRoot.binCacheEngineDartSdkStamp.writeAsStringSync('$baseContentHash\n');
        final Directory dartSdkDir =
            testRoot.root.childDirectory('bin').childDirectory('cache').childDirectory('dart-sdk')
              ..createSync(recursive: true);
        addTearDown(() {
          if (dartSdkDir.existsSync()) {
            dartSdkDir.deleteSync(recursive: true);
          }
        });

        final io.ProcessResult result = await runUpdateDartSdk();
        expect(result.exitCode, 0, reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}');
        expect(
          result.stderr as String,
          contains('WARNING: Engine artifacts for $headContentHash are not available.'),
        );
        expect(
          result.stderr as String,
          contains('Falling back to engine artifacts from merge-base ($baseContentHash).'),
        );
        expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(baseContentHash));
        expect(
          testRoot.binCacheEngineFallbackStamp,
          _hasFileContentsMatching('$headContentHash:$baseContentHash'),
        );
        expect(requestedPaths, isNotEmpty);
        expect(requestedPaths.first, contains(headContentHash));
      },
    );

    test('update_dart_sdk requests merge-base URL on 404 when dart-sdk is not cached', () async {
      final io.HttpServer server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final requestedPaths = <String>[];
      server.listen((io.HttpRequest request) {
        requestedPaths.add(request.uri.path);
        request.response.statusCode = io.HttpStatus.notFound;
        request.response.close();
      });

      environment['FLUTTER_STORAGE_BASE_URL'] = 'http://127.0.0.1:${server.port}';
      runUpdateEngineVersion();
      expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));

      final io.ProcessResult result = await runUpdateDartSdk();
      expect(result.exitCode, isNot(0));
      expect(
        result.stderr as String,
        contains('Falling back to engine artifacts from merge-base ($baseContentHash).'),
      );
      expect(
        requestedPaths,
        containsAllInOrder(<Matcher>[contains(headContentHash), contains(baseContentHash)]),
      );
    });

    test(
      'update_dart_sdk fails without falling back when FLUTTER_STRICT_ENGINE_VERSION=true',
      () async {
        final io.HttpServer server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        server.listen((io.HttpRequest request) {
          request.response.statusCode = io.HttpStatus.notFound;
          request.response.close();
        });

        environment['FLUTTER_STORAGE_BASE_URL'] = 'http://127.0.0.1:${server.port}';
        environment['FLUTTER_STRICT_ENGINE_VERSION'] = 'true';
        runUpdateEngineVersion();
        expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));

        final io.ProcessResult result = await runUpdateDartSdk();
        expect(result.exitCode, isNot(0));
        expect(
          result.stderr as String,
          isNot(contains('Falling back to engine artifacts from merge-base')),
        );
        expect(testRoot.binCacheEngineFallbackStamp.existsSync(), isFalse);
        expect(testRoot.binCacheEngineStamp, _hasFileContentsMatching(headContentHash));
      },
    );
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

  group('concurrent execution', () {
    setUp(() {
      initGitRepoWithBlankInitialCommit();
      environment['FLUTTER_PREBUILT_ENGINE_VERSION'] = '123abc';
    });

    test(
      'writes to engine.stamp atomically without truncation',
      () async {
        // Run the script once first to ensure the file exists.
        runUpdateEngineVersion();

        final File stampFile = testRoot.binCacheEngineStamp;
        expect(stampFile.readAsStringSync().trim(), '123abc');

        var isRunning = true;
        var emptyReads = 0;
        var totalReads = 0;

        // Start a tight read loop
        final readFuture = Future<void>(() async {
          while (isRunning) {
            try {
              final String content = stampFile.readAsStringSync();
              totalReads++;
              if (content.trim().isEmpty) {
                emptyReads++;
              }
            } on io.FileSystemException {
              // Ignore FileSystemExceptions (e.g., Windows sharing violations).
              // A true atomic replacement might still cause a sharing violation on Windows
              // if Dart is reading the file at the exact moment it's being replaced.
              // What we strictly care about for this race condition is that a SUCCESSFUL
              // read NEVER returns an empty string (which indicates non-atomic truncation).
            }
            await Future<void>.delayed(Duration.zero);
          }
        });

        // Spawn multiple writers in parallel
        const numWriters = 20;
        final writers = <Future<io.ProcessResult>>[];

        for (var i = 0; i < numWriters; i++) {
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

          writers.add(
            io.Process.run(
              executable,
              args,
              environment: environment,
              workingDirectory: testRoot.root.absolute.path,
              includeParentEnvironment: false,
            ),
          );
        }

        final List<io.ProcessResult> results = await Future.wait<io.ProcessResult>(writers);

        // Stop the reader
        isRunning = false;
        await readFuture;

        for (final result in results) {
          expect(
            result.exitCode,
            0,
            reason:
                'Writer process failed with exit code ${result.exitCode}:\n'
                'STDOUT:\n${result.stdout}\n'
                'STDERR:\n${result.stderr}',
          );
        }

        // Assert that we never read an empty file during concurrent writes
        expect(
          emptyReads,
          0,
          reason:
              'Race condition detected: engine.stamp was empty $emptyReads times out of $totalReads reads',
        );
      },
      // [intended] Windows-specific file locking limitation
      skip: const LocalPlatform().isWindows
          ? 'Windows file locking makes concurrent file operations unreliable'
          : null,
    );
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
      binCacheEngineFallbackStamp: root.childFile(
        fileSystem.path.join('bin', 'cache', 'engine_fallback.stamp'),
      ),
      binCacheEngineDartSdkStamp: root.childFile(
        fileSystem.path.join('bin', 'cache', 'engine-dart-sdk.stamp'),
      ),
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
      binInternalUpdateDartSdk: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'update_dart_sdk.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
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
    required this.binCacheEngineFallbackStamp,
    required this.binCacheEngineDartSdkStamp,
    required this.binInternalEngineVersion,
    required this.binCacheEngineRealm,
    required this.binInternalUpdateEngineVersion,
    required this.binInternalContentAwareHash,
    required this.binInternalUpdateDartSdk,
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

  /// `bin/cache/engine_fallback.stamp`.
  ///
  /// When the primary engine artifacts for `HEAD` are unavailable and
  /// `update_dart_sdk` falls back to the `merge-base` content hash, this file
  /// stores `<target_content_hash>:<fallback_content_hash>`.
  final File binCacheEngineFallbackStamp;

  /// `bin/cache/engine-dart-sdk.stamp`.
  final File binCacheEngineDartSdkStamp;

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
  /// - [binCacheEngineStamp]
  /// - [binCacheEngineRealm]
  final File binInternalUpdateEngineVersion;

  /// `bin/internal/content_aware_hash.{sh|ps1}`.
  ///
  /// This file contains a shell script that computes the content hash
  final File binInternalContentAwareHash;

  /// `bin/internal/update_dart_sdk.{sh|ps1}`.
  final File binInternalUpdateDartSdk;
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
