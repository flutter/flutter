// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

CommandRunner<Null> createTestCommandRunner([FlutterCommand command]) {
  final FlutterCommandRunner runner  = new FlutterCommandRunner();
  if (command != null)
    runner.addCommand(command);
  return runner;
}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(String path,
                                DateTime baseTime,
                                int seconds) {
  final DateTime modificationTime = baseTime.add(new Duration(seconds: seconds));
  fs.file(path).setLastModifiedSync(modificationTime);
}

/// Matcher for functions that throw ToolExit.
Matcher throwsToolExit([int exitCode]) {
  return exitCode == null
    ? throwsA(isToolExit)
    : throwsA(allOf(isToolExit, (ToolExit e) => e.exitCode == exitCode));
}

/// Matcher for [ToolExit]s.
const Matcher isToolExit = const isInstanceOf<ToolExit>();
