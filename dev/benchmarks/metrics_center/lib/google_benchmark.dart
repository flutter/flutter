// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file uses Dart 2.12 semantics. This is needed as we can't upgrade
// the SDK constraint to `>=2.12.0-0` before the deps are ready.
// @dart=2.12

import 'dart:convert';
import 'dart:io';

import 'package:metrics_center/src/common.dart';

const String _kTimeUnitKey = 'time_unit';

const List<String> _kNonNumericalValueSubResults = <String>[
  kNameKey,
  _kTimeUnitKey,
  'iterations',
  'big_o',
];

/// Parse the json result of https://github.com/google/benchmark.
class GoogleBenchmarkParser {
  /// Given a Google benchmark json output, parse its content into a list of [MetricPoint].
  static Future<List<MetricPoint>> parse(String jsonFileName) async {
    final Map<String, dynamic> jsonResult =
        jsonDecode(File(jsonFileName).readAsStringSync())
            as Map<String, dynamic>;

    final Map<String, dynamic> rawContext = jsonResult['context'] as Map<String, dynamic>;
    final Map<String, String> context = rawContext.map<String, String>(
      (String k, dynamic v) => MapEntry<String, String>(k, v.toString()),
    );
    final List<MetricPoint> points = <MetricPoint>[];
    for (final Map<String, dynamic> item in jsonResult['benchmarks']) {
      _parseAnItem(item, points, context);
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
      num rawValue;
      try {
        rawValue = item[subResult] as num;
      } catch (e) {
        print('$subResult: ${item[subResult]} (${item[subResult].runtimeType}) is not a number');
        rethrow;
      }

      final double value = rawValue is int ? rawValue.toDouble() : rawValue as double;
      points.add(
        MetricPoint(
          value,
          <String, String>{kNameKey: name, kSubResultKey: subResult}
            ..addAll(context)
            ..addAll(subResult.endsWith('time') ? timeUnitMap : <String, String>{}),
        ),
      );
    }
  }
}
