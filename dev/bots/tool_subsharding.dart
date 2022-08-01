// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

class TestSpecs {

  TestSpecs({
    required this.path,
    required this.milliseconds,
    required this.success,
  });

  factory TestSpecs.fromMap(Map<String, dynamic> entry) {
    final String path = entry['path'] as String;
    final int milliseconds = entry['ms'] as int;
    final bool success = entry['success'] as bool;

    return TestSpecs(path: path, milliseconds: milliseconds, success: success);
  }

  final String path;
  final int milliseconds;
  final bool success;

  static TestSpecs get empty {
    return TestSpecs(path: '', milliseconds: 0, success: false);
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
  for (final dynamic entry in shardResult) {
    allFileSpecs.add(TestSpecs.fromMap(entry as Map<String, dynamic>));
  }
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
