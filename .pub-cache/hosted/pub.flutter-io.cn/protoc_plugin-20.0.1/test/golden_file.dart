// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Will test [actual] against the contests of the file at [goldenFilePath].
///
/// If the file doesn't exist, the file is instead created containing [actual].
void expectMatchesGoldenFile(String actual, String goldenFilePath) {
  var goldenFile = File(goldenFilePath);
  if (goldenFile.existsSync()) {
    expect(actual, equals(goldenFile.readAsStringSync()),
        reason: 'goldenFilePath: "$goldenFilePath"');
  } else {
    // This enables writing the updated file when the run in otherwise hermetic
    // settings.
    var workspaceDirectory = Platform.environment['BUILD_WORKSPACE_DIRECTORY'];
    if (workspaceDirectory != null) {
      goldenFile = File(path.join(workspaceDirectory, goldenFilePath));
    }
    goldenFile
      ..createSync(recursive: true)
      ..writeAsStringSync(actual);
  }
}
