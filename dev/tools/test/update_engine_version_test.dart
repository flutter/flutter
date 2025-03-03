// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_testing/file_testing.dart';
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
  const bool usePowershellOnPosix = false;

  const FileSystem localFs = LocalFileSystem();
  final _FlutterRootUnderTest flutterRoot = _FlutterRootUnderTest.findWithin(
    // ignore: avoid_redundant_argument_values
    forcePowershell: usePowershellOnPosix,
  );

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
    print('Running "$executable ${args.join(" ")}"');
    final io.ProcessResult result = io.Process.runSync(
      executable,
      args,
      environment: environment,
      workingDirectory: testRoot.root.absolute.path,
      includeParentEnvironment: false,
    );
    if (result.exitCode != 0) {
      print('exitCode: ${result.exitCode}');
    }
    printIfNotEmpty('stdout', (result.stdout as String).trim());
    printIfNotEmpty('stderr', (result.stderr as String).trim());
    return result;
  }

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('update_engine_version_test.');
    testRoot = _FlutterRootUnderTest.fromPath(
      tmpDir.childDirectory('flutter').path,
      // ignore: avoid_redundant_argument_values
      forcePowershell: usePowershellOnPosix,
    );

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

    // Copy the update_engine_version script and create a rough directory structure.
    flutterRoot.binInternalUpdateEngineVersion.copySyncRecursive(
      testRoot.binInternalUpdateEngineVersion.path,
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
    final Set<String> expectedFiles = <String>{
      localFs.path.join('bin', 'cache', 'engine.realm'),
      localFs.path.join('bin', 'cache', 'engine.stamp'),
      localFs.path.join(
        'bin',
        'internal',
        localFs.path.basename(testRoot.binInternalUpdateEngineVersion.path),
      ),
      localFs.path.join('bin', 'internal', 'engine.realm'),
      localFs.path.join('bin', 'internal', 'engine.version'),
      localFs.path.join('engine', 'src', '.gn'),
      'DEPS',
    };
    final Set<String> currentFiles =
        tmpDir
            .listSync(recursive: true)
            .whereType<File>()
            .map((File e) => localFs.path.relative(e.path, from: testRoot.root.path))
            .toSet();

    // If this test failed, print out the current directory structure.
    printOnFailure(
      'Files in virtual "flutter" directory when test failed:\n\n${(currentFiles.toList()..sort()).join('\n')}',
    );

    // Now do cleanup so even if the next step fails, we still deleted tmp.
    print(tmpDir);
    // tmpDir.deleteSync(recursive: true);

    final Set<String> unexpectedFiles = currentFiles.difference(expectedFiles);
    if (unexpectedFiles.isNotEmpty) {
      final StringBuffer message = StringBuffer(
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

  io.ProcessResult runUpdateEngineVersion() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[testRoot.binInternalUpdateEngineVersion.path];
      // ignore: dead_code
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalUpdateEngineVersion.path];
      // ignore: dead_code
    } else {
      executable = testRoot.binInternalUpdateEngineVersion.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  void setupRepo({required String branch}) {
    for (final File f in <File>[testRoot.deps, testRoot.engineSrcGn]) {
      f.createSync(recursive: true);
    }

    run('git', <String>['init', '--initial-branch', 'master']);
    run('git', <String>['config', '--local', 'user.email', 'test@example.com']);
    run('git', <String>['config', '--local', 'user.name', 'Test User']);
    run('git', <String>['add', '.']);
    run('git', <String>['commit', '-m', 'Initial commit']);
    if (branch != 'master') {
      run('git', <String>['checkout', '-b', branch]);
    }
  }

  const String engineVersionTrackedContents = 'already existing contents';
  void setupTrackedEngineVersion() {
    testRoot.binInternalEngineVersion.writeAsStringSync(engineVersionTrackedContents);
    run('git', <String>['add', '-f', 'bin/internal/engine.version']);
    run('git', <String>['commit', '-m', 'tracking engine.version']);
  }

  void setupRemote({required String remote}) {
    run('git', <String>['remote', 'add', remote, testRoot.root.path]);
    run('git', <String>['fetch', remote]);
  }

  group('if FLUTTER_PREBUILT_ENGINE_VERSION is set', () {
    setUp(() {
      environment['FLUTTER_PREBUILT_ENGINE_VERSION'] = '123abc';
      setupRepo(branch: 'master');
    });

    test('writes it to engine.version with no git interaction', () async {
      runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace('123abc'),
      );
      expect(testRoot.binCacheEngineStamp.readAsStringSync(), equalsIgnoringWhitespace('123abc'));
    });
  });

  test('writes nothing, even if files are set, if we are on "stable"', () async {
    setupRepo(branch: 'stable');
    setupTrackedEngineVersion();
    setupRemote(remote: 'upstream');

    runUpdateEngineVersion();

    expect(testRoot.binInternalEngineVersion, exists);
    expect(
      testRoot.binInternalEngineVersion.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
    expect(
      testRoot.binCacheEngineStamp.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
  });

  test('writes nothing, even if files are set, if we are on "3.29.0"', () async {
    setupRepo(branch: '3.29.0');
    setupTrackedEngineVersion();
    setupRemote(remote: 'upstream');

    runUpdateEngineVersion();

    expect(testRoot.binInternalEngineVersion, exists);
    expect(
      testRoot.binInternalEngineVersion.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
    expect(
      testRoot.binCacheEngineStamp.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
  });

  test('writes nothing, even if files are set, if we are on "beta"', () async {
    setupRepo(branch: 'beta');
    setupTrackedEngineVersion();
    setupRemote(remote: 'upstream');

    runUpdateEngineVersion();

    expect(testRoot.binInternalEngineVersion, exists);
    expect(
      testRoot.binInternalEngineVersion.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
    expect(
      testRoot.binCacheEngineStamp.readAsStringSync(),
      equalsIgnoringWhitespace(engineVersionTrackedContents),
    );
  });

  group('if DEPS and engine/src/.gn are present, engine.version is derived from', () {
    setUp(() async {
      setupRepo(branch: 'master');
    });

    test('merge-base HEAD upstream/master on non-LUCI when upstream is set', () async {
      setupRemote(remote: 'upstream');

      final io.ProcessResult mergeBaseHeadUpstream = run('git', <String>[
        'merge-base',
        'HEAD',
        'upstream/master',
      ]);
      runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadUpstream.stdout as String),
      );
      expect(
        testRoot.binCacheEngineStamp.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadUpstream.stdout as String),
      );
    });

    test('merge-base HEAD origin/master on non-LUCI when upstream is not set', () async {
      setupRemote(remote: 'origin');

      final io.ProcessResult mergeBaseHeadOrigin = run('git', <String>[
        'merge-base',
        'HEAD',
        'origin/master',
      ]);
      runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadOrigin.stdout as String),
      );
      expect(
        testRoot.binCacheEngineStamp.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadOrigin.stdout as String),
      );
    });

    test('rev-parse HEAD when running on LUCI', () async {
      environment['LUCI_CONTEXT'] = '_NON_NULL_AND_NON_EMPTY_STRING';
      runUpdateEngineVersion();

      final io.ProcessResult revParseHead = run('git', <String>['rev-parse', 'HEAD']);
      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(revParseHead.stdout as String),
      );
      expect(
        testRoot.binCacheEngineStamp.readAsStringSync(),
        equalsIgnoringWhitespace(revParseHead.stdout as String),
      );
    });
  });

  group('if DEPS or engine/src/.gn are omitted', () {
    setUp(() {
      for (final File f in <File>[testRoot.deps, testRoot.engineSrcGn]) {
        f.createSync(recursive: true);
      }
      setupRepo(branch: 'master');
      setupRemote(remote: 'origin');
    });

    test('[DEPS] engine.version is blank', () async {
      testRoot.deps.deleteSync();

      runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(testRoot.binInternalEngineVersion.readAsStringSync(), equalsIgnoringWhitespace(''));
      expect(testRoot.binCacheEngineStamp.readAsStringSync(), equalsIgnoringWhitespace(''));
    });

    test('[engine/src/.gn] engine.version is blank', () async {
      testRoot.engineSrcGn.deleteSync();

      runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(testRoot.binInternalEngineVersion.readAsStringSync(), equalsIgnoringWhitespace(''));
      expect(testRoot.binCacheEngineStamp.readAsStringSync(), equalsIgnoringWhitespace(''));
    });
  });

  group('engine.realm', () {
    setUp(() {
      for (final File f in <File>[testRoot.deps, testRoot.engineSrcGn]) {
        f.createSync(recursive: true);
      }
      setupRepo(branch: 'master');
      setupRemote(remote: 'origin');
    });

    test('is empty if the FLUTTER_REALM environment variable is not set', () {
      expect(environment, isNot(contains('FLUTTER_REALM')));

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineRealm, exists);
      expect(testRoot.binCacheEngineRealm.readAsStringSync(), equalsIgnoringWhitespace(''));
      expect(testRoot.binInternalEngineRealm, exists);
      expect(testRoot.binInternalEngineRealm.readAsStringSync(), equalsIgnoringWhitespace(''));
    });

    test('contains the FLUTTER_REALM environment variable', () async {
      environment['FLUTTER_REALM'] = 'flutter_archives_v2';

      runUpdateEngineVersion();

      expect(testRoot.binCacheEngineRealm, exists);
      expect(
        testRoot.binCacheEngineRealm.readAsStringSync(),
        equalsIgnoringWhitespace('flutter_archives_v2'),
      );
      expect(testRoot.binInternalEngineRealm, exists);
      expect(
        testRoot.binInternalEngineRealm.readAsStringSync(),
        equalsIgnoringWhitespace('flutter_archives_v2'),
      );
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
/// │   │   ├── engine.version
/// │   │   ├── engine.realm
/// │   │   └── update_engine_version.{sh|ps1}
/// │   └── engine
/// │       └── src
/// │           └── .gn
/// └── DEPS
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
      deps: root.childFile('DEPS'),
      engineSrcGn: root.childFile(fileSystem.path.join('engine', 'src', '.gn')),
      binInternalEngineVersion: root.childFile(
        fileSystem.path.join('bin', 'internal', 'engine.version'),
      ),
      binCacheEngineRealm: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.realm')),
      binInternalEngineRealm: root.childFile(
        fileSystem.path.join('bin', 'internal', 'engine.realm'),
      ),
      binCacheEngineStamp: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.stamp')),
      binInternalUpdateEngineVersion: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'update_engine_version.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
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
    required this.deps,
    required this.engineSrcGn,
    required this.binCacheEngineStamp,
    required this.binInternalEngineVersion,
    required this.binCacheEngineRealm,
    required this.binInternalEngineRealm,
    required this.binInternalUpdateEngineVersion,
  });

  final Directory root;

  /// `DEPS`.
  ///
  /// The presenence of this file is an indicator we are in a fused (mono) repo.
  final File deps;

  /// `engine/src/.gn`.
  ///
  /// The presenence of this file is an indicator we are in a fused (mono) repo.
  final File engineSrcGn;

  /// `bin/internal/engine.version`.
  ///
  /// This file contains a SHA of which engine binaries to download.
  ///
  /// Currently, the SHA is either _computed_ or _pre-determined_, based on if
  /// the file is checked-in and tracked. That behavior is changing, and in the
  /// future this will be a checked-in file and not computed.
  ///
  /// See also: https://github.com/flutter/flutter/issues/164315.
  final File binInternalEngineVersion; // TODO(matanlurey): Update these docs.

  /// `bin/cache/engine.stamp`.
  ///
  /// This file contains a _computed_ SHA of which engine binaries to download.
  final File binCacheEngineStamp;

  /// `bin/internal/engine.realm`.
  ///
  /// If non-empty, the value comes from the environment variable `FLUTTER_REALM`,
  /// which instructs the tool where the SHA stored in [binInternalEngineVersion]
  /// should be fetched from (it differs for presubmits run for flutter/flutter
  /// and builds downloaded by end-users or by postsubmits).
  final File binInternalEngineRealm;

  /// `bin/cache/engine.realm`.
  ///
  /// If non-empty, the value comes from the environment variable `FLUTTER_REALM`,
  /// which instructs the tool where the SHA stored in [binInternalEngineVersion]
  /// should be fetched from (it differs for presubmits run for flutter/flutter
  /// and builds downloaded by end-users or by postsubmits).
  final File binCacheEngineRealm;

  /// `bin/internal/update_engine_version.{sh|ps1}`.
  ///
  /// This file contains a shell script that conditionally writes, on execution:
  /// - [binInternalEngineVersion]
  /// - [binInternalEngineRealm]
  final File binInternalUpdateEngineVersion;
}

extension on File {
  void copySyncRecursive(String newPath) {
    fileSystem.directory(fileSystem.path.dirname(newPath)).createSync(recursive: true);
    copySync(newPath);
  }
}
