// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

// the numbers below are odd, so that the totals don't seem round. :-)
const double todoCost = 1009.0; // about two average SWE days, in dollars
const double ignoreCost = 2003.0; // four average SWE days, in dollars
const double pythonCost = 3001.0; // six average SWE days, in dollars
const double skipCost = 2473.0; // 20 hours: 5 to fix the issue we're ignoring, 15 to fix the bugs we missed because the test was off
const double ignoreForFileCost = 2477.0; // similar thinking as skipCost
const double asDynamicCost = 2003.0; // same as ignoring analyzer warning

final RegExp todoPattern = RegExp(r'(?://|#) *TODO');
final RegExp ignorePattern = RegExp(r'// *ignore:');
final RegExp ignoreForFilePattern = RegExp(r'// *ignore_for_file:');
final RegExp asDynamicPattern = RegExp(r'as dynamic');

Future<double> findCostsForFile(File file) async {
  if (path.extension(file.path) == '.py')
    return pythonCost;
  if (path.extension(file.path) != '.dart' &&
      path.extension(file.path) != '.yaml' &&
      path.extension(file.path) != '.sh')
    return 0.0;
  final bool isTest = file.path.endsWith('_test.dart');
  double total = 0.0;
  for (String line in await file.readAsLines()) {
    if (line.contains(todoPattern))
      total += todoCost;
    if (line.contains(ignorePattern))
      total += ignoreCost;
    if (line.contains(ignoreForFilePattern))
      total += ignoreForFileCost;
    if (line.contains(asDynamicPattern))
      total += asDynamicCost;
    if (isTest && line.contains('skip:'))
      total += skipCost;
  }
  return total;
}

Future<double> findCostsForRepo() async {
  final Process git = await startProcess(
    'git',
    <String>['ls-files', '--full-name', flutterDirectory.path],
    workingDirectory: flutterDirectory.path,
  );
  double total = 0.0;
  await for (String entry in git.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()))
    total += await findCostsForFile(File(path.join(flutterDirectory.path, entry)));
  final int gitExitCode = await git.exitCode;
  if (gitExitCode != 0)
    throw Exception('git exit with unexpected error code $gitExitCode');
  return total;
}

Future<int> countDependencies() async {
  final List<String> lines = (await evalFlutter(
    'update-packages',
    options: <String>['--transitive-closure'],
  )).split('\n');
  final int count = lines.where((String line) => line.contains('->')).length;
  if (count < 2) // we'll always have flutter and flutter_test, at least...
    throw Exception('"flutter update-packages --transitive-closure" returned bogus output:\n${lines.join("\n")}');
  return count;
}

Future<int> countConsumerDependencies() async {
  final List<String> lines = (await evalFlutter(
    'update-packages',
    options: <String>['--transitive-closure', '--consumer-only'],
  )).split('\n');
  final int count = lines.where((String line) => line.contains('->')).length;
  if (count < 2) // we'll always have flutter and flutter_test, at least...
    throw Exception('"flutter update-packages --transitive-closure" returned bogus output:\n${lines.join("\n")}');
  return count;
}

const String _kCostBenchmarkKey = 'technical_debt_in_dollars';
const String _kNumberOfDependenciesKey = 'dependencies_count';
const String _kNumberOfConsumerDependenciesKey = 'consumer_dependencies_count';

Future<void> main() async {
  await task(() async {
    return TaskResult.success(
      <String, dynamic>{
        _kCostBenchmarkKey: await findCostsForRepo(),
        _kNumberOfDependenciesKey: await countDependencies(),
        _kNumberOfConsumerDependenciesKey: await countConsumerDependencies(),
      },
      benchmarkScoreKeys: <String>[
        _kCostBenchmarkKey,
        _kNumberOfDependenciesKey,
        _kNumberOfConsumerDependenciesKey,
      ],
    );
  });
}
