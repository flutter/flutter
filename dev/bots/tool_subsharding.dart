// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

class TestSpecs {

  TestSpecs({
    required this.path,
    required this.startTime,
  });

  final String path;
  int startTime;
  int? _endTime;

  int get milliseconds {
    return endTime - startTime;
  }

  set endTime(int value) {
    _endTime = value;
  }

  int get endTime {
    if (_endTime == null) {
      return 0;
    }
    return _endTime!;
  }

  String toJson() {
    return json.encode(
      <String, String>{'path': path, 'runtime': milliseconds.toString()}
    );
  }
}

/// Intended to parse the output file of `dart test --file-reporter json:file_name
Map<int, TestSpecs> generateMetrics(File metrics) {
  final Map<int, TestSpecs> allTestSpecs = <int, TestSpecs>{};
  if (!metrics.existsSync()) {
    return allTestSpecs;
  }

  bool success = false;
  for(final String metric in metrics.readAsLinesSync()) {
    final Map<String, dynamic> entry = json.decode(metric) as Map<String, dynamic>;
    if (entry.containsKey('suite')) {
      final Map<dynamic, dynamic> suite = entry['suite'] as Map<dynamic, dynamic>;
      allTestSpecs[suite['id'] as int] = TestSpecs(
        path: suite['path'] as String,
        startTime: entry['time'] as int,
      );
    } else if (_isMetricDone(entry, allTestSpecs)) {
      final Map<dynamic, dynamic> group = entry['group'] as Map<dynamic, dynamic>;
      final int suiteID = group['suiteID'] as int;
      final TestSpecs testSpec = allTestSpecs[suiteID]!;
      testSpec.endTime = entry['time'] as int;
    } else if (entry.containsKey('success') && entry['success'] == true) {
      success = true;
    }
  }

  if (!success) { // means that not all tests succeeded therefore no metrics are stored
    return <int, TestSpecs>{};
  }
  return allTestSpecs;
}

bool _isMetricDone(Map<String, dynamic> entry, Map<int, TestSpecs> allTestSpecs) {
  if (entry.containsKey('group') && entry['type'] as String == 'group') {
    final Map<dynamic, dynamic> group = entry['group'] as Map<dynamic, dynamic>;
    return allTestSpecs.containsKey(group['suiteID'] as int);
  }
  return false;
}
