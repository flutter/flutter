// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

CommandRunner<Null> createTestCommandRunner([FlutterCommand command]) {
  FlutterCommandRunner runner  = new FlutterCommandRunner();
  if (command != null)
    runner.addCommand(command);
  return runner;
}
