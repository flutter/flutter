// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

void Function(LogRecord) stdIOLogListener({bool assumeTty, bool verbose}) =>
    (record) => overrideAnsiOutput(assumeTty == true || ansiOutputEnabled, () {
          _stdIOLogListener(record, verbose: verbose ?? false);
        });

StringBuffer colorLog(LogRecord record, {bool verbose}) {
  AnsiCode color;
  if (record.level < Level.WARNING) {
    color = cyan;
  } else if (record.level < Level.SEVERE) {
    color = yellow;
  } else {
    color = red;
  }
  final level = color.wrap('[${record.level}]');
  final eraseLine = ansiOutputEnabled && !verbose ? '\x1b[2K\r' : '';
  var lines = <Object>[
    '$eraseLine$level ${_recordHeader(record, verbose)}${record.message}'
  ];

  if (record.error != null) {
    lines.add(record.error);
  }

  if (record.stackTrace != null && verbose) {
    var trace = Trace.from(record.stackTrace).foldFrames((f) {
      return f.package == 'build_runner' || f.package == 'build';
    }, terse: true);

    lines.add(trace);
  }

  var message = StringBuffer(lines.join('\n'));

  // We always add an extra newline at the end of each message, so it
  // isn't multiline unless we see > 2 lines.
  var multiLine = LineSplitter.split(message.toString()).length > 2;

  if (record.level > Level.INFO || !ansiOutputEnabled || multiLine || verbose) {
    // Add an extra line to the output so the last line isn't written over.
    message.writeln('');
  }
  return message;
}

void _stdIOLogListener(LogRecord record, {bool verbose}) =>
    stdout.write(colorLog(record, verbose: verbose));

/// Filter out the Logger names which aren't coming from specific builders and
/// splits the header for levels >= WARNING.
String _recordHeader(LogRecord record, bool verbose) {
  var maybeSplit = record.level >= Level.WARNING ? '\n' : '';
  return verbose || record.loggerName.contains(' ')
      ? '${record.loggerName}:$maybeSplit'
      : '';
}
