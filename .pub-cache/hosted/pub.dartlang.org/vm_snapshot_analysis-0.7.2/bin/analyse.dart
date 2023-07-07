#!/usr/bin/env dart

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:vm_snapshot_analysis/src/commands/compare.dart';
import 'package:vm_snapshot_analysis/src/commands/explain.dart';
import 'package:vm_snapshot_analysis/src/commands/summary.dart';
import 'package:vm_snapshot_analysis/src/commands/treemap.dart';

final _executableName = () {
  // There is no reliable way to detect executable name across different modes
  // of running this script. This code handles two most common ways:
  //
  //   * Running from source
  //   * Running a wrapper script created by
  //
  //               pub global activate vm_snapshot_analysis
  //
  // Note that this does not properly handle the case of installing this
  // package from path (pub global activate --source path ...), but
  // we consider that uncommon.
  final scriptName = Platform.script.pathSegments.last;
  if (scriptName.endsWith('.dart')) {
    return scriptName;
  }
  return 'snapshot_analysis';
}();

final runner = CommandRunner(
    _executableName, 'Tools for binary size analysis of Dart VM AOT snapshots.')
  ..addCommand(TreemapCommand())
  ..addCommand(CompareCommand())
  ..addCommand(SummaryCommand())
  ..addCommand(ExplainCommand());

void main(List<String> args) async {
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e.toString());
  }
}
