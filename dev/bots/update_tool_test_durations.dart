// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates `dev/bots/tool_test_durations.json` from the per-test
// durations that recent postsubmit builds reported to ResultDB.
// setUpAll/tearDownAll time is not reported, so files with heavy fixtures read
// a little low.
//
//   dart dev/bots/update_tool_test_durations.dart [--builds=N]

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'test_durations.dart';
import 'utils.dart';

/// `Platform.operatingSystem` value for each `.ci.yaml` platform prefix.
const Map<String, String> _hostByPrefix = <String, String>{
  'Linux': 'linux',
  'Mac': 'macos',
  'Mac_arm64': 'macos',
  'Windows': 'windows',
};

/// A `packages/flutter_tools/test/<name>.shard` directory and the prod
/// builders that run it.
typedef ToolShard = ({String name, RegExp builderName});

RegExp _builderName(String pattern) => RegExp('^(${_hostByPrefix.keys.join('|')}) $pattern\$');

final List<ToolShard> _shards = <ToolShard>[
  (name: 'integration', builderName: _builderName(r'tool_integration_tests_\d+(_\d+)?')),
  (name: 'commands', builderName: _builderName(r'tool_tests_commands(_\d+_\d+)?')),
  (name: 'web', builderName: _builderName(r'web_tool_tests(_\d+_\d+)?')),
];

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('builds', defaultsTo: '3', help: 'Successful builds to sample per subshard.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args = parser.parse(arguments);
  if (args.flag('help')) {
    print(parser.usage);
    return;
  }
  final int builds = int.parse(args.option('builds')!);

  final output = File(path.join(flutterRoot, 'dev', 'bots', 'tool_test_durations.json'));
  final DurationsByGroup previous = readDurations(output);
  final sampler = TestDurationSampler();
  final List<String> prodBuilders = await sampler.listProdBuilders();
  final result = <String, DurationsByFile>{};
  for (final ToolShard shard in _shards) {
    final prefix = 'packages/flutter_tools/test/${shard.name}.shard/';
    final sampled = <String, DurationsByFile>{};
    for (final MapEntry(key: host, value: builders) in _buildersByHost(
      shard,
      prodBuilders,
    ).entries) {
      if (builders.isEmpty) {
        throw StateError('No ${shard.name} builders found for $host');
      }
      sampled[host] = await sampler.sampleDurations(
        builders,
        builds,
        keyFor: (String file) =>
            file.startsWith(prefix) ? file.substring('packages/flutter_tools/'.length) : null,
      );
    }
    // Reconcile per shard so unsampled files get their own shard's median.
    for (final MapEntry(key: host, value: durations) in reconcile(
      sampled,
      _localTestFiles(shard),
      previous,
    ).entries) {
      (result[host] ??= <String, int>{}).addAll(durations);
    }
  }
  sampler.close();
  writeDurations(output, result);
}

/// The [prodBuilders] that run [shard], by host.
Map<String, List<String>> _buildersByHost(ToolShard shard, List<String> prodBuilders) {
  final buildersByHost = <String, List<String>>{
    for (final String host in _hostByPrefix.values) host: <String>[],
  };
  for (final builder in prodBuilders) {
    final Match? m = shard.builderName.firstMatch(builder);
    if (m != null) {
      buildersByHost[_hostByPrefix[m.group(1)]!]!.add(builder);
    }
  }
  return buildersByHost;
}

/// Test files of [shard] in the tree, relative to `packages/flutter_tools`.
List<String> _localTestFiles(ToolShard shard) {
  final String toolsRoot = path.join(flutterRoot, 'packages', 'flutter_tools');
  return Directory(path.join(toolsRoot, 'test', '${shard.name}.shard'))
      .listSync(recursive: true)
      .whereType<File>()
      .map((File f) => path.posix.joinAll(path.split(path.relative(f.path, from: toolsRoot))))
      .where((String f) => f.endsWith('_test.dart'))
      .toList()
    ..sort();
}
