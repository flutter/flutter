// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates `dev/bots/tool_integration_test_durations.json` from the
// per-test durations that recent postsubmit `tool_integration_tests` builds
// reported to ResultDB. setUpAll/tearDownAll time is not reported, so files
// with heavy fixtures read a little low.
//
//   dart dev/bots/update_tool_integration_test_durations.dart [--builds=N]

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

const String _buildbucket = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.';
const String _resultdb = 'https://results.api.luci.app/prpc/luci.resultdb.v1.';

/// `Platform.operatingSystem` value for each `.ci.yaml` platform prefix.
const Map<String, String> _hostByPrefix = <String, String>{
  'Linux': 'linux',
  'Mac': 'macos',
  'Windows': 'windows',
};

final RegExp _builderName = RegExp(r'^(Linux|Mac|Windows) tool_integration_tests_\d+(_\d+)?$');

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

  final String flutterRoot = _repositoryRoot();
  final output = File(
    path.join(flutterRoot, 'dev', 'bots', 'tool_integration_test_durations.json'),
  );

  // The local .ci.yaml may not match prod, so ask Buildbucket.
  final buildersByHost = <String, List<String>>{
    for (final String host in _hostByPrefix.values) host: <String>[],
  };
  for (final String builder in await _listProdBuilders()) {
    final Match? m = _builderName.firstMatch(builder);
    if (m != null) {
      buildersByHost[_hostByPrefix[m.group(1)]!]!.add(builder);
    }
  }

  final result = <String, Map<String, int>>{};
  for (final MapEntry<String, List<String>> entry in buildersByHost.entries) {
    if (entry.value.isEmpty) {
      throw StateError('No tool_integration_tests builders found for ${entry.key}');
    }
    final samples = <String, List<int>>{};
    for (final String builder in entry.value..sort()) {
      stderr.writeln('Fetching $builds builds of $builder');
      for (final String invocation in await _recentInvocations(builder, builds)) {
        for (final MapEntry<String, int> fileDuration in (await _fileDurations(
          invocation,
        )).entries) {
          samples.putIfAbsent(fileDuration.key, () => <int>[]).add(fileDuration.value);
        }
      }
    }
    result[entry.key] = <String, int>{
      for (final MapEntry<String, List<int>> sample in samples.entries)
        sample.key: _median(sample.value),
    };
  }

  _client.close();

  // Logs can include deleted files and miss new ones; emit what's in the tree.
  final String toolsRoot = path.join(flutterRoot, 'packages', 'flutter_tools');
  final List<String> localFiles =
      Directory(path.join(toolsRoot, 'test', 'integration.shard'))
          .listSync(recursive: true)
          .whereType<File>()
          .map((File f) => path.posix.joinAll(path.split(path.relative(f.path, from: toolsRoot))))
          .where((String f) => f.endsWith('_test.dart'))
          .toList()
        ..sort();
  final Map<String, Map<String, int>> previous = _readExisting(output);
  final sampledAnywhere = <String>{for (final Map<String, int> m in result.values) ...m.keys};
  for (final MapEntry<String, Map<String, int>> host in result.entries) {
    final int median = _median(host.value.values.toList());
    host.value.removeWhere((String f, _) => !localFiles.contains(f));
    for (final f in localFiles) {
      host.value.putIfAbsent(f, () {
        if (sampledAnywhere.contains(f)) {
          return 0; // Runs on another host only (`@TestOn`).
        }
        return previous[host.key]?[f] ?? median; // New file; keep any manual entry.
      });
    }
  }

  final sortedResult = <String, Map<String, int>>{
    for (final String host in result.keys.toList()..sort())
      host: <String, int>{for (final String f in localFiles) f: result[host]![f]!},
  };
  output.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sortedResult)}\n');
  stderr.writeln('Wrote ${output.path} (${localFiles.length} files)');
}

/// The flutter repository root: the nearest ancestor of this script with a DEPS file.
String _repositoryRoot() {
  Directory dir = File.fromUri(Platform.script).parent;
  while (!File(path.join(dir.path, 'DEPS')).existsSync()) {
    if (dir.parent.path == dir.path) {
      throw StateError('Could not find the flutter repository root from ${Platform.script}');
    }
    dir = dir.parent;
  }
  return dir.path;
}

Map<String, Map<String, int>> _readExisting(File file) {
  if (!file.existsSync()) {
    return const <String, Map<String, int>>{};
  }
  final hosts = json.decode(file.readAsStringSync()) as Map<String, Object?>;
  return hosts.map(
    (String host, Object? files) => MapEntry<String, Map<String, int>>(
      host,
      Map<String, int>.from(files! as Map<String, Object?>),
    ),
  );
}

/// Names of all builders in the `flutter/prod` bucket.
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

const String _integrationShard = 'packages/flutter_tools/test/integration.shard/';

/// Whole seconds per `integration.shard` file in [invocation], keyed by path
/// relative to `packages/flutter_tools`.
Future<Map<String, int>> _fileDurations(String invocation) async {
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
            when file.startsWith(_integrationShard)) {
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
