// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:path/path.dart' as path;

// TODO(fujino): delete this script once PR #71244 lands on stable.
void main(List<String> args) {
  final String scriptPath = io.Platform.script.toFilePath();
  final String scriptDir = path.dirname(scriptPath);
  final String repoRoot = path.normalize(path.join(scriptDir, '..', '..'));
  final io.ProcessResult result = io.Process.runSync(
    path.join(repoRoot, 'dev', 'tools', 'bin', 'conductor'),
    <String>['codesign', '--verify'],
  );
  if (result.exitCode != 0) {
    print('codesign script exited with code $result.exitCode');
    print('stdout:\n${result.stdout}\n');
    print('stderr:\n${result.stderr}\n');
    io.exit(1);
  }
  print('codesign script succeeded.');
  print('stdout:\n${result.stdout}');
}
