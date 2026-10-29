// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as p;

import './common.dart';

/// Keeps `dev/bots/tool_integration_test_durations.json` in sync with
/// `packages/flutter_tools/test/integration.shard`.
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

  const durationsPath = 'dev/bots/tool_integration_test_durations.json';
  const hosts = <String>['linux', 'macos', 'windows'];

  late Map<String, Map<String, int>> durations;
  late Set<String> testFiles;

  setUpAll(() {
    // Map.from checks every key and value, so a malformed file fails here.
    final hosts = json.decode(
      io.File(p.join(flutterRoot, durationsPath)).readAsStringSync(),
    ) as Map<String, Object?>;
    durations = hosts.map(
      (String host, Object? files) => MapEntry<String, Map<String, int>>(
        host,
        Map<String, int>.from(files! as Map<String, Object?>),
      ),
    );

    final String toolsRoot = p.join(flutterRoot, 'packages', 'flutter_tools');
    testFiles = io.Directory(p.join(toolsRoot, 'test', 'integration.shard'))
        .listSync(recursive: true)
        .whereType<io.File>()
        .map((io.File file) => p.posix.joinAll(p.split(p.relative(file.path, from: toolsRoot))))
        .where((String file) => file.endsWith('_test.dart'))
        .toSet();
  });

  test('has an entry for every host', () {
    expect(durations.keys, unorderedEquals(hosts));
  });

  for (final host in hosts) {
    test('$host lists exactly the files in integration.shard', () {
      final Map<String, int> forHost = durations[host]!;
      final List<String> missing = testFiles.difference(forHost.keys.toSet()).toList()..sort();
      final List<String> stale = forHost.keys.toSet().difference(testFiles).toList()..sort();

      final problems = <String>[
        if (missing.isNotEmpty) ...<String>[
          'Not in "$host" of $durationsPath:',
          ...missing.map((String f) => '  $f'),
        ],
        if (stale.isNotEmpty) ...<String>[
          'In "$host" of $durationsPath but not in the tree:',
          ...stale.map((String f) => '  $f'),
        ],
        if (missing.isNotEmpty || stale.isNotEmpty) ...<String>[
          '',
          'Either run:',
          '  dart dev/bots/update_tool_integration_test_durations.dart',
          'or edit $durationsPath by hand. Each host needs an entry; use the',
          "test's wall time in seconds, or 0 on hosts where it does not run.",
        ],
      ];
      if (problems.isNotEmpty) {
        fail(problems.join('\n'));
      }
    });

    test('$host durations are non-negative', () {
      for (final MapEntry<String, int> entry in durations[host]!.entries) {
        expect(entry.value, isNonNegative, reason: '${entry.key} on $host');
      }
    });
  }
}
