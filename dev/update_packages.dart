#!/usr/bin/env dart
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

final String binaryName = Platform.isWindows ? 'pub.bat' : 'pub';
update(Directory directory) {
  for (FileSystemEntity dir in directory.listSync()) {
    if (dir is Directory) {
      stdout.write("Updating ${dir.path}...");
      ProcessResult result = Process.runSync(
        binaryName,
        ['get', '-v'],
        workingDirectory: dir.path);
      if (result.exitCode != 0) {
        print(" FAILED!");
        print("---- Standard output: ----");
        print(result.stdout);
        print("---- Standard error: ----");
        print(result.stderr);
      } else {
        print(" done.");
      }
    }
  }
}

main() {
  String FLUTTER_ROOT = new File(Platform.script.toFilePath()).parent.parent.path;
  update(new Directory("$FLUTTER_ROOT/packages"));
  update(new Directory("$FLUTTER_ROOT/examples"));
}
