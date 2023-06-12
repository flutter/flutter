// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(#388): Fix and re-enable this test.
@TestOn('!windows')

import 'dart:convert';
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:test/test.dart';

// The scriptId for the main_test.js in the sample report.
const String mainScriptId = '31';

Future<String> sourceMapProvider(String scriptId) async {
  if (scriptId != mainScriptId) {
    return 'something invalid!';
  }
  return File('test/test_files/main_test.js.map').readAsString();
}

Future<String?> sourceProvider(String scriptId) async {
  if (scriptId != mainScriptId) return null;
  return File('test/test_files/main_test.js').readAsString();
}

Future<Uri> sourceUriProvider(String sourceUrl, String scriptId) async =>
    Uri.parse(sourceUrl);

void main() {
  test('reports correctly', () async {
    final preciseCoverage = json.decode(
        await File('test/test_files/chrome_precise_report.txt')
            .readAsString()) as List;

    final report = await parseChromeCoverage(
      preciseCoverage.cast(),
      sourceProvider,
      sourceMapProvider,
      sourceUriProvider,
    );

    final sourceReport = report['coverage'].firstWhere(
        (Map<String, dynamic> report) =>
            report['source'].toString().contains('main_test.dart'));

    final expectedHits = {
      7: 1,
      11: 1,
      13: 1,
      14: 1,
      17: 0,
      19: 0,
      20: 0,
      22: 1,
      23: 1,
      24: 1,
      25: 1,
      28: 1,
      30: 0,
      32: 1,
      34: 1,
      35: 1,
      36: 1,
    };

    final hitMap = sourceReport['hits'] as List<int>;
    expect(hitMap.length, equals(expectedHits.keys.length * 2));
    for (var i = 0; i < hitMap.length; i += 2) {
      expect(expectedHits[hitMap[i]], equals(hitMap[i + 1]));
    }
  });
}
