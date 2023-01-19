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

class TestFileReporterResults {
  final Map<int, TestSpecs> allTestSpecs = <int, TestSpecs>{};
  bool hasFailedTests = true;
  String error = '';

  void addTestSpec(Map<dynamic, dynamic> suite, int time) {
    allTestSpecs[suite['id'] as int] = TestSpecs(
      path: suite['path'] as String,
      startTime: time,
    );
  }

  void addMetricDone(int suiteID, int time) {
    final TestSpecs testSpec = allTestSpecs[suiteID]!;
    testSpec.endTime = time;
  }

  bool isMetricDone(Map<String, dynamic> entry) {
    if (entry.containsKey('group') && entry['type'] as String == 'group') {
      final Map<dynamic, dynamic> group = entry['group'] as Map<dynamic, dynamic>;
      return allTestSpecs.containsKey(group['suiteID'] as int);
    }
    return false;
  }
}

/// Intended to parse the output file of `dart test --file-reporter json:file_name
TestFileReporterResults parseFileReporter(File metrics) {
  final TestFileReporterResults results = TestFileReporterResults();
  if (!metrics.existsSync()) {
    return results;
  }

  for(final String metric in metrics.readAsLinesSync()) {
    final Map<String, dynamic> entry = json.decode(metric) as Map<String, dynamic>;
    if (entry.containsKey('suite')) {
      final Map<dynamic, dynamic> suite = entry['suite'] as Map<dynamic, dynamic>;
      results.addTestSpec(suite, entry['time'] as int);
    } else if (results.isMetricDone(entry)) {
      final Map<dynamic, dynamic> group = entry['group'] as Map<dynamic, dynamic>;
      final int suiteID = group['suiteID'] as int;
      results.addMetricDone(suiteID, entry['time'] as int);
    } else if (entry.containsKey('error') && entry.containsKey('stackTrace')) {
      results.error = '${entry['error']}\n ${entry['stackTrace']}';
    } else if (entry.containsKey('success') && entry['success'] == true) {
      results.hasFailedTests = false;
    }
  }
  return results;
}
