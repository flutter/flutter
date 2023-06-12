// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:coverage/coverage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_util.dart';

final _isolateLibPath = p.join('test', 'test_files', 'test_app_isolate.dart');

final _sampleAppFileUri = p.toUri(p.absolute(testAppPath)).toString();
final _isolateLibFileUri = p.toUri(p.absolute(_isolateLibPath)).toString();

void main() {
  test('runAndCollect', () async {
    // use runAndCollect and verify that the results match w/ running manually
    final coverage = coverageDataFromJson(await runAndCollect(testAppPath));
    expect(coverage, isNotEmpty);

    final sources = coverage.sources();

    for (var sampleCoverageData in sources[_sampleAppFileUri]!) {
      expect(sampleCoverageData['hits'], isNotNull);
    }

    for (var sampleCoverageData in sources[_isolateLibFileUri]!) {
      expect(sampleCoverageData['hits'], isNotEmpty);
    }

    final hitMap = await HitMap.parseJson(coverage, checkIgnoredLines: true);
    checkHitmap(hitMap);
    final Resolver resolver = await Resolver.create();
    final Map<String, List<List<int>>?> ignoredLinesInFilesCache = {};
    final hitMap2 = HitMap.parseJsonSync(coverage,
        checkIgnoredLines: true,
        ignoredLinesInFilesCache: ignoredLinesInFilesCache,
        resolver: resolver);
    checkHitmap(hitMap2);
    checkIgnoredLinesInFilesCache(ignoredLinesInFilesCache);

    // Asking again the cache should answer questions about ignored lines,
    // so providing a resolver that throws when asked for files should be ok.
    final hitMap3 = HitMap.parseJsonSync(coverage,
        checkIgnoredLines: true,
        ignoredLinesInFilesCache: ignoredLinesInFilesCache,
        resolver: ThrowingResolver());
    checkHitmap(hitMap3);
    checkIgnoredLinesInFilesCache(ignoredLinesInFilesCache);
  });
}

class ThrowingResolver implements Resolver {
  @override
  List<String> get failed => throw UnimplementedError();

  @override
  String? get packagePath => throw UnimplementedError();

  @override
  String? get packagesPath => throw UnimplementedError();

  @override
  String? resolve(String scriptUri) => throw UnimplementedError();

  @override
  String? resolveSymbolicLinks(String path) => throw UnimplementedError();

  @override
  String? get sdkRoot => throw UnimplementedError();
}

void checkIgnoredLinesInFilesCache(
    Map<String, List<List<int>>?> ignoredLinesInFilesCache) {
  expect(ignoredLinesInFilesCache.length, 3);
  final List<String> keys = ignoredLinesInFilesCache.keys.toList();
  final String testAppKey =
      keys.where((element) => element.endsWith('test_app.dart')).single;
  final String testAppIsolateKey =
      keys.where((element) => element.endsWith('test_app_isolate.dart')).single;
  final String packageUtilKey = keys
      .where((element) => element.endsWith('package:coverage/src/util.dart'))
      .single;
  expect(ignoredLinesInFilesCache[packageUtilKey], isEmpty);
  expect(ignoredLinesInFilesCache[testAppKey], null /* means whole file */);
  expect(ignoredLinesInFilesCache[testAppIsolateKey], [
    [51, 51],
    [53, 57],
    [62, 65],
    [66, 69]
  ]);
}

void checkHitmap(Map<String, HitMap> hitMap) {
  expect(hitMap, isNot(contains(_sampleAppFileUri)));

  final actualHitMap = hitMap[_isolateLibFileUri];
  final actualLineHits = actualHitMap?.lineHits;
  final expectedLineHits = {
    11: 1,
    12: 1,
    13: 1,
    15: 0,
    19: 1,
    23: 1,
    24: 2,
    28: 1,
    29: 1,
    30: 1,
    32: 0,
    38: 1,
    39: 1,
    41: 1,
    42: 3,
    43: 1,
    44: 3,
    45: 1,
    48: 1,
    49: 1,
    59: 1,
    60: 1
  };

  expect(actualLineHits, expectedLineHits);
  expect(actualHitMap?.funcHits, isNull);
  expect(actualHitMap?.funcNames, isNull);
  expect(actualHitMap?.branchHits, isNull);
}
