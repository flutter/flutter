// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('posix')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:package_config/package_config.dart';

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

void main() {
  final File flutterToolsPackageConfigFile = fileSystem
      .directory(getFlutterRoot())
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory(_dartToolDirName)
      .childFile(_packageConfigFileName);

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

      await _writeOfflineProject(
        flutterToolsPackageConfigFile: flutterToolsPackageConfigFile,
        projectDir: tempDir,
      );

      Future<ProcessResult> runFlutterTest() {
        return processManager.run(
          <String>[
            flutterBin,
            '--suppress-analytics',
            '--no-version-check',
            ...getLocalEngineArguments(),
            'test',
            '--no-pub',
          ],
          workingDirectory: tempDir.path,
          environment: <String, String>{...platform.environment, 'BOT': 'true'},
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

Future<void> _writeOfflineProject({
  required File flutterToolsPackageConfigFile,
  required Directory projectDir,
}) async {
  final PackageConfig flutterToolsPackageConfig = await loadPackageConfig(
    flutterToolsPackageConfigFile,
  );
  final packages = <Package>[
    for (final Package package in flutterToolsPackageConfig.packages)
      if (!package.name.startsWith('flutter_tools') && package.name != _appName) package,
    Package(
      _appName,
      projectDir.uri,
      packageUriRoot: Uri(path: 'lib/'),
      languageVersion: LanguageVersion(3, 7),
    ),
  ];

  await savePackageConfig(PackageConfig(packages), projectDir);

  projectDir
      .childDirectory(_dartToolDirName)
      .childFile(_packageGraphFileName)
      .writeAsStringSync(
        json.encode(<String, Object?>{
          'roots': <String>[_appName],
          'packages': <Map<String, Object?>>[
            for (final Package package in packages)
              <String, Object?>{
                'name': package.name,
                'version': '0.0.0',
                'dependencies': const <String>[],
                if (package.name == _appName) 'devDependencies': const <String>['test'],
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
