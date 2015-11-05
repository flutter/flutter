// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.process');

/// This runs the command and streams stdout/stderr from the child process to
/// this process' stdout/stderr.
Future<int> runCommandAndStreamOutput(List<String> cmd,
    {String prefix: '', RegExp filter}) async {
  _logging.info(cmd.join(' '));
  Process proc =
      await Process.start(cmd[0], cmd.getRange(1, cmd.length).toList());
  proc.stdout.transform(UTF8.decoder).listen((String data) {
    List<String> dataLines = data.trimRight().split('\n');
    if (filter != null) {
      dataLines = dataLines.where((String s) => filter.hasMatch(s)).toList();
    }
    if (dataLines.length > 0) {
      stdout.write('$prefix${dataLines.join('\n$prefix')}\n');
    }
  });
  proc.stderr.transform(UTF8.decoder).listen((String data) {
    List<String> dataLines = data.trimRight().split('\n');
    if (filter != null) {
      dataLines = dataLines.where((String s) => filter.hasMatch(s));
    }
    if (dataLines.length > 0) {
      stderr.write('$prefix${dataLines.join('\n$prefix')}\n');
    }
  });
  return proc.exitCode;
}

Future runAndKill(List<String> cmd, Duration timeout) async {
  Future<Process> proc = runDetached(cmd);
  return new Future.delayed(timeout, () async {
    _logging.info('Intentionally killing ${cmd[0]}');
    Process.killPid((await proc).pid);
  });
}

Future<Process> runDetached(List<String> cmd) async {
  _logging.info(cmd.join(' '));
  Future<Process> proc = Process.start(
      cmd[0], cmd.getRange(1, cmd.length).toList(),
      mode: ProcessStartMode.DETACHED);
  return proc;
}

/// Run cmd and return stdout.
/// Throws an error if cmd exits with a non-zero value.
String runCheckedSync(List<String> cmd) =>
    _runWithLoggingSync(cmd, checked: true);

/// Run cmd and return stdout.
String runSync(List<String> cmd) => _runWithLoggingSync(cmd);

/// Return the platform specific name for the given Dart SDK binary. So, `pub`
/// ==> `pub.bat`.
String sdkBinaryName(String name) {
  return Platform.isWindows ? '${name}.bat' : name;
}

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

class ProcessExit implements Exception {
  final int exitCode;
  ProcessExit(this.exitCode);
  String get message => 'ProcessExit: ${exitCode}';
  String toString() => message;
}
