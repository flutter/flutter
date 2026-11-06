// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('posix')
library;

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../../src/common.dart';
import '../test_utils.dart';

const _appName = 'manifest_overwrite_app';
const _buildDirName = 'build';
const _dartToolDirName = '.dart_tool';
const _nativeAssetsDirName = 'native_assets';
const _nativeAssetsFileName = 'native_assets.json';
const _packageConfigFileName = 'package_config.json';
const _packageGraphFileName = 'package_graph.json';
const _pubspecFileName = 'pubspec.yaml';
const _readExecuteDirMode = '0555';
const _readWriteExecuteDirMode = '0755';
const _toolSnapshotFileName = 'flutter_tools.dill';

void main() {
  final String flutterRoot = getFlutterRoot();
  final Directory flutterToolsDir = fileSystem
      .directory(flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools');
  final Directory flutterToolsDartToolDir = flutterToolsDir.childDirectory(_dartToolDirName);
  final File flutterToolsPackageConfigFile = flutterToolsDartToolDir.childFile(
    _packageConfigFileName,
  );
  final File flutterToolsScript = flutterToolsDir
      .childDirectory('bin')
      .childFile('flutter_tools.dart');

  late Directory snapshotDir;
  late File toolSnapshotFile;

  setUpAll(() async {
    snapshotDir = createResolvedTempDirectorySync('flutter_tools_snapshot.');
    toolSnapshotFile = snapshotDir.childFile(_toolSnapshotFileName);
    final ProcessResult compileResult = await processManager.run(<String>[
      platform.resolvedExecutable,
      '--verbosity=error',
      '--snapshot=${toolSnapshotFile.path}',
      '--snapshot-kind=kernel',
      '--packages=${flutterToolsPackageConfigFile.path}',
      '--no-enable-mirrors',
      flutterToolsScript.path,
    ]);
    expect(compileResult, const ProcessResultMatcher());
  });

  tearDownAll(() {
    tryToDelete(snapshotDir);
  });

  testWithoutContext(
    'flutter test overwrites existing native_assets.json in place without unlinking it '
    '(regression test for https://github.com/flutter/flutter/issues/196121)',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync(
        'native_assets_manifest_overwrite.',
      );
      final Directory nativeAssetsDir = tempDir
          .childDirectory(_buildDirName)
          .childDirectory(_nativeAssetsDirName)
          .childDirectory(platform.operatingSystem);

      addTearDown(() async {
        if (nativeAssetsDir.existsSync()) {
          await processManager.run(<String>[
            'chmod',
            _readWriteExecuteDirMode,
            nativeAssetsDir.path,
          ]);
        }
        tryToDelete(tempDir);
      });

      _writeOfflineProject(
        projectDir: tempDir,
        flutterToolsDartToolDir: flutterToolsDartToolDir,
        flutterToolsPackageConfigFile: flutterToolsPackageConfigFile,
      );

      Future<ProcessResult> runFlutterTest() {
        return processManager.run(
          <String>[
            platform.resolvedExecutable,
            toolSnapshotFile.path,
            '--suppress-analytics',
            '--no-version-check',
            'test',
            '--no-pub',
          ],
          workingDirectory: tempDir.path,
          environment: <String, String>{
            ...platform.environment,
            'FLUTTER_ROOT': flutterRoot,
            'BOT': 'true',
          },
        );
      }

      // First run populates build/native_assets/<os>/native_assets.json.
      final ProcessResult firstRun = await runFlutterTest();
      expect(firstRun, const ProcessResultMatcher(stdoutPattern: 'All tests passed!'));

      final File nativeAssetsJsonFile = nativeAssetsDir.childFile(_nativeAssetsFileName);
      expect(nativeAssetsJsonFile, exists);

      // Seed a sentinel payload before removing directory write permission so
      // we verify that the second run truncates and overwrites native_assets.json
      // in place rather than leaving stale contents untouched.
      const staleManifestSentinel = '{"stale": true}';
      nativeAssetsJsonFile.writeAsStringSync(staleManifestSentinel);

      // Remove write permission on build/native_assets/<os>/ while keeping
      // native_assets.json itself writable so unlinking native_assets.json fails
      // while truncating and overwriting native_assets.json in place succeeds.
      final ProcessResult chmodResult = await processManager.run(<String>[
        'chmod',
        _readExecuteDirMode,
        nativeAssetsDir.path,
      ]);
      expect(chmodResult, const ProcessResultMatcher());

      final ProcessResult secondRun = await runFlutterTest();
      expect(secondRun, const ProcessResultMatcher(stdoutPattern: 'All tests passed!'));
      expect(nativeAssetsJsonFile, exists);
      final String updatedManifest = nativeAssetsJsonFile.readAsStringSync();
      expect(updatedManifest, isNot(contains('"stale"')));
      expect(updatedManifest, contains('"format-version"'));
    },
  );
}

void _writeOfflineProject({
  required Directory projectDir,
  required Directory flutterToolsDartToolDir,
  required File flutterToolsPackageConfigFile,
}) {
  final decoded =
      json.decode(flutterToolsPackageConfigFile.readAsStringSync()) as Map<String, Object?>;
  final rawPackages = decoded['packages']! as List<Object?>;
  final resolvedPackages = <Map<String, Object?>>[
    for (final Object? entry in rawPackages)
      if (entry
          case {
            'name': final String name,
            'rootUri': final String rootUri,
            'packageUri': final String packageUri,
            'languageVersion': final String languageVersion,
          }
          when !name.startsWith('flutter_tools') && name != _appName)
        <String, Object?>{
          'name': name,
          'rootUri': flutterToolsDartToolDir.uri.resolve(rootUri).toString(),
          'packageUri': packageUri,
          'languageVersion': languageVersion,
        },
    <String, Object?>{
      'name': _appName,
      'rootUri': '../',
      'packageUri': 'lib/',
      'languageVersion': '3.7',
    },
  ];

  projectDir.childDirectory(_dartToolDirName).childFile(_packageConfigFileName)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      json.encode(<String, Object?>{'configVersion': 2, 'packages': resolvedPackages}),
    );

  projectDir
      .childDirectory(_dartToolDirName)
      .childFile(_packageGraphFileName)
      .writeAsStringSync(
        json.encode(<String, Object?>{
          'roots': <String>[_appName],
          'packages': <Map<String, Object?>>[
            for (final Map<String, Object?> pkg in resolvedPackages)
              if (pkg['name'] case final String pkgName)
                <String, Object?>{
                  'name': pkgName,
                  'version': '0.0.0',
                  'dependencies': const <String>[],
                  if (pkgName == _appName) 'devDependencies': const <String>['test'],
                },
          ],
          'configVersion': 1,
        }),
      );

  projectDir.childFile(_pubspecFileName).writeAsStringSync('''
name: $_appName
environment:
  sdk: ^3.7.0-0

dev_dependencies:
  test: any
''');

  projectDir.childDirectory('test').childFile('smoke_test.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('smoke test', () {
    expect(1 + 1, 2);
  });
}
''');
}
