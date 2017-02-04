// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

CommandRunner<Null> createTestCommandRunner([FlutterCommand command]) {
  FlutterCommandRunner runner  = new FlutterCommandRunner();
  if (command != null)
    runner.addCommand(command);
  return runner;
}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(String path,
                                DateTime baseTime,
                                int seconds) {
  DateTime modificationTime = baseTime.add(new Duration(seconds: seconds));
  String argument =
      '${modificationTime.year}'
      '${modificationTime.month.toString().padLeft(2, "0")}'
      '${modificationTime.day.toString().padLeft(2, "0")}'
      '${modificationTime.hour.toString().padLeft(2, "0")}'
      '${modificationTime.minute.toString().padLeft(2, "0")}'
      '.${modificationTime.second.toString().padLeft(2, "0")}';
  ProcessManager processManager = context[ProcessManager];
  processManager.runSync(<String>['touch', '-t', argument, path]);
}

/// Matcher for functions that throw ToolExit.
Matcher throwsToolExit([int exitCode]) {
  return exitCode == null
    ? const Throws(isToolExit)
    : new Throws(allOf(isToolExit, (ToolExit e) => e.exitCode == exitCode));
}

/// Matcher for [ToolExit]s.
const Matcher isToolExit = const isInstanceOf<ToolExit>();
