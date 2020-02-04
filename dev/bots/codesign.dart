// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

class CodesignFailure {
  const CodesignFailure({
    this.binaryPath,
    this.exitCode,
    this.stderr,
  });

  final int exitCode;
  final String binaryPath;
  final String stderr;
}

void main() {
  // TODO(fujino): parse codesigning manifest for all files to verify
  final List<String> binaries = <String>[
    path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
    path.join('bin', 'cache', 'artifacts', 'engine', 'darwin-x64', 'flutter_tester'),
    path.join('bin', 'cache', 'artifacts', 'engine', 'darwin-x64', 'gen_snapshot'),
  ];
  final List<CodesignFailure> failures = <CodesignFailure>[];

  for (final String binaryPath in binaries) {
    final ProcessResult result = Process.runSync(
      'codesign',
      <String>[
        '-vvv',
        binaryPath,
      ],
    );
    if (result.exitCode != 0) {
      failures.add(CodesignFailure(
        binaryPath: binaryPath,
        exitCode: result.exitCode,
        stderr: result.stderr as String,
      ));
    }
  }

  if (failures.isNotEmpty) {
    for (final CodesignFailure failure in failures) {
      print('File "${failure.binaryPath}" does not appear to be codesigned.\n'
            'The `codesign` command failed with exit code ${failure.exitCode} and the stderr:\n'
            '${failure.stderr}\n');
    }
    exit(1);
  }

  print('Verified that binaries are codesigned.');
}
