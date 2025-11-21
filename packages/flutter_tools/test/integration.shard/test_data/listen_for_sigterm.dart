// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/io.dart';

// This application will log to STDOUT and exit with 0 when it receives the
// SIGTERM signal.
Future<void> main() async {
  final Stdout stdout = Stdio().stdout;
  final Stream<ProcessSignal> interruptStream = ProcessSignal.sigterm.watch();
  interruptStream.listen((_) {
    // The test should assert that this was logged
    stdout.writeln('Successfully received SIGTERM!');
    exit(0);
  });
  // The test should wait for this message before sending SIGTERM, or else the
  // listener may not have been registered.
  stdout.writeln('Ready to receive signals');

  await Future<void>.delayed(const Duration(seconds: 10));
  stdout.writeln('Did not receive SIGTERM!');
  exit(1);
}
