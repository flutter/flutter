// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'common.dart';
import 'constants.dart';

const String _kTimeUnitKey = 'time_unit';

const List<String> _kNonNumericalValueSubResults = <String>[
  kNameKey,
  _kTimeUnitKey,
  'aggregate_name',
  'aggregate_unit',
  'error_message',
  'family_index',
  'per_family_instance_index',
  'label',
  'run_name',
  'run_type',
  'repetitions',
  'repetition_index',
  'threads',
  'iterations',
  'big_o',
];

// Context has some keys such as 'host_name' which need to be ignored
// so that we can group series together
const List<String> _kContextIgnoreKeys = <String>[
  'host_name',
  'load_avg',
  'caches',
];

// ignore: avoid_classes_with_only_static_members
/// Parse the json result of https://github.com/google/benchmark.
class GoogleBenchmarkParser {
  /// Given a Google benchmark json output, parse its content into a list of [MetricPoint].
  static Future<List<MetricPoint>> parse(String jsonFileName) async {
    final Map<String, dynamic> jsonResult =
        jsonDecode(File(jsonFileName).readAsStringSync())
            as Map<String, dynamic>;

    final Map<String, dynamic> rawContext =
        jsonResult['context'] as Map<String, dynamic>;
    final Map<String, String> context = rawContext.map<String, String>(
      (String k, dynamic v) => MapEntry<String, String>(k, v.toString()),
    )..removeWhere((String k, String v) => _kContextIgnoreKeys.contains(k));

    final List<MetricPoint> points = <MetricPoint>[];
    for (final dynamic item in jsonResult['benchmarks']) {
      _parseAnItem(item as Map<String, dynamic>, points, context);
    }
    return points;
  }
}

void _parseAnItem(
  Map<String, dynamic> item,
  List<MetricPoint> points,
  Map<String, String> context,
) {
  final String name = item[kNameKey] as String;
  final Map<String, String> timeUnitMap = <String, String>{
    kUnitKey: item[_kTimeUnitKey] as String
  };
  for (final String subResult in item.keys) {
    if (!_kNonNumericalValueSubResults.contains(subResult)) {
      num? rawValue;
      try {
        rawValue = item[subResult] as num?;
      } catch (e) {
        print(
            '$subResult: ${item[subResult]} (${item[subResult].runtimeType}) is not a number');
        rethrow;
      }

      final double? value =
          rawValue is int ? rawValue.toDouble() : rawValue as double?;
      points.add(
        MetricPoint(
          value,
          <String, String?>{kNameKey: name, kSubResultKey: subResult}
            ..addAll(context)
            ..addAll(
                subResult.endsWith('time') ? timeUnitMap : <String, String>{}),
        ),
      );
    }
  }
}
