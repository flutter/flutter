// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as p;

import '../suite_runners/run_web_tests.dart';
import './common.dart';

/// Keeps `dev/bots/web_test_durations.json` in sync with the tree.
void main() {
  final String flutterRoot = () {
    io.Directory current = io.Directory.current;
    while (!io.File(p.join(current.path, 'DEPS')).existsSync()) {
      if (current.path == current.parent.path) {
        fail(
          'Could not find flutter repository root (${io.Directory.current.path} -> ${current.path})',
        );
      }
      current = current.parent;
    }
    return current.path;
  }();

  const durationsPath = 'dev/bots/web_test_durations.json';
  const renderers = <String>['canvaskit', 'skwasm'];

  late Map<String, Map<String, int>> durations;
  late Set<String> testFiles;

  setUpAll(() {
    // Map.from checks every key and value, so a malformed file fails here.
    final decoded = json.decode(
      io.File(p.join(flutterRoot, durationsPath)).readAsStringSync(),
    ) as Map<String, Object?>;
    durations = decoded.map(
      (String renderer, Object? files) => MapEntry<String, Map<String, int>>(
        renderer,
        Map<String, int>.from(files! as Map<String, Object?>),
      ),
    );
    testFiles = WebTestsSuite.webUnitTestFiles(root: flutterRoot).toSet();
  });

  test('has an entry for every renderer', () {
    expect(durations.keys, unorderedEquals(renderers));
  });

  for (final renderer in renderers) {
    test('$renderer lists exactly the web unit test files', () {
      final Map<String, int> forRenderer = durations[renderer]!;
      final List<String> missing = testFiles.difference(forRenderer.keys.toSet()).toList()..sort();
      final List<String> stale = forRenderer.keys.toSet().difference(testFiles).toList()..sort();

      final problems = <String>[
        if (missing.isNotEmpty) ...<String>[
          'Not in "$renderer" of $durationsPath:',
          ...missing.map((String f) => '  $f'),
        ],
        if (stale.isNotEmpty) ...<String>[
          'In "$renderer" of $durationsPath but not in the tree:',
          ...stale.map((String f) => '  $f'),
        ],
        if (missing.isNotEmpty || stale.isNotEmpty) ...<String>[
          '',
          'Either run:',
          '  dart dev/bots/update_web_test_durations.dart',
          "or edit $durationsPath by hand with the test file's wall time in seconds.",
        ],
      ];
      if (problems.isNotEmpty) {
        fail(problems.join('\n'));
      }
    });

    test('$renderer durations are non-negative', () {
      for (final MapEntry(key: file, value: seconds) in durations[renderer]!.entries) {
        expect(seconds, isNonNegative, reason: '$file for $renderer');
      }
    });
  }
}
