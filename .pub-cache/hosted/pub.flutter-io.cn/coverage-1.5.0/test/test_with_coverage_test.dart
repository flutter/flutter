// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import 'test_util.dart';

// this package
final _pkgDir = p.absolute('');
final _testWithCoveragePath = p.join(_pkgDir, 'bin', 'test_with_coverage.dart');

// test package
final _testPkgDirPath = p.join(_pkgDir, 'test', 'test_with_coverage_package');

/// Override PUB_CACHE
///
/// Use a subdirectory different from `test/` just in case there is a problem
/// with the clean up. If other packages are present under the `test/`
/// subdirectory their tests may accidentally get run when running `dart test`
final _pubCachePathInTestPkgSubDir = p.join(_pkgDir, 'var', 'pub-cache');
final _env = {'PUB_CACHE': _pubCachePathInTestPkgSubDir};

const _testPackageName = 'coverage_integration_test_for_test_with_coverage';

int _port = 9300;

Iterable<File> _dartFiles(String dir) =>
    Directory(p.join(_testPkgDirPath, dir)).listSync().whereType<File>();

String _fixTestFile(String content) => content.replaceAll(
      "import '../lib/",
      "import 'package:$_testPackageName/",
    );

void main() {
  setUpAll(() async {
    for (var dir in const ['lib', 'test']) {
      await d.dir(dir, [
        for (var dartFile in _dartFiles(dir))
          d.file(
            p.basename(dartFile.path),
            _fixTestFile(dartFile.readAsStringSync()),
          ),
      ]).create();
    }

    var pubspecContent =
        File(p.join(_testPkgDirPath, 'pubspec.yaml')).readAsStringSync();

    expect(
      pubspecContent.replaceAll('\r\n', '\n'),
      contains(r'''
dependency_overrides:
  coverage:
    path: ../../
'''),
    );

    pubspecContent =
        pubspecContent.replaceFirst('path: ../../', 'path: $_pkgDir');

    await d.file('pubspec.yaml', pubspecContent).create();

    final localPub = await _run(['pub', 'get']);
    await localPub.shouldExit(0);
  });

  test('dart run bin/test_with_coverage.dart -f', () async {
    final list = await _runTest(['run', _testWithCoveragePath, '-f']);

    final sources = list.sources();
    final functionHits = functionInfoFromSources(sources);

    expect(
      functionHits['package:$_testPackageName/validate_lib.dart'],
      {
        'product': 1,
        'sum': 1,
      },
    );
  });

  test('dart run bin/test_with_coverage.dart -f -- -N sum', () async {
    final list = await _runTest(
      ['run', _testWithCoveragePath, '-f'],
      extraArgs: ['--', '-N', 'sum'],
    );

    final sources = list.sources();
    final functionHits = functionInfoFromSources(sources);

    expect(
      functionHits['package:$_testPackageName/validate_lib.dart'],
      {
        'product': 0,
        'sum': 1,
      },
      reason: 'only `sum` tests should be run',
    );
  });

  test('dart run coverage:test_with_coverage', () async {
    await _runTest(['run', 'coverage:test_with_coverage']);
  });

  test('dart pub global run coverage:test_with_coverage', () async {
    final globalPub =
        await _run(['pub', 'global', 'activate', '-s', 'path', _pkgDir]);
    await globalPub.shouldExit(0);

    await _runTest(
      ['pub', 'global', 'run', 'coverage:test_with_coverage'],
    );
  });
}

Future<TestProcess> _run(List<String> args) => TestProcess.start(
      Platform.executable,
      args,
      workingDirectory: d.sandbox,
      environment: _env,
    );

Future<List<Map<String, dynamic>>> _runTest(
  List<String> invokeArgs, {
  List<String>? extraArgs,
}) async {
  final process = await _run([
    ...invokeArgs,
    '--port',
    '${_port++}',
    ...?extraArgs,
  ]);

  await process.shouldExit(0);

  await d.dir(
    'coverage',
    [d.file('coverage.json', isNotEmpty), d.file('lcov.info', isNotEmpty)],
  ).validate();

  final coverageDataFile = File(p.join(d.sandbox, 'coverage', 'coverage.json'));

  final json = jsonDecode(coverageDataFile.readAsStringSync());

  return coverageDataFromJson(json as Map<String, dynamic>);
}
