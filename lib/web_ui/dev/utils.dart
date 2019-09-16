// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'environment.dart';

class FilePath {
  FilePath.fromCwd(String relativePath)
      : _absolutePath = path.absolute(relativePath);
  FilePath.fromWebUi(String relativePath)
      : _absolutePath = path.join(environment.webUiRootDir.path, relativePath);

  final String _absolutePath;

  String get absolute => _absolutePath;
  String get relativeToCwd => path.relative(_absolutePath);
  String get relativeToWebUi =>
      path.relative(_absolutePath, from: environment.webUiRootDir.path);

  @override
  bool operator ==(dynamic other) {
    return other is FilePath && _absolutePath == other._absolutePath;
  }

  @override
  String toString() => _absolutePath;
}

Future<int> runProcess(
  String executable,
  List<String> arguments, {
  String workingDirectory,
}) async {
  final io.Process process = await io.Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  return _forwardIOAndWait(process);
}

Future<int> _forwardIOAndWait(io.Process process) {
  final StreamSubscription stdoutSub = process.stdout.listen(io.stdout.add);
  final StreamSubscription stderrSub = process.stderr.listen(io.stderr.add);
  return process.exitCode.then<int>((int exitCode) {
    stdoutSub.cancel();
    stderrSub.cancel();
    return exitCode;
  });
}
