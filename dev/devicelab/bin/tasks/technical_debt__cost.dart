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
const double pythonCost = 3001.0; //  six average SWE days, in dollars

final RegExp todoPattern = new RegExp(r'(?://|#) *TODO');
final RegExp ignorePattern = new RegExp(r'// *ignore:');

Stream<double> findCostsForFile(File file) {
  if (path.extension(file.path) == '.py')
    return new Stream<double>.fromIterable(<double>[pythonCost]);
  if (path.extension(file.path) != '.dart' &&
      path.extension(file.path) != '.yaml' &&
      path.extension(file.path) != '.sh')
    return null;
  StreamController<double> result = new StreamController<double>();
  file.openRead().transform(UTF8.decoder).transform(const LineSplitter()).listen((String line) {
    if (line.contains(todoPattern))
      result.add(todoCost);
    if (line.contains(ignorePattern))
      result.add(ignoreCost);
  }, onDone: () { result.close(); });
  return result.stream;
}

Stream<double> findCostsForDirectory(Directory directory, Set<String> gitFiles) {
  StreamController<double> result = new StreamController<double>();
  Set<StreamSubscription<dynamic>> subscriptions = new Set<StreamSubscription<dynamic>>();

  void checkDone(StreamSubscription<dynamic> subscription, String path) {
    subscriptions.remove(subscription);
    if (subscriptions.isEmpty)
      result.close();
  }

  StreamSubscription<FileSystemEntity> listSubscription;
  subscriptions.add(listSubscription = directory.list(followLinks: false).listen((FileSystemEntity entity) {
    String name = path.relative(entity.path, from: flutterDirectory.path);
    if (gitFiles.contains(name)) {
      if (entity is File) {
        StreamSubscription<double> subscription;
        subscription = findCostsForFile(entity)?.listen((double cost) {
          result.add(cost);
        }, onDone: () { checkDone(subscription, name); });
        if (subscription != null)
          subscriptions.add(subscription);
      } else if (entity is Directory) {
        StreamSubscription<double> subscription;
        subscription = findCostsForDirectory(entity, gitFiles)?.listen((double cost) {
          result.add(cost);
        }, onDone: () { checkDone(subscription, name); });
        if (subscription != null)
          subscriptions.add(subscription);
      }
    }
  }, onDone: () { checkDone(listSubscription, directory.path); }));
  return result.stream;
}

const String _kBenchmarkKey = 'technical_debt_in_dollars';

Future<Null> main() async {
  await task(() async {
    Process git = await startProcess(
      'git',
      <String>['ls-files', '--full-name', flutterDirectory.path],
      workingDirectory: flutterDirectory.path,
    );
    Set<String> gitFiles = new Set<String>();
    await for (String entry in git.stdout.transform(UTF8.decoder).transform(const LineSplitter())) {
      String subentry = '';
      for (String component in path.split(entry)) {
        if (subentry.isNotEmpty)
          subentry += path.separator;
        subentry += component;
        gitFiles.add(subentry);
      }
    }
    int gitExitCode = await git.exitCode;
    if (gitExitCode != 0)
      throw new Exception('git exit with unexpected error code $gitExitCode');
    List<double> costs = await findCostsForDirectory(flutterDirectory, gitFiles).toList();
    double total = costs.fold(0.0, (double total, double cost) => total + cost);
    return new TaskResult.success(
      <String, dynamic>{_kBenchmarkKey: total},
      benchmarkScoreKeys: <String>[_kBenchmarkKey],
    );
  });
}
