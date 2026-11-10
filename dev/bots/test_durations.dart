// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shared by the update_*_test_durations.dart scripts: per-test durations from
// ResultDB, written as `{group: {file: seconds}}`.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Whole seconds per test file.
typedef DurationsByFile = Map<String, int>;

/// [DurationsByFile] per group (host, renderer, ...).
typedef DurationsByGroup = Map<String, DurationsByFile>;

const String _buildbucket = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.';
const String _resultdb = 'https://results.api.luci.app/prpc/luci.resultdb.v1.';

/// Reads Buildbucket and ResultDB. No auth needed.
class TestDurationSampler {
  final http.Client _client = http.Client();

  void close() => _client.close();

  /// Names of all builders in the `flutter/prod` bucket.
  ///
  /// The local .ci.yaml may not match prod, so ask Buildbucket.
  Future<List<String>> listProdBuilders() async {
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

  /// Median seconds per file over the last [builds] successful builds of
  /// [builders]. [keyFor] maps a repo-relative test file to its key, or null to
  /// skip it.
  Future<DurationsByFile> sampleDurations(
    List<String> builders,
    int builds, {
    required String? Function(String moduleName) keyFor,
  }) async {
    final samples = <String, List<int>>{};
    for (final builder in builders..sort()) {
      stderr.writeln('Fetching $builds builds of $builder');
      for (final String invocation in await _recentInvocations(builder, builds)) {
        final DurationsByFile fileDurations = await _fileDurations(invocation, keyFor);
        for (final MapEntry(key: file, value: seconds) in fileDurations.entries) {
          samples.putIfAbsent(file, () => <int>[]).add(seconds);
        }
      }
    }
    return <String, int>{
      for (final MapEntry(key: file, value: seconds) in samples.entries) file: median(seconds),
    };
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
          if (build case {'infra': {'resultdb': {'invocation': final String invocation}}})
            invocation,
    ];
  }

  /// Whole seconds per file in [invocation], keyed by [keyFor].
  Future<DurationsByFile> _fileDurations(
    String invocation,
    String? Function(String moduleName) keyFor,
  ) async {
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
          if (result case {
            'testIdStructured': {'moduleName': final String file},
            'duration': final String duration,
          }) {
            final String? key = keyFor(file);
            if (key != null) {
              seconds[key] =
                  (seconds[key] ?? 0) + double.parse(duration.substring(0, duration.length - 1));
            }
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
}

/// Exactly [localFiles] per group. Unsampled files get 0 if another group
/// sampled them, else the previous value, else the group's median.
DurationsByGroup reconcile(
  DurationsByGroup sampled,
  List<String> localFiles,
  DurationsByGroup previous,
) {
  final sampledAnywhere = <String>{for (final DurationsByFile m in sampled.values) ...m.keys};
  final result = <String, DurationsByFile>{};
  for (final MapEntry(key: group, value: durations) in sampled.entries) {
    final int groupMedian = median(durations.values.toList());
    result[group] = <String, int>{
      for (final String f in localFiles)
        f: durations[f] ?? (sampledAnywhere.contains(f) ? 0 : previous[group]?[f] ?? groupMedian),
    };
  }
  return <String, DurationsByFile>{
    for (final String group in result.keys.toList()..sort()) group: result[group]!,
  };
}

DurationsByGroup readDurations(File file) {
  if (!file.existsSync()) {
    return const <String, DurationsByFile>{};
  }
  final groups = json.decode(file.readAsStringSync()) as Map<String, Object?>;
  return groups.map(
    (String group, Object? files) => MapEntry<String, DurationsByFile>(
      group,
      Map<String, int>.from(files! as Map<String, Object?>),
    ),
  );
}

/// Writes [durations] to [file], sorted.
void writeDurations(File file, DurationsByGroup durations) {
  final sorted = <String, DurationsByFile>{
    for (final String group in durations.keys.toList()..sort())
      group: <String, int>{
        for (final file in durations[group]!.keys.toList()..sort()) file: durations[group]![file]!,
      },
  };
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
  stderr.writeln('Wrote ${file.path} (${sorted.values.first.length} files)');
}

int median(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  final List<int> sorted = values.toList()..sort();
  return sorted[sorted.length ~/ 2];
}
