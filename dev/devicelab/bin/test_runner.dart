// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutter_devicelab/command/test.dart';
import 'package:flutter_devicelab/command/upload_metrics.dart';

final CommandRunner<void> runner =
    CommandRunner<void>('devicelab_runner', 'DeviceLab test runner for recording performance metrics on applications')
      ..addCommand(TestCommand())
      ..addCommand(UploadMetricsCommand());

Future<void> main(List<String> rawArgs) async {
  runner.run(rawArgs).catchError((dynamic error) {
    stderr.writeln('$error\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(runner.usage);
    exit(64); // Exit code 64 indicates a usage error.
  });
}
