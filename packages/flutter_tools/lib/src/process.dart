// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.process');

// This runs the command and streams stdout/stderr from the child process to this process' stdout/stderr.
Future<int> runCommandAndStreamOutput(String command, List<String> args) async {
  _logging.fine("Starting ${command} with args: ${args}");
  Process proc = await Process.start(command, args);
  proc.stdout.transform(UTF8.decoder).listen((data) {
    stdout.write(data);
  });
  proc.stderr.transform(UTF8.decoder).listen((data) {
    stderr.write(data);
  });
  return proc.exitCode;
}
