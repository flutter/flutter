// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

abstract class CommandHandler {
  final String name;
  final String description;

  CommandHandler(this.name, this.description);

  ArgParser get parser;

  /// @return 0 for no errors or warnings executing command, 1 for warnings, 2 for errors.
  Future<int> processArgResults(ArgResults results);

  void printUsage([String message]) {
    if (message != null) {
      print('${message}\n');
    }
    print('usage: sky_tools ${name} [arguments]');
    print('');
    print(parser.usage);
  }

  String toString() => name;
}
