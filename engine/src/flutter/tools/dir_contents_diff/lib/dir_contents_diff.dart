// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// The main entrypoint for the program, returns `exitCode`.
int run(List<String> args) {
  if (args.length != 1) {
    throw Exception('usage: <path to directory>');
  }
  final String dirPath = args[0];
  if (!Directory(dirPath).existsSync()) {
    throw Exception('unable to find `$dirPath`');
  }

  // Look for at least one golden file generated.
  for (final FileSystemEntity entity in Directory(dirPath).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.png')) {
      return;
    }
  }
  throw Exception('Failed to find golden files.');
}
