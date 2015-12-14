#!/usr/bin/env dart
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

final String binaryName = Platform.isWindows ? 'pub.bat' : 'pub';
int runPub(Directory directory, List<String> pubArgs) {
  int updateCount = 0;
  for (FileSystemEntity dir in directory.listSync()) {
    if (dir is Directory) {
      updateCount++;
      Stopwatch timer = new Stopwatch()..start();
      stdout.write("Updating ${dir.path}...");
      ProcessResult result = Process.runSync(
        binaryName,
        pubArgs,
        workingDirectory: dir.path
      );
      timer.stop();
      stdout.write(" (${timer.elapsedMilliseconds} ms)");
      if (result.exitCode != 0) {
        print("... failed with exit code ${result.exitCode}.");
        print(result.stdout);
        print(result.stderr);
      } else {
        stdout.write("\n");
      }
    }
  }
  return updateCount;
}

void main(List<String> arguments) {
  Stopwatch timer = new Stopwatch()..start();
  bool upgrade = arguments.length > 0 && arguments[0] == '--upgrade';
  String FLUTTER_ROOT = new File(Platform.script.toFilePath()).parent.parent.path;
  List<String> pubArgs = [ upgrade ? 'upgrade' : 'get' ];
  int count = 0;
  count += runPub(new Directory("$FLUTTER_ROOT/packages"), pubArgs);
  count += runPub(new Directory("$FLUTTER_ROOT/examples"), pubArgs);
  String command = "$binaryName ${pubArgs.join(' ')}";
  print("Ran \"$command\" $count times in ${timer.elapsedMilliseconds} ms");
}
