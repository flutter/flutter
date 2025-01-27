// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_testing/file_testing.dart';
import 'package:platform/platform.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

void main() {
  const FileSystem localFs = LocalFileSystem();
  final _FlutterRootUnderTest flutterRoot = _FlutterRootUnderTest.findWithin();

  late Directory tmpDir;
  late _FlutterRootUnderTest testRoot;
  late Map<String, String> environment;
  late ProcessRunner processRunner;

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('update_engine_version_test.');
    testRoot = _FlutterRootUnderTest.fromPath(tmpDir.childDirectory('flutter').path);

    environment = <String, String>{};
    processRunner = ProcessRunner(
      defaultWorkingDirectory: testRoot.root,
      environment: environment,
      printOutputDefault: true,
    );

    // Copy the update_engine_version script and create a rough directory structure.
    flutterRoot.binInternalUpdateEngineVersion.copySyncRecursive(
      testRoot.binInternalUpdateEngineVersion.path,
    );

    // On some systems, copying the file means losing the executable bit.
    if (const LocalPlatform().isWindows) {
      await processRunner.runProcess(<String>[
        'attrib',
        '+x',
        testRoot.binInternalUpdateEngineVersion.path,
      ]);
    }
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  Future<void> runUpdateEngineVersion() async {
    if (const LocalPlatform().isWindows) {
      await processRunner.runProcess(<String>[
        'powershell',
        testRoot.binInternalUpdateEngineVersion.path,
      ]);
    } else {
      await processRunner.runProcess(<String>[testRoot.binInternalUpdateEngineVersion.path]);
    }
  }

  group('if FLUTTER_PREBUILT_ENGINE_VERSION is set', () {
    setUp(() {
      environment['FLUTTER_PREBUILT_ENGINE_VERSION'] = '123abc';
    });

    test('writes it to engine.version with no git interaction', () async {
      await runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace('123abc'),
      );
    });
  });

  Future<void> setupRepo({required String branch}) async {
    for (final File f in <File>[testRoot.deps, testRoot.engineSrcGn]) {
      f.createSync(recursive: true);
    }

    await processRunner.runProcess(<String>['git', 'init', '--initial-branch', 'master']);
    await processRunner.runProcess(<String>['git', 'add', '.']);
    await processRunner.runProcess(<String>['git', 'commit', '-m', 'Initial commit']);
    if (branch != 'master') {
      await processRunner.runProcess(<String>['git', 'checkout', '-b', branch]);
    }
  }

  Future<void> setupRemote({required String remote}) async {
    await processRunner.runProcess(<String>['git', 'remote', 'add', remote, testRoot.root.path]);
    await processRunner.runProcess(<String>['git', 'fetch', remote]);
  }

  test('writes nothing, even if files are set, if we are on "stable"', () async {
    await setupRepo(branch: 'stable');
    await setupRemote(remote: 'upstream');

    await runUpdateEngineVersion();

    expect(testRoot.binInternalEngineVersion, isNot(exists));
  });

  test('writes nothing, even if files are set, if we are on "beta"', () async {
    await setupRepo(branch: 'beta');
    await setupRemote(remote: 'upstream');

    await runUpdateEngineVersion();

    expect(testRoot.binInternalEngineVersion, isNot(exists));
  });

  group('if DEPS and engine/src/.gn are present, engine.version is derived from', () {
    setUp(() async {
      await setupRepo(branch: 'master');
    });

    test('merge-base HEAD upstream/master on non-LUCI when upstream is set', () async {
      await setupRemote(remote: 'upstream');

      final ProcessRunnerResult mergeBaseHeadUpstream = await processRunner.runProcess(<String>[
        'git',
        'merge-base',
        'HEAD',
        'upstream/master',
      ]);
      await runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadUpstream.stdout),
      );
    });

    test('merge-base HEAD origin/master on non-LUCI when upstream is not set', () async {
      await setupRemote(remote: 'origin');

      final ProcessRunnerResult mergeBaseHeadOrigin = await processRunner.runProcess(<String>[
        'git',
        'merge-base',
        'HEAD',
        'origin/master',
      ]);
      await runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(mergeBaseHeadOrigin.stdout),
      );
    });

    test('rev-parse HEAD when running on LUCI', () async {
      environment['LUCI_CONTEXT'] = '_NON_NULL_AND_NON_EMPTY_STRING';
      await runUpdateEngineVersion();

      final ProcessRunnerResult revParseHead = await processRunner.runProcess(<String>[
        'git',
        'rev-parse',
        'HEAD',
      ]);
      expect(testRoot.binInternalEngineVersion, exists);
      expect(
        testRoot.binInternalEngineVersion.readAsStringSync(),
        equalsIgnoringWhitespace(revParseHead.stdout),
      );
    });
  });

  group('if DEPS or engine/src/.gn are omitted', () {
    setUp(() {
      for (final File f in <File>[testRoot.deps, testRoot.engineSrcGn]) {
        f.createSync(recursive: true);
      }
    });

    test('[DEPS] engine.version is blank', () async {
      testRoot.deps.deleteSync();

      await runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(testRoot.binInternalEngineVersion.readAsStringSync(), equalsIgnoringWhitespace(''));
    });

    test('[engine/src/.gn] engine.version is blank', () async {
      testRoot.engineSrcGn.deleteSync();

      await runUpdateEngineVersion();

      expect(testRoot.binInternalEngineVersion, exists);
      expect(testRoot.binInternalEngineVersion.readAsStringSync(), equalsIgnoringWhitespace(''));
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
  }) {
    final Directory root = fileSystem.directory(path);
    return _FlutterRootUnderTest._(
      root,
      deps: root.childFile('DEPS'),
      engineSrcGn: root.childFile(fileSystem.path.join('engine', 'src', '.gn')),
      binInternalEngineVersion: root.childFile(
        fileSystem.path.join('bin', 'internal', 'engine.version'),
      ),
      binInternalEngineRealm: root.childFile(
        fileSystem.path.join('bin', 'internal', 'engine.realm'),
      ),
      binInternalUpdateEngineVersion: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'update_engine_version.${platform.isWindows ? 'ps1' : 'sh'}',
        ),
      ),
    );
  }

  factory _FlutterRootUnderTest.findWithin([
    String? path,
    FileSystem fileSystem = const LocalFileSystem(),
  ]) {
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
    required this.engineSrcGn,
    required this.binInternalEngineVersion,
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
  final File binInternalEngineVersion;

  /// `bin/internal/engine.realm`.
  ///
  /// It is a mystery what this file contains, but it's set by `FLUTTER_REALM`.
  final File binInternalEngineRealm;

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
