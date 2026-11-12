// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates `dev/bots/tool_test_durations.json` from the per-test
// durations that recent postsubmit builds reported to ResultDB.
// setUpAll/tearDownAll time is not reported, so files with heavy fixtures read
// a little low.
//
//   dart dev/bots/update_tool_test_durations.dart [--builds=N]

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'utils.dart';

/// Whole seconds per test file, keyed by path relative to `packages/flutter_tools`.
typedef DurationsByFile = Map<String, int>;

/// [DurationsByFile] keyed by `Platform.operatingSystem`.
typedef DurationsByHost = Map<String, DurationsByFile>;

const String _buildbucket = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.';
const String _resultdb = 'https://results.api.luci.app/prpc/luci.resultdb.v1.';

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

final http.Client _client = http.Client();

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
  final DurationsByHost previous = _readExisting(output);
  final List<String> prodBuilders = await _listProdBuilders();
  final result = <String, DurationsByFile>{};
  for (final ToolShard shard in _shards) {
    final sampled = <String, DurationsByFile>{};
    for (final MapEntry(key: host, value: builders) in _buildersByHost(
      shard,
      prodBuilders,
    ).entries) {
      if (builders.isEmpty) {
        throw StateError('No ${shard.name} builders found for $host');
      }
      sampled[host] = await _sampleDurations(shard, builders, builds);
    }
    // Reconcile per shard so unsampled files get their own shard's median.
    for (final MapEntry(key: host, value: durations) in _reconcile(
      sampled,
      _localTestFiles(shard),
      previous,
    ).entries) {
      (result[host] ??= <String, int>{}).addAll(durations);
    }
  }
  _client.close();

  final sorted = <String, DurationsByFile>{
    for (final MapEntry(key: host, value: durations) in result.entries)
      host: <String, int>{
        for (final file in durations.keys.toList()..sort()) file: durations[file]!,
      },
  };
  output.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
  stderr.writeln('Wrote ${output.path} (${sorted.values.first.length} files)');
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

/// Returns the median duration per file over the last [builds] successful builds of [builders].
Future<DurationsByFile> _sampleDurations(ToolShard shard, List<String> builders, int builds) async {
  final samples = <String, List<int>>{};
  for (final builder in builders..sort()) {
    stderr.writeln('Fetching $builds builds of $builder');
    for (final String invocation in await _recentInvocations(builder, builds)) {
      final DurationsByFile fileDurations = await _fileDurations(shard, invocation);
      for (final MapEntry(key: file, value: seconds) in fileDurations.entries) {
        samples.putIfAbsent(file, () => <int>[]).add(seconds);
      }
    }
  }
  return <String, int>{
    for (final MapEntry(key: file, value: seconds) in samples.entries) file: _median(seconds),
  };
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

/// Emits exactly [localFiles] per host, filling in unsampled files.
DurationsByHost _reconcile(
  DurationsByHost sampled,
  List<String> localFiles,
  DurationsByHost previous,
) {
  final sampledAnywhere = <String>{for (final DurationsByFile m in sampled.values) ...m.keys};
  final result = <String, DurationsByFile>{};
  for (final MapEntry(key: host, value: durations) in sampled.entries) {
    final int median = _median(durations.values.toList());
    result[host] = <String, int>{
      for (final String f in localFiles)
        f: durations[f] ?? (sampledAnywhere.contains(f) ? 0 : previous[host]?[f] ?? median),
    };
  }
  return <String, DurationsByFile>{
    for (final String host in result.keys.toList()..sort()) host: result[host]!,
  };
}

DurationsByHost _readExisting(File file) {
  if (!file.existsSync()) {
    return const <String, DurationsByFile>{};
  }
  final hosts = json.decode(file.readAsStringSync()) as Map<String, Object?>;
  return hosts.map(
    (String host, Object? files) => MapEntry<String, DurationsByFile>(
      host,
      Map<String, int>.from(files! as Map<String, Object?>),
    ),
  );
}

/// Names of all builders in the `flutter/prod` bucket.
///
/// The local .ci.yaml may not match prod, so ask Buildbucket.
Future<List<String>> _listProdBuilders() async {
  final names = <String>[];
  String? pageToken;
  do {
    final Object? response = await _rpc(_buildbucket, 'Builders/ListBuilders', <String, Object?>{
      'project': 'flutter',
      'bucket': 'prod',
      'pageSize': 1000,
      if (pageToken != null) 'pageToken': pageToken,
    });
    if (response case {'builders': final List<Object?> builders}) {
      for (final builder in builders) {
        if (builder case {'id': {'builder': final String name}}) {
          names.add(name);
        }
      }
    }
    pageToken = switch (response) {
      {'nextPageToken': final String token} => token,
      _ => null,
    };
  } while (pageToken != null);
  return names;
}

Future<Object?> _rpc(String service, String method, Map<String, Object?> body) async {
  final http.Response response = await _client.post(
    Uri.parse('$service$method'),
    headers: const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode(body),
  );
  if (response.statusCode != 200) {
    throw StateError('$method failed: ${response.statusCode} ${response.body}');
  }
  // pRPC prefixes JSON responses with an XSSI guard.
  const guard = ")]}'";
  final String text = response.body.startsWith(guard)
      ? response.body.substring(guard.length)
      : response.body;
  return json.decode(text);
}

/// ResultDB invocations of the last [count] successful builds of [builder].
Future<List<String>> _recentInvocations(String builder, int count) async {
  final Object? response = await _rpc(_buildbucket, 'Builds/SearchBuilds', <String, Object?>{
    'predicate': <String, Object?>{
      'builder': <String, String>{'project': 'flutter', 'bucket': 'prod', 'builder': builder},
      'status': 'SUCCESS',
    },
    'pageSize': count,
    'fields': 'builds.*.infra.resultdb.invocation',
  });
  return <String>[
    if (response case {'builds': final List<Object?> builds})
      for (final build in builds)
        if (build case {'infra': {'resultdb': {'invocation': final String invocation}}}) invocation,
  ];
}

/// Whole seconds per [shard] file in [invocation].
Future<DurationsByFile> _fileDurations(ToolShard shard, String invocation) async {
  final prefix = 'packages/flutter_tools/test/${shard.name}.shard/';
  final seconds = <String, double>{};
  String? pageToken;
  do {
    final Object? response = await _rpc(_resultdb, 'ResultDB/QueryTestResults', <String, Object?>{
      'invocations': <String>[invocation],
      'pageSize': 1000,
      'readMask': 'testIdStructured,duration',
      if (pageToken != null) 'pageToken': pageToken,
    });
    if (response case {'testResults': final List<Object?> results}) {
      for (final result in results) {
        if (result
            case {
              'testIdStructured': {'moduleName': final String file},
              'duration': final String duration,
            }
            when file.startsWith(prefix)) {
          final String key = file.substring('packages/flutter_tools/'.length);
          seconds[key] =
              (seconds[key] ?? 0) + double.parse(duration.substring(0, duration.length - 1));
        }
      }
    }
    pageToken = switch (response) {
      {'nextPageToken': final String token} => token,
      _ => null,
    };
  } while (pageToken != null);
  return seconds.map((String file, double s) => MapEntry<String, int>(file, s.round()));
}

int _median(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  final List<int> sorted = values.toList()..sort();
  return sorted[sorted.length ~/ 2];
}
