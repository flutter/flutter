// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:bazel_tools/bazel_tools.dart';

Future<void> main(List<String> arguments) async {
  final GenDepsCommand? command = GenDepsCommand.fromCommandLine(arguments);
  if (command == null) {
    io.exitCode = 1;
    return;
  }
  io.exitCode = await command.run();
}
