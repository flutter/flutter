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
const double asDynamicCost = 2003.0; // same as ignoring analyzer warning

final RegExp todoPattern = new RegExp(r'(?://|#) *TODO');
final RegExp ignorePattern = new RegExp(r'// *ignore:');
final RegExp asDynamicPattern = new RegExp(r'as dynamic');

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
    if (line.contains(asDynamicPattern))
      total += asDynamicCost;
    if (isTest && line.contains('skip:'))
      total += skipCost;
  }
  return total;
}

const String _kBenchmarkKey = 'technical_debt_in_dollars';

Future<Null> main() async {
  await task(() async {
    final Process git = await startProcess(
      'git',
      <String>['ls-files', '--full-name', flutterDirectory.path],
      workingDirectory: flutterDirectory.path,
    );
    double total = 0.0;
    await for (String entry in git.stdout.transform(utf8.decoder).transform(const LineSplitter()))
      total += await findCostsForFile(new File(path.join(flutterDirectory.path, entry)));
    final int gitExitCode = await git.exitCode;
    if (gitExitCode != 0)
      throw new Exception('git exit with unexpected error code $gitExitCode');
    return new TaskResult.success(
      <String, dynamic>{_kBenchmarkKey: total},
      benchmarkScoreKeys: <String>[_kBenchmarkKey],
    );
  });
}
