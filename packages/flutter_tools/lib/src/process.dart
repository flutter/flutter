// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.process');

/// This runs the command and streams stdout/stderr from the child process to
/// this process' stdout/stderr.
Future<int> runCommandAndStreamOutput(List<String> cmd,
    {String prefix: ''}) async {
  _logging.info(cmd.join(' '));
  Process proc =
      await Process.start(cmd[0], cmd.getRange(1, cmd.length).toList());
  proc.stdout.transform(UTF8.decoder).listen((data) {
    stdout.write('$prefix${data.trimRight().split('\n').join('\n$prefix')}\n');
  });
  proc.stderr.transform(UTF8.decoder).listen((data) {
    stderr.write('$prefix${data.trimRight().split('\n').join('\n$prefix')}\n');
  });
  return proc.exitCode;
}

Future runAndKill(List<String> cmd, Duration timeout) async {
  _logging.info(cmd.join(' '));
  Future<Process> proc = Process.start(
      cmd[0], cmd.getRange(1, cmd.length).toList(),
      mode: ProcessStartMode.DETACHED);

  return new Future.delayed(timeout, () async {
    _logging.info('Intentionally killing ${cmd[0]}');
    Process.killPid((await proc).pid);
  });
}

/// Run cmd and return stdout.
/// Throws an error if cmd exits with a non-zero value.
String runCheckedSync(List<String> cmd) =>
    _runWithLoggingSync(cmd, checked: true);

/// Run cmd and return stdout.
String runSync(List<String> cmd) => _runWithLoggingSync(cmd);

String _runWithLoggingSync(List<String> cmd, {bool checked: false}) {
  _logging.info(cmd.join(' '));
  ProcessResult results =
      Process.runSync(cmd[0], cmd.getRange(1, cmd.length).toList());
  if (results.exitCode != 0) {
    String errorDescription = 'Error code ${results.exitCode} '
        'returned when attempting to run command: ${cmd.join(' ')}';
    _logging.fine(errorDescription);
    if (results.stderr.length > 0) {
      _logging.info('Errors logged: ${results.stderr.trim()}');
    }

    if (checked) {
      throw errorDescription;
    }
  }
  _logging.fine(results.stdout.trim());
  return results.stdout;
}
