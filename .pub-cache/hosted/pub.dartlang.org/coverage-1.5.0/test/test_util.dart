// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

final String testAppPath = p.join('test', 'test_files', 'test_app.dart');

const Duration timeout = Duration(seconds: 20);

Future<TestProcess> runTestApp(int openPort) => TestProcess.start(
      Platform.resolvedExecutable,
      [
        '--enable-vm-service=$openPort',
        '--pause_isolates_on_exit',
        // Dart VM versions before 2.17 don't support branch coverage.
        if (platformVersionCheck(2, 17)) '--branch-coverage',
        testAppPath
      ],
    );

List<Map<String, dynamic>> coverageDataFromJson(Map<String, dynamic> json) {
  expect(json.keys, unorderedEquals(<String>['type', 'coverage']));
  expect(json, containsPair('type', 'CodeCoverage'));

  return (json['coverage'] as List).cast<Map<String, dynamic>>();
}

final _versionPattern = RegExp('([0-9]+)\\.([0-9]+)\\.([0-9]+)');
bool platformVersionCheck(int minMajor, int minMinor) {
  final match = _versionPattern.matchAsPrefix(Platform.version);
  if (match == null) return false;
  if (match.groupCount < 3) return false;
  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  return major > minMajor || (major == minMajor && minor >= minMinor);
}

/// Returns a mapping of <URL: <function_name: hit_count>> from [sources].
Map<String, Map<String, int>> functionInfoFromSources(
  Map<String, List<Map<dynamic, dynamic>>> sources,
) {
  Map<int, String> getFuncNames(List list) {
    return {
      for (var i = 0; i < list.length; i += 2)
        list[i] as int: list[i + 1] as String,
    };
  }

  Map<int, int> getFuncHits(List list) {
    return {
      for (var i = 0; i < list.length; i += 2)
        list[i] as int: list[i + 1] as int,
    };
  }

  return {
    for (var entry in sources.entries)
      entry.key: entry.value.fold(
        {},
        (previousValue, element) {
          expect(element['source'], entry.key);
          final names = getFuncNames(element['funcNames'] as List);
          final hits = getFuncHits(element['funcHits'] as List);

          for (var pair in hits.entries) {
            previousValue[names[pair.key]!] =
                (previousValue[names[pair.key]!] ?? 0) + pair.value;
          }

          return previousValue;
        },
      ),
  };
}

extension ListTestExtension on List {
  Map<String, List<Map<dynamic, dynamic>>> sources() => cast<Map>().fold(
        <String, List<Map>>{},
        (Map<String, List<Map>> map, value) {
          final sourceUri = value['source'] as String;
          map.putIfAbsent(sourceUri, () => <Map>[]).add(value);
          return map;
        },
      );
}
