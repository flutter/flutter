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
}

class TestSpecsCluster {
  TestSpecsCluster(this.maxSize);
  List<TestSpecs> allTestSpecs = <TestSpecs>[];
  final int maxSize;
  int currentSize = 0;

  bool get isEmpty {
    return allTestSpecs.isEmpty;
  }

  List<String> get paths {
    final List<String> allPaths = <String>[];
    for (final TestSpecs testSpecs in allTestSpecs) {
      allPaths.add(testSpecs.path);
    }
    return allPaths;
  }

  bool canFit(TestSpecs testSpecs) {
    return testSpecs.milliseconds + currentSize <= maxSize;
  }

  void addTestSpecs(TestSpecs testSpecs) {
    allTestSpecs.add(testSpecs);
    currentSize += testSpecs.milliseconds;
  }
}

List<TestSpecsCluster> buildClusters(List<TestSpecs> allFileSpecs) {
  int totalRunTime = 0;
  for (final TestSpecs fileSpec in allFileSpecs) {
    totalRunTime += fileSpec.milliseconds;
  }
  final double averageRunTime = totalRunTime / allFileSpecs.length;
  final int maxSize = (averageRunTime * 5).round();
  final List<TestSpecsCluster> allClusters = <TestSpecsCluster>[TestSpecsCluster(maxSize)];

  for (final TestSpecs testSpecs in allFileSpecs) {
    final TestSpecsCluster lastCluster = allClusters.last;
    if (lastCluster.isEmpty || lastCluster.canFit(testSpecs)) {
      lastCluster.addTestSpecs(testSpecs);
    } else {
      final TestSpecsCluster newCluster = TestSpecsCluster(maxSize);
      newCluster.addTestSpecs(testSpecs);
      allClusters.add(newCluster);
    }
  }

  return allClusters;
}

List<TestSpecsCluster> makeClusters(List<dynamic> shardResult) {
  final List<TestSpecs> allFileSpecs = <TestSpecs>[];
  final List<TestSpecsCluster> allClusters = buildClusters(allFileSpecs);
  return allClusters;
}

void addTestsToMap(String shardName, List<TestSpecsCluster> testClusters, Map<String, dynamic> map) {
  final List<List<String>> allPaths = <List<String>>[];
  for (final TestSpecsCluster testCluster in testClusters) {
    allPaths.add(testCluster.paths);
  }
  map[shardName] = allPaths;
}

void toolSubSharding(List<String> shards) {
  final File doc = File('test_results.json');

  final Map<String, dynamic> testResults = json.decode(doc.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> map = <String, dynamic>{};
  for (final String shardName in testResults.keys) {
    final List<dynamic> shardResult = testResults[shardName] as List<dynamic>;
    final List<TestSpecsCluster> testClusters = makeClusters(shardResult);
    addTestsToMap(shardName, testClusters, map);
  }

  final String jsonOutput = json.encode(map);
  final File output = File('output.json');
  output.createSync();
  output.writeAsStringSync(jsonOutput);
}

void writeJsonTestsSubShardFile(Map<String, dynamic> map, String fileName) {
  final String jsonOutput = json.encode(map);
  final File output = File(fileName);
  output.createSync();
  output.writeAsStringSync(jsonOutput);
}

Map<String, dynamic> readJsonTestsSubShardFile(String fileName) {
  final File file = File(fileName);
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Intended to parse the output file of `dart test --file-reporter json:file_name
Map<int, TestSpecs> generateMetrics(File metrics) {
  final Map<int, TestSpecs> allTestSpecs = <int, TestSpecs>{};
  if (!metrics.existsSync()) {
    print('failed');
    return allTestSpecs;
  }
  bool success = false;
  print('lines');
  print(metrics.readAsLinesSync().length);

  for(final String metric in metrics.readAsLinesSync()) {
    final Map<String, dynamic> entry = json.decode(metric) as Map<String, dynamic>;
    if (entry.containsKey('suite')) {
      final Map<dynamic, dynamic> suite = entry['suite'] as Map<dynamic, dynamic>;
      allTestSpecs[suite['id'] as int] = TestSpecs(
        path: suite['path'] as String,
        startTime: entry['time'] as int,
      );
    } else if (isMetricDone(entry, allTestSpecs)) {
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

bool isMetricDone(Map<String, dynamic> entry, Map<int, TestSpecs> allTestSpecs) {
  if (entry.containsKey('group') && entry['type'] as String == 'group') {
    final Map<dynamic, dynamic> group = entry['group'] as Map<dynamic, dynamic>;
    return allTestSpecs.containsKey(group['suiteID'] as int);
  }
  return false;
}
