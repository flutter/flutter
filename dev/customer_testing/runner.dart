// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

final RegExp _spaces = RegExp(r' +');

Future<bool> shell(String command, Directory directory, { bool verbose = false, bool silentFailure = false }) async {
  if (verbose)
    print('>> $command');
  Process process;
  if (Platform.isWindows) {
    process = await Process.start('CMD.EXE', <String>['/S', '/C', command], workingDirectory: directory.path);
  } else {
    final List<String> segments = command.trim().split(_spaces);
    process = await Process.start(segments.first, segments.skip(1).toList(), workingDirectory: directory.path);
  }
  final List<String> output = <String>[];
  utf8.decoder.bind(process.stdout).transform(const LineSplitter()).listen(verbose ? printLog : output.add);
  utf8.decoder.bind(process.stderr).transform(const LineSplitter()).listen(verbose ? printLog : output.add);
  final bool success = await process.exitCode == 0;
  if (success || silentFailure)
    return success;
  if (!verbose) {
    print('>> $command');
    output.forEach(printLog);
  }
  return success;
}

void printLog(String line) {
  print('| $line'.trimRight());
}
