// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Retry(3)
import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:coverage/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'test_util.dart';

final _isolateLibPath = p.join('test', 'test_files', 'test_app_isolate.dart');
final _collectAppPath = p.join('bin', 'collect_coverage.dart');

final _sampleAppFileUri = p.toUri(p.absolute(testAppPath)).toString();
final _isolateLibFileUri = p.toUri(p.absolute(_isolateLibPath)).toString();

void main() {
  test('collect_coverage', () async {
    final resultString = await _getCoverageResult();

    // analyze the output json
    final coverage =
        coverageDataFromJson(json.decode(resultString) as Map<String, dynamic>);

    expect(coverage, isNotEmpty);

    final sources = coverage.sources();

    for (var sampleCoverageData in sources[_sampleAppFileUri]!) {
      expect(sampleCoverageData['hits'], isNotNull);
    }

    for (var sampleCoverageData in sources[_isolateLibFileUri]!) {
      expect(sampleCoverageData['hits'], isNotEmpty);
    }
  });

  test('createHitmap returns a sorted hitmap', () async {
    final coverage = [
      {
        'source': 'foo',
        'script': '{type: @Script, fixedId: true, '
            'id: bar.dart, uri: bar.dart, _kind: library}',
        'hits': [
          45,
          1,
          46,
          1,
          49,
          0,
          50,
          0,
          15,
          1,
          16,
          2,
          17,
          2,
        ]
      }
    ];
    // ignore: deprecated_member_use_from_same_package
    final hitMap = await createHitmap(
      coverage.cast<Map<String, dynamic>>(),
    );
    final expectedHits = {15: 1, 16: 2, 17: 2, 45: 1, 46: 1, 49: 0, 50: 0};
    expect(hitMap['foo'], expectedHits);
  });

  test('HitMap.parseJson returns a sorted hitmap', () async {
    final coverage = [
      {
        'source': 'foo',
        'script': '{type: @Script, fixedId: true, '
            'id: bar.dart, uri: bar.dart, _kind: library}',
        'hits': [
          45,
          1,
          46,
          1,
          49,
          0,
          50,
          0,
          15,
          1,
          16,
          2,
          17,
          2,
        ]
      }
    ];
    final hitMap = await HitMap.parseJson(
      coverage.cast<Map<String, dynamic>>(),
    );
    final expectedHits = {15: 1, 16: 2, 17: 2, 45: 1, 46: 1, 49: 0, 50: 0};
    expect(hitMap['foo']?.lineHits, expectedHits);
  });

  test('HitMap.parseJson', () async {
    final resultString = await _collectCoverage(true, true);
    final jsonResult = json.decode(resultString) as Map<String, dynamic>;
    final coverage = jsonResult['coverage'] as List;
    final hitMap = await HitMap.parseJson(
      coverage.cast<Map<String, dynamic>>(),
    );
    expect(hitMap, contains(_sampleAppFileUri));

    final isolateFile = hitMap[_isolateLibFileUri];
    final expectedHits = {
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
      51: 1,
      54: 1,
      55: 1,
      56: 1,
      59: 1,
      60: 1,
      62: 1,
      63: 1,
      64: 1,
      66: 1,
      67: 1,
      68: 1
    };
    expect(isolateFile?.lineHits, expectedHits);
    expect(isolateFile?.funcHits, {11: 1, 19: 1, 23: 1, 28: 1, 38: 1});
    expect(isolateFile?.funcNames, {
      11: 'fooSync',
      19: 'BarClass.BarClass',
      23: 'BarClass.baz',
      28: 'fooAsync',
      38: 'isolateTask'
    });
    expect(isolateFile?.branchHits, {
      11: 1,
      12: 1,
      15: 0,
      19: 1,
      23: 1,
      28: 1,
      if (platformVersionCheck(2, 18)) 29: 1,
      32: 0,
      38: 1,
      42: 1
    });
  }, skip: !platformVersionCheck(2, 17));

  test('HitMap.parseJson, old VM without branch coverage', () async {
    final resultString = await _collectCoverage(true, true);
    final jsonResult = json.decode(resultString) as Map<String, dynamic>;
    final coverage = jsonResult['coverage'] as List;
    final hitMap = await HitMap.parseJson(
      coverage.cast<Map<String, dynamic>>(),
    );
    expect(hitMap, contains(_sampleAppFileUri));

    final isolateFile = hitMap[_isolateLibFileUri];
    final expectedHits = {
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
      51: 1,
      54: 1,
      55: 1,
      56: 1,
      59: 1,
      60: 1,
      62: 1,
      63: 1,
      64: 1,
      66: 1,
      67: 1,
      68: 1
    };
    expect(isolateFile?.lineHits, expectedHits);
    expect(isolateFile?.funcHits, {11: 1, 19: 1, 23: 1, 28: 1, 38: 1});
    expect(isolateFile?.funcNames, {
      11: 'fooSync',
      19: 'BarClass.BarClass',
      23: 'BarClass.baz',
      28: 'fooAsync',
      38: 'isolateTask'
    });
  }, skip: platformVersionCheck(2, 17));

  test('parseCoverage', () async {
    final tempDir = await Directory.systemTemp.createTemp('coverage.test.');

    try {
      final outputFile = File(p.join(tempDir.path, 'coverage.json'));

      final coverageResults = await _getCoverageResult();
      await outputFile.writeAsString(coverageResults, flush: true);

      // ignore: deprecated_member_use_from_same_package
      final parsedResult = await parseCoverage([outputFile], 1);

      expect(parsedResult, contains(_sampleAppFileUri));
      expect(parsedResult, contains(_isolateLibFileUri));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('HitMap.parseFiles', () async {
    final tempDir = await Directory.systemTemp.createTemp('coverage.test.');

    try {
      final outputFile = File(p.join(tempDir.path, 'coverage.json'));

      final coverageResults = await _getCoverageResult();
      await outputFile.writeAsString(coverageResults, flush: true);

      final parsedResult = await HitMap.parseFiles([outputFile]);

      expect(parsedResult, contains(_sampleAppFileUri));
      expect(parsedResult, contains(_isolateLibFileUri));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('HitMap.parseFiles with packagesPath and checkIgnoredLines', () async {
    final tempDir = await Directory.systemTemp.createTemp('coverage.test.');

    try {
      final outputFile = File(p.join(tempDir.path, 'coverage.json'));

      final coverageResults = await _getCoverageResult();
      await outputFile.writeAsString(coverageResults, flush: true);

      final parsedResult = await HitMap.parseFiles([outputFile],
          packagePath: '.', checkIgnoredLines: true);

      // This file has ignore:coverage-file.
      expect(parsedResult, isNot(contains(_sampleAppFileUri)));
      expect(parsedResult, contains(_isolateLibFileUri));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('mergeHitmaps', () {
    final resultMap = <String, Map<int, int>>{
      "foo.dart": {10: 2, 20: 0},
      "bar.dart": {10: 3, 20: 1, 30: 0},
    };
    final newMap = <String, Map<int, int>>{
      "bar.dart": {10: 2, 20: 0, 40: 3},
      "baz.dart": {10: 1, 20: 0, 30: 1},
    };
    // ignore: deprecated_member_use_from_same_package
    mergeHitmaps(newMap, resultMap);
    expect(resultMap, <String, Map<int, int>>{
      "foo.dart": {10: 2, 20: 0},
      "bar.dart": {10: 5, 20: 1, 30: 0, 40: 3},
      "baz.dart": {10: 1, 20: 0, 30: 1},
    });
  });

  test('FileHitMaps.merge', () {
    final resultMap = <String, HitMap>{
      "foo.dart":
          HitMap({10: 2, 20: 0}, {15: 0, 25: 1}, {15: "bobble", 25: "cobble"}),
      "bar.dart": HitMap(
          {10: 3, 20: 1, 30: 0}, {15: 5, 25: 0}, {15: "gobble", 25: "wobble"}),
    };
    final newMap = <String, HitMap>{
      "bar.dart": HitMap(
          {10: 2, 20: 0, 40: 3}, {15: 1, 35: 4}, {15: "gobble", 35: "dobble"}),
      "baz.dart": HitMap(
          {10: 1, 20: 0, 30: 1}, {15: 0, 25: 2}, {15: "lobble", 25: "zobble"}),
    };
    resultMap.merge(newMap);
    expect(resultMap["foo.dart"]?.lineHits, <int, int>{10: 2, 20: 0});
    expect(resultMap["foo.dart"]?.funcHits, <int, int>{15: 0, 25: 1});
    expect(resultMap["foo.dart"]?.funcNames,
        <int, String>{15: "bobble", 25: "cobble"});
    expect(resultMap["bar.dart"]?.lineHits,
        <int, int>{10: 5, 20: 1, 30: 0, 40: 3});
    expect(resultMap["bar.dart"]?.funcHits, <int, int>{15: 6, 25: 0, 35: 4});
    expect(resultMap["bar.dart"]?.funcNames,
        <int, String>{15: "gobble", 25: "wobble", 35: "dobble"});
    expect(resultMap["baz.dart"]?.lineHits, <int, int>{10: 1, 20: 0, 30: 1});
    expect(resultMap["baz.dart"]?.funcHits, <int, int>{15: 0, 25: 2});
    expect(resultMap["baz.dart"]?.funcNames,
        <int, String>{15: "lobble", 25: "zobble"});
  });
}

String? _coverageData;

Future<String> _getCoverageResult() async =>
    _coverageData ??= await _collectCoverage(false, false);

Future<String> _collectCoverage(
    bool functionCoverage, bool branchCoverage) async {
  expect(FileSystemEntity.isFileSync(testAppPath), isTrue);

  final openPort = await getOpenPort();

  // Run the sample app with the right flags.
  final sampleProcess = await runTestApp(openPort);

  // Capture the VM service URI.
  final serviceUri = await serviceUriFromProcess(sampleProcess.stdoutStream());

  // Run the collection tool.
  // TODO: need to get all of this functionality in the lib
  final toolResult = await TestProcess.start(Platform.resolvedExecutable, [
    _collectAppPath,
    if (functionCoverage) '--function-coverage',
    if (branchCoverage) '--branch-coverage',
    '--uri',
    '$serviceUri',
    '--resume-isolates',
    '--wait-paused'
  ]);

  await toolResult.shouldExit(0).timeout(timeout, onTimeout: () {
    throw 'We timed out waiting for the tool to finish.';
  });

  await sampleProcess.shouldExit();

  return toolResult.stdoutStream().join('\n');
}
