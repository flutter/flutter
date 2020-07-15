// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core' as core_internals show print;
import 'dart:core' hide print;
import 'dart:io' as io_internals show exit;
import 'dart:io' hide exit;

final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String green = hasColor ? '\x1B[32m' : ''; // used for section titles, commands
final String yellow = hasColor ? '\x1B[33m' : ''; // used for skips
final String cyan = hasColor ? '\x1B[36m' : ''; // used for paths
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks
final String reset = hasColor ? '\x1B[0m' : '';

class ExitException implements Exception {
  ExitException(this.exitCode);

  final int exitCode;

  void apply() {
    io_internals.exit(exitCode);
  }
}

// We actually reimplement exit() so that it uses exceptions rather
// than truly immediately terminating the application, so that we can
// test the exit code in unit tests (see test/analyze_test.dart).
void exit(int exitCode) {
  throw ExitException(exitCode);
}

void exitWithError(List<String> messages) {
  final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';
  print(redLine);
  messages.forEach(print);
  print(redLine);
  exit(1);
}

typedef PrintCallback = void Function(Object line);

// Allow print() to be overridden, for tests.
PrintCallback print = core_internals.print;

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
         '${now.hour.toString().padLeft(2, "0")}:'
         '${now.minute.toString().padLeft(2, "0")}:'
         '${now.second.toString().padLeft(2, "0")}'
         '▐$reset';
}

String prettyPrintDuration(Duration duration) {
  String result = '';
  final int minutes = duration.inMinutes;
  if (minutes > 0)
    result += '${minutes}min ';
  final int seconds = duration.inSeconds - minutes * 60;
  final int milliseconds = duration.inMilliseconds - (seconds * 1000 + minutes * 60 * 1000);
  result += '$seconds.${milliseconds.toString().padLeft(3, "0")}s';
  return result;
}

void printProgress(String action, String workingDir, String command) {
  print('$clock $action: cd $cyan$workingDir$reset; $green$command$reset');
}
